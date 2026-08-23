module main

import math
import os
import sdl

fn main() {
	if sdl.init(sdl.init_video | sdl.init_audio) != 0 {
		eprintln('Failed to initialize SDL')
		return
	}
	defer { sdl.quit() }

	// Snapshot capture for tests / docs
	if os.args.contains('--snapshot') || os.args.contains('--snap') {
		surface := sdl.create_rgb_surface(0, 800, 600, 32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000)
		if unsafe { surface == nil } {
			return
		}
		defer { sdl.free_surface(surface) }

		s_renderer := sdl.create_software_renderer(surface)
		if unsafe { s_renderer == nil } {
			return
		}
		defer { sdl.destroy_renderer(s_renderer) }

		mut game := new_mario_bros_game()
		game.start_game(.two_players)
		game.state = .playing
		game.phase = 4
		game.high_score = 38400

		// Setup Mario (P1) jumping near POW block
		if game.players.len > 0 {
			game.players[0].x = 360.0
			game.players[0].y = 440.0
			game.players[0].vx = 140.0
			game.players[0].vy = -280.0
			game.players[0].is_jumping = true
			game.players[0].score = 12800
			game.players[0].invuln_timer = 0.0
		}

		// Setup Luigi (P2) kicking flipped turtle on lower right
		if game.players.len > 1 {
			game.players[1].x = 520.0
			game.players[1].y = 380.0
			game.players[1].vx = 180.0
			game.players[1].facing_right = true
			game.players[1].score = 9600
			game.players[1].invuln_timer = 0.0
		}

		// Enemies in action across tiers
		game.enemies.clear()
		// Flipped shellcreeper being kicked
		game.enemies << Enemy{
			id: 1
			enemy_type: .shellcreeper
			state: .stunned
			x: 548.0
			y: 388.0
			vx: 0.0
			vy: 0.0
			stun_timer: 5.0
			is_grounded: true
			active: true
		}
		// Angry crab walking on middle tier
		game.enemies << Enemy{
			id: 2
			enemy_type: .sidestepper
			state: .angry
			angry_level: 1
			x: 320.0
			y: 262.0
			vx: -160.0
			vy: 0.0
			facing_right: false
			is_grounded: true
			active: true
		}
		// Fighter fly hopping on top tier
		game.enemies << Enemy{
			id: 3
			enemy_type: .fighterfly
			state: .walking
			x: 210.0
			y: 110.0
			vx: 110.0
			vy: -180.0
			hop_timer: 0.4
			facing_right: true
			is_grounded: false
			active: true
		}
		// Shellcreeper emerging from top right pipe
		game.enemies << Enemy{
			id: 4
			enemy_type: .shellcreeper
			state: .walking
			x: 690.0
			y: 132.0
			vx: -100.0
			vy: 0.0
			facing_right: false
			is_grounded: true
			active: true
		}

		// Gold coins floating and bouncing
		game.coins.clear()
		game.coins << Coin{ x: 260.0, y: 388.0, vx: 0.0, vy: 0.0, is_grounded: true, anim_timer: 1.0, active: true }
		game.coins << Coin{ x: 440.0, y: 260.0, vx: 0.0, vy: 0.0, is_grounded: true, anim_timer: 2.2, active: true }

		// Water drips
		game.water_drips << WaterDrip{ x: 70.0, y: 250.0, active: true }
		game.water_drips << WaterDrip{ x: 730.0, y: 340.0, active: true }

		// Shockwave effect
		game.shockwaves << Shockwave{
			x: 400.0
			y: 400.0
			radius: 60.0
			max_r: 400.0
			timer: 0.3
			duration: 0.45
			color: Color{ r: 80, g: 190, b: 255, a: 200 }
			active: true
		}

		// Score popup
		game.add_score_popup(550.0, 360.0, '800', Color{ r: 255, g: 240, b: 60, a: 255 })

		render_mario_bros_game(s_renderer, mut game, unsafe { nil })
		sdl.save_bmp(surface, 'screenshots/mariobros.bmp'.str)
		return
	}

	// Normal Windowed Execution
	window := sdl.create_window(
		'Mario Bros. (1983 Arcade Recreation)'.str,
		sdl.windowpos_centered,
		sdl.windowpos_centered,
		800,
		600,
		u32(sdl.WindowFlags.shown) | u32(sdl.WindowFlags.fullscreen_desktop) | u32(sdl.WindowFlags.resizable)
	)
	if unsafe { window == nil } {
		eprintln('Failed to create window')
		return
	}
	defer { sdl.destroy_window(window) }

	renderer := sdl.create_renderer(window, -1, u32(sdl.RendererFlags.accelerated) | u32(sdl.RendererFlags.presentvsync))
	if unsafe { renderer == nil } {
		eprintln('Failed to create renderer')
		return
	}
	defer { sdl.destroy_renderer(renderer) }
	sdl.render_set_logical_size(renderer, 800, 600)

	mut tex_mgr := MarioBrosTextureManager{}
	tex_mgr.init(renderer)

	mut game := new_mario_bros_game()

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
					// Player 1 Controls (WASD + Space / F / X)
					if sym == int(sdl.KeyCode.f11) {
						toggle_fullscreen(window)
					} else if sym == int(sdl.KeyCode.a) || sym == int(sdl.KeyCode.left) {
						game.p1_left = true
					} else if sym == int(sdl.KeyCode.d) || sym == int(sdl.KeyCode.right) {
						game.p1_right = true
					} else if sym == int(sdl.KeyCode.s) || sym == int(sdl.KeyCode.down) {
						game.p1_down = true
					} else if sym == int(sdl.KeyCode.f) || sym == int(sdl.KeyCode.x) {
						game.p1_fire = true
					} else if sym == int(sdl.KeyCode.w) || sym == int(sdl.KeyCode.space) {
						if game.state == .title {
							game.start_game(game.mode)
						} else if game.state == .phase_clear {
							game.next_phase()
						} else if game.state == .game_over {
							game.reset_to_title()
						} else {
							game.p1_jump = true
						}
					}
					// Player 2 Controls (J / L move, I / Up jump, K down, H fire)
					else if sym == int(sdl.KeyCode.j) {
						game.p2_left = true
					} else if sym == int(sdl.KeyCode.l) {
						game.p2_right = true
					} else if sym == int(sdl.KeyCode.k) {
						game.p2_down = true
					} else if sym == int(sdl.KeyCode.h) || sym == int(sdl.KeyCode.semicolon) {
						game.p2_fire = true
					} else if sym == int(sdl.KeyCode.i) || sym == int(sdl.KeyCode.up) {
						if game.state == .title {
							game.start_game(game.mode)
						} else {
							game.p2_jump = true
						}
					}
					// Mode Selection on Title Screen
					else if sym == int(sdl.KeyCode._1) {
						game.mode = .single_player
						if game.state == .title {
							game.start_game(.single_player)
						}
					} else if sym == int(sdl.KeyCode._2) {
						game.mode = .two_players
						if game.state == .title {
							game.start_game(.two_players)
						}
					} else if sym == int(sdl.KeyCode.@return) {
						if game.state == .title {
							game.start_game(game.mode)
						} else if game.state == .phase_clear {
							game.next_phase()
						} else if game.state == .game_over {
							game.reset_to_title()
						}
					}
					// Game control keys
					else if sym == int(sdl.KeyCode.p) {
						if game.state == .playing || game.state == .bonus_phase {
							game.state = .paused
						} else if game.state == .paused {
							game.state = .playing
						}
					} else if sym == int(sdl.KeyCode.r) {
						game.reset_to_title()
					} else if sym == int(sdl.KeyCode.m) {
						game.sound_mgr.toggle_sound()
					} else if sym == int(sdl.KeyCode.c) {
						game.crt_filter = !game.crt_filter
					} else if sym == int(sdl.KeyCode.escape) {
						if game.state == .title {
							running = false
						} else {
							game.reset_to_title()
						}
					}
				}
				.keyup {
					sym := event.key.keysym.sym
					// P1
					if sym == int(sdl.KeyCode.a) || sym == int(sdl.KeyCode.left) {
						game.p1_left = false
					} else if sym == int(sdl.KeyCode.d) || sym == int(sdl.KeyCode.right) {
						game.p1_right = false
					} else if sym == int(sdl.KeyCode.s) || sym == int(sdl.KeyCode.down) {
						game.p1_down = false
					} else if sym == int(sdl.KeyCode.f) || sym == int(sdl.KeyCode.x) {
						game.p1_fire = false
					} else if sym == int(sdl.KeyCode.w) || sym == int(sdl.KeyCode.space) {
						game.p1_jump = false
					}
					// P2
					else if sym == int(sdl.KeyCode.j) {
						game.p2_left = false
					} else if sym == int(sdl.KeyCode.l) {
						game.p2_right = false
					} else if sym == int(sdl.KeyCode.k) {
						game.p2_down = false
					} else if sym == int(sdl.KeyCode.h) || sym == int(sdl.KeyCode.semicolon) {
						game.p2_fire = false
					} else if sym == int(sdl.KeyCode.i) || sym == int(sdl.KeyCode.up) {
						game.p2_jump = false
					}
				}
				else {}
			}
		}

		current_ticks := sdl.get_ticks()
		dt := f32(current_ticks - last_ticks) / 1000.0
		last_ticks = current_ticks
		clamped_dt := f32(math.min(f64(dt), 0.05))

		game.update(clamped_dt)
		render_mario_bros_game(renderer, mut game, tex_mgr.sprite_texture)
		prod_fx_render(renderer)
		sdl.render_present(renderer)
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
