module main

import os
import sdl

const win_w = 840
const win_h = 480

struct App {
mut:
	window    &sdl.Window   = unsafe { nil }
	renderer  &sdl.Renderer = unsafe { nil }
	game      ContraGame
	sound_mgr SoundManager
}

fn new_app() App {
	return App{
		game:      new_contra_game()
		sound_mgr: new_sound_manager()
	}
}

fn (mut app App) handle_sound_events() {
	if app.game.sound_rifle {
		app.sound_mgr.play_rifle()
		app.game.sound_rifle = false
	}
	if app.game.sound_spread {
		app.sound_mgr.play_spread()
		app.game.sound_spread = false
	}
	if app.game.sound_laser {
		app.sound_mgr.play_laser()
		app.game.sound_laser = false
	}
	if app.game.sound_fireball {
		app.sound_mgr.play_fireball()
		app.game.sound_fireball = false
	}
	if app.game.sound_jump {
		app.sound_mgr.play_jump()
		app.game.sound_jump = false
	}
	if app.game.sound_explosion {
		app.sound_mgr.play_explosion()
		app.game.sound_explosion = false
	}
	if app.game.sound_powerup {
		app.sound_mgr.play_powerup()
		app.game.sound_powerup = false
	}
	if app.game.sound_konami {
		app.sound_mgr.play_konami_code()
		app.game.sound_konami = false
	}
	if app.game.sound_stage_clear {
		app.sound_mgr.play_stage_clear()
		app.game.sound_stage_clear = false
	}
	if app.game.sound_death {
		app.sound_mgr.play_death()
		app.game.sound_death = false
	}
}

