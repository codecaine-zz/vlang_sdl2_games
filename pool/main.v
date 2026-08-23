module main

import math
import os
import sdl

struct App {
mut:
	window       &sdl.Window   = unsafe { nil }
	renderer     &sdl.Renderer = unsafe { nil }
	game         PoolGame
	sound_mgr    SoundManager
	tex_mgr      PoolTextureManager
	mouse_down   bool
	drag_start_x f64
	drag_start_y f64
}

fn new_app() App {
	return App{
		game:      new_pool_game()
		sound_mgr: new_sound_manager()
	}
}

fn (app &App) init() bool {
	if sdl.init(sdl.init_video | sdl.init_audio) < 0 {
		eprintln('Failed to init SDL')
		return false
	}

	mut mutable_app := unsafe { &App(app) }
	mutable_app.sound_mgr.init()
	window_flags := u32(sdl.WindowFlags.shown) | u32(sdl.WindowFlags.fullscreen_desktop) | u32(sdl.WindowFlags.resizable)
	mutable_app.window = sdl.create_window('Billiards Pro - 8-Ball & 9-Ball Pool'.str,
		sdl.windowpos_centered, sdl.windowpos_centered, 800, 600, window_flags)

	if mutable_app.window == unsafe { nil } {
		eprintln('Failed to create window')
		return false
	}

	render_flags := u32(sdl.RendererFlags.accelerated) | u32(sdl.RendererFlags.presentvsync)
	mutable_app.renderer = sdl.create_renderer(mutable_app.window, -1, render_flags)

	if mutable_app.renderer == unsafe { nil } {
		eprintln('Failed to create renderer')
		return false
	}

	sdl.render_set_logical_size(mutable_app.renderer, 800, 600)
	mutable_app.tex_mgr.init(mutable_app.renderer)

	sdl.set_render_draw_blend_mode(mutable_app.renderer, .blend)
	return true
}

