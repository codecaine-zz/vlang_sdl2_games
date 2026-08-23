module main

import os
import sdl

struct App {
mut:
	window      &sdl.Window   = unsafe { nil }
	renderer    &sdl.Renderer = unsafe { nil }
	game        MathMunchersGame
	sound_mgr   SoundManager
	mouse_x     int
	mouse_y     int
	btn_restart Button
	btn_sound   Button
	btn_pause   Button
	btn_menu    Button
}

fn new_app() App {
	mut app := App{
		game:        new_mathmunchers_game()
		sound_mgr:   new_sound_manager()
		btn_restart: Button{
			x:            30
			y:            550
			w:            130
			h:            38
			text:         'RESTART [R]'
			bg_color:     Color{r: 25, g: 35, b: 55}
			hover_color:  Color{r: 45, g: 65, b: 105}
			text_color:   Color{r: 255, g: 255, b: 255}
			border_color: Color{r: 80, g: 110, b: 170}
		}
		btn_sound:   Button{
			x:            170
			y:            550
			w:            140
			h:            38
			text:         'SOUND: ON [O]'
			bg_color:     Color{r: 25, g: 35, b: 55}
			hover_color:  Color{r: 45, g: 65, b: 105}
			text_color:   Color{r: 255, g: 255, b: 255}
			border_color: Color{r: 80, g: 110, b: 170}
		}
		btn_pause:   Button{
			x:            320
			y:            550
			w:            120
			h:            38
			text:         'PAUSE [P]'
			bg_color:     Color{r: 25, g: 35, b: 55}
			hover_color:  Color{r: 45, g: 65, b: 105}
			text_color:   Color{r: 255, g: 255, b: 255}
			border_color: Color{r: 80, g: 110, b: 170}
		}
		btn_menu:    Button{
			x:            450
			y:            550
			w:            150
			h:            38
			text:         'MAIN MENU [M]'
			bg_color:     Color{r: 25, g: 35, b: 55}
			hover_color:  Color{r: 45, g: 65, b: 105}
			text_color:   Color{r: 255, g: 255, b: 255}
			border_color: Color{r: 80, g: 110, b: 170}
		}
	}
	return app
}

fn (mut b Button) render(renderer &sdl.Renderer, mx int, my int) {
	is_hover := b.contains(mx, my)
	bg := if is_hover { b.hover_color } else { b.bg_color }

	shadow := sdl.Rect{
		x: b.x + 2
		y: b.y + 2
		w: b.w
		h: b.h
	}
	sdl.set_render_draw_color(renderer, 0, 0, 0, 140)
	sdl.render_fill_rect(renderer, &shadow)

	sdl.set_render_draw_color(renderer, bg.r, bg.g, bg.b, bg.a)
	rect := sdl.Rect{
		x: b.x
		y: b.y
		w: b.w
		h: b.h
	}
	sdl.render_fill_rect(renderer, &rect)

	sdl.set_render_draw_color(renderer, b.border_color.r, b.border_color.g, b.border_color.b, 255)
	sdl.render_draw_rect(renderer, &rect)

	draw_text_centered(renderer, b.x + b.w / 2, b.y + (b.h - 14) / 2, b.text, 1, b.text_color)
}

