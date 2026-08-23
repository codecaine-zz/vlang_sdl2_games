module main

import math
import os
import sdl

const win_w = 920
const win_h = 600

struct App {
mut:
	window    &sdl.Window   = unsafe { nil }
	renderer  &sdl.Renderer = unsafe { nil }
	game      LemmingsGame
	sound_mgr SoundManager
	mouse_x   int
	mouse_y   int
}

fn new_app() App {
	return App{
		game:      new_lemmings_game()
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

		mut snap_game := new_lemmings_game()
		snap_game.banner_timer = 0.0
		snap_game.banner_text = ''
		snap_game.selected_skill = .builder
		for i in 0 .. 15 {
			snap_game.lemmings << Lemming{
				x: 100.0 + f64(i * 12)
				y: 220.0
				state: if i % 3 == 0 { .building } else if i % 4 == 0 { .blocking } else { .walking }
			}
		}

		render_lemmings_game(renderer, snap_game, win_w, win_h, 0, 0, true)
		sdl.save_bmp(surface, 'screenshots/lemmings.bmp'.str)
		return
	}

	mut app := new_app()

	window := sdl.create_window(
		'Lemmings Deluxe - 1991 Amiga Classic'.str,
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
					app.mouse_x = mx
					app.mouse_y = my

					if event.button.button == u8(sdl.button_left) {
						// 1. Top Header Action Buttons
						if my >= 8 && my <= 32 {
							// Reset Button
							rst_x := win_w - 330
							if mx >= rst_x && mx <= rst_x + 80 {
								app.game.load_level(app.game.level_idx)
								continue
							}
							// Next Level Button
							nxt_x := win_w - 240
							if mx >= nxt_x && mx <= nxt_x + 85 {
								app.game.load_level(app.game.level_idx + 1)
								continue
							}
							// Sound toggle badge
							sound_x := win_w - 145
							if mx >= sound_x && mx <= sound_x + 130 {
								app.sound_mgr.toggle_sound()
								continue
							}
						}

						// 2. Bottom Panel Buttons
						panel_y := win_h - 70
						if my >= panel_y + 10 && my <= panel_y + 58 {
							skills := [
								Skill.climber,
								Skill.floater,
								Skill.bomber,
								Skill.blocker,
								Skill.builder,
								Skill.basher,
								Skill.miner,
								Skill.digger,
							]
							mut sx := 15
							mut clicked_skill := false
							for s in skills {
								if mx >= sx && mx <= sx + 72 {
									app.game.selected_skill = s
									clicked_skill = true
									break
								}
								sx += 76
							}
							if clicked_skill {
								continue
							}

							// Pause
							if mx >= sx + 8 && mx <= sx + 78 {
								app.game.is_paused = !app.game.is_paused
								continue
							}
							// Speed
							if mx >= sx + 84 && mx <= sx + 149 {
								app.game.game_speed = if app.game.game_speed >= 4.0 { 1.0 } else { app.game.game_speed * 2.0 }
								continue
							}
							// Nuke
							if mx >= sx + 155 && mx <= sx + 235 {
								app.game.trigger_nuke()
								continue
							}
						} else if my >= 40 && my < panel_y {
							// 3. Assign Skill to closest clicked Lemming
							scale := 2
							mut closest_lem := -1
							mut min_dist := 35.0
							for i, lem in app.game.lemmings {
								if lem.state != .dead && lem.state != .exiting {
									lx := f64(int(lem.x) * scale)
									ly := f64(40 + int(lem.y) * scale)
									dist := math.sqrt(f64((mx - int(lx)) * (mx - int(lx)) + (my - int(ly)) * (my - int(ly))))
									if dist < min_dist {
										min_dist = dist
										closest_lem = i
									}
								}
							}
							if closest_lem >= 0 {
								app.game.assign_skill(closest_lem)
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
						// Number keys 1-8 and keypad 1-8
						int(sdl.KeyCode._1), int(sdl.KeyCode.kp_1), int(sdl.KeyCode.c) {
							app.game.selected_skill = .climber
						}
						int(sdl.KeyCode._2), int(sdl.KeyCode.kp_2) {
							app.game.selected_skill = .floater
						}
						int(sdl.KeyCode._3), int(sdl.KeyCode.kp_3), int(sdl.KeyCode.b) {
							app.game.selected_skill = .bomber
						}
						int(sdl.KeyCode._4), int(sdl.KeyCode.kp_4), int(sdl.KeyCode.k) {
							app.game.selected_skill = .blocker
						}
						int(sdl.KeyCode._5), int(sdl.KeyCode.kp_5), int(sdl.KeyCode.u) {
							app.game.selected_skill = .builder
						}
						int(sdl.KeyCode._6), int(sdl.KeyCode.kp_6), int(sdl.KeyCode.s) {
							app.game.selected_skill = .basher
						}
						int(sdl.KeyCode._7), int(sdl.KeyCode.kp_7), int(sdl.KeyCode.m) {
							app.game.selected_skill = .miner
						}
						int(sdl.KeyCode._8), int(sdl.KeyCode.kp_8), int(sdl.KeyCode.d) {
							app.game.selected_skill = .digger
						}
						// Cycle skills left/right
						int(sdl.KeyCode.tab), int(sdl.KeyCode.e), int(sdl.KeyCode.right) {
							app.game.selected_skill = match app.game.selected_skill {
								.climber { Skill.floater }
								.floater { Skill.bomber }
								.bomber { Skill.blocker }
								.blocker { Skill.builder }
								.builder { Skill.basher }
								.basher { Skill.miner }
								.miner { Skill.digger }
								.digger { Skill.climber }
							}
						}
						int(sdl.KeyCode.q), int(sdl.KeyCode.left) {
							app.game.selected_skill = match app.game.selected_skill {
								.climber { Skill.digger }
								.floater { Skill.climber }
								.bomber { Skill.floater }
								.blocker { Skill.bomber }
								.builder { Skill.blocker }
								.basher { Skill.builder }
								.miner { Skill.basher }
								.digger { Skill.miner }
							}
						}
						int(sdl.KeyCode.p), int(sdl.KeyCode.space) {
							app.game.is_paused = !app.game.is_paused
						}
						int(sdl.KeyCode.f), int(sdl.KeyCode.equals), int(sdl.KeyCode.plus) {
							app.game.game_speed = if app.game.game_speed >= 4.0 { 1.0 } else { app.game.game_speed * 2.0 }
						}
						int(sdl.KeyCode.x), int(sdl.KeyCode.delete) {
							app.game.trigger_nuke()
						}
						int(sdl.KeyCode.r), int(sdl.KeyCode.backspace) {
							app.game.load_level(app.game.level_idx)
						}
						int(sdl.KeyCode.n), int(sdl.KeyCode.return) {
							app.game.load_level(app.game.level_idx + 1)
						}
						int(sdl.KeyCode.o) {
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
				'letsgo' { app.sound_mgr.play_start() }
				'ohno' { app.sound_mgr.play_oh_no() }
				'explode', 'pop' { app.sound_mgr.play_explode() }
				'yippee', 'win' { app.sound_mgr.play_yippee() }
				'brick' { app.sound_mgr.play_brick() }
				else {}
			}
		}

		render_lemmings_game(renderer, app.game, win_w, win_h, app.mouse_x, app.mouse_y, app.sound_mgr.enabled)
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