fn toggle_fullscreen(window &sdl.Window) {
	flags := sdl.get_window_flags(window)
	if (flags & u32(sdl.WindowFlags.fullscreen_desktop)) != 0 {
		sdl.set_window_fullscreen(window, 0)
	} else {
		sdl.set_window_fullscreen(window, u32(sdl.WindowFlags.fullscreen_desktop))
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

		mut tex_mgr := ContraTextureManager{}
		tex_mgr.init(renderer)

		mut snap_game := new_contra_game()
		snap_game.start_game(1, false)
		snap_game.state = .playing
		snap_game.players[0].x = 320.0
		snap_game.players[0].y = 380.0
		snap_game.players[0].weapon = .spread_gun
		snap_game.players[0].state = .running
		snap_game.players[0].score = 12500

		// Add enemies, capsule, and bullets
		snap_game.enemies = [
			Enemy{ x: 540, y: 380, vx: -60, vy: 0, enemy_type: .runner, health: 1, active: true, facing_right: false, on_ground: true },
			Enemy{ x: 620, y: 380, vx: -60, vy: 0, enemy_type: .runner, health: 1, active: true, facing_right: false, on_ground: true },
			Enemy{ x: 560, y: 220, vx: 0, vy: 0, enemy_type: .turret, health: 3, active: true, facing_right: false },
		]
		snap_game.capsules = [
			FlyingCapsule{ x: 420, y: 140, vx: 120, vy: 0, w_type: .spread_gun, active: true }
		]
		snap_game.bullets << create_player_bullets(330, 355, 1.0, 0.0, .spread_gun, false, 1)

		render_game(renderer, &snap_game, win_w, win_h, tex_mgr.sprite_texture)
		bmp_path := 'screenshots/contra.bmp'
		sdl.save_bmp(surface, bmp_path.str)
		return
	}

	mut app := new_app()

	window := sdl.create_window(
		'Contra - NES 1988 Classic Remake'.str,
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

	mut tex_mgr := ContraTextureManager{}
	tex_mgr.init(renderer)

	app.window = window
	app.renderer = renderer

	mut running := true
	mut last_ticks := sdl.get_ticks()

	for running {
		mut ev := sdl.Event{}
		for sdl.poll_event(&ev) != 0 {
			match ev.@type {
				.quit {
					running = false
				}
				.keydown {
					sym := int(ev.key.keysym.sym)
					if sym == int(sdl.KeyCode.f11) {
						toggle_fullscreen(window)
					} else if sym == int(sdl.KeyCode.escape) {
						if app.game.state == .title {
							running = false
						} else {
							app.game.init_title()
						}
					} else if sym == int(sdl.KeyCode.space) || sym == int(sdl.KeyCode.@return) {
						match app.game.state {
							.title {
								app.game.start_game(1, app.game.is_2p_mode)
							}
							.stage_intro {
								app.game.state = .playing
							}
							.game_over, .victory {
								app.game.init_title()
							}
							.playing {
								app.game.p1_jump = true
							}
							else {}
						}
					} else if sym == int(sdl.KeyCode.up) || sym == int(sdl.KeyCode.w) {
						app.game.p1_up = true
						if app.game.state == .title {
							app.game.push_konami_key(1)
						}
					} else if sym == int(sdl.KeyCode.down) || sym == int(sdl.KeyCode.s) {
						app.game.p1_down = true
						if app.game.state == .title {
							app.game.push_konami_key(2)
						}
					} else if sym == int(sdl.KeyCode.left) || sym == int(sdl.KeyCode.a) {
						app.game.p1_left = true
						if app.game.state == .title {
							app.game.push_konami_key(3)
						}
					} else if sym == int(sdl.KeyCode.right) || sym == int(sdl.KeyCode.d) {
						app.game.p1_right = true
						if app.game.state == .title {
							app.game.push_konami_key(4)
						}
					} else if sym == int(sdl.KeyCode.j) || sym == int(sdl.KeyCode.z) {
						app.game.p1_fire = true
						if app.game.state == .title {
							app.game.push_konami_key(5) // B button
						}
					} else if sym == int(sdl.KeyCode.k) || sym == int(sdl.KeyCode.x) {
						app.game.p1_jump = true
						if app.game.state == .title {
							app.game.push_konami_key(6) // A button
						}
					} else if sym == int(sdl.KeyCode.p) {
						if app.game.state == .playing {
							app.game.state = .paused
						} else if app.game.state == .paused {
							app.game.state = .playing
						}
					} else if sym == int(sdl.KeyCode.r) {
						app.game.start_game(app.game.current_stage, app.game.is_2p_mode)
					} else if sym == int(sdl.KeyCode.m) {
						app.sound_mgr.toggle_sound()
					} else if sym == int(sdl.KeyCode.c) {
						app.game.is_2p_mode = !app.game.is_2p_mode
					} else if sym == int(sdl.KeyCode._1) {
						app.game.start_game(1, app.game.is_2p_mode)
					} else if sym == int(sdl.KeyCode._2) {
						app.game.start_game(2, app.game.is_2p_mode)
					} else if sym == int(sdl.KeyCode._3) {
						app.game.start_game(3, app.game.is_2p_mode)
					} else if sym == int(sdl.KeyCode._4) {
						app.game.start_game(4, app.game.is_2p_mode)
					}
				}
				.keyup {
					sym := int(ev.key.keysym.sym)
					if sym == int(sdl.KeyCode.up) || sym == int(sdl.KeyCode.w) {
						app.game.p1_up = false
					} else if sym == int(sdl.KeyCode.down) || sym == int(sdl.KeyCode.s) {
						app.game.p1_down = false
					} else if sym == int(sdl.KeyCode.left) || sym == int(sdl.KeyCode.a) {
						app.game.p1_left = false
					} else if sym == int(sdl.KeyCode.right) || sym == int(sdl.KeyCode.d) {
						app.game.p1_right = false
					} else if sym == int(sdl.KeyCode.j) || sym == int(sdl.KeyCode.z) {
						app.game.p1_fire = false
					} else if sym == int(sdl.KeyCode.k) || sym == int(sdl.KeyCode.x) || sym == int(sdl.KeyCode.space) {
						app.game.p1_jump = false
					}
				}
				else {}
			}
		}

		current_ticks := sdl.get_ticks()
		dt := f32(current_ticks - last_ticks) / 1000.0
		last_ticks = current_ticks
		clamped_dt := if dt > 0.05 { f32(0.05) } else { dt }

		app.game.update(clamped_dt)
		app.handle_sound_events()

		render_game(renderer, &app.game, win_w, win_h, tex_mgr.sprite_texture)
		prod_fx_render(renderer)
		sdl.render_present(renderer)
		sdl.delay(1)
	}
}
