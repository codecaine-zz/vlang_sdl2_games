module main

import math
import os
import sdl

struct App {
mut:
	window      &sdl.Window   = unsafe { nil }
	renderer    &sdl.Renderer = unsafe { nil }
	game        BowlingGame
	sound_mgr   SoundManager
	tex_mgr     BowlingTextureManager
	key_left    bool
	key_right   bool
}

fn new_app() App {
	return App{
		game:      new_bowling_game()
		sound_mgr: new_sound_manager()
	}
}

fn (app &App) init() bool {
	if sdl.init(sdl.init_video | sdl.init_audio) < 0 {
		eprintln('Failed to init SDL')
		return false
	}

	mut mutable_app := unsafe { &App(app) }
	mutable_app.sound_mgr.init()
	window_flags := u32(sdl.WindowFlags.shown) | u32(sdl.WindowFlags.fullscreen_desktop) | u32(sdl.WindowFlags.resizable)
	mutable_app.window = sdl.create_window('Bowling Pro - 10-Pin Arcade Bowling'.str,
		sdl.windowpos_centered, sdl.windowpos_centered, 800, 680, window_flags)

	if mutable_app.window == unsafe { nil } {
		eprintln('Failed to create window')
		return false
	}

	render_flags := u32(sdl.RendererFlags.accelerated) | u32(sdl.RendererFlags.presentvsync)
	mutable_app.renderer = sdl.create_renderer(mutable_app.window, -1, render_flags)

	if mutable_app.renderer == unsafe { nil } {
		eprintln('Failed to create renderer')
		return false
	}

	sdl.render_set_logical_size(mutable_app.renderer, 800, 680)

	sdl.set_render_draw_blend_mode(mutable_app.renderer, .blend)
	mutable_app.tex_mgr.init(mutable_app.renderer)
	return true
}

fn (app &App) run() {
	mut mutable_app := unsafe { &App(app) }
	mut event := sdl.Event{}
	mut last_ticks := sdl.get_ticks()
	mut running := true

	for running {
		if os.getenv('SNAPSHOT') == '1' {
			surface := sdl.create_rgb_surface(0, 800, 680, 32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000)
			if unsafe { surface != nil } {
				sw_rend := sdl.create_software_renderer(surface)
				if unsafe { sw_rend != nil } {
					mutable_app.game.power = 0.75
					mutable_app.game.aim_angle = 0.04
					mutable_app.game.hook = 0.3
					draw_bowling_game(sw_rend, &mutable_app.game, unsafe { nil })
					sdl.save_bmp(surface, 'screenshots/bowling.bmp'.str)
					sdl.destroy_renderer(sw_rend)
				}
				sdl.free_surface(surface)
			}
			break
		}

		current_ticks := sdl.get_ticks()
		raw_dt := f64(current_ticks - last_ticks) / 1000.0
		last_ticks = current_ticks
		dt := math.min(0.033, if raw_dt > 0.001 { raw_dt } else { 1.0 / 60.0 })

		for sdl.poll_event(&event) != 0 {
			match unsafe { event.type } {
				.quit {
					running = false
				}
				.keydown {
					sym := event.key.keysym.sym
					if sym == int(sdl.KeyCode.f11) {
						toggle_fullscreen(mutable_app.window)
					} else if sym == int(sdl.KeyCode.escape) {
						running = false
					} else if sym == int(sdl.KeyCode.r) {
						mutable_app.game.reset_game()
					} else if sym == int(sdl.KeyCode.m) {
						mutable_app.sound_mgr.toggle_sound()
					} else if sym == int(sdl.KeyCode._1) {
						mutable_app.game.set_mode(.solo)
					} else if sym == int(sdl.KeyCode._2) {
						mutable_app.game.set_mode(.vs_2p)
					} else if sym == int(sdl.KeyCode._3) {
						mutable_app.game.set_mode(.vs_ai)
					} else if sym == int(sdl.KeyCode.tab) {
						mutable_app.game.ai_diff = (mutable_app.game.ai_diff + 1) % 3
					} else if sym == int(sdl.KeyCode.left) || sym == int(sdl.KeyCode.a) {
						mutable_app.key_left = true
					} else if sym == int(sdl.KeyCode.right) || sym == int(sdl.KeyCode.d) {
						mutable_app.key_right = true
					} else if sym == int(sdl.KeyCode.z) {
						mutable_app.game.hook = math.max(-1.0, mutable_app.game.hook - 0.2)
					} else if sym == int(sdl.KeyCode.x) {
						mutable_app.game.hook = math.min(1.0, mutable_app.game.hook + 0.2)
					} else if sym == int(sdl.KeyCode.space) {
						if mutable_app.game.phase == .game_over {
							mutable_app.game.reset_game()
						} else if mutable_app.game.phase == .position {
							mutable_app.game.phase = .angle
						} else if mutable_app.game.phase == .angle {
							mutable_app.game.phase = .power
						} else if mutable_app.game.phase == .power {
							mutable_app.game.launch_ball(mut mutable_app.sound_mgr)
						}
					}
				}
				.keyup {
					sym := event.key.keysym.sym
					if sym == int(sdl.KeyCode.left) || sym == int(sdl.KeyCode.a) {
						mutable_app.key_left = false
					} else if sym == int(sdl.KeyCode.right) || sym == int(sdl.KeyCode.d) {
						mutable_app.key_right = false
					}
				}
				else {}
			}
		}

		// Handle continuous position shifting
		if mutable_app.game.phase == .position && !mutable_app.game.players[mutable_app.game.current_player].is_ai {
			if mutable_app.key_left {
				mutable_app.game.aim_x = math.max(mutable_app.game.lane_left + 25.0, mutable_app.game.aim_x - 180.0 * dt)
			}
			if mutable_app.key_right {
				mutable_app.game.aim_x = math.min(mutable_app.game.lane_right - 25.0, mutable_app.game.aim_x + 180.0 * dt)
			}
		}

		mutable_app.game.update(dt, mut mutable_app.sound_mgr)
		mutable_app.sound_mgr.update_bgm(mutable_app.game.phase != .game_over)

		draw_bowling_game(mutable_app.renderer, &mutable_app.game, mutable_app.tex_mgr.sprite_texture)
		prod_fx_render(mutable_app.renderer)
		sdl.render_present(mutable_app.renderer)
		sdl.delay(1)
	}

	sdl.destroy_renderer(mutable_app.renderer)
	sdl.destroy_window(mutable_app.window)
	sdl.quit()
}

fn main() {
	mut app := new_app()
	if app.init() {
		app.run()
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
