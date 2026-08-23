module main

import math
import os
import sdl

struct App {
mut:
	window      &sdl.Window   = unsafe { nil }
	renderer    &sdl.Renderer = unsafe { nil }
	game        BlackjackGame
	sound_mgr   SoundManager
}

fn new_app() App {
	return App{
		game:      new_blackjack_game()
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
	mutable_app.window = sdl.create_window('Blackjack 21 Pro - Vegas Casino Table'.str,
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
					mutable_app.game.dealer_hand = [
						Card{ rank: 1, suit: .spades },   // Ace
						Card{ rank: 9, suit: .hearts }    // 9
					]
					mutable_app.game.dealer_hidden = false
					mutable_app.game.player_hands = [
						Hand{
							cards: [Card{ rank: 1, suit: .diamonds }, Card{ rank: 13, suit: .clubs }] // Ace + King = Blackjack!
							bet: 100
							is_bj: true
						}
					]
					mutable_app.game.state = .round_over
					mutable_app.game.celebration = 'BLACKJACK 21!! PAYS 3:2 ($250)'
					mutable_app.game.floating_texts.clear()
					mutable_app.game.spawn_confetti(400, 320, 50)
					mutable_app.game.spawn_shockwave(400, 320, Color{ r: 255, g: 215, b: 0 })
					mutable_app.game.spawn_floating_text(400, 295, '★ NATURAL BLACKJACK! +$250 ★', Color{ r: 255, g: 230, b: 50 }, 1)
					draw_blackjack_game(sw_rend, &mutable_app.game)
					sdl.save_bmp(surface, 'screenshots/blackjack.bmp'.str)
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
						mx := event.button.x
						my := event.button.y

						if mutable_app.game.state == .betting {
							// Click Chips
							if my >= 440 && my <= 480 {
								chips_x := 80
								for i := 0; i < 5; i++ {
									cx := chips_x + i * 48
									if mx >= cx - 20 && mx <= cx + 20 {
										amounts := [5, 25, 50, 100, 500]
										mutable_app.game.place_chip(amounts[i])
										mutable_app.sound_mgr.play_chip_clink()
										break
									}
								}
							}
							// Click Deal circle
							else if mx >= 360 && mx <= 440 && my >= 420 && my <= 500 {
								mutable_app.game.deal(mut mutable_app.sound_mgr)
							}
						} else if mutable_app.game.state == .round_over {
							mutable_app.game.state = .betting
							mutable_app.game.celebration = ''
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
						if mutable_app.game.state == .betting {
							mutable_app.game.deal(mut mutable_app.sound_mgr)
						} else if mutable_app.game.state == .round_over {
							mutable_app.game.state = .betting
							mutable_app.game.celebration = ''
						}
					} else if sym == int(sdl.KeyCode.h) {
						mutable_app.game.hit(mut mutable_app.sound_mgr)
					} else if sym == int(sdl.KeyCode.s) {
						mutable_app.game.stand(mut mutable_app.sound_mgr)
					} else if sym == int(sdl.KeyCode.d) {
						mutable_app.game.double_down(mut mutable_app.sound_mgr)
					} else if sym == int(sdl.KeyCode.p) {
						mutable_app.game.split(mut mutable_app.sound_mgr)
					} else if sym == int(sdl.KeyCode.i) {
						mutable_app.game.buy_insurance()
					} else if sym == int(sdl.KeyCode.c) {
						mutable_app.game.clear_bet()
					} else if sym == int(sdl.KeyCode._1) {
						mutable_app.game.place_chip(5)
						mutable_app.sound_mgr.play_chip_clink()
					} else if sym == int(sdl.KeyCode._2) {
						mutable_app.game.place_chip(25)
						mutable_app.sound_mgr.play_chip_clink()
					} else if sym == int(sdl.KeyCode._3) {
						mutable_app.game.place_chip(50)
						mutable_app.sound_mgr.play_chip_clink()
					} else if sym == int(sdl.KeyCode._4) {
						mutable_app.game.place_chip(100)
						mutable_app.sound_mgr.play_chip_clink()
					} else if sym == int(sdl.KeyCode._5) {
						mutable_app.game.place_chip(500)
						mutable_app.sound_mgr.play_chip_clink()
					} else if sym == int(sdl.KeyCode.m) {
						mutable_app.sound_mgr.toggle_sound()
					}
				}
				else {}
			}
		}

		mutable_app.game.update(dt, mut mutable_app.sound_mgr)

		draw_blackjack_game(mutable_app.renderer, &mutable_app.game)
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
