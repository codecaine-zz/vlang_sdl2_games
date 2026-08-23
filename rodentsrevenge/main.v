module main

import math
import os
import sdl

const win_w = 920
const win_h = 660

struct App {
mut:
	window    &sdl.Window    = unsafe { nil }
	renderer  &sdl.Renderer  = unsafe { nil }
	game      RodentGame
	sound_mgr SoundManager
	tex_mgr   TextureManager
}

fn new_app() App {
	return App{
		game:      new_rodent_game()
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

		mut snap_game := new_rodent_game()
		snap_game.banner_timer = 0.0
		snap_game.banner_text = ''
		snap_game.grid[8][8] = .cheese
		snap_game.grid[12][8] = .cheese
		snap_game.grid[9][11] = .cheese
		snap_game.score = 2500
		snap_game.move_player(1, 0)

		render_rodent_game(renderer, mut snap_game, win_w, win_h, true, snap_tex.sprite_texture)
		sdl.save_bmp(surface, 'screenshots/rodentsrevenge.bmp'.str)
		return
	}

	mut app := new_app()

	window := sdl.create_window(
		"Rodent's Revenge Deluxe - Windows 1991 Classic Remaster".str,
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
						sound_x := win_w - 130
						if mx >= sound_x && mx <= sound_x + 115 && my >= 10 && my <= 36 {
							app.sound_mgr.toggle_sound()
							continue
						}

						// 2. Mouse Click Navigation on Warehouse Board
						tile_s := 28
						board_x := (win_w - grid_w * tile_s) / 2
						board_y := 58
						board_w := grid_w * tile_s
						board_h := grid_h * tile_s

						if mx >= board_x && mx < board_x + board_w && my >= board_y && my < board_y + board_h {
							target_gx := (mx - board_x) / tile_s
							target_gy := (my - board_y) / tile_s
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
							app.game.init_level(app.game.level)
						}
						int(sdl.KeyCode.n) {
							app.game.init_level(app.game.level + 1)
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
		app.sound_mgr.update_bgm(!app.game.is_game_over)

		// Play sound events
		if app.game.sound_event != '' {
			ev := app.game.sound_event
			app.game.sound_event = ''
			match ev {
				'step' { app.sound_mgr.play_step() }
				'push' { app.sound_mgr.play_push() }
				'cheese' { app.sound_mgr.play_cheese_spawn() }
				'eat' { app.sound_mgr.play_eat() }
				'die' { app.sound_mgr.play_die() }
				'win' { app.sound_mgr.play_win() }
				'trap' { app.sound_mgr.play_trap() }
				'meow' { app.sound_mgr.play_meow() }
				else {}
			}
		}

		render_rodent_game(renderer, mut app.game, win_w, win_h, app.sound_mgr.enabled, app.tex_mgr.sprite_texture)
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
