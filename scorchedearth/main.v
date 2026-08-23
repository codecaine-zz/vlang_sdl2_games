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
	game      ScorchedGame
	sound_mgr SoundManager
	key_left  bool
	key_right bool
	key_up    bool
	key_down  bool
	mouse_x   int
	mouse_y   int
}

fn new_app() App {
	return App{
		game:      new_scorched_game()
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

		mut snap_game := new_scorched_game()
		snap_game.init_textures(renderer)
		snap_game.projectiles << Projectile{
			wtype: .baby_nuke
			x: 460
			y: 220
			vx: 80
			vy: 10
			owner_id: 0
			active: true
		}
		snap_game.explosions << Explosion{
			x: 620
			y: 420
			radius: 35.0
			max_r: 50.0
			life: 0.2
			max_l: 0.4
			is_nuke: true
			col: Color{255, 200, 50, 255}
		}

		render_scorched_game(renderer, mut snap_game, win_w, win_h, 0, 0, true)
		sdl.save_bmp(surface, 'screenshots/scorchedearth.bmp'.str)
		return
	}

	mut app := new_app()

	window := sdl.create_window(
		'Scorched Earth - The Mother of All Games'.str,
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
	app.game.init_textures(renderer)

	mut event := sdl.Event{}
	mut running := true
	mut last_ticks := sdl.get_ticks()

	for running {
		now := sdl.get_ticks()
		dt := math.min(f64(now - last_ticks) / 1000.0, 0.05)
		last_ticks = now

		// Continuous angle & power adjustment
		if !app.game.in_shop && !app.game.is_game_over {
			mut cur_t := app.game.tanks[app.game.current_turn]
			if !cur_t.is_ai {
				if app.key_left {
					cur_t.angle = math.min(180.0, cur_t.angle + 35.0 * dt)
				}
				if app.key_right {
					cur_t.angle = math.max(0.0, cur_t.angle - 35.0 * dt)
				}
				if app.key_up {
					cur_t.power = math.min(1000.0, cur_t.power + 250.0 * dt)
				}
				if app.key_down {
					cur_t.power = math.max(50.0, cur_t.power - 250.0 * dt)
				}
				app.game.tanks[app.game.current_turn] = cur_t
			}
		}

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
					app.mouse_x = mx
					app.mouse_y = my

					if event.button.button == u8(sdl.button_left) {
						// 1. Sound toggle badge
						sound_x := win_w - 110
						if mx >= sound_x && mx <= sound_x + 95 && my >= 8 && my <= 32 {
							app.sound_mgr.toggle_sound()
							continue
						}

						// 2. Shop clicks
						if app.game.in_shop {
							weps := [
								WeaponType.baby_nuke,
								WeaponType.mirv,
								WeaponType.mountain_mover,
								WeaponType.napalm,
								WeaponType.digger,
							]
							mut row_y := 160
							for w in weps {
								if mx >= 110 && mx <= win_w - 110 && my >= row_y && my <= row_y + 48 {
									app.game.buy_weapon(w)
									break
								}
								row_y += 58
							}

							// Next Round Button
							if my >= win_h - 120 && my <= win_h - 70 && mx >= win_w / 2 - 200 && mx <= win_w / 2 + 200 {
								app.game.start_next_round()
							}
						} else if !app.game.is_game_over {
							// Gameplay dashboard clicks
							if my >= win_h - 55 {
								if mx >= win_w - 220 {
									app.game.fire_shot()
								} else if mx >= 330 && mx <= win_w - 230 {
									app.game.cycle_weapon(true)
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
						int(sdl.KeyCode.left), int(sdl.KeyCode.a) {
							app.key_left = true
						}
						int(sdl.KeyCode.right), int(sdl.KeyCode.d) {
							app.key_right = true
						}
						int(sdl.KeyCode.up), int(sdl.KeyCode.w) {
							app.key_up = true
						}
						int(sdl.KeyCode.down), int(sdl.KeyCode.s) {
							app.key_down = true
						}
						int(sdl.KeyCode.space), int(sdl.KeyCode.return) {
							if app.game.in_shop {
								app.game.start_next_round()
							} else {
								app.game.fire_shot()
							}
						}
						int(sdl.KeyCode.tab) {
							app.game.cycle_weapon(true)
						}
						int(sdl.KeyCode._1), int(sdl.KeyCode.kp_1) {
							if app.game.in_shop {
								app.game.buy_weapon(.baby_nuke)
							} else {
								app.game.select_weapon(.standard)
							}
						}
						int(sdl.KeyCode._2), int(sdl.KeyCode.kp_2) {
							if app.game.in_shop {
								app.game.buy_weapon(.mirv)
							} else {
								app.game.select_weapon(.baby_nuke)
							}
						}
						int(sdl.KeyCode._3), int(sdl.KeyCode.kp_3) {
							if app.game.in_shop {
								app.game.buy_weapon(.mountain_mover)
							} else {
								app.game.select_weapon(.mirv)
							}
						}
						int(sdl.KeyCode._4), int(sdl.KeyCode.kp_4) {
							if app.game.in_shop {
								app.game.buy_weapon(.napalm)
							} else {
								app.game.select_weapon(.mountain_mover)
							}
						}
						int(sdl.KeyCode._5), int(sdl.KeyCode.kp_5) {
							if app.game.in_shop {
								app.game.buy_weapon(.digger)
							} else {
								app.game.select_weapon(.napalm)
							}
						}
						int(sdl.KeyCode._6), int(sdl.KeyCode.kp_6) {
							if !app.game.in_shop {
								app.game.select_weapon(.digger)
							}
						}
						int(sdl.KeyCode.r) {
							app.game.init_match()
						}
						int(sdl.KeyCode.m), int(sdl.KeyCode.o) {
							app.sound_mgr.toggle_sound()
						}
						else {}
					}
				}
				.keyup {
					sym := int(event.key.keysym.sym)
					match sym {
						int(sdl.KeyCode.left), int(sdl.KeyCode.a) {
							app.key_left = false
						}
						int(sdl.KeyCode.right), int(sdl.KeyCode.d) {
							app.key_right = false
						}
						int(sdl.KeyCode.up), int(sdl.KeyCode.w) {
							app.key_up = false
						}
						int(sdl.KeyCode.down), int(sdl.KeyCode.s) {
							app.key_down = false
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
				'shot' { app.sound_mgr.play_shot(.standard) }
				'nuke_launch' { app.sound_mgr.play_shot(.baby_nuke) }
				'drill' { app.sound_mgr.play_shot(.digger) }
				'napalm' { app.sound_mgr.play_shot(.napalm) }
				'dirt' { app.sound_mgr.play_dirt() }
				'mirv_split' { app.sound_mgr.play_mirv_split() }
				'explosion' { app.sound_mgr.play_explosion(false) }
				'nuke_detonate' { app.sound_mgr.play_explosion(true) }
				'cash' { app.sound_mgr.play_cash() }
				'select' { app.sound_mgr.play_select() }
				'win' { app.sound_mgr.play_win() }
				else {}
			}
		}

		app.sound_mgr.update_audio(app.game.in_shop)

		render_scorched_game(renderer, mut app.game, win_w, win_h, app.mouse_x, app.mouse_y, app.sound_mgr.enabled)
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
