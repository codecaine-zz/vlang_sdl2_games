module main

import math
import os
import sdl

const win_w = 920
const win_h = 640

struct App {
mut:
	window    &sdl.Window    = unsafe { nil }
	renderer  &sdl.Renderer  = unsafe { nil }
	game      ChipsGame
	sound_mgr SoundManager
	tex_mgr   TextureManager
}

fn new_app() App {
	return App{
		game:      new_chips_game()
		sound_mgr: new_sound_manager()
		tex_mgr:   new_texture_manager()
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

		mut snap_tex := new_texture_manager()
		snap_tex.init(renderer)

		mut snap_game := new_chips_game()
		snap_game.banner_timer = 0.0
		snap_game.banner_text = ''
		snap_game.move_player(1, 0)
		snap_game.move_player(1, 0)
		snap_game.red_keys = 1
		snap_game.blue_keys = 1
		snap_game.has_flippers = true

		render_chips_game(renderer, mut snap_game, win_w, win_h, true, snap_tex.sprite_texture)
		sdl.save_bmp(surface, 'screenshots/chipschallenge.bmp'.str)
		return
	}

	mut app := new_app()

	window := sdl.create_window(
		"Chip's Challenge Deluxe - 1989 Windows Classic".str,
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
				.mousebuttondown {
					mx := int(event.button.x)
					my := int(event.button.y)
					if event.button.button == u8(sdl.button_left) {
						// 1. Sound toggle badge
						tile_size := 36
						board_x := 30
						board_y := 30
						board_w := grid_size * tile_size
						hud_x := board_x + board_w + 25
						hud_w := win_w - hud_x - 30
						sound_x := hud_x + 20
						sound_y := 30 + board_w - 50
						if mx >= sound_x && mx <= sound_x + (hud_w - 40) && my >= sound_y && my <= sound_y + 28 {
							app.sound_mgr.toggle_sound()
							continue
						}

						// 2. Mouse Click Navigation on Maze Board
						if mx >= board_x && mx < board_x + board_w && my >= board_y && my < board_y + board_w {
							target_gx := (mx - board_x) / tile_size
							target_gy := (my - board_y) / tile_size
							dx := target_gx - app.game.player_x
							dy := target_gy - app.game.player_y
							if math.abs(dx) > math.abs(dy) {
								app.game.move_player(if dx > 0 { 1 } else { -1 }, 0)
							} else if dy != 0 {
								app.game.move_player(0, if dy > 0 { 1 } else { -1 })
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
						int(sdl.KeyCode.f5) {
							app.game.save_state()
						}
						int(sdl.KeyCode.f9) {
							app.game.load_state()
						}
						int(sdl.KeyCode.left), int(sdl.KeyCode.a) {
							app.game.move_player(-1, 0)
						}
						int(sdl.KeyCode.right), int(sdl.KeyCode.d) {
							app.game.move_player(1, 0)
						}
						int(sdl.KeyCode.up), int(sdl.KeyCode.w) {
							app.game.move_player(0, -1)
						}
						int(sdl.KeyCode.down), int(sdl.KeyCode.s) {
							app.game.move_player(0, 1)
						}
						int(sdl.KeyCode.r) {
							app.game.load_level(app.game.level_idx)
						}
						int(sdl.KeyCode.n) {
							app.game.load_level(app.game.level_idx + 1)
							app.game.save_progress()
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
				'step' { app.sound_mgr.play_step() }
				'chip' { app.sound_mgr.play_chip() }
				'key' { app.sound_mgr.play_key() }
				'door' { app.sound_mgr.play_door() }
				'socket' { app.sound_mgr.play_socket() }
				'win' { app.sound_mgr.play_win() }
				'death' { app.sound_mgr.play_death() }
				'push' { app.sound_mgr.play_push() }
				'boot' { app.sound_mgr.play_boot() }
				'splash' { app.sound_mgr.play_splash() }
				'burn' { app.sound_mgr.play_burn() }
				else {}
			}
		}

		// Stream background soundtrack & active SFX channels
		app.sound_mgr.update_bgm(true)

		sdl.set_render_draw_color(renderer, 0, 0, 0, 255)
		sdl.render_clear(renderer)

		render_chips_game(renderer, mut app.game, win_w, win_h, app.sound_mgr.sound_enabled, app.tex_mgr.sprite_texture)
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
