module main

import math
import os
import sdl

const win_w = 720
const win_h = 600

struct App {
mut:
	window    &sdl.Window        = unsafe { nil }
	renderer  &sdl.Renderer      = unsafe { nil }
	game      PuyoGame
	sound_mgr SoundManager
	tex_mgr   PuyoTextureManager
	particles []PuyoParticle
}

fn new_app() App {
	return App{
		game:      new_puyo_game()
		sound_mgr: new_sound_manager()
		tex_mgr:   new_puyo_texture_manager()
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

		mut snap_tex := new_puyo_texture_manager()
		snap_tex.init(renderer)

		mut snap_game := new_puyo_game()
		snap_game.score = 6400
		snap_game.chain_count = 3

		// Setup colorful board with combo structure
		snap_game.grid[11] = [1, 1, 2, 2, 3, 3]
		snap_game.grid[10] = [1, 4, 2, 4, 3, 5]
		snap_game.grid[9]  = [4, 4, 4, 5, 5, 5]
		snap_game.grid[8]  = [0, 0, 1, 2, 3, 0]
		snap_game.grid[7]  = [0, 0, 1, 2, 0, 0]

		snap_game.pair.r1 = 2.0
		snap_game.pair.c1 = 3
		snap_game.pair.rot = 1
		snap_game.pair.col1 = 1
		snap_game.pair.col2 = 4

		snap_game.next_pair.col1 = 2
		snap_game.next_pair.col2 = 3

		render_puyo_game(renderer, &snap_game, win_w, win_h, []PuyoParticle{}, snap_tex.sprite_texture)
		bmp_path := 'screenshots/puyopuyo.bmp'
		sdl.save_bmp(surface, bmp_path.str)
		return
	}

	mut app := new_app()

	window := sdl.create_window(
		'Puyo Puyo Cascade - Match-4 Combo Puzzle'.str,
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
	mut prev_game_over := false

	for running {
		now := sdl.get_ticks()
		dt := math.min(f64(now - last_ticks) / 1000.0, 0.05)
		last_ticks = now

		update_puyo_particles(mut app.particles, dt)
		app.sound_mgr.update_bgm(app.game.state != .game_over)

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
					} else if sym == int(sdl.KeyCode.r) {
						app.game.reset_game()
						prev_game_over = false
					} else if sym == int(sdl.KeyCode.m) {
						app.sound_mgr.toggle_sound()
					} else if sym == int(sdl.KeyCode.left) || sym == int(sdl.KeyCode.a) {
						if app.game.move_horiz(-1) { app.sound_mgr.play_move_sound() }
					} else if sym == int(sdl.KeyCode.right) || sym == int(sdl.KeyCode.d) {
						if app.game.move_horiz(1) { app.sound_mgr.play_move_sound() }
					} else if sym == int(sdl.KeyCode.w) || sym == int(sdl.KeyCode.up) || sym == int(sdl.KeyCode.z) {
						if app.game.rotate(1) { app.sound_mgr.play_rotate_sound() }
					} else if sym == int(sdl.KeyCode.x) {
						if app.game.rotate(-1) { app.sound_mgr.play_rotate_sound() }
					} else if sym == int(sdl.KeyCode.s) || sym == int(sdl.KeyCode.down) {
						app.game.fall_speed = 0.08
					} else if sym == int(sdl.KeyCode.space) {
						if app.game.state == .game_over {
							app.game.reset_game()
							prev_game_over = false
						} else {
							app.game.drop_instant()
							app.sound_mgr.play_drop_sound()
						}
					}
				}
				.keyup {
					sym := int(event.key.keysym.sym)
					if sym == int(sdl.KeyCode.s) || sym == int(sdl.KeyCode.down) {
						app.game.fall_speed = 0.65
					}
				}
				else {}
			}
		}

		res := app.game.update(dt)
		if res.popped {
			app.sound_mgr.play_chain_pop_sound(res.chain_level)
			for pop_ev in app.game.last_pops {
				col, _, _ := get_puyo_colors(pop_ev.color)
				for pos in pop_ev.positions {
					px := 180.0 + f64(pos[1]) * cell_sz + cell_sz / 2.0
					py := 60.0 + f64(pos[0]) * cell_sz + cell_sz / 2.0
					app.particles << create_puyo_burst(px, py, col)
				}
			}
			app.game.last_pops.clear()
		}

		if app.game.state == .game_over && !prev_game_over {
			prev_game_over = true
			app.sound_mgr.play_game_over_sound()
		}

		render_puyo_game(app.renderer, &app.game, win_w, win_h, app.particles, app.tex_mgr.sprite_texture)
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
