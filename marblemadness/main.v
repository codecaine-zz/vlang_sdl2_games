module main

import os
import sdl

const win_w = 840
const win_h = 640

struct App {
mut:
	window        &sdl.Window   = unsafe { nil }
	renderer      &sdl.Renderer = unsafe { nil }
	game          MarbleGame
	sound_mgr     SoundManager
	mouse_locked  bool
}

fn new_app() App {
	return App{
		game:      new_marble_game()
		sound_mgr: new_sound_manager()
	}
}

fn (mut app App) handle_sound_events() {
	if app.game.sound_play_bounce {
		app.sound_mgr.play_bounce(app.game.sound_bounce_int)
		app.game.sound_play_bounce = false
	}
	if app.game.sound_play_shatter {
		app.sound_mgr.play_shatter()
		app.game.sound_play_shatter = false
	}
	if app.game.sound_play_respawn {
		app.sound_mgr.play_respawn()
		app.game.sound_play_respawn = false
	}
	if app.game.sound_play_muncher {
		app.sound_mgr.play_muncher_chomp()
		app.game.sound_play_muncher = false
	}
	if app.game.sound_play_boost {
		app.sound_mgr.play_boost()
		app.game.sound_play_boost = false
	}
	if app.game.sound_play_spring {
		app.sound_mgr.play_spring()
		app.game.sound_play_spring = false
	}
	if app.game.sound_play_tube {
		app.sound_mgr.play_tube()
		app.game.sound_play_tube = false
	}
	if app.game.sound_play_warning {
		app.sound_mgr.play_warning()
		app.game.sound_play_warning = false
	}
	if app.game.sound_play_goal {
		app.sound_mgr.play_goal()
		app.game.sound_play_goal = false
	}
	if app.game.sound_play_gameover {
		app.sound_mgr.play_game_over()
		app.game.sound_play_gameover = false
	}

	if app.game.state == .playing && app.game.player.state == .rolling {
		spd := app.game.player.vel.len_2d()
		app.sound_mgr.play_rolling(spd, 0.016)
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

		mut snap_game := new_marble_game()
		snap_game.start_game(1)
		snap_game.state = .playing
		snap_game.time_left = 54.0
		snap_game.score = 4800
		snap_game.player.pos = vec3(4.5, 9.5, 4.5)
		snap_game.player.state = .rolling
		snap_game.player.speed_mph = 32.0

		render_game(renderer, &snap_game, win_w, win_h)
		bmp_path := 'screenshots/marblemadness.bmp'
		sdl.save_bmp(surface, bmp_path.str)
		return
	}

	mut app := new_app()

	window := sdl.create_window(
		'Marble Madness Modern - 3D Isometric Platformer'.str,
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
						app.game.input_turbo = true
					} else if app.game.state == .game_over || app.game.state == .victory {
						app.game.init_title()
					}
				}
				.mousebuttonup {
					app.game.input_turbo = false
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
							.level_intro {
								app.game.state = .playing
							}
							.game_over, .victory {
								app.game.init_title()
							}
							.playing {
								app.game.input_turbo = true
								app.game.input_jump = true
							}
							else {}
						}
					} else if sym == int(sdl.KeyCode.up) || sym == int(sdl.KeyCode.w) {
						app.game.input_up = true
					} else if sym == int(sdl.KeyCode.down) || sym == int(sdl.KeyCode.s) {
						app.game.input_down = true
					} else if sym == int(sdl.KeyCode.left) || sym == int(sdl.KeyCode.a) {
						app.game.input_left = true
					} else if sym == int(sdl.KeyCode.right) || sym == int(sdl.KeyCode.d) {
						app.game.input_right = true
					} else if sym == int(sdl.KeyCode.j) || sym == int(sdl.KeyCode.z) {
						app.game.input_turbo = true
						app.game.input_jump = true
					} else if sym == int(sdl.KeyCode.p) {
						if app.game.state == .playing {
							app.game.state = .paused
						} else if app.game.state == .paused {
							app.game.state = .playing
						}
					} else if sym == int(sdl.KeyCode.r) {
						app.game.start_game(app.game.current_level)
					} else if sym == int(sdl.KeyCode.m) {
						app.sound_mgr.toggle_sound()
					} else if sym == int(sdl.KeyCode.t) {
						app.game.control_diagonal = !app.game.control_diagonal
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
					} else if sym == int(sdl.KeyCode._6) {
						app.game.start_game(6)
					}
				}
				.keyup {
					sym := int(ev.key.keysym.sym)
					if sym == int(sdl.KeyCode.up) || sym == int(sdl.KeyCode.w) {
						app.game.input_up = false
					} else if sym == int(sdl.KeyCode.down) || sym == int(sdl.KeyCode.s) {
						app.game.input_down = false
					} else if sym == int(sdl.KeyCode.left) || sym == int(sdl.KeyCode.a) {
						app.game.input_left = false
					} else if sym == int(sdl.KeyCode.right) || sym == int(sdl.KeyCode.d) {
						app.game.input_right = false
					} else if sym == int(sdl.KeyCode.space) || sym == int(sdl.KeyCode.j) || sym == int(sdl.KeyCode.z) {
						app.game.input_turbo = false
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

		render_game(renderer, &app.game, win_w, win_h)
		prod_fx_render(renderer)
		sdl.render_present(renderer)
		sdl.delay(1)
	}
}
