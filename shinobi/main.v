module main

import os
import sdl

fn main() {
	sdl.init(sdl.init_video | sdl.init_audio)
	defer { sdl.quit() }

	if os.getenv('SNAPSHOT') == '1' || os.args.contains('--snap') {
		surface := sdl.create_rgb_surface(0, 800, 600, 32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000)
		if unsafe { surface == nil } { return }
		defer { sdl.free_surface(surface) }

		renderer := sdl.create_software_renderer(surface)
		if unsafe { renderer == nil } { return }
		defer { sdl.destroy_renderer(renderer) }
	sdl.render_set_logical_size(renderer, 800, 600)

		mut game := new_shinobi_game()
		game.state = .playing
		game.player_x = 180.0
		game.player_y = 380.0
		game.score = 1250
		game.update(0.016)

		render_shinobi_game(renderer, mut game, unsafe { nil })
		sdl.save_bmp(surface, 'screenshots/shinobi.bmp'.str)
		return
	}

	window := sdl.create_window(
		'Cyber Shinobi Runner'.str,
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
	mut tex_mgr := ShinobiTextureManager{}
	tex_mgr.init(renderer)

	mut game := new_shinobi_game()

	mut running := true
	mut event := sdl.Event{}
	mut last_ticks := sdl.get_ticks()

	for running {
		for sdl.poll_event(&event) != 0 {
			match unsafe { event.@type } {
				.quit { running = false }
				.keydown {
					sym := event.key.keysym.sym
					if sym == int(sdl.KeyCode.f11) {
						toggle_fullscreen(window)
					} else if sym == int(sdl.KeyCode.left) || sym == int(sdl.KeyCode.a) { game.key_left = true }
					else if sym == int(sdl.KeyCode.right) || sym == int(sdl.KeyCode.d) { game.key_right = true }
					else if sym == int(sdl.KeyCode.w) || sym == int(sdl.KeyCode.up) { game.jump() }
					else if sym == int(sdl.KeyCode.j) || sym == int(sdl.KeyCode.z) { game.slash() }
					else if sym == int(sdl.KeyCode.k) || sym == int(sdl.KeyCode.x) { game.throw_shuriken() }
					else if sym == int(sdl.KeyCode.space) {
						if game.state == .menu || game.state == .game_over {
							game.reset_game()
						} else {
							game.jump()
						}
					} else if sym == int(sdl.KeyCode.p) {
						if game.state == .playing { game.state = .paused }
						else if game.state == .paused { game.state = .playing }
					} else if sym == int(sdl.KeyCode.r) { game.reset_game() }
					else if sym == int(sdl.KeyCode.m) { game.sound_mgr.toggle_sound() }
					else if sym == int(sdl.KeyCode.escape) { running = false }
				}
				.keyup {
					sym := event.key.keysym.sym
					if sym == int(sdl.KeyCode.left) || sym == int(sdl.KeyCode.a) { game.key_left = false }
					else if sym == int(sdl.KeyCode.right) || sym == int(sdl.KeyCode.d) { game.key_right = false }
				}
				else {}
			}
		}

		current_ticks := sdl.get_ticks()
		dt := f32(current_ticks - last_ticks) / 1000.0
		last_ticks = current_ticks

		capped_dt := if dt > 0.05 { f32(0.05) } else { dt }
		game.update(capped_dt)
		game.sound_mgr.update_bgm(game.state == .playing)
		render_shinobi_game(renderer, mut game, tex_mgr.sprite_texture)

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
