module main

import math
import os
import sdl

struct App {
mut:
	window      &sdl.Window   = unsafe { nil }
	renderer    &sdl.Renderer = unsafe { nil }
	game        WarGame
	sound_mgr   SoundManager
}

fn new_app() App {
	return App{
		game:      new_war_game()
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
	mutable_app.window = sdl.create_window('War - The 52-Card Battle Strategy'.str,
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
					mutable_app.game.battle_player = Card{ rank: 14, suit: .spades } // Ace of Spades
					mutable_app.game.battle_ai = Card{ rank: 13, suit: .hearts } // King of Hearts
					mutable_app.game.has_battle_card = true
					mutable_app.game.round_winner = 1
					mutable_app.game.phase = .comparing
					mutable_app.game.bob_mood = 2 // Worried
					mutable_app.game.war_pot = [Card{ rank: 10, suit: .clubs }, Card{ rank: 7, suit: .diamonds }, Card{ rank: 9, suit: .hearts }]
					mutable_app.game.floating_texts.clear()
					mutable_app.game.spawn_sparks(460, 290, 30, Color{ r: 70, g: 180, b: 255 })
					mutable_app.game.spawn_shockwave(460, 290, Color{ r: 100, g: 200, b: 255 })
					mutable_app.game.spawn_floating_text(460, 252, '★ CRITICAL ACE SLAM! ★', Color{ r: 255, g: 230, b: 60 }, 1)
					draw_war_game(sw_rend, &mutable_app.game)
					sdl.save_bmp(surface, 'screenshots/war.bmp'.str)
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
				.mousebuttondown {
					if event.button.button == u8(sdl.button_left) {
						if mutable_app.game.phase == .ready || mutable_app.game.phase == .comparing {
							mutable_app.game.step_battle(mut mutable_app.sound_mgr)
						} else if mutable_app.game.phase == .game_over {
							mutable_app.game.start_new_match()
						}
					}
				}
				.keydown {
					sym := event.key.keysym.sym
					if sym == int(sdl.KeyCode.f11) {
						toggle_fullscreen(mutable_app.window)
					} else if sym == int(sdl.KeyCode.escape) {
						running = false
					} else if sym == int(sdl.KeyCode.space) || sym == int(sdl.KeyCode.return) {
						if mutable_app.game.phase == .ready || mutable_app.game.phase == .comparing {
							mutable_app.game.step_battle(mut mutable_app.sound_mgr)
						} else if mutable_app.game.phase == .game_over {
							mutable_app.game.start_new_match()
						}
					} else if sym == int(sdl.KeyCode.a) {
						mutable_app.game.auto_play = !mutable_app.game.auto_play
					} else if sym == int(sdl.KeyCode.r) {
						mutable_app.game.start_new_match()
					} else if sym == int(sdl.KeyCode.m) {
						mutable_app.sound_mgr.toggle_sound()
					}
				}
				else {}
			}
		}

		mutable_app.game.update(dt, mut mutable_app.sound_mgr)

		draw_war_game(mutable_app.renderer, &mutable_app.game)
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
