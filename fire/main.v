module main

import os
import sdl

struct App {
mut:
	window    &sdl.Window   = unsafe { nil }
	renderer  &sdl.Renderer = unsafe { nil }
	game      FireGame
	sound_mgr SoundManager
}

fn new_app() App {
	return App{
		game: new_fire_game()
		sound_mgr: new_sound_manager()
	}
}

fn (app &App) init() bool {
	if sdl.init(sdl.init_video | sdl.init_audio) < 0 {
		eprintln('Failed to init SDL')
		return false
	}

	mut mutable_app := unsafe { &App(app) }
	mutable_app.sound_mgr.init()

	window_flags := u32(sdl.WindowFlags.shown) | u32(sdl.WindowFlags.fullscreen_desktop) | u32(sdl.WindowFlags.resizable)
	mutable_app.window = sdl.create_window('Nintendo Game & Watch: Fire (1980 LCD Arcade)'.str,
		sdl.windowpos_centered, sdl.windowpos_centered, 800, 600, window_flags)

	if mutable_app.window == unsafe { nil } {
		eprintln('Failed to create window')
		return false
	}

	render_flags := u32(sdl.RendererFlags.accelerated) | u32(sdl.RendererFlags.presentvsync)
	mutable_app.renderer = sdl.create_renderer(mutable_app.window, -1, render_flags)

	if mutable_app.renderer == unsafe { nil } {
		eprintln('Failed to create renderer')
		return false
	}

	sdl.render_set_logical_size(mutable_app.renderer, 800, 600)

	sdl.set_render_draw_blend_mode(mutable_app.renderer, .blend)
	return true
}

fn (app &App) run() {
	mut mutable_app := unsafe { &App(app) }
	mut event := sdl.Event{}
	mut last_ticks := sdl.get_ticks()
	mut running := true

	for running {
		if os.getenv('SNAPSHOT') == '1' || os.args.contains('--snap') || os.args.contains('--snapshot') {
			surface := sdl.create_rgb_surface(0, 800, 600, 32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000)
			if unsafe { surface != nil } {
				sw_rend := sdl.create_software_renderer(surface)
				if unsafe { sw_rend != nil } {
					mutable_app.game.start_game(.game_a)
					mutable_app.game.jumpers << Jumper{ step: 1, active: true, crashed: false }
					mutable_app.game.jumpers << Jumper{ step: 7, active: true, crashed: false }
					mutable_app.game.jumpers << Jumper{ step: 11, active: true, crashed: false }
					mutable_app.game.score = 42
					draw_fire_game(sw_rend, &mutable_app.game)
					os.mkdir_all('screenshots') or {}
					sdl.save_bmp(surface, 'screenshots/fire.bmp'.str)
					sdl.destroy_renderer(sw_rend)
				}
				sdl.free_surface(surface)
			}
			break
		}

		current_ticks := sdl.get_ticks()
		dt := f64(current_ticks - last_ticks) / 1000.0
		last_ticks = current_ticks
		clamped_dt := if dt > 0.1 { 0.1 } else { dt }

		for sdl.poll_event(&event) != 0 {
			match unsafe { event.type } {
				.quit {
					running = false
				}
				.keydown {
					sym := event.key.keysym.sym
					if sym == int(sdl.KeyCode.f11) {
						toggle_fullscreen(mutable_app.window)
					} else if sym == int(sdl.KeyCode.escape) {
						running = false
					} else if sym == int(sdl.KeyCode.m) {
						mutable_app.sound_mgr.toggle_sound()
					} else if sym == int(sdl.KeyCode._1) {
						mutable_app.game.start_game(.game_a)
					} else if sym == int(sdl.KeyCode._2) {
						mutable_app.game.start_game(.game_b)
					} else if sym == int(sdl.KeyCode.space) || sym == int(sdl.KeyCode.return) {
						if mutable_app.game.state == .title || mutable_app.game.state == .game_over {
							mutable_app.game.start_game(mutable_app.game.mode)
						}
					} else if sym == int(sdl.KeyCode.left) || sym == int(sdl.KeyCode.a) {
						mutable_app.game.move_left()
					} else if sym == int(sdl.KeyCode.right) || sym == int(sdl.KeyCode.d) {
						mutable_app.game.move_right()
					} else if sym == int(sdl.KeyCode.z) {
						mutable_app.game.set_pos(0)
					} else if sym == int(sdl.KeyCode.x) {
						mutable_app.game.set_pos(1)
					} else if sym == int(sdl.KeyCode.c) {
						mutable_app.game.set_pos(2)
					}
				}
				else {}
			}
		}

		mutable_app.game.update(clamped_dt, mut mutable_app.sound_mgr)

		sdl.set_render_draw_color(mutable_app.renderer, 0, 0, 0, 255)
		sdl.render_clear(mutable_app.renderer)
		draw_fire_game(mutable_app.renderer, &mutable_app.game)
		prod_fx_render(mutable_app.renderer)
		sdl.render_present(mutable_app.renderer)
		sdl.delay(16)
	}

	if mutable_app.renderer != unsafe { nil } {
		sdl.destroy_renderer(mutable_app.renderer)
	}
	if mutable_app.window != unsafe { nil } {
		sdl.destroy_window(mutable_app.window)
	}
	sdl.quit()
}

fn main() {
	app := new_app()
	if app.init() {
		app.run()
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
