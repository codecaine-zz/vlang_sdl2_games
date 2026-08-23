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
	game      PeggleGame
	sound_mgr SoundManager
	key_left  bool
	key_right bool
}

fn new_app() App {
	return App{
		game:      new_peggle_game()
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

		mut snap_game := new_peggle_game()
		snap_game.cannon_angle = math.pi / 2.3
		snap_game.shoot_ball()
		for _ in 0 .. 25 {
			snap_game.update(0.016)
		}

		render_peggle_game(renderer, mut snap_game, win_w, win_h, true, unsafe { nil })
		sdl.save_bmp(surface, 'screenshots/peggle.bmp'.str)
		return
	}

	mut app := new_app()

	window := sdl.create_window(
		'Peggle Extreme - Pachinko Peg-Popper Physics Arcade'.str,
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

	mut tex_mgr := PeggleTextureManager{}
	tex_mgr.init(renderer)

	app.window = window
	app.renderer = renderer

	mut event := sdl.Event{}
	mut running := true
	mut last_ticks := sdl.get_ticks()

	for running {
		now := sdl.get_ticks()
		dt := math.min(f64(now - last_ticks) / 1000.0, 0.05)
		last_ticks = now

		// Keyboard Aiming
		if app.key_left {
			app.game.cannon_angle = math.max(0.2, app.game.cannon_angle - 1.5 * dt)
		}
		if app.key_right {
			app.game.cannon_angle = math.min(math.pi - 0.2, app.game.cannon_angle + 1.5 * dt)
		}

		for sdl.poll_event(&event) != 0 {
			match event.@type {
				.quit {
					running = false
				}
				.mousemotion {
					mx := int(event.motion.x)
					my := int(event.motion.y)
					if my > 45 {
						cx := f64(win_w) / 2.0
						cy := 45.0
						app.game.cannon_angle = math.atan2(f64(my) - cy, f64(mx) - cx)
						app.game.cannon_angle = math.clamp(app.game.cannon_angle, 0.2, math.pi - 0.2)
					}
				}
				.mousebuttondown {
					mx := int(event.button.x)
					my := int(event.button.y)
					if event.button.button == u8(sdl.button_left) {
						// Sound toggle badge
						sound_x := win_w - 140
						if mx >= sound_x && mx <= sound_x + 120 && my >= 8 && my <= 32 {
							app.sound_mgr.toggle_sound()
						} else {
							app.game.shoot_ball()
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
						int(sdl.KeyCode.space) {
							app.game.shoot_ball()
						}
						int(sdl.KeyCode.r) {
							app.game.init_level()
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
				'cannon' { app.sound_mgr.play_cannon() }
				'ding' { app.sound_mgr.play_peg_ding(app.game.combo_hits) }
				'bucket' { app.sound_mgr.play_bucket_catch() }
				'fever' { app.sound_mgr.play_fever() }
				else {}
			}
		}

		render_peggle_game(renderer, mut app.game, win_w, win_h, app.sound_mgr.enabled, tex_mgr.sprite_texture)
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
