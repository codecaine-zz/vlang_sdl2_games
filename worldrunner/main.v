module main

import os
import sdl

const win_w = 840
const win_h = 480

struct App {
mut:
	window        &sdl.Window   = unsafe { nil }
	renderer      &sdl.Renderer = unsafe { nil }
	game          WorldRunnerGame
	sound_mgr     SoundManager
	tex_mgr       WorldRunnerTextureManager
	mouse_locked  bool
}

fn new_app() App {
	return App{
		game:      new_worldrunner_game()
		sound_mgr: new_sound_manager()
		tex_mgr:   WorldRunnerTextureManager{}
	}
}

fn (mut app App) handle_sound_events() {
	if app.game.sound_laser {
		app.sound_mgr.play_laser()
		app.game.sound_laser = false
	}
	if app.game.sound_jump {
		app.sound_mgr.play_jump()
		app.game.sound_jump = false
	}
	if app.game.sound_boost {
		app.sound_mgr.play_boost()
		app.game.sound_boost = false
	}
	if app.game.sound_explosion {
		app.sound_mgr.play_explosion()
		app.game.sound_explosion = false
	}
	if app.game.sound_powerup {
		app.sound_mgr.play_powerup()
		app.game.sound_powerup = false
	}
	if app.game.sound_dragon {
		app.sound_mgr.play_dragon_roar()
		app.game.sound_dragon = false
	}
	if app.game.sound_victory {
		app.sound_mgr.play_victory()
		app.game.sound_victory = false
	}
	if app.game.sound_crash {
		app.sound_mgr.play_crash()
		app.game.sound_crash = false
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

		mut snap_game := new_worldrunner_game()
		snap_game.start_game(1)
		snap_game.state = .playing
		snap_game.player.pos = vec3(0, 40.0, 350.0)
		snap_game.player.speed_kmh = 320.0
		snap_game.player.score = 14500
		snap_game.time_left = 78.0

		// Add glowing forward lasers
		snap_game.lasers << LaserBolt{
			pos: vec3(-24.0, 30.0, 520.0)
			vel: vec3(0, 0, 1400.0)
			is_player: true
			damage: 1
		}
		snap_game.lasers << LaserBolt{
			pos: vec3(24.0, 30.0, 520.0)
			vel: vec3(0, 0, 1400.0)
			is_player: true
			damage: 1
		}

		render_game(renderer, &snap_game, win_w, win_h, unsafe { nil })
		bmp_path := 'screenshots/worldrunner.bmp'
		sdl.save_bmp(surface, bmp_path.str)
		return
	}

	mut app := new_app()

	window := sdl.create_window(
		'3D WorldRunner - Cosmic Harrier 3D'.str,
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

	mut running := true
	mut last_ticks := sdl.get_ticks()

	for running {
		mut ev := sdl.Event{}
		for sdl.poll_event(&ev) != 0 {
			match ev.@type {
				.quit {
					running = false
				}
				.mousemotion {
					if app.game.state == .playing {
						app.game.mouse_dx += f32(ev.motion.xrel)
						app.game.mouse_dy += f32(ev.motion.yrel)
					}
				}
				.mousebuttondown {
					if app.game.state == .title {
						app.game.start_game(1)
					} else if app.game.state == .playing {
						app.game.input_fire = true
					} else if app.game.state == .game_over || app.game.state == .victory {
						app.game.init_title()
					}
				}
				.mousebuttonup {
					app.game.input_fire = false
				}
				.keydown {
					sym := int(ev.key.keysym.sym)
					if sym == int(sdl.KeyCode.f11) {
						toggle_fullscreen(window)
					} else if sym == int(sdl.KeyCode.tab) {
						app.mouse_locked = !app.mouse_locked
						sdl.set_relative_mouse_mode(app.mouse_locked)
					} else if sym == int(sdl.KeyCode.escape) {
						if app.mouse_locked {
							app.mouse_locked = false
							sdl.set_relative_mouse_mode(false)
						} else if app.game.state == .title {
							running = false
						} else {
							app.game.init_title()
						}
					} else if sym == int(sdl.KeyCode.space) || sym == int(sdl.KeyCode.@return) {
						match app.game.state {
							.title {
								app.game.start_game(1)
							}
							.world_intro {
								app.game.state = .playing
							}
							.game_over, .victory {
								app.game.init_title()
							}
							.playing {
								app.game.input_jump = true
							}
							else {}
						}
					} else if sym == int(sdl.KeyCode.left) || sym == int(sdl.KeyCode.a) {
						app.game.input_left = true
					} else if sym == int(sdl.KeyCode.right) || sym == int(sdl.KeyCode.d) {
						app.game.input_right = true
					} else if sym == int(sdl.KeyCode.up) || sym == int(sdl.KeyCode.w) || sym == int(sdl.KeyCode.lshift) || sym == int(sdl.KeyCode.rshift) {
						app.game.input_boost = true
					} else if sym == int(sdl.KeyCode.down) || sym == int(sdl.KeyCode.s) {
						app.game.input_down = true
					} else if sym == int(sdl.KeyCode.j) || sym == int(sdl.KeyCode.z) {
						app.game.input_fire = true
					} else if sym == int(sdl.KeyCode.k) || sym == int(sdl.KeyCode.x) {
						app.game.input_jump = true
					} else if sym == int(sdl.KeyCode.p) {
						if app.game.state == .playing {
							app.game.state = .paused
						} else if app.game.state == .paused {
							app.game.state = .playing
						}
					} else if sym == int(sdl.KeyCode.r) {
						app.game.start_game(app.game.current_world)
					} else if sym == int(sdl.KeyCode.m) {
						app.sound_mgr.toggle_sound()
					} else if sym == int(sdl.KeyCode._1) {
						app.game.start_game(1)
					} else if sym == int(sdl.KeyCode._2) {
						app.game.start_game(2)
					} else if sym == int(sdl.KeyCode._3) {
						app.game.start_game(3)
					} else if sym == int(sdl.KeyCode._4) {
						app.game.start_game(4)
					} else if sym == int(sdl.KeyCode._5) {
						app.game.start_game(5)
					}
				}
				.keyup {
					sym := int(ev.key.keysym.sym)
					if sym == int(sdl.KeyCode.left) || sym == int(sdl.KeyCode.a) {
						app.game.input_left = false
					} else if sym == int(sdl.KeyCode.right) || sym == int(sdl.KeyCode.d) {
						app.game.input_right = false
					} else if sym == int(sdl.KeyCode.up) || sym == int(sdl.KeyCode.w) || sym == int(sdl.KeyCode.lshift) || sym == int(sdl.KeyCode.rshift) {
						app.game.input_boost = false
					} else if sym == int(sdl.KeyCode.down) || sym == int(sdl.KeyCode.s) {
						app.game.input_down = false
					} else if sym == int(sdl.KeyCode.j) || sym == int(sdl.KeyCode.z) {
						app.game.input_fire = false
					} else if sym == int(sdl.KeyCode.k) || sym == int(sdl.KeyCode.x) || sym == int(sdl.KeyCode.space) {
						app.game.input_jump = false
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
		app.sound_mgr.update_audio_stream(app.game.current_world, app.game.has_boss && app.game.boss.active, app.game.state == .playing)

		render_game(renderer, &app.game, win_w, win_h, app.tex_mgr.sprite_texture)
		prod_fx_render(renderer)
		sdl.render_present(renderer)
	}
}
