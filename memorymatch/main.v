module main

import math
import os
import sdl

const win_w = 900
const win_h = 650

struct App {
mut:
	window    &sdl.Window   = unsafe { nil }
	renderer  &sdl.Renderer = unsafe { nil }
	game      MemoryGame
	sound_mgr SoundManager
}

fn new_app() App {
	return App{
		game:      new_memory_game()
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

		mut snap_game := new_memory_game()
		snap_game.init_textures(renderer)
		snap_game.grid_mode = .grid_4x4
		snap_game.reset_game()
		snap_game.turns = 7
		snap_game.matches = 3
		snap_game.timer = 18.4
		snap_game.combo = 2

		// Uncover a few cards for showcase
		snap_game.cards[0].is_face_up = true
		snap_game.cards[0].flip_progress = 1.0
		snap_game.cards[0].is_matched = true

		snap_game.cards[3].is_face_up = true
		snap_game.cards[3].flip_progress = 1.0
		snap_game.cards[3].is_matched = true

		snap_game.cards[5].is_face_up = true
		snap_game.cards[5].flip_progress = 1.0

		snap_game.cards[9].is_face_up = true
		snap_game.cards[9].flip_progress = 0.7

		snap_game.spawn_sparks(450, 320, 30, Color{ r: 100, g: 255, b: 180 })
		snap_game.spawn_shockwave(450, 320, Color{ r: 80, g: 220, b: 255 })
		snap_game.spawn_floating_text(450, 260, '★ 2X COMBO! MATCH! ★', Color{ r: 255, g: 215, b: 0 }, 1)

		render_memory_match(renderer, &snap_game, win_w, win_h, 6)
		sdl.save_bmp(surface, 'screenshots/memorymatch.bmp'.str)
		return
	}

	mut app := new_app()

	window := sdl.create_window(
		'Memory Match Pro - 3D Card Flip Pair Memory Training'.str,
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
	mut mouse_x := 0
	mut mouse_y := 0

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
					mouse_x = event.motion.x
					mouse_y = event.motion.y
				}
				.keydown {
					sym := int(event.key.keysym.sym)
					if sym == int(sdl.KeyCode.f11) {
						toggle_fullscreen(window)
					} else if sym == int(sdl.KeyCode.escape) {
						running = false
					} else if sym == int(sdl.KeyCode.r) {
						app.game.reset_game()
					} else if sym == int(sdl.KeyCode.g) {
						app.game.toggle_grid_mode()
					} else if sym == int(sdl.KeyCode.s) {
						app.sound_mgr.toggle_sound()
					} else if sym == int(sdl.KeyCode.space) {
						if app.game.state == .game_won {
							app.game.reset_game()
						}
					}
				}
				.mousebuttondown {
					if event.button.button == u8(sdl.button_left) || event.button.button == 1 {
						mouse_x = event.button.x
						mouse_y = event.button.y

						if app.game.state == .game_won {
							app.game.reset_game()
						} else {
							// Top HUD Click shortcuts (Grid mode, Sound, Reset)
							if mouse_y < 54 {
								if mouse_x >= 220 && mouse_x <= 360 {
									app.game.toggle_grid_mode()
									app.sound_mgr.play_click_sound()
								}
							} else {
								clicked_card := get_card_index_at(mouse_x, mouse_y, &app.game, win_w, win_h)
								if clicked_card >= 0 {
									_, ev := app.game.flip_card(clicked_card)
									if ev.card_flipped {
										app.sound_mgr.play_flip_sound()
									}
									if ev.cards_matched {
										app.sound_mgr.play_match_sound(ev.combo_level)
									}
									if ev.cards_mismatch {
										app.sound_mgr.play_mismatch_sound()
									}
									if ev.game_won {
										app.sound_mgr.play_win_fanfare()
									}
								}
							}
						}
					}
				}
				else {}
			}
		}

		hover_card := get_card_index_at(mouse_x, mouse_y, &app.game, win_w, win_h)

		ev := app.game.update(dt)
		if ev.game_won {
			app.sound_mgr.play_win_fanfare()
		}

		app.sound_mgr.update_bgm(app.game.state == .playing)
		render_memory_match(app.renderer, &app.game, win_w, win_h, hover_card)
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
