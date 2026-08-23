module main

import math
import os
import sdl

struct App {
mut:
	window           &sdl.Window   = unsafe { nil }
	renderer         &sdl.Renderer = unsafe { nil }
	game             NuclearThroneGame
	sound_mgr        SoundManager
	tex_mgr          NuclearThroneTextureManager
	mouse_x          int
	mouse_y          int
	key_w            bool
	key_a            bool
	key_s            bool
	key_d            bool
	key_shoot        bool
	key_ability      bool
	key_swap         bool
	paused           bool
	btn_restart      Button
	btn_sound        Button
}

fn new_app() App {
	mut app := App{
		game:      new_nuclear_throne_game()
		sound_mgr: new_sound_manager()
		tex_mgr:   new_nuclear_throne_texture_manager()
		btn_restart: Button{
			x:            30
			y:            540
			w:            140
			h:            40
			text:         'RESTART [R]'
			bg_color:     Color{r: 35, g: 25, b: 25}
			hover_color:  Color{r: 75, g: 45, b: 45}
			text_color:   Color{r: 255, g: 255, b: 255}
			border_color: Color{r: 160, g: 80, b: 80}
		}
		btn_sound:   Button{
			x:            180
			y:            540
			w:            150
			h:            40
			text:         'SOUND: ON [O]'
			bg_color:     Color{r: 35, g: 25, b: 25}
			hover_color:  Color{r: 75, g: 45, b: 45}
			text_color:   Color{r: 255, g: 255, b: 255}
			border_color: Color{r: 160, g: 80, b: 80}
		}
	}
	return app
}

fn (mut b Button) render(renderer &sdl.Renderer, mx int, my int) {
	is_hover := b.contains(mx, my)
	bg := if is_hover { b.hover_color } else { b.bg_color }
	
	// Drop shadow
	shadow := sdl.Rect{x: b.x + 2, y: b.y + 2, w: b.w, h: b.h}
	sdl.set_render_draw_color(renderer, 0, 0, 0, 140)
	sdl.render_fill_rect(renderer, &shadow)

	// Button base
	sdl.set_render_draw_color(renderer, bg.r, bg.g, bg.b, bg.a)
	rect := sdl.Rect{x: b.x, y: b.y, w: b.w, h: b.h}
	sdl.render_fill_rect(renderer, &rect)

	// Border
	sdl.set_render_draw_color(renderer, b.border_color.r, b.border_color.g, b.border_color.b, 255)
	sdl.render_draw_rect(renderer, &rect)

	draw_text_centered(renderer, b.x + b.w / 2, b.y + (b.h - 16) / 2, b.text, 1, b.text_color)
}

