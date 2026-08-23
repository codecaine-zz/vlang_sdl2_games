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

	// Snapshot capture mode
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

		mut game := new_legend_of_kage_game()
		game.start_game()
		game.player.score = 7200
		game.high_score = 15000

		// Position player high in the trees mid-slash
		game.player.x = 320.0
		game.player.y = 220.0
		game.player.is_jumping = true
		game.player.sword_timer = 0.15
		game.player.facing_right = true

		// Spawn enemy red ninjas and fire monks around
		game.enemies.clear()
		game.enemies << Enemy{
			x: 420.0
			y: 220.0
			vx: -60.0
			enemy_type: .red_ninja
			facing_right: false
			active: true
		}
		game.enemies << Enemy{
			x: 180.0
			y: 496.0
			vx: 80.0
			enemy_type: .fire_monk
			facing_right: true
			active: true
		}
		game.enemies << Enemy{
			x: 580.0
			y: 180.0
			vx: -70.0
			enemy_type: .blue_ninja
			facing_right: false
			active: true
		}

		// Throwing shuriken & monk fireball
		game.projectiles.clear()
		game.projectiles << Projectile{
			x: 360.0
			y: 232.0
			vx: 300.0
			vy: 0.0
			is_player: true
			active: true
		}
		game.projectiles << Projectile{
			x: 230.0
			y: 508.0
			vx: 180.0
			vy: 0.0
			is_player: false
			is_fire: true
			active: true
		}

		// Magic scroll
		game.scrolls.clear()
		game.scrolls << MagicScroll{
			x: 300.0
			y: 360.0
			scroll_type: .shadow_clones
			active: true
		}

		// Slash sparks and score popup
		game.add_particles(410.0, 230.0, 12, Color{ r: 255, g: 240, b: 80, a: 255 })
		game.add_score_popup(410.0, 200.0, '+200', Color{ r: 255, g: 230, b: 60, a: 255 })

		render_legend_of_kage_game(s_renderer, mut game, unsafe { nil })
		sdl.save_bmp(surface, 'screenshots/legendofkage.bmp'.str)
		return
	}

	// Normal Window
	window := sdl.create_window(
		'The Legend of Kage (1985 Taito Ninja Classic)'.str,
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

	mut tex_mgr := LegendOfKageTextureManager{}
	tex_mgr.init(renderer)

	mut game := new_legend_of_kage_game()

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
					k_sym := event.key.keysym.sym
					// Left
					if k_sym == int(sdl.KeyCode.f11) {
						toggle_fullscreen(window)
					} else if k_sym == int(sdl.KeyCode.a) || k_sym == int(sdl.KeyCode.left) {
						game.key_left = true
					}
					// Right
					else if k_sym == int(sdl.KeyCode.d) || k_sym == int(sdl.KeyCode.right) {
						game.key_right = true
					}
					// Down / Duck
					else if k_sym == int(sdl.KeyCode.s) || k_sym == int(sdl.KeyCode.down) {
						game.key_down = true
					}
					// Up / Jump
					else if k_sym == int(sdl.KeyCode.w) || k_sym == int(sdl.KeyCode.up) || k_sym == int(sdl.KeyCode.space) {
						if game.state == .title {
							game.start_game()
						} else if game.state == .stage_clear {
							game.next_stage()
						} else if game.state == .game_over {
							game.reset_to_title()
						} else {
							game.key_jump = true
						}
					}
					// Katana Slash
					else if k_sym == int(sdl.KeyCode.j) || k_sym == int(sdl.KeyCode.z) {
						game.player_slash()
					}
					// Shuriken Throw
					else if k_sym == int(sdl.KeyCode.k) || k_sym == int(sdl.KeyCode.x) {
						game.player_throw_shuriken()
					}
					// Pause
					else if k_sym == int(sdl.KeyCode.p) {
						if game.state == .playing {
							game.state = .paused
						} else if game.state == .paused {
							game.state = .playing
						}
					}
					// Sound toggle
					else if k_sym == int(sdl.KeyCode.m) {
						game.sound_mgr.toggle_sound()
					}
					// CRT Scanlines toggle
					else if k_sym == int(sdl.KeyCode.c) {
						game.crt_filter = !game.crt_filter
					}
					// Restart
					else if k_sym == int(sdl.KeyCode.r) {
						game.reset_to_title()
					}
					// Escape
					else if k_sym == int(sdl.KeyCode.escape) {
						if game.state == .title {
							running = false
						} else {
							game.reset_to_title()
						}
					}
				}
				.keyup {
					u_sym := event.key.keysym.sym
					if u_sym == int(sdl.KeyCode.a) || u_sym == int(sdl.KeyCode.left) {
						game.key_left = false
					} else if u_sym == int(sdl.KeyCode.d) || u_sym == int(sdl.KeyCode.right) {
						game.key_right = false
					} else if u_sym == int(sdl.KeyCode.s) || u_sym == int(sdl.KeyCode.down) {
						game.key_down = false
					} else if u_sym == int(sdl.KeyCode.w) || u_sym == int(sdl.KeyCode.up) || u_sym == int(sdl.KeyCode.space) {
						game.key_jump = false
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
		render_legend_of_kage_game(renderer, mut game, tex_mgr.sprite_texture)
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
