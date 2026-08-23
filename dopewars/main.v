module main

import math
import os
import sdl

const win_w = 920
const win_h = 640

struct App {
mut:
	window    &sdl.Window   = unsafe { nil }
	renderer  &sdl.Renderer = unsafe { nil }
	game      DopeWarsGame
	sound_mgr SoundManager
	mouse_x   int
	mouse_y   int
}

fn new_app() App {
	return App{
		game:      new_dopewars_game()
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

		mut snap_game := new_dopewars_game()
		snap_game.day = 12
		snap_game.cash = 45000
		snap_game.bank = 120000
		snap_game.debt = 0
		snap_game.inventory['Acid'] = 25
		snap_game.inventory['Cocaine'] = 5
		snap_game.inventory['Weed'] = 30

		render_dopewars_game(renderer, mut snap_game, win_w, win_h, 0, 0, true)
		sdl.save_bmp(surface, 'screenshots/dopewars.bmp'.str)
		return
	}

	mut app := new_app()

	window := sdl.create_window(
		'Dope Wars 1990 - NYC Economic Trading Strategy'.str,
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
					app.mouse_x = int(event.motion.x)
					app.mouse_y = int(event.motion.y)
				}
				.mousebuttondown {
					mx := int(event.button.x)
					my := int(event.button.y)
					if event.button.button == u8(sdl.button_left) {
						// 1. Sound toggle badge
						sound_x := win_w - 140
						if mx >= sound_x && mx <= sound_x + 120 && my >= 10 && my <= 36 {
							app.sound_mgr.toggle_sound()
							continue
						}

						// 2. State-specific mouse click interactions
						match app.game.ui_state {
							.market {
								// Check commodity table rows
								table_x := 30
								table_y := 65
								for i in 0 .. drug_catalogue.len {
									row_y := table_y + 44 + i * 42
									if my >= row_y - 4 && my <= row_y + 32 && mx >= table_x && mx <= table_x + 540 {
										app.game.selected_drug = i
										// Check BUY button
										if mx >= table_x + 430 && mx <= table_x + 475 {
											app.game.buy_drug(i, 100)
										} else if mx >= table_x + 480 && mx <= table_x + 525 {
											app.game.sell_drug(i, 100)
										}
										break
									}
								}

								// Check Navigation Buttons
								ledger_x := 590
								nav_y := 65 + 330
								if mx >= ledger_x + 20 && mx <= ledger_x + 280 {
									if my >= nav_y && my <= nav_y + 38 {
										app.game.ui_state = .subway
									} else if my >= nav_y + 50 && my <= nav_y + 88 {
										app.game.ui_state = .bank
									} else if my >= nav_y + 100 && my <= nav_y + 138 {
										app.game.ui_state = .loan_shark
									}
								}
							}
							.subway {
								locs := [
									Location.manhattan,
									Location.bronx,
									Location.brooklyn,
									Location.queens,
									Location.staten_island,
									Location.coney_island,
								]
								mut by := 190
								for l in locs {
									if mx >= win_w / 2 - 160 && mx <= win_w / 2 + 160 && my >= by && my <= by + 36 {
										app.game.travel_to(l)
										break
									}
									by += 48
								}
								if my >= win_h - 135 && my <= win_h - 100 {
									app.game.ui_state = .market
								}
							}
							.bank {
								if my >= 220 && my <= 250 {
									app.game.deposit_bank(app.game.cash)
								} else if my >= 260 && my <= 290 {
									app.game.withdraw_bank(app.game.bank)
								} else if my >= 315 && my <= 350 {
									app.game.ui_state = .market
								}
							}
							.loan_shark {
								if my >= 220 && my <= 255 {
									app.game.pay_debt(app.game.cash)
								} else if my >= 285 && my <= 325 {
									app.game.ui_state = .market
								}
							}
							.police_encounter {
								if my >= 255 && my <= 290 {
									app.game.handle_police_action('run')
								} else if my >= 295 && my <= 330 {
									app.game.handle_police_action('bribe')
								}
							}
							.game_over_screen {
								if my >= 400 && my <= 450 {
									app.game.init_game()
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
							if app.game.ui_state != .market && app.game.ui_state != .police_encounter {
								app.game.ui_state = .market
							} else {
								running = false
							}
						}
						// Up / Down arrow keys cycle through commodities in Market view
						int(sdl.KeyCode.up) {
							if app.game.ui_state == .market {
								app.game.selected_drug = (app.game.selected_drug + drug_catalogue.len - 1) % drug_catalogue.len
							}
						}
						int(sdl.KeyCode.down) {
							if app.game.ui_state == .market {
								app.game.selected_drug = (app.game.selected_drug + 1) % drug_catalogue.len
							}
						}
						int(sdl.KeyCode._1), int(sdl.KeyCode.kp_1) {
							if app.game.ui_state == .subway {
								app.game.travel_to(.manhattan)
							} else if app.game.ui_state == .market {
								app.game.selected_drug = 0
							}
						}
						int(sdl.KeyCode._2), int(sdl.KeyCode.kp_2) {
							if app.game.ui_state == .subway {
								app.game.travel_to(.bronx)
							} else if app.game.ui_state == .market {
								app.game.selected_drug = 1
							}
						}
						int(sdl.KeyCode._3), int(sdl.KeyCode.kp_3) {
							if app.game.ui_state == .subway {
								app.game.travel_to(.brooklyn)
							} else if app.game.ui_state == .market {
								app.game.selected_drug = 2
							}
						}
						int(sdl.KeyCode._4), int(sdl.KeyCode.kp_4) {
							if app.game.ui_state == .subway {
								app.game.travel_to(.queens)
							} else if app.game.ui_state == .market {
								app.game.selected_drug = 3
							}
						}
						int(sdl.KeyCode._5), int(sdl.KeyCode.kp_5) {
							if app.game.ui_state == .subway {
								app.game.travel_to(.staten_island)
							} else if app.game.ui_state == .market {
								app.game.selected_drug = 4
							}
						}
						int(sdl.KeyCode._6), int(sdl.KeyCode.kp_6) {
							if app.game.ui_state == .subway {
								app.game.travel_to(.coney_island)
							} else if app.game.ui_state == .market {
								app.game.selected_drug = 5
							}
						}
						int(sdl.KeyCode._7), int(sdl.KeyCode.kp_7) {
							if app.game.ui_state == .market {
								app.game.selected_drug = 6
							}
						}
						int(sdl.KeyCode._8), int(sdl.KeyCode.kp_8) {
							if app.game.ui_state == .market {
								app.game.selected_drug = 7
							}
						}
						int(sdl.KeyCode.b) {
							if app.game.ui_state == .market {
								app.game.buy_drug(app.game.selected_drug, 100)
							} else if app.game.ui_state == .police_encounter {
								app.game.handle_police_action('bribe')
							}
						}
						int(sdl.KeyCode.return), int(sdl.KeyCode.space) {
							if app.game.ui_state == .market {
								app.game.buy_drug(app.game.selected_drug, 100)
							} else if app.game.ui_state == .game_over_screen {
								app.game.init_game()
							}
						}
						int(sdl.KeyCode.s) {
							if app.game.ui_state == .market {
								app.game.sell_drug(app.game.selected_drug, 100)
							}
						}
						int(sdl.KeyCode.t) {
							if app.game.ui_state == .market {
								app.game.ui_state = .subway
							}
						}
						int(sdl.KeyCode.k) {
							if app.game.ui_state == .market {
								app.game.ui_state = .bank
							}
						}
						int(sdl.KeyCode.l) {
							if app.game.ui_state == .market {
								app.game.ui_state = .loan_shark
							}
						}
						int(sdl.KeyCode.d) {
							if app.game.ui_state == .bank {
								app.game.deposit_bank(app.game.cash)
							}
						}
						int(sdl.KeyCode.w) {
							if app.game.ui_state == .bank {
								app.game.withdraw_bank(app.game.bank)
							}
						}
						int(sdl.KeyCode.p) {
							if app.game.ui_state == .loan_shark {
								app.game.pay_debt(app.game.cash)
							}
						}
						int(sdl.KeyCode.r) {
							if app.game.ui_state == .police_encounter {
								app.game.handle_police_action('run')
							} else if app.game.ui_state == .game_over_screen {
								app.game.init_game()
							}
						}
						int(sdl.KeyCode.m), int(sdl.KeyCode.o) {
							app.sound_mgr.toggle_sound()
						}
						else {}
					}
				}
				else {}
			}
		}

		app.game.update(dt)

		// Play sound events
		if app.game.sound_event != '' {
			ev := app.game.sound_event
			app.game.sound_event = ''
			match ev {
				'cash' { app.sound_mgr.play_cash() }
				'subway' { app.sound_mgr.play_subway() }
				'siren' { app.sound_mgr.play_siren() }
				'gunshot' { app.sound_mgr.play_gunshot() }
				else {}
			}
		}

		render_dopewars_game(renderer, mut app.game, win_w, win_h, app.mouse_x, app.mouse_y, app.sound_mgr.enabled)
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
