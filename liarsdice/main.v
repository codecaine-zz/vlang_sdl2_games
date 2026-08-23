module main

import math
import os
import sdl

const win_w = 940
const win_h = 660

struct App {
mut:
	window    &sdl.Window   = unsafe { nil }
	renderer  &sdl.Renderer = unsafe { nil }
	game      LiarsDiceGame
	sound_mgr SoundManager
	mouse_x   int
	mouse_y   int
}

fn new_app() App {
	return App{
		game:      new_liarsdice_game(false)
		sound_mgr: new_sound_manager()
	}
}

fn main() {
	if sdl.init(sdl.init_video | sdl.init_audio | sdl.init_events | sdl.init_timer) < 0 {
		eprintln('Failed to initialize SDL2')
		return
	}
	defer { sdl.quit() }

	// Snapshot mode for README showcase
	if os.args.contains('--snap') {
		surface := sdl.create_rgb_surface(0, win_w, win_h, 32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000)
		if unsafe { surface == nil } { return }
		defer { sdl.free_surface(surface) }

		renderer := sdl.create_software_renderer(surface)
		if unsafe { renderer == nil } { return }
		defer { sdl.destroy_renderer(renderer) }
	sdl.render_set_logical_size(renderer, win_w, win_h)

		mut snap_game := new_liarsdice_game(false)
		snap_game.phase = .bidding
		snap_game.last_bid = Bid{ qty: 4, face: 5 }
		snap_game.last_bidder = 1
		snap_game.current_player = 0
		snap_game.selected_qty = 5
		snap_game.selected_face = 5
		snap_game.players[0].dice = [2, 3, 5, 5, 6]
		snap_game.players[1].dice = [1, 4, 5, 5, 6]
		snap_game.players[2].dice = [2, 2, 3, 4, 5]
		snap_game.players[3].dice = [1, 1, 3, 4, 6]

		render_liarsdice_game(renderer, mut snap_game, win_w, win_h, 0, 0)
		sdl.save_bmp(surface, 'screenshots/liarsdice.bmp'.str)
		return
	}

	mut app := new_app()

	window := sdl.create_window(
		'Liar\'s Dice Deluxe - Perudo Bluffing & Bidding Party Game'.str,
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

	mut event := sdl.Event{}
	mut running := true
	mut last_ticks := sdl.get_ticks()

	for running {
		now := sdl.get_ticks()
		dt := math.min(f64(now - last_ticks) / 1000.0, 0.05)
		last_ticks = now

		for sdl.poll_event(&event) != 0 {
			match event.@type {
				.quit {
					running = false
				}
				.mousemotion {
					app.mouse_x = event.motion.x
					app.mouse_y = event.motion.y
				}
				.mousebuttondown {
					if event.button.button == sdl.button_left {
						mx := event.button.x
						my := event.button.y
						panel_y := win_h - 85

						if app.game.phase == .round_over {
							app.game.start_new_round()
							app.sound_mgr.play_cup_shake()
						} else if app.game.phase == .game_over {
							app.game.reset()
							app.sound_mgr.play_cup_shake()
						} else if app.game.phase == .bidding && !app.game.players[app.game.current_player].is_ai {
							// Qty minus
							if mx >= 80 && mx <= 110 && my >= panel_y + 10 && my <= panel_y + 42 {
								if app.game.selected_qty > 1 {
									app.game.selected_qty--
									app.sound_mgr.play_bid()
								}
							}
							// Qty plus
							if mx >= 160 && mx <= 190 && my >= panel_y + 10 && my <= panel_y + 42 {
								if app.game.selected_qty < app.game.total_active_dice() {
									app.game.selected_qty++
									app.sound_mgr.play_bid()
								}
							}
							// Face selectors
							for f := 1; f <= 6; f++ {
								fx := 260 + (f - 1) * 44
								if mx >= fx - 2 && mx <= fx + 34 && my >= panel_y + 8 && my <= panel_y + 44 {
									app.game.selected_face = f
									app.sound_mgr.play_bid()
								}
							}
							// Bid Button
							if mx >= 540 && mx <= 640 && my >= panel_y + 10 && my <= panel_y + 44 {
								if app.game.make_bid(app.game.current_player, app.game.selected_qty, app.game.selected_face) {
									app.sound_mgr.play_bid()
								}
							}
							// Liar Button
							if mx >= 655 && mx <= 765 && my >= panel_y + 10 && my <= panel_y + 44 {
								if app.game.call_liar(app.game.current_player) {
									app.sound_mgr.play_challenge()
								}
							}
							// Spot On Button
							if mx >= 780 && mx <= 890 && my >= panel_y + 10 && my <= panel_y + 44 {
								if app.game.call_spot_on(app.game.current_player) {
									app.sound_mgr.play_spot_on()
								}
							}
						}
					}
				}
				.keydown {
					sym := int(event.key.keysym.sym)
					match sym {
						int(sdl.KeyCode.f11) {
							toggle_fullscreen(window)
						}
						int(sdl.KeyCode.escape) {
							running = false
						}
						int(sdl.KeyCode.r) {
							app.game.reset()
							app.sound_mgr.play_cup_shake()
						}
						int(sdl.KeyCode.m) {
							app.game.is_two_player = !app.game.is_two_player
							app.game.reset()
							app.sound_mgr.play_cup_shake()
						}
						int(sdl.KeyCode.s) {
							app.sound_mgr.toggle_sound()
						}
						int(sdl.KeyCode.space) {
							if app.game.phase == .round_over {
								app.game.start_new_round()
								app.sound_mgr.play_cup_shake()
							} else if app.game.phase == .game_over {
								app.game.reset()
								app.sound_mgr.play_cup_shake()
							} else if app.game.phase == .bidding && !app.game.players[app.game.current_player].is_ai {
								if app.game.make_bid(app.game.current_player, app.game.selected_qty, app.game.selected_face) {
									app.sound_mgr.play_bid()
								}
							}
						}
						int(sdl.KeyCode.l) {
							if app.game.phase == .bidding && !app.game.players[app.game.current_player].is_ai {
								if app.game.call_liar(app.game.current_player) {
									app.sound_mgr.play_challenge()
								}
							}
						}
						int(sdl.KeyCode.c) {
							if app.game.phase == .bidding && !app.game.players[app.game.current_player].is_ai {
								if app.game.call_spot_on(app.game.current_player) {
									app.sound_mgr.play_spot_on()
								}
							}
						}
						int(sdl.KeyCode.up) {
							if app.game.selected_qty < app.game.total_active_dice() {
								app.game.selected_qty++
								app.sound_mgr.play_bid()
							}
						}
						int(sdl.KeyCode.down) {
							if app.game.selected_qty > 1 {
								app.game.selected_qty--
								app.sound_mgr.play_bid()
							}
						}
						int(sdl.KeyCode.right) {
							if app.game.selected_face < 6 {
								app.game.selected_face++
								app.sound_mgr.play_bid()
							}
						}
						int(sdl.KeyCode.left) {
							if app.game.selected_face > 1 {
								app.game.selected_face--
								app.sound_mgr.play_bid()
							}
						}
						int(sdl.KeyCode._1) { app.game.selected_face = 1; app.sound_mgr.play_bid() }
						int(sdl.KeyCode._2) { app.game.selected_face = 2; app.sound_mgr.play_bid() }
						int(sdl.KeyCode._3) { app.game.selected_face = 3; app.sound_mgr.play_bid() }
						int(sdl.KeyCode._4) { app.game.selected_face = 4; app.sound_mgr.play_bid() }
						int(sdl.KeyCode._5) { app.game.selected_face = 5; app.sound_mgr.play_bid() }
						int(sdl.KeyCode._6) { app.game.selected_face = 6; app.sound_mgr.play_bid() }
						else {}
					}
				}
				else {}
			}
		}

		app.game.update(dt)

		sdl.set_render_draw_color(renderer, 0, 0, 0, 255)
		sdl.render_clear(renderer)

		render_liarsdice_game(renderer, mut app.game, win_w, win_h, app.mouse_x, app.mouse_y)

		prod_fx_render(renderer)
		sdl.render_present(renderer)
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
