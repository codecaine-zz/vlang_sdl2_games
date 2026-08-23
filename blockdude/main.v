module main

import os
import sdl

struct App {
mut:
	window    &sdl.Window   = unsafe { nil }
	renderer  &sdl.Renderer = unsafe { nil }
	game      BlockDudeGame
	sound_mgr SoundManager
}

fn new_app() App {
	return App{
		game: new_blockdude_game()
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
	mutable_app.window = sdl.create_window('TI-83 Block Dude - Retro Puzzle Platformer'.str,
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
	mut running := true

	for running {
		if os.getenv('SNAPSHOT') == '1' {
			surface := sdl.create_rgb_surface(0, 800, 600, 32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000)
			if unsafe { surface != nil } {
				sw_rend := sdl.create_software_renderer(surface)
				if unsafe { sw_rend != nil } {
					draw_blockdude_game(sw_rend, &mutable_app.game)
					os.mkdir_all('screenshots') or {}
					sdl.save_bmp(surface, 'screenshots/blockdude.bmp'.str)
					sdl.destroy_renderer(sw_rend)
				}
				sdl.free_surface(surface)
			}
			break
		}

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
					} else if sym == int(sdl.KeyCode.u) {
						if mutable_app.game.undo() {
							mutable_app.sound_mgr.play_step()
						}
					} else if sym == int(sdl.KeyCode.r) {
						mutable_app.game.restart_level()
						mutable_app.sound_mgr.play_restart()
					} else if sym == int(sdl.KeyCode.n) {
						mutable_app.game.next_level()
						mutable_app.sound_mgr.play_step()
					} else if sym == int(sdl.KeyCode.p) {
						mutable_app.game.prev_level()
						mutable_app.sound_mgr.play_step()
					} else if sym == int(sdl.KeyCode.left) || sym == int(sdl.KeyCode.a) {
						prev_y := mutable_app.game.player_y
						if mutable_app.game.move_dir(.left) {
							if mutable_app.game.player_y < prev_y {
								mutable_app.sound_mgr.play_climb()
							} else {
								mutable_app.sound_mgr.play_step()
							}
							if mutable_app.game.state == .level_complete || mutable_app.game.state == .game_won {
								mutable_app.sound_mgr.play_win()
							}
						}
					} else if sym == int(sdl.KeyCode.right) || sym == int(sdl.KeyCode.d) {
						prev_y := mutable_app.game.player_y
						if mutable_app.game.move_dir(.right) {
							if mutable_app.game.player_y < prev_y {
								mutable_app.sound_mgr.play_climb()
							} else {
								mutable_app.sound_mgr.play_step()
							}
							if mutable_app.game.state == .level_complete || mutable_app.game.state == .game_won {
								mutable_app.sound_mgr.play_win()
							}
						}
					} else if sym == int(sdl.KeyCode.space) || sym == int(sdl.KeyCode.up) || sym == int(sdl.KeyCode.w) || sym == int(sdl.KeyCode.down) || sym == int(sdl.KeyCode.s) {
						if mutable_app.game.state == .level_complete {
							mutable_app.game.next_level()
							mutable_app.sound_mgr.play_step()
						} else if mutable_app.game.state == .game_won {
							mutable_app.game.load_level(0)
							mutable_app.sound_mgr.play_restart()
						} else {
							was_carrying := mutable_app.game.carrying_block
							if mutable_app.game.pickup_or_drop() {
								if was_carrying {
									mutable_app.sound_mgr.play_drop()
								} else {
									mutable_app.sound_mgr.play_pickup()
								}
							}
						}
					} else if sym == int(sdl.KeyCode.return) {
						if mutable_app.game.state == .level_complete {
							mutable_app.game.next_level()
							mutable_app.sound_mgr.play_step()
						}
					}
				}
				else {}
			}
		}

		sdl.set_render_draw_color(mutable_app.renderer, 0, 0, 0, 255)
		sdl.render_clear(mutable_app.renderer)
		draw_blockdude_game(mutable_app.renderer, &mutable_app.game)
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
