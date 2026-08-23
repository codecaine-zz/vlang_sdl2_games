module main

import math
import os
import sdl

struct App {
mut:
	window    &sdl.Window   = unsafe { nil }
	renderer  &sdl.Renderer = unsafe { nil }
	game      GameEngine
	sound_mgr SoundManager
}

fn new_app() App {
	return App{
		game:      new_game_engine()
		sound_mgr: new_sound_manager()
	}
}

fn (app &App) init() bool {
	if sdl.init(sdl.init_video | sdl.init_audio) < 0 {
		eprintln('Failed to init SDL')
		return false
	}

	mut mutable_app := unsafe { &App(app) }

	window_flags := u32(sdl.WindowFlags.shown) | u32(sdl.WindowFlags.fullscreen_desktop) | u32(sdl.WindowFlags.resizable)
	mutable_app.window = sdl.create_window('CyberType - Neon Arcade Space Typist'.str,
		sdl.windowpos_centered, sdl.windowpos_centered, 800, 600, window_flags)

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

	sdl.render_set_logical_size(mutable_app.renderer, 800, 600)

	sdl.set_render_draw_blend_mode(mutable_app.renderer, .blend)
	sdl.start_text_input()
	return true
}

fn (app &App) run() {
	mut mutable_app := unsafe { &App(app) }
	mut event := sdl.Event{}
	mut last_ticks := sdl.get_ticks()
	mut running := true

	for running {
		if os.getenv('SNAPSHOT') == '1' {
			surface := sdl.create_rgb_surface(0, 800, 600, 32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000)
			if unsafe { surface != nil } {
				sw_rend := sdl.create_software_renderer(surface)
				if unsafe { sw_rend != nil } {
					mutable_app.game.start_game(.arcade)
					mutable_app.game.update(1.0, mut mutable_app.sound_mgr)
					draw_game(sw_rend, &mutable_app.game)
					sdl.save_bmp(surface, 'screenshots/typing.bmp'.str)
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
				.textinput {
					// Handle typed text character
					text_bytes := unsafe { event.text.text }
					for i := 0; i < 32 && text_bytes[i] != 0; i++ {
						ch := rune(text_bytes[i])
						mutable_app.game.handle_character_input(ch, mut mutable_app.sound_mgr)
					}
				}
				.keydown {
					sym := event.key.keysym.sym

					// Global shortcuts that don't collide with typing
					if sym == int(sdl.KeyCode.f11) {
						toggle_fullscreen(mutable_app.window)
					} else if sym == int(sdl.KeyCode.f1) || sym == int(sdl.KeyCode.pause) {
						if mutable_app.game.state == .playing {
							mutable_app.game.state = .paused
						} else if mutable_app.game.state == .paused {
							mutable_app.game.state = .playing
						}
					} else if sym == int(sdl.KeyCode.f9) {
						mutable_app.sound_mgr.toggle_sound()
					} else if sym == int(sdl.KeyCode.f5) {
						mutable_app.game.start_game(mutable_app.game.mode)
					}

					// State-specific keyboard actions
					match mutable_app.game.state {
						.playing {
							if sym == int(sdl.KeyCode.escape) {
								if mutable_app.game.locked_enemy_id != -1 {
									mutable_app.game.cancel_lock()
								} else {
									mutable_app.game.state = .paused
								}
							} else if sym == int(sdl.KeyCode.backspace) {
								mutable_app.game.cancel_lock()
							}
						}
						.paused {
							if sym == int(sdl.KeyCode.escape) || sym == int(sdl.KeyCode.p) || sym == int(sdl.KeyCode.space) || sym == int(sdl.KeyCode.@return) {
								mutable_app.game.state = .playing
							} else if sym == int(sdl.KeyCode.r) {
								mutable_app.game.start_game(mutable_app.game.mode)
							} else if sym == int(sdl.KeyCode.m) || sym == int(sdl.KeyCode.s) {
								mutable_app.sound_mgr.toggle_sound()
							}
						}
						.title {
							if sym == int(sdl.KeyCode.space) || sym == int(sdl.KeyCode.@return) {
								mutable_app.game.start_game(mutable_app.game.mode)
							} else if sym == int(sdl.KeyCode._1) {
								mutable_app.game.set_mode(.arcade)
							} else if sym == int(sdl.KeyCode._2) {
								mutable_app.game.set_mode(.speed_blitz)
							} else if sym == int(sdl.KeyCode._3) {
								mutable_app.game.set_mode(.code_words)
							} else if sym == int(sdl.KeyCode._4) {
								mutable_app.game.set_mode(.endless)
							} else if sym == int(sdl.KeyCode.tab) {
								mutable_app.game.cycle_mode()
							} else if sym == int(sdl.KeyCode.m) || sym == int(sdl.KeyCode.s) {
								mutable_app.sound_mgr.toggle_sound()
							}
						}
						.game_over, .victory {
							if sym == int(sdl.KeyCode.space) || sym == int(sdl.KeyCode.@return) || sym == int(sdl.KeyCode.r) {
								mutable_app.game.start_game(mutable_app.game.mode)
							} else if sym == int(sdl.KeyCode.m) || sym == int(sdl.KeyCode.s) {
								mutable_app.sound_mgr.toggle_sound()
							}
						}
						else {}
					}
				}
				else {}
			}
		}

		// Update game logic with screen shake offset
		mutable_app.game.update(dt, mut mutable_app.sound_mgr)

		// Render frame
		draw_game(mutable_app.renderer, &mutable_app.game)
		prod_fx_render(mutable_app.renderer)
		sdl.render_present(mutable_app.renderer)
		sdl.delay(1)
	}

	sdl.stop_text_input()
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
