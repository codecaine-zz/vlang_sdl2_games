module main

import math
import os
import sdl

const win_w = 960
const win_h = 600

struct App {
mut:
	window    &sdl.Window   = unsafe { nil }
	renderer  &sdl.Renderer = unsafe { nil }
	game      DukeGame
	sound_mgr SoundManager
	sparks    []SparkParticle
}

fn new_app() App {
	return App{
		game:      new_duke_game()
		sound_mgr: new_sound_manager()
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

		// 1. Sector 1 Screenshot
		mut snap_game1 := new_duke_game()
		snap_game1.init_textures(renderer)
		snap_game1.load_sector(1)
		snap_game1.player.score = 12850
		snap_game1.player.hp = 7
		snap_game1.player.has_red_key = true
		snap_game1.player.weapon = .dual_laser
		snap_game1.player.ammo = 35
		snap_game1.player.x = 240.0
		snap_game1.player.y = 448.0
		snap_game1.player.dir = 1
		snap_game1.player.on_ground = true
		snap_game1.bullets << Bullet{ x: 300.0, y: 460.0, vx: 480.0, vy: 0.0, rad: 5.0, damage: 2, @type: .dual_laser }
		snap_game1.bullets << Bullet{ x: 300.0, y: 468.0, vx: 480.0, vy: 0.0, rad: 5.0, damage: 2, @type: .dual_laser }

		render_duke_game(renderer, &snap_game1, win_w, win_h, []SparkParticle{})
		sdl.save_bmp(surface, 'screenshots/duke.bmp'.str)

		// 2. Sector 2 Screenshot (Subterranean Reactor Core)
		mut snap_game2 := new_duke_game()
		snap_game2.init_textures(renderer)
		snap_game2.load_sector(2)
		snap_game2.player.score = 28400
		snap_game2.player.hp = 6
		snap_game2.player.has_green_key = true
		snap_game2.player.weapon = .flamethrower
		snap_game2.player.ammo = 42
		snap_game2.player.x = 780.0
		snap_game2.player.y = 416.0
		snap_game2.player.dir = 1
		snap_game2.player.on_ground = true
		snap_game2.bullets << Bullet{ x: 840.0, y: 428.0, vx: 400.0, vy: -20.0, rad: 8.0, damage: 2, @type: .flamethrower }

		render_duke_game(renderer, &snap_game2, win_w, win_h, []SparkParticle{})
		sdl.save_bmp(surface, 'screenshots/duke_sector2.bmp'.str)

		// 3. Sector 3 Screenshot (Orbital Fortress Boss Battle)
		mut snap_game3 := new_duke_game()
		snap_game3.init_textures(renderer)
		snap_game3.load_sector(3)
		snap_game3.player.score = 46900
		snap_game3.player.hp = 8
		snap_game3.player.weapon = .missile
		snap_game3.player.ammo = 18
		snap_game3.player.x = 1350.0
		snap_game3.player.y = 608.0
		snap_game3.player.dir = 1
		snap_game3.player.on_ground = true
		snap_game3.boss.hp = 22
		snap_game3.bullets << Bullet{ x: 1420.0, y: 618.0, vx: 450.0, vy: 0.0, rad: 7.0, damage: 5, @type: .missile }

		render_duke_game(renderer, &snap_game3, win_w, win_h, []SparkParticle{})
		sdl.save_bmp(surface, 'screenshots/duke_sector3.bmp'.str)
		return
	}

	mut app := new_app()

	window := sdl.create_window(
		'Duke Nukem: Cyber Outpost - 2D Retro Platformer Shooter'.str,
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
	app.game.init_textures(renderer)

	mut event := sdl.Event{}
	mut running := true
	mut last_ticks := sdl.get_ticks()

	mut key_left := false
	mut key_right := false
	mut key_up := false
	mut key_down := false

	for running {
		now := sdl.get_ticks()
		dt := math.min(f64(now - last_ticks) / 1000.0, 0.05)
		last_ticks = now

		update_sparks(mut app.sparks, dt)

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
					} else if sym == int(sdl.KeyCode.r) {
						app.game.reset_game()
					} else if sym == int(sdl.KeyCode.m) {
						app.sound_mgr.toggle_sound()
					} else if sym == int(sdl.KeyCode.a) || sym == int(sdl.KeyCode.left) {
						key_left = true
					} else if sym == int(sdl.KeyCode.d) || sym == int(sdl.KeyCode.right) {
						key_right = true
					} else if sym == int(sdl.KeyCode.w) || sym == int(sdl.KeyCode.up) {
						key_up = true
					} else if sym == int(sdl.KeyCode.s) || sym == int(sdl.KeyCode.down) {
						key_down = true
					} else if sym == int(sdl.KeyCode.space) {
						if app.game.state == .sector_debrief {
							app.game.load_sector(app.game.level_num + 1)
						} else if app.game.state == .game_won || app.game.state == .game_over {
							app.game.reset_game()
						} else {
							if app.game.player_jump() {
								app.sound_mgr.play_jump_sound()
							}
						}
					} else if sym == int(sdl.KeyCode.lctrl) || sym == int(sdl.KeyCode.rctrl) || sym == int(sdl.KeyCode.j) || sym == int(sdl.KeyCode.f) {
						if app.game.player_shoot() {
							match app.game.player.weapon {
								.blaster { app.sound_mgr.play_laser_sound() }
								.dual_laser { app.sound_mgr.play_dual_laser_sound() }
								.flamethrower { app.sound_mgr.play_flame_sound() }
								.missile { app.sound_mgr.play_rocket_sound() }
							}
						}
					}
				}
				.keyup {
					sym := int(event.key.keysym.sym)
					if sym == int(sdl.KeyCode.a) || sym == int(sdl.KeyCode.left) {
						key_left = false
					} else if sym == int(sdl.KeyCode.d) || sym == int(sdl.KeyCode.right) {
						key_right = false
					} else if sym == int(sdl.KeyCode.w) || sym == int(sdl.KeyCode.up) {
						key_up = false
					} else if sym == int(sdl.KeyCode.s) || sym == int(sdl.KeyCode.down) {
						key_down = false
					}
				}
				else {}
			}
		}

		move_dir := if key_right && !key_left { 1 } else if key_left && !key_right { -1 } else { 0 }
		climb_dir := if key_up && !key_down { -1 } else if key_down && !key_up { 1 } else { 0 }
		crouch := key_down
		aim_up := key_up

		ev := app.game.update(dt, move_dir, climb_dir, crouch, aim_up)
		if ev.picked_item {
			app.sound_mgr.play_pickup_sound()
		}
		if ev.unlocked_door {
			app.sound_mgr.play_keycard_sound()
		}
		if ev.camera_destroyed {
			app.sound_mgr.play_camera_sound()
		}
		if ev.player_hurt {
			app.sound_mgr.play_hurt_sound()
		}
		if ev.explosion {
			app.sound_mgr.play_explosion_sound()
			app.sparks << create_explosion_fx(app.game.player.x + 30.0, app.game.player.y + 10.0, 16)
		}
		if ev.sector_cleared || ev.game_won {
			app.sound_mgr.play_win_sound()
		}

		app.sound_mgr.update_audio(app.game.boss.active)

		render_duke_game(app.renderer, &app.game, win_w, win_h, app.sparks)
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
