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
	game      TriviaGame
	sound_mgr SoundManager
	mouse_x   int
	mouse_y   int
}

fn new_app() App {
	return App{
		game:      new_trivia_game(false)
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

		mut snap_game := new_trivia_game(false)
		snap_game.state = .question
		snap_game.current_round = 4
		snap_game.p1_score = 3250
		snap_game.p1_streak = 3
		snap_game.question_timer = 9.5

		render_trivia_game(renderer, mut snap_game, win_w, win_h, 0, 0)
		sdl.save_bmp(surface, 'screenshots/trivia.bmp'.str)
		return
	}

	mut app := new_app()

	window := sdl.create_window(
		'Party Trivia Show - TV Quiz Arena & Buzzers'.str,
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

						if app.game.state == .title || app.game.state == .game_over {
							app.game.start_game()
						} else if app.game.state == .question {
							btn_w := (win_w - 72) / 2
							btn_h := 85
							for i in 0 .. 4 {
								gx := i % 2
								gy := i / 2
								bx := 24 + gx * (btn_w + 24)
								by := 280 + gy * (btn_h + 20)
								if mx >= bx && mx <= bx + btn_w && my >= by && my <= by + btn_h {
									app.game.submit_answer_p1(i)
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
						int(sdl.KeyCode.space) {
							if app.game.state == .title || app.game.state == .game_over {
								app.game.start_game()
							} else if app.game.state == .answer_reveal {
								app.game.advance_to_next()
							}
						}
						int(sdl.KeyCode.t) {
							app.game.start_game()
						}
						int(sdl.KeyCode.m) {
							app.game.is_two_player = !app.game.is_two_player
							app.game.start_game()
						}
						int(sdl.KeyCode.s) {
							app.sound_mgr.toggle_sound()
						}
						// P1 Input (1-4 or A-D)
						int(sdl.KeyCode._1), int(sdl.KeyCode.a) { app.game.submit_answer_p1(0) }
						int(sdl.KeyCode._2), int(sdl.KeyCode.b) { app.game.submit_answer_p1(1) }
						int(sdl.KeyCode._3), int(sdl.KeyCode.c) { app.game.submit_answer_p1(2) }
						int(sdl.KeyCode._4), int(sdl.KeyCode.d) { app.game.submit_answer_p1(3) }
						// P2 Input (for 2P Mode: U, I, O, P)
						int(sdl.KeyCode.u) { app.game.submit_answer_p2(0) }
						int(sdl.KeyCode.i) { app.game.submit_answer_p2(1) }
						int(sdl.KeyCode.o) { app.game.submit_answer_p2(2) }
						int(sdl.KeyCode.p) { app.game.submit_answer_p2(3) }
						else {}
					}
				}
				else {}
			}
		}

		app.game.update(dt)

		// Sound events
		if app.game.sound_event != '' {
			ev := app.game.sound_event
			app.game.sound_event = ''
			match ev {
				'lock' { app.sound_mgr.play_buzzer_lock() }
				'correct' { app.sound_mgr.play_correct() }
				'wrong' { app.sound_mgr.play_wrong() }
				'victory' { app.sound_mgr.play_victory() }
				else {}
			}
		}

		sdl.set_render_draw_color(renderer, 0, 0, 0, 255)
		sdl.render_clear(renderer)

		render_trivia_game(renderer, mut app.game, win_w, win_h, app.mouse_x, app.mouse_y)

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
