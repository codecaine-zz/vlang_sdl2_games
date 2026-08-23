module main

import math
import os
import sdl

const win_w = 920
const win_h = 680

struct App {
mut:
	window            &sdl.Window   = unsafe { nil }
	renderer          &sdl.Renderer = unsafe { nil }
	game              EtchGame
	sound_mgr         SoundManager
	key_left          bool
	key_right         bool
	key_up            bool
	key_down          bool
	is_mouse_down     bool
	last_mouse_x      int
	last_mouse_y      int
	dragging_knob     int // 0: None, 1: Left knob, 2: Right knob
	prev_knob_a       f64
	accum_dist_x      f64
	accum_dist_y      f64
	accum_scratch     f64
	accum_knob_rot    f64
}

fn new_app() App {
	return App{
		game:      new_etch_game()
		sound_mgr: new_sound_manager()
	}
}

fn main() {
	if sdl.init(sdl.init_video | sdl.init_audio | sdl.init_events | sdl.init_timer) < 0 {
		eprintln('Failed to initialize SDL2')
		return
	}
	defer { sdl.quit() }

	// Snapshot mode for README showcase
	if os.args.contains('--snap') {
		surface := sdl.create_rgb_surface(0, win_w, win_h, 32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000)
		if unsafe { surface == nil } { return }
		defer { sdl.free_surface(surface) }

		renderer := sdl.create_software_renderer(surface)
		if unsafe { renderer == nil } { return }
		defer { sdl.destroy_renderer(renderer) }
	sdl.render_set_logical_size(renderer, win_w, win_h)

		mut snap_game := new_etch_game()
		snap_game.tool_mode = .spirograph
		snap_game.spiro.preset = 1
		snap_game.spiro.running = true
		for _ in 0 .. 180 {
			snap_game.update(0.016)
		}
		snap_game.spiro.running = false

		render_etch_game(renderer, mut snap_game, win_w, win_h, true)
		sdl.save_bmp(surface, 'screenshots/etchasketch.bmp'.str)
		return
	}

	mut app := new_app()

	window := sdl.create_window(
		'Etch A Sketch Deluxe - Classic Mechanical Drawing Studio'.str,
		sdl.windowpos_centered,
		sdl.windowpos_centered,
		win_w,
		win_h,
		u32(sdl.WindowFlags.shown) | u32(sdl.WindowFlags.fullscreen_desktop) | u32(sdl.WindowFlags.resizable)
	)
	if unsafe { window == nil } {
		eprintln('Failed to create SDL window')
		return
	}
	defer { sdl.destroy_window(window) }

	renderer := sdl.create_renderer(window, -1, u32(sdl.RendererFlags.accelerated) | u32(sdl.RendererFlags.presentvsync))
	if unsafe { renderer == nil } {
		eprintln('Failed to create SDL renderer')
		return
	}
	defer { sdl.destroy_renderer(renderer) }
	sdl.render_set_logical_size(renderer, win_w, win_h)

	app.window = window
	app.renderer = renderer

	mut event := sdl.Event{}
	mut running := true
	mut last_ticks := sdl.get_ticks()

	for running {
		now := sdl.get_ticks()
		dt := math.min(f64(now - last_ticks) / 1000.0, 0.05)
		last_ticks = now

		// Continuous keyboard movement
		mut kx := 0.0
		mut ky := 0.0
		spd := app.game.speed

		if app.key_left {
			kx -= spd
		}
		if app.key_right {
			kx += spd
		}
		if app.key_up {
			ky -= spd
		}
		if app.key_down {
			ky += spd
		}

		if kx != 0.0 || ky != 0.0 {
			if app.game.move_pen(kx, ky) {
				if kx != 0.0 {
					app.accum_dist_x += math.abs(kx)
					if app.accum_dist_x >= 10.0 {
						app.sound_mgr.play_knob_click(false)
						app.accum_dist_x = 0.0
					}
				}
				if ky != 0.0 {
					app.accum_dist_y += math.abs(ky)
					if app.accum_dist_y >= 10.0 {
						app.sound_mgr.play_knob_click(true)
						app.accum_dist_y = 0.0
					}
				}
			}
		}

		if app.game.toast_timer > 0 {
			app.game.toast_timer -= dt
		}

		for sdl.poll_event(&event) != 0 {
			match event.@type {
				.quit {
					running = false
				}
				.keydown {
					sym := int(event.key.keysym.sym)
					if sym == int(sdl.KeyCode.f11) {
						toggle_fullscreen(window)
					} else if sym == int(sdl.KeyCode.escape) {
						running = false
					} else if sym == int(sdl.KeyCode.f5) {
						app.game.save_state()
					} else if sym == int(sdl.KeyCode.f9) {
						app.game.load_state()
					} else if sym == int(sdl.KeyCode.left) || sym == int(sdl.KeyCode.a) {
						app.key_left = true
					} else if sym == int(sdl.KeyCode.right) || sym == int(sdl.KeyCode.d) {
						app.key_right = true
					} else if sym == int(sdl.KeyCode.up) || sym == int(sdl.KeyCode.w) {
						app.key_up = true
					} else if sym == int(sdl.KeyCode.down) || sym == int(sdl.KeyCode.s) {
						app.key_down = true
					} else if sym == int(sdl.KeyCode.space) {
						if app.game.tool_mode == .spirograph {
							app.game.spiro.running = !app.game.spiro.running
							app.sound_mgr.play_chime(4)
						} else {
							app.game.trigger_shake()
							app.sound_mgr.play_shake_whoosh()
						}
					} else if sym == int(sdl.KeyCode._1) {
						app.game.tool_mode = .freehand
						app.sound_mgr.play_chime(0)
					} else if sym == int(sdl.KeyCode._2) {
						app.game.tool_mode = .spirograph
						app.sound_mgr.play_chime(2)
					} else if sym == int(sdl.KeyCode._3) {
						app.game.tool_mode = .stencil
						app.sound_mgr.play_chime(4)
					} else if sym == int(sdl.KeyCode._4) {
						app.game.tool_mode = .symmetry
						app.sound_mgr.play_chime(7)
					} else if sym == int(sdl.KeyCode.tab) {
						match app.game.tool_mode {
							.spirograph {
								app.game.next_spiro_preset()
								app.sound_mgr.play_chime(3)
							}
							.stencil {
								app.game.current_stencil = (app.game.current_stencil + 1) % app.game.stencils.len
								app.game.evaluate_stencil_progress()
								app.sound_mgr.play_chime(5)
							}
							.symmetry {
								app.game.sym_mode = match app.game.sym_mode {
									.mirror_h { SymmetryMode.mirror_v }
									.mirror_v { SymmetryMode.quad }
									.quad { SymmetryMode.kaleidoscope }
									.kaleidoscope { SymmetryMode.mirror_h }
								}
								app.sound_mgr.play_chime(6)
							}
							else {}
						}
					} else if sym == int(sdl.KeyCode.c) {
						app.game.theme = match app.game.theme {
							.classic_silver { ColorTheme.amber_phosphor }
							.amber_phosphor { ColorTheme.emerald_matrix }
							.emerald_matrix { ColorTheme.cyber_neon }
							.cyber_neon { ColorTheme.rainbow_gradient }
							.rainbow_gradient { ColorTheme.chalkboard }
							.chalkboard { ColorTheme.classic_silver }
						}
						app.sound_mgr.play_chime(8)
					} else if sym == int(sdl.KeyCode.r) {
						app.game.start_replay()
						app.sound_mgr.play_chime(12)
					} else if sym == int(sdl.KeyCode.m) || sym == int(sdl.KeyCode.o) {
						app.sound_mgr.toggle_sound()
					}
				}
				.keyup {
					sym := int(event.key.keysym.sym)
					if sym == int(sdl.KeyCode.left) || sym == int(sdl.KeyCode.a) {
						app.key_left = false
					} else if sym == int(sdl.KeyCode.right) || sym == int(sdl.KeyCode.d) {
						app.key_right = false
					} else if sym == int(sdl.KeyCode.up) || sym == int(sdl.KeyCode.w) {
						app.key_up = false
					} else if sym == int(sdl.KeyCode.down) || sym == int(sdl.KeyCode.s) {
						app.key_down = false
					}
				}
				.mousebuttondown {
					mx := int(event.button.x)
					my := int(event.button.y)
					app.is_mouse_down = true
					app.last_mouse_x = mx
					app.last_mouse_y = my

					// Check Sound / Mute button click
					chassis_x := 40
					chassis_y := 20
					chassis_w := win_w - 80
					sound_btn_x := chassis_x + chassis_w - 150
					sound_btn_y := chassis_y + 12
					if mx >= sound_btn_x && mx <= sound_btn_x + 135 && my >= sound_btn_y && my <= sound_btn_y + 24 {
						app.sound_mgr.toggle_sound()
					}

					// Check mode tabs click
					tab_y := 20 + 44
					if my >= tab_y && my <= tab_y + 24 {
						for i in 0 .. 4 {
							tx := 40 + 60 + i * (140 + 12)
							if mx >= tx && mx <= tx + 140 {
								app.game.tool_mode = match i {
									0 { ToolMode.freehand }
									1 { ToolMode.spirograph }
									2 { ToolMode.stencil }
									else { ToolMode.symmetry }
								}
								app.sound_mgr.play_chime(i * 2)
							}
						}
					}

					// Check knobs click
					knob_l_cx := 40 + 72
					knob_l_cy := 20 + (win_h - 40) - 60
					knob_r_cx := 40 + (win_w - 80) - 72
					knob_r_cy := 20 + (win_h - 40) - 60

					dl := (mx - knob_l_cx) * (mx - knob_l_cx) + (my - knob_l_cy) * (my - knob_l_cy)
					dr := (mx - knob_r_cx) * (mx - knob_r_cx) + (my - knob_r_cy) * (my - knob_r_cy)

					if dl <= 40 * 40 {
						app.dragging_knob = 1
						app.prev_knob_a = math.atan2(f64(my - knob_l_cy), f64(mx - knob_l_cx))
						app.accum_knob_rot = 0.0
					} else if dr <= 40 * 40 {
						app.dragging_knob = 2
						app.prev_knob_a = math.atan2(f64(my - knob_r_cy), f64(mx - knob_r_cx))
						app.accum_knob_rot = 0.0
					}
				}
				.mousebuttonup {
					app.is_mouse_down = false
					app.dragging_knob = 0
				}
				.mousemotion {
					mx := int(event.motion.x)
					my := int(event.motion.y)

					if app.is_mouse_down {
						if app.dragging_knob == 1 {
							// Turning left knob (X-axis)
							knob_l_cx := 40 + 72
							knob_l_cy := 20 + (win_h - 40) - 60
							angle := math.atan2(f64(my - knob_l_cy), f64(mx - knob_l_cx))
							mut da := angle - app.prev_knob_a
							if da > math.pi { da -= 2.0 * math.pi }
							if da < -math.pi { da += 2.0 * math.pi }
							app.prev_knob_a = angle
							if app.game.move_pen(da * 35.0, 0) {
								app.accum_knob_rot += math.abs(da)
								if app.accum_knob_rot >= 0.25 {
									app.sound_mgr.play_knob_click(false)
									app.accum_knob_rot = 0.0
								}
							}
						} else if app.dragging_knob == 2 {
							// Turning right knob (Y-axis)
							knob_r_cx := 40 + (win_w - 80) - 72
							knob_r_cy := 20 + (win_h - 40) - 60
							angle := math.atan2(f64(my - knob_r_cy), f64(mx - knob_r_cx))
							mut da := angle - app.prev_knob_a
							if da > math.pi { da -= 2.0 * math.pi }
							if da < -math.pi { da += 2.0 * math.pi }
							app.prev_knob_a = angle
							if app.game.move_pen(0, da * 35.0) {
								app.accum_knob_rot += math.abs(da)
								if app.accum_knob_rot >= 0.25 {
									app.sound_mgr.play_knob_click(true)
									app.accum_knob_rot = 0.0
								}
							}
						} else {
							// Direct drawing on screen
							sx := app.game.screen_x
							sy := app.game.screen_y
							sw := app.game.screen_w
							sh := app.game.screen_h

							if mx >= sx && mx < sx + sw && my >= sy && my < sy + sh {
								target_x := f64(mx - sx)
								target_y := f64(my - sy)
								dx := target_x - app.game.pen_x
								dy := target_y - app.game.pen_y
								if app.game.move_pen(dx, dy) {
									dist := math.sqrt(dx * dx + dy * dy)
									app.accum_scratch += dist
									if app.accum_scratch >= 18.0 {
										app.sound_mgr.play_scratch()
										app.accum_scratch = 0.0
									}
								}
							}
						}
					}
					app.last_mouse_x = mx
					app.last_mouse_y = my
				}
				else {}
			}
		}

		app.game.update(dt)

		render_etch_game(renderer, mut app.game, win_w, win_h, app.sound_mgr.enabled)
		prod_fx_render(renderer)
		sdl.render_present(renderer)
	}
}

fn toggle_fullscreen(window &sdl.Window) {
	flags := sdl.get_window_flags(window)
	if (flags & u32(sdl.WindowFlags.fullscreen_desktop)) != 0 || (flags & u32(sdl.WindowFlags.fullscreen)) != 0 {
		sdl.set_window_fullscreen(window, 0)
	} else {
		sdl.set_window_fullscreen(window, u32(sdl.WindowFlags.fullscreen_desktop))
	}
}
