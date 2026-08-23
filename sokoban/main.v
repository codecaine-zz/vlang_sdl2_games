module main

import math
import os
import sdl

const win_w = 900
const win_h = 720

struct App {
mut:
	window    &sdl.Window   = unsafe { nil }
	renderer  &sdl.Renderer = unsafe { nil }
	game      SokobanGame
	sound_mgr SoundManager
	tex_mgr   SokobanTextureManager
	pulse     f64
}

fn new_app() App {
	return App{
		game:      new_sokoban_game()
		sound_mgr: new_sound_manager()
	}
}

fn (mut app App) handle_move(dr int, dc int) {
	moved, pushed, hit_target := app.game.try_move(dr, dc)
	if moved {
		if pushed {
			app.sound_mgr.play_push_sound()
			if hit_target {
				app.sound_mgr.play_target_sound()
			}
		} else {
			app.sound_mgr.play_step_sound()
		}

		if app.game.level_cleared {
			app.sound_mgr.play_win_sound()
		}
	}
}

fn main() {
	if sdl.init(sdl.init_video | sdl.init_audio | sdl.init_events | sdl.init_timer) < 0 {
		eprintln('Failed to initialize SDL2')
		return
	}
	defer { sdl.quit() }

	if os.args.contains('--snap') {
		surface := sdl.create_rgb_surface(0, win_w, win_h, 32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000)
		if unsafe { surface == nil } { return }
		defer { sdl.free_surface(surface) }

		renderer := sdl.create_software_renderer(surface)
		if unsafe { renderer == nil } { return }
		defer { sdl.destroy_renderer(renderer) }
		sdl.render_set_logical_size(renderer, win_w, win_h)

		mut snap_game := new_sokoban_game()
		snap_game.load_level(4) // Cloverleaf Chamber
		snap_game.try_move(0, 1) // Push a crate
		snap_game.steps = 14
		snap_game.pushes = 5

		render_sokoban_game(renderer, &snap_game, win_w, win_h, 1.2, unsafe { nil })
		bmp_path := 'screenshots/sokoban.bmp'
		sdl.save_bmp(surface, bmp_path.str)
		return
	}

	mut app := new_app()

	window := sdl.create_window(
		'Sokoban Master - Warehouse Puzzle Strategy'.str,
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
	app.tex_mgr.init(renderer)

	mut event := sdl.Event{}
	mut running := true
	mut last_ticks := sdl.get_ticks()

	for running {
		now := sdl.get_ticks()
		dt := math.min(f64(now - last_ticks) / 1000.0, 0.05)
		last_ticks = now
		app.pulse += dt

		// Smooth player movement interpolation
		target_x := f64(app.game.player_c)
		target_y := f64(app.game.player_r)
		app.game.anim_px += (target_x - app.game.anim_px) * math.min(dt * 18.0, 1.0)
		app.game.anim_py += (target_y - app.game.anim_py) * math.min(dt * 18.0, 1.0)

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
					} else if sym == int(sdl.KeyCode.r) {
						app.game.load_level(app.game.current_level)
					} else if sym == int(sdl.KeyCode.u) || sym == int(sdl.KeyCode.z) {
						app.game.undo()
					} else if sym == int(sdl.KeyCode.n) {
						if app.game.current_level < sokoban_levels.len - 1 {
							app.game.load_level(app.game.current_level + 1)
							app.game.save_progress()
						}
					} else if sym == int(sdl.KeyCode.p) {
						if app.game.current_level > 0 {
							app.game.load_level(app.game.current_level - 1)
							app.game.save_progress()
						}
					} else if sym == int(sdl.KeyCode.space) {
						if app.game.level_cleared {
							if app.game.current_level < sokoban_levels.len - 1 {
								app.game.load_level(app.game.current_level + 1)
								app.game.save_progress()
							}
						}
					} else if sym == int(sdl.KeyCode.m) {
						app.sound_mgr.toggle_sound()
					} else if sym == int(sdl.KeyCode.up) || sym == int(sdl.KeyCode.w) {
						app.handle_move(-1, 0)
					} else if sym == int(sdl.KeyCode.down) || sym == int(sdl.KeyCode.s) {
						app.handle_move(1, 0)
					} else if sym == int(sdl.KeyCode.left) || sym == int(sdl.KeyCode.a) {
						app.handle_move(0, -1)
					} else if sym == int(sdl.KeyCode.right) || sym == int(sdl.KeyCode.d) {
						app.handle_move(0, 1)
					}
				}
				else {}
			}
		}

		app.sound_mgr.update_bgm(true)
		render_sokoban_game(app.renderer, &app.game, win_w, win_h, app.pulse, app.tex_mgr.sprite_texture)
		sdl.delay(16)
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
