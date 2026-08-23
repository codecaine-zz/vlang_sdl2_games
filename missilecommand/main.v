module main

import os
import sdl

fn main() {
	if sdl.init(sdl.init_video | sdl.init_audio) != 0 {
		return
	}
	defer { sdl.quit() }

	if os.args.contains('--snapshot') || os.args.contains('--snap') {
		surface := sdl.create_rgb_surface(0, 800, 600, 32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000)
		s_renderer := sdl.create_software_renderer(surface)
		mut game := new_missilecommand_game()
		game.state = .playing
		game.score = 15400
		// Descending enemy missiles
		game.icbms.clear()
		game.icbms << ICBM{ start_x: 100.0, start_y: 0.0, target_x: 220.0, target_y: 540.0, x: 160.0, y: 270.0, speed: 45.0, active: true }
		game.icbms << ICBM{ start_x: 400.0, start_y: 0.0, target_x: 400.0, target_y: 540.0, x: 400.0, y: 180.0, speed: 50.0, active: true }
		game.icbms << ICBM{ start_x: 700.0, start_y: 0.0, target_x: 580.0, target_y: 540.0, x: 640.0, y: 270.0, speed: 45.0, active: true }
		// Rising interceptor
		game.interceptors << Interceptor{ start_x: 400.0, start_y: 540.0, target_x: 400.0, target_y: 190.0, x: 400.0, y: 260.0, speed: 450.0, active: true }
		// Explosive flak clouds
		game.blasts << BlastCloud{ x: 300.0, y: 200.0, radius: 28.0, max_radius: 35.0, timer: 0.6, active: true }
		game.blasts << BlastCloud{ x: 500.0, y: 220.0, radius: 22.0, max_radius: 35.0, timer: 0.8, active: true }

		render_missilecommand_game(s_renderer, mut game, unsafe { nil })
		sdl.save_bmp(surface, 'screenshots/missilecommand.bmp'.str)
		sdl.destroy_renderer(s_renderer)
		sdl.free_surface(surface)
		return
	}

	window := sdl.create_window(
		'Missile Command Air Defense'.str,
		sdl.windowpos_centered,
		sdl.windowpos_centered,
		800,
		600,
		u32(sdl.WindowFlags.shown) | u32(sdl.WindowFlags.fullscreen_desktop) | u32(sdl.WindowFlags.resizable)
	)
	if unsafe { window == nil } { return }
	defer { sdl.destroy_window(window) }

	renderer := sdl.create_renderer(window, -1, u32(sdl.RendererFlags.accelerated) | u32(sdl.RendererFlags.presentvsync))
	if unsafe { renderer == nil } { return }
	defer { sdl.destroy_renderer(renderer) }
	sdl.render_set_logical_size(renderer, 800, 600)

	mut tex_mgr := MissileCommandTextureManager{}
	tex_mgr.init(renderer)

	mut game := new_missilecommand_game()

	mut running := true
	mut event := sdl.Event{}
	mut last_ticks := sdl.get_ticks()

	for running {
		for sdl.poll_event(&event) != 0 {
			match unsafe { event.@type } {
				.quit { running = false }
				.mousemotion {
					game.crosshair_x = f32(event.motion.x)
					game.crosshair_y = f32(event.motion.y)
				}
				.mousebuttondown {
					if event.button.button == u8(sdl.button_left) {
						if game.state == .menu || game.state == .game_over {
							game.reset_game()
						} else {
							game.fire_interceptor(f32(event.button.x), f32(event.button.y))
						}
					}
				}
				.keydown {
					sym := event.key.keysym.sym
					if sym == int(sdl.KeyCode.f11) {
						toggle_fullscreen(window)
					} else if sym == int(sdl.KeyCode.space) {
						if game.state == .menu || game.state == .game_over {
							game.reset_game()
						} else {
							game.fire_interceptor(game.crosshair_x, game.crosshair_y)
						}
					} else if sym == int(sdl.KeyCode.p) {
						if game.state == .playing { game.state = .paused }
						else if game.state == .paused { game.state = .playing }
					} else if sym == int(sdl.KeyCode.r) { game.reset_game() }
					else if sym == int(sdl.KeyCode.m) { game.sound_mgr.toggle_sound() }
					else if sym == int(sdl.KeyCode.escape) { running = false }
				}
				else {}
			}
		}

		current_ticks := sdl.get_ticks()
		dt := f32(current_ticks - last_ticks) / 1000.0
		last_ticks = current_ticks

		capped_dt := if dt > 0.05 { f32(0.05) } else { dt }
		game.update(capped_dt)
		render_missilecommand_game(renderer, mut game, tex_mgr.sprite_texture)

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
