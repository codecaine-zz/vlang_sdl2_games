module main

import math
import os
import sdl

struct App {
mut:
	window      &sdl.Window         = unsafe { nil }
	renderer    &sdl.Renderer       = unsafe { nil }
	game        Game
	sound_mgr   SoundManager
	tex_mgr     PacmanTextureManager
	btn_reset   Button
	btn_sound   Button
	btn_pause   Button
	mouse_x     int
	mouse_y     int
	siren_timer f64
}

fn new_app() App {
	mut app := App{
		game:      new_game()
		sound_mgr: new_sound_manager()
		tex_mgr:   new_pacman_texture_manager()
		btn_reset: Button{
			x:            735
			y:            160
			w:            200
			h:            44
			text:         'RESET [R]'
			bg_color:     Color{
				r: 35
				g: 45
				b: 70
			}
			hover_color:  Color{
				r: 55
				g: 70
				b: 105
			}
			text_color:   Color{
				r: 255
				g: 255
				b: 255
			}
			border_color: Color{
				r: 85
				g: 105
				b: 150
			}
		}
		btn_sound: Button{
			x:            735
			y:            225
			w:            200
			h:            44
			text:         'SOUND: ON [S]'
			bg_color:     Color{
				r: 35
				g: 45
				b: 70
			}
			hover_color:  Color{
				r: 55
				g: 70
				b: 105
			}
			text_color:   Color{
				r: 255
				g: 255
				b: 255
			}
			border_color: Color{
				r: 85
				g: 105
				b: 150
			}
		}
		btn_pause: Button{
			x:            735
			y:            290
			w:            200
			h:            44
			text:         'PAUSE [P]'
			bg_color:     Color{
				r: 35
				g: 45
				b: 70
			}
			hover_color:  Color{
				r: 55
				g: 70
				b: 105
			}
			text_color:   Color{
				r: 255
				g: 255
				b: 255
			}
			border_color: Color{
				r: 85
				g: 105
				b: 150
			}
		}
	}
	return app
}

fn (mut app App) init_sdl() bool {
	if sdl.init(sdl.init_video | sdl.init_audio) < 0 {
		eprintln('Failed to init SDL')
		return false
	}

	app.window = sdl.create_window(c'Pac-Man Arcade - V & SDL2', sdl.windowpos_centered,
		sdl.windowpos_centered, win_w, win_h, u32(sdl.WindowFlags.shown) | u32(sdl.WindowFlags.fullscreen_desktop) | u32(sdl.WindowFlags.resizable))
	if app.window == unsafe { nil } {
		eprintln('Failed to create window')
		return false
	}

	app.renderer = sdl.create_renderer(app.window, -1, u32(sdl.RendererFlags.accelerated) | u32(sdl.RendererFlags.presentvsync))
	if app.renderer == unsafe { nil } {
		eprintln('Failed to create renderer')
		return false
	}

	sdl.render_set_logical_size(app.renderer, win_w, win_h)
	app.tex_mgr.init(app.renderer)

	return true
}

