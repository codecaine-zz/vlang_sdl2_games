module main

import math
import os
import sdl

struct App {
mut:
	window      &sdl.Window   = unsafe { nil }
	renderer    &sdl.Renderer = unsafe { nil }
	game        UnoGame
	sound_mgr   SoundManager
}

fn new_app() App {
	return App{
		game:      new_uno_game()
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
	mutable_app.window = sdl.create_window('Uno Master 4-Player - Arcade Card Classic'.str,
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
					mutable_app.game.players[0].hand = [
						UnoCard{ id: 1, color: .red, typ: .num_7 },
						UnoCard{ id: 2, color: .blue, typ: .skip },
						UnoCard{ id: 3, color: .yellow, typ: .draw_two },
						UnoCard{ id: 4, color: .green, typ: .reverse },
						UnoCard{ id: 5, color: .wild_color, typ: .wild },
					]
					mutable_app.game.discard_pile = [
						UnoCard{ id: 99, color: .red, typ: .num_7 }
					]
					mutable_app.game.active_color = .red
					mutable_app.game.selected_card = 0
					mutable_app.game.spawn_confetti(400, 260, 45)
					mutable_app.game.spawn_shockwave(400, 260, Color{ r: 235, g: 45, b: 55 })
					mutable_app.game.spawn_floating_text(400, 195, '★ MATCH RED 7! YOUR TURN ★', Color{ r: 255, g: 220, b: 50 }, 1)
					draw_uno_game(sw_rend, &mutable_app.game)
					sdl.save_bmp(surface, 'screenshots/uno.bmp'.str)
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

						if mutable_app.game.state == .color_pick {
							// Color picker quadrant clicks
							if mx >= 275 && mx <= 390 && my >= 215 && my <= 265 {
								mutable_app.game.play_card(mutable_app.game.selected_card, .red, mut mutable_app.sound_mgr)
								mutable_app.game.state = .player_turn
							} else if mx >= 410 && mx <= 525 && my >= 215 && my <= 265 {
								mutable_app.game.play_card(mutable_app.game.selected_card, .blue, mut mutable_app.sound_mgr)
								mutable_app.game.state = .player_turn
							} else if mx >= 275 && mx <= 390 && my >= 280 && my <= 330 {
								mutable_app.game.play_card(mutable_app.game.selected_card, .green, mut mutable_app.sound_mgr)
								mutable_app.game.state = .player_turn
							} else if mx >= 410 && mx <= 525 && my >= 280 && my <= 330 {
								mutable_app.game.play_card(mutable_app.game.selected_card, .yellow, mut mutable_app.sound_mgr)
								mutable_app.game.state = .player_turn
							}
						} else if mutable_app.game.state == .player_turn && mutable_app.game.current_p_idx == 0 {
							// Click Draw Pile
							if mx >= 325 && mx <= 385 && my >= 220 && my <= 310 {
								mutable_app.game.draw_card_for_player(0, mut mutable_app.sound_mgr)
								mutable_app.game.advance_turn()
							}
							// Click Call Uno Button
							else if mx >= 670 && mx <= 775 && my >= 490 && my <= 532 {
								mutable_app.game.call_uno()
							}
							// Click Player Hand Card
							else if my >= 450 && my <= 560 {
								p := &mutable_app.game.players[0]
								hand_len := p.hand.len
								if hand_len > 0 {
									spacing := math.min(52.0, 520.0 / f64(math.max(1, hand_len)))
									total_w := int(f64(hand_len - 1) * spacing) + 58
									start_x := 400 - total_w / 2

									for i := hand_len - 1; i >= 0; i-- {
										cx := start_x + int(f64(i) * spacing)
										if mx >= cx && mx <= cx + 58 {
											if mutable_app.game.selected_card == i {
												// Double click / Play
												card := p.hand[i]
												if card.color == .wild_color {
													mutable_app.game.state = .color_pick
												} else {
													mutable_app.game.play_card(i, card.color, mut mutable_app.sound_mgr)
												}
											} else {
												mutable_app.game.selected_card = i
											}
											break
										}
									}
								}
							}
						}
					}
				}
				.keydown {
					sym := event.key.keysym.sym
					if sym == int(sdl.KeyCode.f11) {
						toggle_fullscreen(mutable_app.window)
					} else if sym == int(sdl.KeyCode.escape) {
						running = false
					} else if mutable_app.game.state == .color_pick {
						if sym == int(sdl.KeyCode._1) || sym == int(sdl.KeyCode.r) {
							mutable_app.game.play_card(mutable_app.game.selected_card, .red, mut mutable_app.sound_mgr)
							mutable_app.game.state = .player_turn
						} else if sym == int(sdl.KeyCode._2) || sym == int(sdl.KeyCode.b) {
							mutable_app.game.play_card(mutable_app.game.selected_card, .blue, mut mutable_app.sound_mgr)
							mutable_app.game.state = .player_turn
						} else if sym == int(sdl.KeyCode._3) || sym == int(sdl.KeyCode.g) {
							mutable_app.game.play_card(mutable_app.game.selected_card, .green, mut mutable_app.sound_mgr)
							mutable_app.game.state = .player_turn
						} else if sym == int(sdl.KeyCode._4) || sym == int(sdl.KeyCode.y) {
							mutable_app.game.play_card(mutable_app.game.selected_card, .yellow, mut mutable_app.sound_mgr)
							mutable_app.game.state = .player_turn
						}
					} else if mutable_app.game.state == .player_turn && mutable_app.game.current_p_idx == 0 {
						hand_len := mutable_app.game.players[0].hand.len

						if sym == int(sdl.KeyCode.left) || sym == int(sdl.KeyCode.a) {
							if hand_len > 0 {
								mutable_app.game.selected_card = (mutable_app.game.selected_card - 1 + hand_len) % hand_len
							}
						} else if sym == int(sdl.KeyCode.right) || sym == int(sdl.KeyCode.d) {
							if hand_len > 0 {
								mutable_app.game.selected_card = (mutable_app.game.selected_card + 1) % hand_len
							}
						} else if sym == int(sdl.KeyCode.space) || sym == int(sdl.KeyCode.return) {
							idx := mutable_app.game.selected_card
							if idx >= 0 && idx < hand_len {
								card := mutable_app.game.players[0].hand[idx]
								if card.color == .wild_color && mutable_app.game.is_card_playable(card) {
									mutable_app.game.state = .color_pick
								} else {
									mutable_app.game.play_card(idx, card.color, mut mutable_app.sound_mgr)
								}
							}
						} else if sym == int(sdl.KeyCode.u) {
							mutable_app.game.call_uno()
						} else if sym == int(sdl.KeyCode.x) || sym == int(sdl.KeyCode.down) {
							mutable_app.game.draw_card_for_player(0, mut mutable_app.sound_mgr)
							mutable_app.game.advance_turn()
						} else if sym == int(sdl.KeyCode.m) {
							mutable_app.sound_mgr.toggle_sound()
						}
					}
				}
				else {}
			}
		}

		mutable_app.game.update(dt, mut mutable_app.sound_mgr)

		draw_uno_game(mutable_app.renderer, &mutable_app.game)
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
