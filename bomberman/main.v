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
		mut game := new_bomberman_game()
		game.state = .playing
		if game.players.len > 1 {
			game.players[0].x = 220.0
			game.players[0].y = 160.0
			game.players[1].x = 580.0
			game.players[1].y = 440.0
		}
		// Active ticking bomb
		game.bombs << Bomb{ grid_x: 4, grid_y: 3, owner_id: 1, fuse_timer: 1.2, radius: 3, active: true }
		// Crossfire flame explosion
		game.flames << FlameRay{ grid_x: 7, grid_y: 5, timer: 0.4 }
		game.flames << FlameRay{ grid_x: 6, grid_y: 5, timer: 0.4 }
		game.flames << FlameRay{ grid_x: 8, grid_y: 5, timer: 0.4 }
		game.flames << FlameRay{ grid_x: 7, grid_y: 4, timer: 0.4 }
		game.flames << FlameRay{ grid_x: 7, grid_y: 6, timer: 0.4 }

		render_bomberman_game(s_renderer, mut game, unsafe { nil })
		sdl.save_bmp(surface, 'screenshots/bomberman.bmp'.str)
		sdl.destroy_renderer(s_renderer)
		sdl.free_surface(surface)
		return
	}

	window := sdl.create_window(
		'Cyber Bomberman Tactical Maze'.str,
		sdl.windowpos_centered,
		sdl.windowpos_centered,
		800,
		600,
		u32(sdl.WindowFlags.shown) | u32(sdl.WindowFlags.fullscreen_desktop) | u32(sdl.WindowFlags.resizable)
	)
	if unsafe { window == nil } {
		return
	}
	defer { sdl.destroy_window(window) }

	renderer := sdl.create_renderer(window, -1, u32(sdl.RendererFlags.accelerated) | u32(sdl.RendererFlags.presentvsync))
	if unsafe { renderer == nil } {
		return
	}
	defer { sdl.destroy_renderer(renderer) }
	sdl.render_set_logical_size(renderer, 800, 600)

	mut tex_mgr := BombermanTextureManager{}
	tex_mgr.init(renderer)

	mut game := new_bomberman_game()

	mut running := true
	mut event := sdl.Event{}
	mut last_ticks := sdl.get_ticks()

	for running {
		for sdl.poll_event(&event) != 0 {
			match unsafe { event.@type } {
				.quit {
					running = false
				}
				.keydown {
					sym := event.key.keysym.sym
					if sym == int(sdl.KeyCode.f11) {
						toggle_fullscreen(window)
					} else if sym == int(sdl.KeyCode.a) { game.key_p1_left = true }
					else if sym == int(sdl.KeyCode.d) { game.key_p1_right = true }
					else if sym == int(sdl.KeyCode.w) { game.key_p1_up = true }
					else if sym == int(sdl.KeyCode.s) { game.key_p1_down = true }
					else if sym == int(sdl.KeyCode.space) {
						if game.state == .menu || game.state == .game_over || game.state == .victory {
							game.reset_game()
						} else {
							game.key_p1_bomb = true
						}
					} else if sym == int(sdl.KeyCode.left) { game.key_p2_left = true }
					else if sym == int(sdl.KeyCode.right) { game.key_p2_right = true }
					else if sym == int(sdl.KeyCode.up) { game.key_p2_up = true }
					else if sym == int(sdl.KeyCode.down) { game.key_p2_down = true }
					else if sym == int(sdl.KeyCode.@return) || sym == int(sdl.KeyCode.kp_enter) { game.key_p2_bomb = true }
					else if sym == int(sdl.KeyCode.p) {
						if game.state == .playing { game.state = .paused }
						else if game.state == .paused { game.state = .playing }
					} else if sym == int(sdl.KeyCode.r) { game.reset_game() }
					else if sym == int(sdl.KeyCode.m) { game.sound_mgr.toggle_sound() }
					else if sym == int(sdl.KeyCode.escape) { running = false }
				}
				.keyup {
					sym := event.key.keysym.sym
					if sym == int(sdl.KeyCode.a) { game.key_p1_left = false }
					else if sym == int(sdl.KeyCode.d) { game.key_p1_right = false }
					else if sym == int(sdl.KeyCode.w) { game.key_p1_up = false }
					else if sym == int(sdl.KeyCode.s) { game.key_p1_down = false }
					else if sym == int(sdl.KeyCode.left) { game.key_p2_left = false }
					else if sym == int(sdl.KeyCode.right) { game.key_p2_right = false }
					else if sym == int(sdl.KeyCode.up) { game.key_p2_up = false }
					else if sym == int(sdl.KeyCode.down) { game.key_p2_down = false }
					else if sym == int(sdl.KeyCode.space) { game.key_p1_bomb = false }
					else if sym == int(sdl.KeyCode.@return) || sym == int(sdl.KeyCode.kp_enter) { game.key_p2_bomb = false }
				}
				else {}
			}
		}

		current_ticks := sdl.get_ticks()
		dt := f32(current_ticks - last_ticks) / 1000.0
		last_ticks = current_ticks

		capped_dt := if dt > 0.05 { f32(0.05) } else { dt }
		game.update(capped_dt)
		render_bomberman_game(renderer, mut game, tex_mgr.sprite_texture)

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