fn (mut app App) run() {
	mut last_ticks := sdl.get_ticks()
	mut should_close := false
	app.sound_mgr.play_intro_sound()

	for !should_close {
		current_ticks := sdl.get_ticks()
		dt := f64(current_ticks - last_ticks) / 1000.0
		last_ticks = current_ticks

		mut ev := sdl.Event{}
		for 0 < sdl.poll_event(&ev) {
			match ev.@type {
				.quit {
					should_close = true
				}
				.mousemotion {
					app.mouse_x = ev.motion.x
					app.mouse_y = ev.motion.y
				}
				.mousebuttondown {
					mx := ev.button.x
					my := ev.button.y

					if app.btn_reset.contains(mx, my) {
						app.game.init_level()
						app.game.score = 0
						app.game.lives = 3
						app.sound_mgr.play_intro_sound()
					} else if app.btn_sound.contains(mx, my) {
						is_on := app.sound_mgr.toggle_sound()
						app.btn_sound.text = if is_on {
							'SOUND: ON [S]'
						} else {
							'SOUND: OFF [S]'
						}
					} else if app.btn_pause.contains(mx, my) {
						if app.game.status == .playing {
							app.game.status = .paused
						} else if app.game.status == .paused {
							app.game.status = .playing
						}
					}
				}
				.keydown {
					sym := ev.key.keysym.sym
					if sym == int(sdl.KeyCode.f11) {
						toggle_fullscreen(app.window)
					} else if sym == int(sdl.KeyCode.up) || sym == int(sdl.KeyCode.w) {
						app.game.pacman.next_dir = .up
					} else if sym == int(sdl.KeyCode.down) || sym == int(sdl.KeyCode.s) {
						app.game.pacman.next_dir = .down
					} else if sym == int(sdl.KeyCode.left) || sym == int(sdl.KeyCode.a) {
						app.game.pacman.next_dir = .left
					} else if sym == int(sdl.KeyCode.right) || sym == int(sdl.KeyCode.d) {
						app.game.pacman.next_dir = .right
					} else if sym == int(sdl.KeyCode.r) {
						app.game.init_level()
						app.game.score = 0
						app.game.lives = 3
					} else if sym == int(sdl.KeyCode.p) {
						if app.game.status == .playing {
							app.game.status = .paused
						} else if app.game.status == .paused {
							app.game.status = .playing
						}
					} else if sym == int(sdl.KeyCode.s) || sym == int(sdl.KeyCode.o) {
						is_on := app.sound_mgr.toggle_sound()
						app.btn_sound.text = if is_on {
							'SOUND: ON [S]'
						} else {
							'SOUND: OFF [S]'
						}
					} else if sym == int(sdl.KeyCode.escape) {
						should_close = true
					}
				}
				else {}
			}
		}

		// Update game logic
		game_ev := app.game.update(dt)
		if game_ev.ate_dot || (game_ev.is_moving && math.fmod(app.game.global_timer, 0.2) < dt) {
			app.sound_mgr.play_waka_sound()
		}
		if game_ev.ate_power {
			app.sound_mgr.play_power_pellet_sound()
		}
		if game_ev.ate_fruit {
			app.sound_mgr.play_eat_fruit_sound()
		}
		if game_ev.ate_ghost {
			app.sound_mgr.play_eat_ghost_sound()
		}
		if game_ev.pac_died {
			app.sound_mgr.play_death_sound()
		}
		if game_ev.level_win {
			app.sound_mgr.play_extra_life_sound()
		}

		app.sound_mgr.update_mixer(app.game.status == .playing)

		draw_game(app.renderer, app.game, app.mouse_x, app.mouse_y, app.btn_reset, app.btn_sound,
			app.btn_pause, app.tex_mgr.sprite_texture)
		prod_fx_render(app.renderer)
		sdl.render_present(app.renderer)

		sdl.delay(16) // ~60 FPS
	}
}

fn (mut app App) cleanup() {
	app.sound_mgr.cleanup()
	if app.renderer != unsafe { nil } {
		sdl.destroy_renderer(app.renderer)
	}
	if app.window != unsafe { nil } {
		sdl.destroy_window(app.window)
	}
	sdl.quit()
}

fn main() {
	if os.args.contains('--snapshot') || os.args.contains('--snap') || os.getenv('SNAPSHOT') == '1' {
		sdl.init(sdl.init_video)
		surface := sdl.create_rgb_surface(0, win_w, win_h, 32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000)
		s_renderer := sdl.create_software_renderer(surface)
		mut app := new_app()
		app.renderer = s_renderer
		app.tex_mgr.init(s_renderer)
		app.game.score = 3680
		app.game.frightened_timer = 4.5
		draw_game(app.renderer, app.game, app.mouse_x, app.mouse_y, app.btn_reset, app.btn_sound,
			app.btn_pause, app.tex_mgr.sprite_texture)
		sdl.save_bmp(surface, 'screenshots/pacman.bmp'.str)
		sdl.destroy_renderer(s_renderer)
		sdl.free_surface(surface)
		sdl.quit()
		return
	}

	mut app := new_app()
	if !app.init_sdl() {
		return
	}
	defer {
		app.cleanup()
	}
	app.run()
}

fn toggle_fullscreen(window &sdl.Window) {
	flags := sdl.get_window_flags(window)
	if (flags & u32(sdl.WindowFlags.fullscreen_desktop)) != 0 || (flags & u32(sdl.WindowFlags.fullscreen)) != 0 {
		sdl.set_window_fullscreen(window, 0)
	} else {
		sdl.set_window_fullscreen(window, u32(sdl.WindowFlags.fullscreen_desktop))
	}
}
