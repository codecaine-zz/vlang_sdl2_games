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
	game      TamagotchiGame
	sound_mgr SoundManager
}

fn new_app() App {
	return App{
		game:      new_tamagotchi_game()
		sound_mgr: new_sound_manager()
	}
}

fn main() {
	if sdl.init(sdl.init_video | sdl.init_audio | sdl.init_events | sdl.init_timer) < 0 {
		eprintln('Failed to initialize SDL2')
		return
	}
	defer { sdl.quit() }

	if os.args.contains('--snap') || os.getenv('SNAPSHOT') == '1' {
		surface := sdl.create_rgb_surface(0, win_w, win_h, 32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000)
		if unsafe { surface == nil } { return }
		defer { sdl.free_surface(surface) }

		renderer := sdl.create_software_renderer(surface)
		if unsafe { renderer == nil } { return }
		defer { sdl.destroy_renderer(renderer) }
	sdl.render_set_logical_size(renderer, win_w, win_h)

		mut snap_game := new_tamagotchi_game()
		snap_game.stage = .adult
		snap_game.age_days = 6
		snap_game.hunger = 4
		snap_game.happiness = 4
		snap_game.weight_oz = 12
		snap_game.dialog_msg = 'MAMETCHI IS FULL OF JOY!'
		snap_game.selected_icon = 2 // Game icon selected

		render_tamagotchi(renderer, &snap_game, win_w, win_h)
		sdl.save_bmp(surface, 'screenshots/tamagotchi.bmp'.str)
		return
	}

	mut app := new_app()

	window := sdl.create_window(
		'Tamagotchi 1996 - Virtual Pet Keychain Simulator'.str,
		sdl.windowpos_centered,
		sdl.windowpos_centered,
		win_w,
		win_h,
		u32(sdl.WindowFlags.shown) | u32(sdl.WindowFlags.fullscreen_desktop) | u32(sdl.WindowFlags.resizable)
	)
	if unsafe { window == nil } {
		eprintln('Failed to create window')
		return
	}
	defer { sdl.destroy_window(window) }

	renderer := sdl.create_renderer(window, -1, u32(sdl.RendererFlags.accelerated) | u32(sdl.RendererFlags.presentvsync))
	if unsafe { renderer == nil } {
		eprintln('Failed to create renderer')
		return
	}
	defer { sdl.destroy_renderer(renderer) }
	sdl.render_set_logical_size(renderer, win_w, win_h)

	app.window = window
	app.renderer = renderer
	app.sound_mgr.init()

	mut event := sdl.Event{}
	mut running := true
	mut last_ticks := sdl.get_ticks()

	for running {
		now := sdl.get_ticks()
		dt := math.min(f64(now - last_ticks) / 1000.0, 0.05)
		last_ticks = now

		if app.game.toast_timer > 0 {
			app.game.toast_timer -= dt
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
						running = false
					} else if sym == int(sdl.KeyCode.f5) {
						app.game.save_state()
					} else if sym == int(sdl.KeyCode.f9) {
						app.game.load_state()
					} else if sym == int(sdl.KeyCode.a) || sym == int(sdl.KeyCode.left) {
						app.game.button_a()
						app.sound_mgr.play_btn_click()
					} else if sym == int(sdl.KeyCode.b) || sym == int(sdl.KeyCode.space) || sym == int(sdl.KeyCode.return) {
						app.game.button_b()
						app.sound_mgr.play_btn_click()
					} else if sym == int(sdl.KeyCode.c) || sym == int(sdl.KeyCode.backspace) {
						app.game.button_c()
						app.sound_mgr.play_btn_click()
					} else if sym == int(sdl.KeyCode.m) {
						app.sound_mgr.toggle_sound()
					}
				}
				.mousebuttondown {
					if event.button.button == 1 {
						mx := event.button.x
						my := event.button.y
						cx := win_w / 2
						btn_y := win_h / 2 + 110

						// Click A, B, or C rubber buttons
						if my >= btn_y - 25 && my <= btn_y + 25 {
							if mx >= cx - 85 && mx <= cx - 45 {
								app.game.button_a()
								app.sound_mgr.play_btn_click()
							} else if mx >= cx - 20 && mx <= cx + 20 {
								app.game.button_b()
								app.sound_mgr.play_btn_click()
							} else if mx >= cx + 45 && mx <= cx + 85 {
								app.game.button_c()
								app.sound_mgr.play_btn_click()
							}
						}
					}
				}
				else {}
			}
		}

		app.game.update(dt)
		render_tamagotchi(app.renderer, &app.game, win_w, win_h)
		prod_fx_render(app.renderer)
		sdl.render_present(app.renderer)
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
