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
		mut game := new_donkeykong_game()
		game.state = .playing
		game.score = 14200
		game.high_score = 30000
		game.player_x = 220.0
		game.player_y = 420.0
		game.hammer_timer = 4.0
		game.dk_anim_timer = 1.0

		// Active rolling barrels on multiple tiers
		game.barrels.clear()
		game.barrels << Barrel{ x: 480.0, y: 224.0, vx: -140.0, vy: 0.0, b_type: .normal, active: true }
		game.barrels << Barrel{ x: 300.0, y: 324.0, vx: 140.0, vy: 0.0, b_type: .blue, active: true }
		game.barrels << Barrel{ x: 550.0, y: 424.0, vx: -140.0, vy: 0.0, b_type: .normal, active: true }
		game.barrels << Barrel{ x: 160.0, y: 524.0, vx: -140.0, vy: 0.0, b_type: .normal, active: true }

		// Fireball climbing ladder
		game.fireballs.clear()
		game.fireballs << Fireball{ x: 120.0, y: 380.0, vx: 0.0, vy: -40.0, is_climbing: true, active: true }

		render_donkeykong_game(s_renderer, mut game, unsafe { nil })
		sdl.save_bmp(surface, 'screenshots/donkeykong.bmp'.str)
		sdl.destroy_renderer(s_renderer)
		sdl.free_surface(surface)
		return
	}

	window := sdl.create_window(
		'Donkey Kong Arcade Platformer'.str,
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

	mut tex_mgr := DonkeyKongTextureManager{}
	tex_mgr.init(renderer)

	mut game := new_donkeykong_game()

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
					else if sym == int(sdl.KeyCode.up) || sym == int(sdl.KeyCode.w) { game.key_up = true }
					else if sym == int(sdl.KeyCode.down) || sym == int(sdl.KeyCode.s) { game.key_down = true }
					else if sym == int(sdl.KeyCode.space) {
						if game.state == .menu || game.state == .game_over {
							game.reset_game()
						} else if game.state == .victory {
							game.init_stage()
							game.state = .playing
						} else {
							game.key_jump = true
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
					else if sym == int(sdl.KeyCode.up) || sym == int(sdl.KeyCode.w) { game.key_up = false }
					else if sym == int(sdl.KeyCode.down) || sym == int(sdl.KeyCode.s) { game.key_down = false }
					else if sym == int(sdl.KeyCode.space) { game.key_jump = false }
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
		render_donkeykong_game(renderer, mut game, tex_mgr.sprite_texture)

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