fn main() {
	// Snapshot capture support for automated testing and gallery previews
	if os.args.contains('--snapshot') || os.args.contains('--snap') {
		sdl.init(sdl.init_video)
		surface := sdl.create_rgb_surface(0, 800, 600, 32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000)
		if !isnil(surface) {
			s_renderer := sdl.create_software_renderer(surface)
			if !isnil(s_renderer) {
				mut app := new_app()
				app.renderer = s_renderer
				app.game.score = 8450
				app.game.player.kills = 34
				app.game.player.rads = 20
				app.game.player.level = 2
				app.game.player.weapon = .laser_rifle
				app.game.player.ammo = 160
				app.game.player.hp = 6
				app.game.player.max_hp = 8
				app.game.fire_player_weapon()

				render_nuclear_throne_game(app.renderer, &app.game, app.tex_mgr.sprite_texture)

				os.mkdir_all('screenshots') or {}
				sdl.save_bmp(surface, 'screenshots/nuclearthrone.bmp'.str)
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

	window := sdl.create_window(
		'Nuclear Throne - Wasteland Twin-Stick Shooter'.str,
		sdl.windowpos_centered,
		sdl.windowpos_centered,
		800,
		600,
		u32(sdl.WindowFlags.shown)
	)
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
	app.tex_mgr.init(renderer)

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
					} else if app.game.mutation_screen {
						if my >= 190 && my <= 440 {
							idx := (my - 190) / 55
							app.game.select_mutation(idx)
						}
					} else {
						if ev.button.button == u8(sdl.button_left) {
							app.key_shoot = true
						} else if ev.button.button == u8(sdl.button_right) {
							app.key_ability = true
						}
					}
				}
				.mousebuttonup {
					if ev.button.button == u8(sdl.button_left) {
						app.key_shoot = false
					} else if ev.button.button == u8(sdl.button_right) {
						app.key_ability = false
					}
				}
				.keydown {
					sym := ev.key.keysym.sym
					if sym == int(sdl.KeyCode.w) || sym == int(sdl.KeyCode.up) {
						app.key_w = true
					} else if sym == int(sdl.KeyCode.a) || sym == int(sdl.KeyCode.left) {
						app.key_a = true
					} else if sym == int(sdl.KeyCode.s) || sym == int(sdl.KeyCode.down) {
						app.key_s = true
					} else if sym == int(sdl.KeyCode.d) || sym == int(sdl.KeyCode.right) {
						app.key_d = true
					} else if sym == int(sdl.KeyCode.e) || sym == int(sdl.KeyCode.f) || sym == int(sdl.KeyCode.q) {
						app.key_swap = true
					} else if sym == int(sdl.KeyCode.space) || sym == int(sdl.KeyCode.lshift) {
						app.key_ability = true
					} else if sym == int(sdl.KeyCode.r) {
						app.game.start_new_game()
					} else if sym == int(sdl.KeyCode.o) {
						muted := !app.sound_mgr.toggle_sound()
						app.btn_sound.text = if muted { 'SOUND: OFF [O]' } else { 'SOUND: ON [O]' }
					} else if sym >= int(sdl.KeyCode._1) && sym <= int(sdl.KeyCode._5) {
						if app.game.mutation_screen {
							app.game.select_mutation(sym - int(sdl.KeyCode._1))
						}
					} else if sym == int(sdl.KeyCode.escape) {
						quit = true
					}
				}
				.keyup {
					sym := ev.key.keysym.sym
					if sym == int(sdl.KeyCode.w) || sym == int(sdl.KeyCode.up) {
						app.key_w = false
					} else if sym == int(sdl.KeyCode.a) || sym == int(sdl.KeyCode.left) {
						app.key_a = false
					} else if sym == int(sdl.KeyCode.s) || sym == int(sdl.KeyCode.down) {
						app.key_s = false
					} else if sym == int(sdl.KeyCode.d) || sym == int(sdl.KeyCode.right) {
						app.key_d = false
					} else if sym == int(sdl.KeyCode.space) || sym == int(sdl.KeyCode.lshift) {
						app.key_ability = false
					}
				}
				else {}
			}
		}

		if !app.paused {
			// Calculate Movement Vectors
			mut move_x := 0.0
			mut move_y := 0.0
			if app.key_a { move_x -= 1.0 }
			if app.key_d { move_x += 1.0 }
			if app.key_w { move_y -= 1.0 }
			if app.key_s { move_y += 1.0 }

			// Normalize movement vector if diagonal
			if move_x != 0 && move_y != 0 {
				move_x *= 0.7071
				move_y *= 0.7071
			}

			// Calculate Aim Angle relative to player on screen
			player_screen_x := app.game.player.x - app.game.camera_x
			player_screen_y := app.game.player.y - app.game.camera_y
			aim_angle := math.atan2(f64(app.mouse_y) - player_screen_y, f64(app.mouse_x) - player_screen_x)

			app.game.update(math.min(dt, 0.05), move_x, move_y, aim_angle, app.key_shoot, app.key_ability, app.key_swap)
			app.key_swap = false
		}

		app.sound_mgr.update_bgm(!app.paused && !app.game.game_over)

		if app.game.last_sound_event != '' {
			app.sound_mgr.play_sound(app.game.last_sound_event)
			app.game.last_sound_event = ''
		}

		render_nuclear_throne_game(app.renderer, &app.game, app.tex_mgr.sprite_texture)

		// UI Buttons
		app.btn_restart.render(app.renderer, app.mouse_x, app.mouse_y)
		app.btn_sound.render(app.renderer, app.mouse_x, app.mouse_y)

		prod_fx_render(app.renderer)
		sdl.render_present(app.renderer)
		sdl.delay(16)
	}
}
