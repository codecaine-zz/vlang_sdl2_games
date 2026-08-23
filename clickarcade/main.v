module main

import math
import os
import sdl

const win_w = 880
const win_h = 600

struct App {
pub mut:
	window    &sdl.Window   = unsafe { nil }
	renderer  &sdl.Renderer = unsafe { nil }
	arcade    ArcadeManager
	sound_mgr SoundManager
}

fn new_app() App {
	return App{
		arcade:    new_arcade_manager()
		sound_mgr: new_sound_manager()
	}
}

fn main() {
	if sdl.init(sdl.init_video | sdl.init_audio | sdl.init_events | sdl.init_timer) < 0 {
		eprintln('Failed to initialize SDL2')
		return
	}
	defer { sdl.quit() }

	// Snapshot capture support for automated testing and gallery
	if os.args.contains('--snap') {
		surface := sdl.create_rgb_surface(0, win_w, win_h, 32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000)
		if unsafe { surface == nil } { return }
		defer { sdl.free_surface(surface) }

		renderer := sdl.create_software_renderer(surface)
		if unsafe { renderer == nil } { return }
		defer { sdl.destroy_renderer(renderer) }
	sdl.render_set_logical_size(renderer, win_w, win_h)

		mut snap_app := new_app()
		snap_app.arcade.screen = .menu
		snap_app.arcade.hovered_btn = 0
		snap_app.arcade.total_clicks = 1380
		snap_app.arcade.gem_rush_best = 42500.0
		snap_app.arcade.chain_best_score = 18400
		snap_app.arcade.whack_best_score = 9600
		snap_app.arcade.blade_best_score = 14200

		render_arcade_menu(renderer, &snap_app.arcade, win_w, win_h)
		sdl.save_bmp(surface, 'screenshots/clickarcade.bmp'.str)
		return
	}

	mut app := new_app()

	window := sdl.create_window(
		'Click Arcade - Addictive Mouse Mini Games'.str,
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
	mut is_mouse_down := false

	for running {
		now := sdl.get_ticks()
		dt := math.min(f64(now - last_ticks) / 1000.0, 0.05)
		last_ticks = now

		mut mouse_x := 0
		mut mouse_y := 0
		sdl.get_mouse_state(&mouse_x, &mouse_y)

		// Update hover state in menu
		if app.arcade.screen == .menu {
			app.arcade.hovered_btn = -1
			for i, btn in app.arcade.buttons {
				if mouse_x >= btn.x && mouse_x <= btn.x + btn.w && mouse_y >= btn.y && mouse_y <= btn.y + btn.h {
					app.arcade.hovered_btn = i
					break
				}
			}
		}

		for sdl.poll_event(&event) != 0 {
			match event.@type {
				.quit {
					running = false
				}
				.keydown {
					sym := int(event.key.keysym.sym)
					if sym == int(sdl.KeyCode.f11) {
						toggle_fullscreen(window)
					} else if sym == int(sdl.KeyCode.escape) {
						if app.arcade.screen == .menu {
							running = false
						} else {
							app.arcade.screen = .menu
							app.sound_mgr.play_click_pop()
						}
					} else if sym == int(sdl.KeyCode.m) {
						app.sound_mgr.toggle_sound()
					}
				}
				.mousemotion {
					if app.arcade.screen == .blade_slicer {
						app.arcade.blade_game.process_mouse_move(f64(event.motion.x), f64(event.motion.y), is_mouse_down, mut app.sound_mgr)
					}
				}
				.mousebuttonup {
					if event.button.button == sdl.button_left {
						is_mouse_down = false
						if app.arcade.screen == .blade_slicer {
							app.arcade.blade_game.process_mouse_move(f64(event.button.x), f64(event.button.y), false, mut app.sound_mgr)
						}
					}
				}
				.mousebuttondown {
					if event.button.button == sdl.button_left {
						is_mouse_down = true
						app.arcade.total_clicks++
						mx := f64(event.button.x)
						my := f64(event.button.y)

						match app.arcade.screen {
							.menu {
								if app.arcade.hovered_btn >= 0 {
									app.sound_mgr.play_upgrade_bought()
									match app.arcade.hovered_btn {
										0 { app.arcade.screen = .gem_rush }
										1 {
											app.arcade.chain_game.start_level(1)
											app.arcade.screen = .chain_reaction
										}
										2 {
											app.arcade.whack_game.reset()
											app.arcade.screen = .whack_monster
										}
										3 {
											app.arcade.blade_game.reset()
											app.arcade.screen = .blade_slicer
										}
										else {}
									}
								}
							}
							.gem_rush {
								// Check back button
								if mx >= 20.0 && mx <= 120.0 && my >= 10.0 && my <= 40.0 {
									app.arcade.screen = .menu
									app.sound_mgr.play_click_pop()
									continue
								}

								// Check Golden Gem
								if app.arcade.gem_game.golden_gem.active {
									dx := mx - app.arcade.gem_game.golden_gem.x
									dy := my - app.arcade.gem_game.golden_gem.y
									if dx * dx + dy * dy <= 30.0 * 30.0 {
										app.arcade.gem_game.click_golden_gem(mut app.sound_mgr)
										continue
									}
								}

								// Check Shop Buildings
								shop_x := 490.0
								shop_w := 365.0
								mut cur_y := 115.0
								mut clicked_shop := false

								for i in 0 .. app.arcade.gem_game.buildings.len {
									if mx >= shop_x && mx <= shop_x + shop_w && my >= cur_y && my <= cur_y + 56.0 {
										app.arcade.gem_game.buy_building(i, mut app.sound_mgr)
										clicked_shop = true
										break
									}
									cur_y += 62.0
								}

								// Check Ascension button
								if !clicked_shop && app.arcade.gem_game.can_ascend() {
									if mx >= shop_x && mx <= shop_x + shop_w && my >= cur_y + 10.0 && my <= cur_y + 52.0 {
										app.arcade.gem_game.ascend(mut app.sound_mgr)
										clicked_shop = true
									}
								}

								// Check Big Gem click
								if !clicked_shop {
									gem_cx := 240.0
									gem_cy := 290.0
									dx := mx - gem_cx
									dy := my - gem_cy
									rad := 110.0
									if dx * dx + dy * dy <= rad * rad {
										app.arcade.gem_game.click_gem(mx, my, mut app.sound_mgr)
									} else {
										// Click anywhere on left field still clicks gem!
										if mx < 470.0 && my > 70.0 {
											app.arcade.gem_game.click_gem(gem_cx, gem_cy, mut app.sound_mgr)
										}
									}
								}
							}
							.chain_reaction {
								// Check back button
								if mx >= 20.0 && mx <= 120.0 && my >= 10.0 && my <= 40.0 {
									app.arcade.screen = .menu
									app.sound_mgr.play_click_pop()
									continue
								}

								if app.arcade.chain_game.state == 'cleared' {
									app.arcade.chain_game.start_level(app.arcade.chain_game.level + 1)
									app.sound_mgr.play_click_pop()
								} else if app.arcade.chain_game.state == 'failed' {
									app.arcade.chain_game.start_level(app.arcade.chain_game.level)
									app.sound_mgr.play_click_pop()
								} else if app.arcade.chain_game.state == 'ready' {
									app.arcade.chain_game.click_trigger(mx, my, mut app.sound_mgr)
								}
							}
							.whack_monster {
								// Check back button
								if mx >= 20.0 && mx <= 120.0 && my >= 10.0 && my <= 40.0 {
									app.arcade.screen = .menu
									app.sound_mgr.play_click_pop()
									continue
								}

								if app.arcade.whack_game.game_over {
									app.arcade.whack_game.reset()
									app.sound_mgr.play_click_pop()
								} else {
									app.arcade.whack_game.click_at(mx, my, mut app.sound_mgr)
								}
							}
							.blade_slicer {
								// Check back button
								if mx >= 20.0 && mx <= 120.0 && my >= 10.0 && my <= 40.0 {
									app.arcade.screen = .menu
									app.sound_mgr.play_click_pop()
									continue
								}

								if app.arcade.blade_game.game_over {
									app.arcade.blade_game.reset()
									app.sound_mgr.play_click_pop()
								}
							}
						}
					}
				}
				else {}
			}
		}

		// Update game logic
		app.arcade.update(dt, mut app.sound_mgr)

		// Render frame
		match app.arcade.screen {
			.menu {
				render_arcade_menu(renderer, &app.arcade, win_w, win_h)
			}
			.gem_rush {
				render_gem_rush(renderer, &app.arcade.gem_game, win_w, win_h)
			}
			.chain_reaction {
				render_chain_reaction(renderer, &app.arcade.chain_game, win_w, win_h, mouse_x, mouse_y)
			}
			.whack_monster {
				render_whack_monster(renderer, &app.arcade.whack_game, win_w, win_h, mouse_x, mouse_y)
			}
			.blade_slicer {
				render_blade_slicer(renderer, &app.arcade.blade_game, win_w, win_h)
			}
		}

		prod_fx_render(renderer)
		sdl.render_present(renderer)
		sdl.delay(1)
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
