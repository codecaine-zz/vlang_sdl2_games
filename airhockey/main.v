module main

import math
import os
import sdl

const win_w = 940
const win_h = 660

struct App {
mut:
	window      &sdl.Window   = unsafe { nil }
	renderer    &sdl.Renderer = unsafe { nil }
	game        AirHockeyGame
	sound_mgr   SoundManager
	tex_mgr     AirHockeyTextureManager
	p1_target_x f64
	p1_target_y f64
	p2_target_x f64
	p2_target_y f64
	p1_up       bool
	p1_down     bool
	p1_left     bool
	p1_right    bool
	p2_up       bool
	p2_down     bool
	p2_left     bool
	p2_right    bool
	use_mouse_p1 bool = true
}

fn new_app() App {
	return App{
		game:      new_airhockey_game(false)
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
	if os.args.contains('--snap') || os.args.contains('--snapshot') || os.getenv('SNAPSHOT') == '1' {
		surface := sdl.create_rgb_surface(0, win_w, win_h, 32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000)
		if unsafe { surface == nil } { return }
		defer { sdl.free_surface(surface) }

		renderer := sdl.create_software_renderer(surface)
		if unsafe { renderer == nil } { return }
		defer { sdl.destroy_renderer(renderer) }
	sdl.render_set_logical_size(renderer, win_w, win_h)

		mut snap_game := new_airhockey_game(false)
		snap_game.score_p1 = 4
		snap_game.score_p2 = 3
		snap_game.puck.x = win_w / 2.0 + 80.0
		snap_game.puck.y = win_h / 2.0 - 40.0
		snap_game.puck.vx = -350.0
		snap_game.puck.vy = 180.0
		snap_game.puck.trail = [
			[win_w / 2.0 + 160.0, win_h / 2.0 - 80.0],
			[win_w / 2.0 + 130.0, win_h / 2.0 - 65.0],
			[win_w / 2.0 + 100.0, win_h / 2.0 - 50.0],
		]
		snap_game.p1_mallet.x = win_w / 2.0 - 150.0
		snap_game.p1_mallet.y = win_h / 2.0 - 30.0
		snap_game.p2_mallet.x = win_w / 2.0 + 220.0
		snap_game.p2_mallet.y = win_h / 2.0 - 100.0

		render_airhockey_game(renderer, mut snap_game, win_w, win_h, unsafe { nil })
		sdl.save_bmp(surface, 'screenshots/airhockey.bmp'.str)
		return
	}

	mut app := new_app()

	window := sdl.create_window(
		'Hyper Air Hockey - 2D Physics Arcade Table'.str,
		sdl.windowpos_centered,
		sdl.windowpos_centered,
		win_w,
		win_h,
		u32(sdl.WindowFlags.shown) | u32(sdl.WindowFlags.fullscreen_desktop) | u32(sdl.WindowFlags.resizable) | u32(sdl.WindowFlags.fullscreen_desktop) | u32(sdl.WindowFlags.resizable)
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
	app.tex_mgr.init(renderer)

	app.window = window
	app.renderer = renderer
	app.p1_target_x = app.game.p1_mallet.x
	app.p1_target_y = app.game.p1_mallet.y
	app.p2_target_x = app.game.p2_mallet.x
	app.p2_target_y = app.game.p2_mallet.y

	mut event := sdl.Event{}
	mut running := true
	mut last_ticks := sdl.get_ticks()

	for running {
		now := sdl.get_ticks()
		dt := math.min(f64(now - last_ticks) / 1000.0, 0.05)
		last_ticks = now

		for sdl.poll_event(&event) != 0 {
			match event.@type {
				.quit {
					running = false
				}
				.mousemotion {
					if app.use_mouse_p1 {
						app.p1_target_x = f64(event.motion.x)
						app.p1_target_y = f64(event.motion.y)
					}
				}
				.keydown {
					sym := int(event.key.keysym.sym)
					match sym {
						int(sdl.KeyCode.f11) {
							toggle_fullscreen(window)
						}
						int(sdl.KeyCode.escape) {
							running = false
						}
						int(sdl.KeyCode.r), int(sdl.KeyCode.space) {
							if app.game.state == .game_over {
								app.game.reset_game()
							} else if sym == int(sdl.KeyCode.r) {
								app.game.reset_game()
							}
						}
						int(sdl.KeyCode.m) {
							app.game.is_two_player = !app.game.is_two_player
							app.game.reset_game()
						}
						int(sdl.KeyCode.tab) {
							app.game.difficulty = match app.game.difficulty {
								.easy { AIDifficulty.medium }
								.medium { AIDifficulty.hard }
								.hard { AIDifficulty.easy }
							}
						}
						int(sdl.KeyCode.v), int(sdl.KeyCode.o) {
							app.sound_mgr.toggle_sound()
						}
						// P1 WASD Keyboard controls
						int(sdl.KeyCode.w) { app.p1_up = true; app.use_mouse_p1 = false }
						int(sdl.KeyCode.s) { app.p1_down = true; app.use_mouse_p1 = false }
						int(sdl.KeyCode.a) { app.p1_left = true; app.use_mouse_p1 = false }
						int(sdl.KeyCode.d) { app.p1_right = true; app.use_mouse_p1 = false }
						// P2 Arrow / IJKL Keyboard controls
						int(sdl.KeyCode.up), int(sdl.KeyCode.i) { app.p2_up = true }
						int(sdl.KeyCode.down), int(sdl.KeyCode.k) { app.p2_down = true }
						int(sdl.KeyCode.left), int(sdl.KeyCode.j) { app.p2_left = true }
						int(sdl.KeyCode.right), int(sdl.KeyCode.l) { app.p2_right = true }
						else {}
					}
				}
				.keyup {
					sym := int(event.key.keysym.sym)
					match sym {
						int(sdl.KeyCode.w) { app.p1_up = false }
						int(sdl.KeyCode.s) { app.p1_down = false }
						int(sdl.KeyCode.a) { app.p1_left = false }
						int(sdl.KeyCode.d) { app.p1_right = false }
						int(sdl.KeyCode.up), int(sdl.KeyCode.i) { app.p2_up = false }
						int(sdl.KeyCode.down), int(sdl.KeyCode.k) { app.p2_down = false }
						int(sdl.KeyCode.left), int(sdl.KeyCode.j) { app.p2_left = false }
						int(sdl.KeyCode.right), int(sdl.KeyCode.l) { app.p2_right = false }
						else {}
					}
				}
				else {}
			}
		}

		// Process keyboard movement deltas
		kbd_speed := 600.0 * dt
		if !app.use_mouse_p1 {
			if app.p1_up { app.p1_target_y -= kbd_speed }
			if app.p1_down { app.p1_target_y += kbd_speed }
			if app.p1_left { app.p1_target_x -= kbd_speed }
			if app.p1_right { app.p1_target_x += kbd_speed }
		}

		if app.game.is_two_player {
			if app.p2_up { app.p2_target_y -= kbd_speed }
			if app.p2_down { app.p2_target_y += kbd_speed }
			if app.p2_left { app.p2_target_x -= kbd_speed }
			if app.p2_right { app.p2_target_x += kbd_speed }
		}

		app.game.update(dt, app.p1_target_x, app.p1_target_y, app.p2_target_x, app.p2_target_y)

		// Play sound events
		if app.game.sound_event != '' {
			ev := app.game.sound_event
			speed := app.game.sound_speed
			app.game.sound_event = ''
			match ev {
				'hit' { app.sound_mgr.play_mallet_hit(speed) }
				'rail' { app.sound_mgr.play_rail_bounce(speed) }
				'goal' { app.sound_mgr.play_goal_horn() }
				'victory' { app.sound_mgr.play_victory() }
				else {}
			}
		}

		app.sound_mgr.update_bgm(app.game.state != .game_over)

		sdl.set_render_draw_color(renderer, 0, 0, 0, 255)
		sdl.render_clear(renderer)

		render_airhockey_game(renderer, mut app.game, win_w, win_h, app.tex_mgr.sprite_texture)

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
