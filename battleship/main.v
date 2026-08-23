module main

import math
import os
import sdl

const win_w = 940
const win_h = 660

struct App {
mut:
	window    &sdl.Window              = unsafe { nil }
	renderer  &sdl.Renderer            = unsafe { nil }
	game      BattleshipGame
	sound_mgr SoundManager
	tex_mgr   BattleshipTextureManager
	mouse_x   int
	mouse_y   int
}

fn new_app() App {
	return App{
		game:      new_battleship_game(false)
		sound_mgr: new_sound_manager()
		tex_mgr:   new_battleship_texture_manager()
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

		mut snap_tex := new_battleship_texture_manager()
		snap_tex.init(renderer)

		mut snap_game := new_battleship_game(false)
		snap_game.p1_grid.auto_place_all()
		snap_game.start_battle()

		// Simulate some hits and misses
		snap_game.p2_grid.cells[1][2] = cell_hit
		snap_game.p2_grid.cells[1][3] = cell_hit
		snap_game.p2_grid.cells[1][4] = cell_hit
		snap_game.p2_grid.cells[4][6] = cell_miss
		snap_game.p2_grid.cells[7][8] = cell_sunk
		snap_game.p2_grid.cells[8][8] = cell_sunk

		snap_game.p1_grid.cells[3][3] = cell_hit
		snap_game.p1_grid.cells[0][0] = cell_miss
		snap_game.p1_grid.cells[6][1] = cell_miss
		snap_game.shots_fired_p1 = 8
		snap_game.shots_hit_p1 = 5
		snap_game.status_message = 'DIRECT HIT! Enemy Destroyer vessel SUNK at I9!'

		render_battleship_game(renderer, mut snap_game, win_w, win_h, 0, 0, snap_tex.sprite_texture)
		sdl.save_bmp(surface, 'screenshots/battleship.bmp'.str)
		return
	}

	mut app := new_app()

	window := sdl.create_window(
		'Battleship Pro - Tactical Naval Warfare & Radar Strategy'.str,
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
					mx := event.button.x
					my := event.button.y
					btn := event.button.button

					if btn == sdl.button_right {
						// Toggle placement orientation
						if app.game.phase == .placement {
							app.game.place_horizontal = !app.game.place_horizontal
						}
					} else if btn == sdl.button_left {
						grid_pix := 32
						left_gx := 50
						left_gy := 120
						right_gx := 520
						right_gy := 120
						panel_y := win_h - 170

						if app.game.phase == .placement {
							// Check click on ship selection buttons
							for i in 0 .. app.game.p1_grid.ships.len {
								bx := 40 + i * 140
								by := panel_y + 52
								if mx >= bx && mx <= bx + 130 && my >= by && my <= by + 42 {
									app.game.selected_ship_idx = i
								}
							}

							// Check click on Auto-Place button
							if mx >= 760 && mx <= 890 && my >= panel_y + 14 && my <= panel_y + 50 {
								app.game.p1_grid.auto_place_all()
								app.sound_mgr.play_sonar()
							}

							// Check click on Start Battle button
							if mx >= 760 && mx <= 890 && my >= panel_y + 58 && my <= panel_y + 94 {
								app.game.start_battle()
							}

							// Check click on player placement grid
							if mx >= left_gx && mx < left_gx + grid_pix * 10 && my >= left_gy && my < left_gy + grid_pix * 10 {
								gx := (mx - left_gx) / grid_pix
								gy := (my - left_gy) / grid_pix
								if app.game.p1_grid.place_ship(app.game.selected_ship_idx, gx, gy, app.game.place_horizontal) {
									app.sound_mgr.play_sonar()
									// Select next unplaced ship
									for next_i, s in app.game.p1_grid.ships {
										if !s.placed {
											app.game.selected_ship_idx = next_i
											break
										}
									}
								}
							}
						} else if app.game.phase == .battle {
							// Check Radar Recon button click
							if mx >= 750 && mx <= 890 && my >= panel_y + 35 && my <= panel_y + 77 {
								if app.game.radar_left_p1 > 0 {
									app.game.radar_active = !app.game.radar_active
								}
							}

							// Check click on enemy radar grid
							if mx >= right_gx && mx < right_gx + grid_pix * 10 && my >= right_gy && my < right_gy + grid_pix * 10 {
								gx := (mx - right_gx) / grid_pix
								gy := (my - right_gy) / grid_pix
								app.game.execute_player_turn(gx, gy)
							}
						} else if app.game.phase == .game_over {
							app.game.reset()
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
							if app.game.phase == .placement {
								app.game.place_horizontal = !app.game.place_horizontal
							} else if app.game.phase == .game_over {
								app.game.reset()
							}
						}
						int(sdl.KeyCode.f) {
							if app.game.phase == .placement {
								app.game.p1_grid.auto_place_all()
								app.sound_mgr.play_sonar()
							}
						}
						int(sdl.KeyCode.space) {
							if app.game.phase == .placement {
								app.game.start_battle()
							} else if app.game.phase == .game_over {
								app.game.reset()
							}
						}
						int(sdl.KeyCode.v), int(sdl.KeyCode.o) {
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
				'sonar' { app.sound_mgr.play_sonar() }
				'launch' { app.sound_mgr.play_launch() }
				'splash' { app.sound_mgr.play_splash() }
				'hit' { app.sound_mgr.play_hit() }
				'sunk' { app.sound_mgr.play_sunk() }
				'victory' { app.sound_mgr.play_victory() }
				'place' { app.sound_mgr.play_place() }
				'radar' { app.sound_mgr.play_radar() }
				else {}
			}
		}

		// Stream background soundtrack & active SFX channels
		app.sound_mgr.update_bgm(true)

		sdl.set_render_draw_color(renderer, 0, 0, 0, 255)
		sdl.render_clear(renderer)

		render_battleship_game(renderer, mut app.game, win_w, win_h, app.mouse_x, app.mouse_y, app.tex_mgr.sprite_texture)

		prod_fx_render(renderer)
		sdl.render_present(renderer)
	}

	app.sound_mgr.cleanup()
}

fn toggle_fullscreen(window &sdl.Window) {
	flags := sdl.get_window_flags(window)
	if (flags & u32(sdl.WindowFlags.fullscreen_desktop)) != 0 || (flags & u32(sdl.WindowFlags.fullscreen)) != 0 {
		sdl.set_window_fullscreen(window, 0)
	} else {
		sdl.set_window_fullscreen(window, u32(sdl.WindowFlags.fullscreen_desktop))
	}
}
