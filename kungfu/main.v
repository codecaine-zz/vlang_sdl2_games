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

	// Snapshot capture
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

		mut game := new_kung_fu_game()
		game.start_game()
		game.floor = 1
		game.player.score = 14800
		game.player.health = 14
		game.player.x = 420.0
		game.player.y = 400.0
		game.player.facing_right = true
		game.player.attack = .high_kick
		game.player.attack_timer = 0.15

		// Enemies in action
		game.enemies.clear()
		// Gripper rushing from left
		game.enemies << Enemy{
			id: 1
			enemy_type: .gripper
			x: 290.0
			y: 400.0
			vx: 120.0
			vy: 0.0
			facing_right: true
			health: 1
			active: true
		}
		// Knife thrower getting kicked on right
		game.enemies << Enemy{
			id: 2
			enemy_type: .knife_thrower
			x: 468.0
			y: 400.0
			vx: 0.0
			vy: 0.0
			facing_right: false
			health: 1
			is_hit: true
			hit_timer: 0.2
			active: true
		}
		// Tom Tom acrobat leaping
		game.enemies << Enemy{
			id: 3
			enemy_type: .tom_tom
			x: 610.0
			y: 350.0
			vx: -130.0
			vy: -100.0
			facing_right: false
			health: 1
			active: true
		}
		// Stick Fighter boss standing at far right
		game.enemies << Enemy{
			id: 99
			enemy_type: .boss_stick
			x: 710.0
			y: 396.0
			vx: -80.0
			vy: 0.0
			facing_right: false
			health: 10
			max_health: 12
			active: true
		}

		// Flying knife
		game.projectiles << Projectile{
			x: 360.0
			y: 418.0
			vx: 300.0
			vy: 0.0
			active: true
		}

		// Hit sparks & score popup
		game.add_particles(470.0, 415.0, 12, Color{ r: 255, g: 220, b: 60, a: 255 })
		game.add_score_popup(470.0, 370.0, '+200', Color{ r: 255, g: 240, b: 50, a: 255 })

		render_kung_fu_game(s_renderer, mut game)
		sdl.save_bmp(surface, 'screenshots/kungfu.bmp'.str)
		return
	}

	// Normal Window
	window := sdl.create_window(
		'Kung-Fu Master (1984 Irem Arcade / NES Spartan X)'.str,
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

	mut game := new_kung_fu_game()

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
					// Left
					if sym == int(sdl.KeyCode.f11) {
						toggle_fullscreen(window)
					} else if sym == int(sdl.KeyCode.a) || sym == int(sdl.KeyCode.left) {
						game.key_left = true
						if game.last_dir_key == 2 {
							game.shake_off_grippers()
						}
						game.last_dir_key = 1
					}
					// Right
					else if sym == int(sdl.KeyCode.d) || sym == int(sdl.KeyCode.right) {
						game.key_right = true
						if game.last_dir_key == 1 {
							game.shake_off_grippers()
						}
						game.last_dir_key = 2
					}
					// Crouch / Down
					else if sym == int(sdl.KeyCode.s) || sym == int(sdl.KeyCode.down) {
						game.key_down = true
					}
					// Jump / Up
					else if sym == int(sdl.KeyCode.w) || sym == int(sdl.KeyCode.up) || sym == int(sdl.KeyCode.space) {
						if game.state == .title {
							game.start_game()
						} else if game.state == .floor_clear {
							game.next_floor()
						} else if game.state == .game_over || game.state == .victory {
							game.reset_to_title()
						} else {
							game.key_jump = true
						}
					}
					// Punch
					else if sym == int(sdl.KeyCode.j) || sym == int(sdl.KeyCode.z) {
						game.key_punch = true
					}
					// Kick
					else if sym == int(sdl.KeyCode.k) || sym == int(sdl.KeyCode.x) {
						game.key_kick = true
					}
					// Return
					else if sym == int(sdl.KeyCode.@return) {
						if game.state == .title {
							game.start_game()
						} else if game.state == .floor_clear {
							game.next_floor()
						} else if game.state == .game_over || game.state == .victory {
							game.reset_to_title()
						}
					}
					// Pause
					else if sym == int(sdl.KeyCode.p) {
						if game.state == .playing {
							game.state = .paused
						} else if game.state == .paused {
							game.state = .playing
						}
					}
					// Restart
					else if sym == int(sdl.KeyCode.r) {
						game.reset_to_title()
					}
					// Sound toggle
					else if sym == int(sdl.KeyCode.m) {
						game.sound_mgr.toggle_sound()
					}
					// CRT Scanlines toggle
					else if sym == int(sdl.KeyCode.c) {
						game.crt_filter = !game.crt_filter
					}
					// Escape
					else if sym == int(sdl.KeyCode.escape) {
						if game.state == .title {
							running = false
						} else {
							game.reset_to_title()
						}
					}
				}
				.keyup {
					sym := event.key.keysym.sym
					if sym == int(sdl.KeyCode.a) || sym == int(sdl.KeyCode.left) {
						game.key_left = false
					} else if sym == int(sdl.KeyCode.d) || sym == int(sdl.KeyCode.right) {
						game.key_right = false
					} else if sym == int(sdl.KeyCode.s) || sym == int(sdl.KeyCode.down) {
						game.key_down = false
					} else if sym == int(sdl.KeyCode.w) || sym == int(sdl.KeyCode.up) || sym == int(sdl.KeyCode.space) {
						game.key_jump = false
					} else if sym == int(sdl.KeyCode.j) || sym == int(sdl.KeyCode.z) {
						game.key_punch = false
					} else if sym == int(sdl.KeyCode.k) || sym == int(sdl.KeyCode.x) {
						game.key_kick = false
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
		render_kung_fu_game(renderer, mut game)
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