fn main() {
	if os.args.contains('--snapshot') || os.args.contains('--snap') {
		sdl.init(sdl.init_video)
		surface := sdl.create_rgb_surface(0, 800, 600, 32, 0x00FF0000, 0x0000FF00, 0x000000FF,
			0xFF000000)
		if !isnil(surface) {
			s_renderer := sdl.create_software_renderer(surface)
			if !isnil(s_renderer) {
				mut app := new_app()
				app.renderer = s_renderer
				app.game.state = .playing
				app.game.score = 2400
				app.game.high_score = 5600
				app.game.level = 2
				app.game.player.lives = 3
				app.game.player.combo = 3

				app.game.troggles << Troggle{
					grid_x: 1
					grid_y: 1
					real_x: 1.0
					real_y: 1.0
					kind:   .reggie
					active: true
				}
				app.game.troggles << Troggle{
					grid_x: 4
					grid_y: 2
					real_x: 4.0
					real_y: 2.0
					kind:   .smartie
					active: true
				}
				app.game.troggles << Troggle{
					grid_x: 2
					grid_y: 4
					real_x: 2.0
					real_y: 4.0
					kind:   .glutton
					active: true
				}
				app.game.troggles << Troggle{
					grid_x: 5
					grid_y: 0
					real_x: 5.0
					real_y: 0.0
					kind:   .helper
					active: true
				}

				render_mathmunchers_game(app.renderer, &app.game)
				prod_fx_render(app.renderer)

				os.mkdir_all('screenshots') or {}
				sdl.save_bmp(surface, 'screenshots/mathmunchers.bmp'.str)
				sdl.destroy_renderer(s_renderer)
			}
			sdl.free_surface(surface)
		}
		sdl.quit()
		return
	}

	if sdl.init(sdl.init_video | sdl.init_audio) < 0 {
		eprintln('Failed to init SDL: ${sdl.get_error()}')
		return
	}
	defer {
		sdl.quit()
	}

	window := sdl.create_window('Math Munchers - Retro Educational Arcade'.str, sdl.windowpos_centered,
		sdl.windowpos_centered, 800, 600, u32(sdl.WindowFlags.shown))
	if unsafe { window == nil } {
		eprintln('Failed to create window: ${sdl.get_error()}')
		return
	}
	defer {
		sdl.destroy_window(window)
	}

	renderer := sdl.create_renderer(window, -1, u32(sdl.RendererFlags.accelerated) | u32(sdl.RendererFlags.presentvsync))
	if unsafe { renderer == nil } {
		eprintln('Failed to create renderer: ${sdl.get_error()}')
		return
	}
	defer {
		sdl.destroy_renderer(renderer)
	}

	mut app := new_app()
	app.window = window
	app.renderer = renderer

	mut last_ticks := sdl.get_ticks()
	mut quit := false

	for !quit {
		current_ticks := sdl.get_ticks()
		dt := f64(current_ticks - last_ticks) / 1000.0
		last_ticks = current_ticks

		mut ev := sdl.Event{}
		for 0 < sdl.poll_event(&ev) {
			match ev.@type {
				.quit {
					quit = true
				}
				.mousemotion {
					app.mouse_x = ev.motion.x
					app.mouse_y = ev.motion.y
				}
				.mousebuttondown {
					mx := ev.button.x
					my := ev.button.y
					if app.btn_restart.contains(mx, my) {
						app.game.start_new_game()
					} else if app.btn_sound.contains(mx, my) {
						muted := !app.sound_mgr.toggle_sound()
						app.btn_sound.text = if muted { 'SOUND: OFF [O]' } else { 'SOUND: ON [O]' }
					} else if app.btn_pause.contains(mx, my) {
						if app.game.state == .playing {
							app.game.state = .paused
						} else if app.game.state == .paused {
							app.game.state = .playing
						}
					} else if app.btn_menu.contains(mx, my) {
						app.game.state = .start_menu
					} else if my >= 75 && my <= 110 && mx >= 135 && mx <= 250 {
						// Click on HUD MODE badge to toggle difficulty
						app.game.cycle_difficulty()
						app.sound_mgr.play_sound('move')
					} else if app.game.state == .start_menu {
						if my >= 200 && my <= 240 {
							if mx >= 120 && mx <= 280 {
								app.game.set_difficulty(.easy)
								app.game.start_new_game()
							} else if mx >= 320 && mx <= 480 {
								app.game.set_difficulty(.medium)
								app.game.start_new_game()
							} else if mx >= 520 && mx <= 680 {
								app.game.set_difficulty(.hard)
								app.game.start_new_game()
							}
						} else {
							app.game.start_new_game()
						}
					} else if app.game.state == .level_clear {
						app.game.next_level()
					} else if app.game.state == .game_over {
						app.game.start_new_game()
					}
				}
				.keydown {
					sym := ev.key.keysym.sym
					if sym == int(sdl.KeyCode.escape) || sym == int(sdl.KeyCode.m) {
						app.game.state = .start_menu
						app.sound_mgr.play_sound('move')
					} else if sym == int(sdl.KeyCode.d) {
						app.game.cycle_difficulty()
						app.sound_mgr.play_sound('move')
					} else if sym == int(sdl.KeyCode._1) || sym == int(sdl.KeyCode.kp_1) {
						if app.game.state == .start_menu {
							app.game.set_difficulty(.easy)
							app.sound_mgr.play_sound('move')
						}
					} else if sym == int(sdl.KeyCode._2) || sym == int(sdl.KeyCode.kp_2) {
						if app.game.state == .start_menu {
							app.game.set_difficulty(.medium)
							app.sound_mgr.play_sound('move')
						}
					} else if sym == int(sdl.KeyCode._3) || sym == int(sdl.KeyCode.kp_3) {
						if app.game.state == .start_menu {
							app.game.set_difficulty(.hard)
							app.sound_mgr.play_sound('move')
						}
					} else if sym == int(sdl.KeyCode.a) || sym == int(sdl.KeyCode.left) {
						if app.game.state == .playing && app.game.player.grid_x > 0 {
							app.game.player.grid_x--
							app.game.player.facing_right = false
							app.sound_mgr.play_sound('move')
						}
					} else if sym == int(sdl.KeyCode.d) || sym == int(sdl.KeyCode.right) {
						if app.game.state == .playing && app.game.player.grid_x < grid_cols - 1 {
							app.game.player.grid_x++
							app.game.player.facing_right = true
							app.sound_mgr.play_sound('move')
						}
					} else if sym == int(sdl.KeyCode.w) || sym == int(sdl.KeyCode.up) {
						if app.game.state == .playing && app.game.player.grid_y > 0 {
							app.game.player.grid_y--
							app.sound_mgr.play_sound('move')
						}
					} else if sym == int(sdl.KeyCode.s) || sym == int(sdl.KeyCode.down) {
						if app.game.state == .playing && app.game.player.grid_y < grid_rows - 1 {
							app.game.player.grid_y++
							app.sound_mgr.play_sound('move')
						}
					} else if sym == int(sdl.KeyCode.space) || sym == int(sdl.KeyCode.@return) || sym == int(sdl.KeyCode.z) {
						if app.game.state == .start_menu {
							app.game.start_new_game()
						} else if app.game.state == .playing {
							app.game.munch_cell(mut app.sound_mgr)
						} else if app.game.state == .level_clear {
							app.game.next_level()
						} else if app.game.state == .game_over {
							app.game.start_new_game()
						} else if app.game.state == .paused {
							app.game.state = .playing
						}
					} else if sym == int(sdl.KeyCode.r) {
						app.game.start_new_game()
					} else if sym == int(sdl.KeyCode.p) {
						if app.game.state == .playing {
							app.game.state = .paused
						} else if app.game.state == .paused {
							app.game.state = .playing
						}
					} else if sym == int(sdl.KeyCode.o) {
						muted := !app.sound_mgr.toggle_sound()
						app.btn_sound.text = if muted { 'SOUND: OFF [O]' } else { 'SOUND: ON [O]' }
					}
				}
				else {}
			}
		}

		app.game.update(dt, mut app.sound_mgr)

		render_mathmunchers_game(app.renderer, &app.game)

		app.btn_restart.render(app.renderer, app.mouse_x, app.mouse_y)
		app.btn_sound.render(app.renderer, app.mouse_x, app.mouse_y)
		app.btn_pause.render(app.renderer, app.mouse_x, app.mouse_y)
		app.btn_menu.render(app.renderer, app.mouse_x, app.mouse_y)

		prod_fx_render(app.renderer)

		sdl.render_present(app.renderer)
		sdl.delay(16)
	}
}