fn (app &App) run() {
	mut mutable_app := unsafe { &App(app) }
	mut event := sdl.Event{}
	mut last_ticks := sdl.get_ticks()
	mut running := true

	for running {
		if os.getenv('SNAPSHOT') == '1' {
			surface := sdl.create_rgb_surface(0, 800, 600, 32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000)
			if unsafe { surface != nil } {
				sw_rend := sdl.create_software_renderer(surface)
				if unsafe { sw_rend != nil } {
					mutable_app.game.cue_power = 0.65
					mutable_app.game.aim_angle = 0.05
					draw_pool_game(sw_rend, &mutable_app.game, unsafe { nil })
					sdl.save_bmp(surface, 'screenshots/pool.bmp'.str)
					sdl.destroy_renderer(sw_rend)
				}
				sdl.free_surface(surface)
			}
			break
		}

		current_ticks := sdl.get_ticks()
		raw_dt := f64(current_ticks - last_ticks) / 1000.0
		last_ticks = current_ticks
		dt := math.min(0.033, if raw_dt > 0.001 { raw_dt } else { 1.0 / 60.0 })

		for sdl.poll_event(&event) != 0 {
			match unsafe { event.type } {
				.quit {
					running = false
				}
				.mousemotion {
					mx := f64(event.motion.x)
					my := f64(event.motion.y)

					if mutable_app.game.state == .aiming && mutable_app.game.balls.len > 0 && !mutable_app.game.balls[0].potted {
						cx := mutable_app.game.balls[0].x
						cy := mutable_app.game.balls[0].y
						mutable_app.game.aim_angle = math.atan2(my - cy, mx - cx)
					}

					if mutable_app.mouse_down && mutable_app.game.state == .power_pull {
						dy := my - mutable_app.drag_start_y
						mutable_app.game.cue_power = math.min(1.0, math.max(0.0, dy / 120.0))
					}
				}
				.mousebuttondown {
					if event.button.button == u8(sdl.button_left) {
						mx := f64(event.button.x)
						my := f64(event.button.y)

						if mutable_app.game.state == .ball_in_hand {
							// Place cue ball on table felt
							inner_min_x := mutable_app.game.table_x + mutable_app.game.cushion_thick + 12.0
							inner_max_x := mutable_app.game.table_x + mutable_app.game.table_w - mutable_app.game.cushion_thick - 12.0
							inner_min_y := mutable_app.game.table_y + mutable_app.game.cushion_thick + 12.0
							inner_max_y := mutable_app.game.table_y + mutable_app.game.table_h - mutable_app.game.cushion_thick - 12.0

							if mx >= inner_min_x && mx <= inner_max_x && my >= inner_min_y && my <= inner_max_y {
								mutable_app.game.balls[0].x = mx
								mutable_app.game.balls[0].y = my
								mutable_app.game.balls[0].potted = false
								mutable_app.game.state = .aiming
							}
						} else if mutable_app.game.state == .aiming {
							mutable_app.mouse_down = true
							mutable_app.drag_start_x = mx
							mutable_app.drag_start_y = my
							mutable_app.game.state = .power_pull
							mutable_app.game.cue_power = 0.1
						}
					}
				}
				.mousebuttonup {
					if event.button.button == u8(sdl.button_left) && mutable_app.game.state == .power_pull {
						mutable_app.mouse_down = false
						if mutable_app.game.cue_power > 0.05 {
							mutable_app.game.strike_cue_ball(mutable_app.game.cue_power, mut mutable_app.sound_mgr)
						} else {
							mutable_app.game.state = .aiming
						}
						mutable_app.game.cue_power = 0.0
					}
				}
				.keydown {
					sym := event.key.keysym.sym
					if sym == int(sdl.KeyCode.f11) {
						toggle_fullscreen(mutable_app.window)
					} else if sym == int(sdl.KeyCode.escape) {
						running = false
					} else if sym == int(sdl.KeyCode.r) {
						if mutable_app.game.typ == .nine_ball {
							mutable_app.game.rack_9ball()
						} else {
							mutable_app.game.rack_8ball()
						}
						mutable_app.game.state = .aiming
					} else if sym == int(sdl.KeyCode.m) {
						mutable_app.sound_mgr.toggle_sound()
					} else if sym == int(sdl.KeyCode._1) {
						mutable_app.game.set_mode(.eight_ball, false, false)
					} else if sym == int(sdl.KeyCode._2) {
						mutable_app.game.set_mode(.nine_ball, false, false)
					} else if sym == int(sdl.KeyCode._3) {
						mutable_app.game.set_mode(.practice, false, false)
					} else if sym == int(sdl.KeyCode.p) {
						// 2P Versus
						mutable_app.game.set_mode(mutable_app.game.typ, true, false)
					} else if sym == int(sdl.KeyCode.c) {
						// CPU AI
						mutable_app.game.set_mode(mutable_app.game.typ, false, true)
					} else if sym == int(sdl.KeyCode.tab) {
						mutable_app.game.ai_diff = (mutable_app.game.ai_diff + 1) % 3
					} else if sym == int(sdl.KeyCode.left) || sym == int(sdl.KeyCode.a) {
						mutable_app.game.aim_angle -= 0.04
					} else if sym == int(sdl.KeyCode.right) || sym == int(sdl.KeyCode.d) {
						mutable_app.game.aim_angle += 0.04
					} else if sym == int(sdl.KeyCode.space) {
						if mutable_app.game.state == .aiming {
							mutable_app.game.state = .power_pull
							mutable_app.game.cue_power = 0.0
						}
					}
				}
				.keyup {
					sym := event.key.keysym.sym
					if sym == int(sdl.KeyCode.space) && mutable_app.game.state == .power_pull {
						if mutable_app.game.cue_power > 0.05 {
							mutable_app.game.strike_cue_ball(mutable_app.game.cue_power, mut mutable_app.sound_mgr)
						} else {
							mutable_app.game.state = .aiming
						}
						mutable_app.game.cue_power = 0.0
					}
				}
				else {}
			}
		}

		mutable_app.game.update(dt, mut mutable_app.sound_mgr)
		mutable_app.sound_mgr.update_bgm(true)

		draw_pool_game(mutable_app.renderer, &mutable_app.game, mutable_app.tex_mgr.sprite_texture)
		prod_fx_render(mutable_app.renderer)
		sdl.render_present(mutable_app.renderer)
		sdl.delay(1)
	}

	sdl.destroy_renderer(mutable_app.renderer)
	sdl.destroy_window(mutable_app.window)
	sdl.quit()
}

fn main() {
	mut app := new_app()
	if app.init() {
		app.run()
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
