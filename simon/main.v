module main

import math
import os
import sdl

const win_w = 800
const win_h = 600

struct App {
mut:
	window    &sdl.Window   = unsafe { nil }
	renderer  &sdl.Renderer = unsafe { nil }
	game      SimonGame
	sound_mgr SoundManager
}

fn new_app() App {
	return App{
		game:      new_simon_game()
		sound_mgr: new_sound_manager()
	}
}

fn main() {
	if sdl.init(sdl.init_video | sdl.init_audio | sdl.init_events | sdl.init_timer) < 0 {
		eprintln('Failed to initialize SDL2')
		return
	}
	defer { sdl.quit() }

	if os.args.contains('--snap') {
		surface := sdl.create_rgb_surface(0, win_w, win_h, 32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000)
		if unsafe { surface == nil } { return }
		defer { sdl.free_surface(surface) }

		renderer := sdl.create_software_renderer(surface)
		if unsafe { renderer == nil } { return }
		defer { sdl.destroy_renderer(renderer) }
	sdl.render_set_logical_size(renderer, win_w, win_h)

		mut snap_game := new_simon_game()
		snap_game.mode = .classic
		snap_game.state = .player_turn
		snap_game.sequence = [0, 1, 3, 2, 0, 3]
		snap_game.lit_pad = 0 // Green illuminated
		snap_game.score = 6
		snap_game.streak = 6
		snap_game.high_score_classic = 12

		render_simon_console(renderer, &snap_game, win_w, win_h, 0, 0, unsafe { nil })
		sdl.save_bmp(surface, 'screenshots/simon.bmp'.str)
		return
	}

	mut app := new_app()

	window := sdl.create_window(
		'Cyber Simon - Electronic Light & Sound Memory Game'.str,
		sdl.windowpos_centered,
		sdl.windowpos_centered,
		win_w,
		win_h,
		u32(sdl.WindowFlags.shown) | u32(sdl.WindowFlags.fullscreen_desktop) | u32(sdl.WindowFlags.resizable)
	)
	if unsafe { window == nil } { return }
	defer { sdl.destroy_window(window) }

	renderer := sdl.create_renderer(window, -1, u32(sdl.RendererFlags.accelerated) | u32(sdl.RendererFlags.presentvsync))
	if unsafe { renderer == nil } { return }
	defer { sdl.destroy_renderer(renderer) }
	sdl.render_set_logical_size(renderer, win_w, win_h)

	mut tex_mgr := SimonTextureManager{}
	tex_mgr.init(renderer)

	app.window = window
	app.renderer = renderer

	mut event := sdl.Event{}
	mut running := true
	mut last_ticks := sdl.get_ticks()

	cx := win_w / 2
	cy := win_h / 2 + 10
	outer_rad := 200
	inner_rad := 85

	for running {
		now := sdl.get_ticks()
		dt := math.min(f64(now - last_ticks) / 1000.0, 0.05)
		last_ticks = now

		mut mouse_x := 0
		mut mouse_y := 0
		sdl.get_mouse_state(&mouse_x, &mouse_y)

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
						running = false
					} else if sym == int(sdl.KeyCode.space) {
						if app.game.state == .attract || app.game.state == .game_over {
							app.game.start_new_game()
						}
					} else if sym == int(sdl.KeyCode.r) {
						app.game.reset_game()
					} else if sym == int(sdl.KeyCode.m) {
						app.game.toggle_mode()
					} else if sym == int(sdl.KeyCode.s) {
						app.sound_mgr.toggle_sound()
					} else if sym == int(sdl.KeyCode._1) || sym == int(sdl.KeyCode.q) {
						_, ev := app.game.handle_pad_press(0)
						if ev.pad_tone >= 0 { app.sound_mgr.play_pad_tone(ev.pad_tone, ev.pad_dur) }
						if ev.error_buzz { app.sound_mgr.play_error_buzzer() }
						if ev.round_clear { app.sound_mgr.play_victory_jingle() }
					} else if sym == int(sdl.KeyCode._2) || sym == int(sdl.KeyCode.w) {
						_, ev := app.game.handle_pad_press(1)
						if ev.pad_tone >= 0 { app.sound_mgr.play_pad_tone(ev.pad_tone, ev.pad_dur) }
						if ev.error_buzz { app.sound_mgr.play_error_buzzer() }
						if ev.round_clear { app.sound_mgr.play_victory_jingle() }
					} else if sym == int(sdl.KeyCode._3) || sym == int(sdl.KeyCode.a) {
						_, ev := app.game.handle_pad_press(2)
						if ev.pad_tone >= 0 { app.sound_mgr.play_pad_tone(ev.pad_tone, ev.pad_dur) }
						if ev.error_buzz { app.sound_mgr.play_error_buzzer() }
						if ev.round_clear { app.sound_mgr.play_victory_jingle() }
					} else if sym == int(sdl.KeyCode._4) || sym == int(sdl.KeyCode.s) {
						_, ev := app.game.handle_pad_press(3)
						if ev.pad_tone >= 0 { app.sound_mgr.play_pad_tone(ev.pad_tone, ev.pad_dur) }
						if ev.error_buzz { app.sound_mgr.play_error_buzzer() }
						if ev.round_clear { app.sound_mgr.play_victory_jingle() }
					}
				}
				.mousebuttondown {
					if event.button.button == 1 {
						if app.game.state == .attract || app.game.state == .game_over {
							app.game.start_new_game()
						} else if app.game.state == .player_turn {
							pad := get_pad_under_mouse(cx, cy, inner_rad, outer_rad, mouse_x, mouse_y)
							if pad >= 0 {
								_, ev := app.game.handle_pad_press(pad)
								if ev.pad_tone >= 0 { app.sound_mgr.play_pad_tone(ev.pad_tone, ev.pad_dur) }
								if ev.error_buzz { app.sound_mgr.play_error_buzzer() }
								if ev.round_clear { app.sound_mgr.play_victory_jingle() }
							}
						}
					}
				}
				else {}
			}
		}

		ev := app.game.update(dt)
		if ev.pad_tone >= 0 {
			app.sound_mgr.play_pad_tone(ev.pad_tone, ev.pad_dur)
		}
		if ev.error_buzz {
			app.sound_mgr.play_error_buzzer()
		}
		if ev.round_clear {
			app.sound_mgr.play_victory_jingle()
		}

		render_simon_console(app.renderer, &app.game, win_w, win_h, mouse_x, mouse_y, tex_mgr.sprite_texture)
		sdl.delay(16)
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
