module main

import math
import sdl

struct App {
mut:
	window      &sdl.Window   = unsafe { nil }
	renderer    &sdl.Renderer = unsafe { nil }
	game        DownwellGame
	sound_mgr   SoundManager
	tex_mgr     DownwellTextureManager
	mouse_x     int
	mouse_y     int
	key_left    bool
	key_right   bool
	key_jump    bool
	key_shoot   bool
	paused      bool
	btn_restart Button
	btn_sound   Button
}

fn new_app() App {
	mut app := App{
		game:      new_downwell_game()
		sound_mgr: new_sound_manager()
		tex_mgr:   new_downwell_texture_manager()
		btn_restart: Button{
			x:            30
			y:            540
			w:            140
			h:            40
			text:         'RESTART [R]'
			bg_color:     Color{r: 25, g: 35, b: 55}
			hover_color:  Color{r: 45, g: 60, b: 90}
			text_color:   Color{r: 255, g: 255, b: 255}
			border_color: Color{r: 70, g: 90, b: 140}
		}
		btn_sound:   Button{
			x:            180
			y:            540
			w:            150
			h:            40
			text:         'SOUND: ON [O]'
			bg_color:     Color{r: 25, g: 35, b: 55}
			hover_color:  Color{r: 45, g: 60, b: 90}
			text_color:   Color{r: 255, g: 255, b: 255}
			border_color: Color{r: 70, g: 90, b: 140}
		}
	}
	return app
}

fn (mut b Button) render(renderer &sdl.Renderer, mx int, my int) {
	is_hover := b.contains(mx, my)
	bg := if is_hover { b.hover_color } else { b.bg_color }
	sdl.set_render_draw_color(renderer, bg.r, bg.g, bg.b, bg.a)
	rect := sdl.Rect{x: b.x, y: b.y, w: b.w, h: b.h}
	sdl.render_fill_rect(renderer, &rect)
	sdl.set_render_draw_color(renderer, b.border_color.r, b.border_color.g, b.border_color.b, 255)
	sdl.render_draw_rect(renderer, &rect)
	draw_text_centered(renderer, b.x + b.w / 2, b.y + (b.h - 16) / 2, b.text, 1, b.text_color)
}

fn main() {
	if sdl.init(sdl.init_video | sdl.init_audio) < 0 {
		eprintln('Failed to init SDL: ${sdl.get_error()}')
		return
	}
	defer {
		sdl.quit()
	}

	window := sdl.create_window(
		'Downwell - Gunboots Vertical Descent'.str,
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
					} else if app.game.shop_active {
						// Shop click buy
						if my >= 200 && my <= 400 {
							idx := (my - 200) / 55
							app.game.buy_shop_item(idx)
						}
					} else {
						app.key_shoot = true
					}
				}
				.mousebuttonup {
					app.key_shoot = false
				}
				.keydown {
					sym := ev.key.keysym.sym
					if sym == int(sdl.KeyCode.a) || sym == int(sdl.KeyCode.left) {
						app.key_left = true
					} else if sym == int(sdl.KeyCode.d) || sym == int(sdl.KeyCode.right) {
						app.key_right = true
					} else if sym == int(sdl.KeyCode.space) || sym == int(sdl.KeyCode.up) || sym == int(sdl.KeyCode.z) {
						app.key_jump = true
					} else if sym == int(sdl.KeyCode.down) || sym == int(sdl.KeyCode.x) {
						app.key_shoot = true
					} else if sym == int(sdl.KeyCode.r) {
						app.game.start_new_game()
					} else if sym == int(sdl.KeyCode.o) {
						muted := !app.sound_mgr.toggle_sound()
						app.btn_sound.text = if muted { 'SOUND: OFF [O]' } else { 'SOUND: ON [O]' }
					} else if sym == int(sdl.KeyCode.c) {
						app.game.close_shop()
					} else if sym >= int(sdl.KeyCode._1) && sym <= int(sdl.KeyCode._4) {
						if app.game.shop_active {
							app.game.buy_shop_item(sym - int(sdl.KeyCode._1))
						}
					} else if sym == int(sdl.KeyCode.escape) {
						quit = true
					}
				}
				.keyup {
					sym := ev.key.keysym.sym
					if sym == int(sdl.KeyCode.a) || sym == int(sdl.KeyCode.left) {
						app.key_left = false
					} else if sym == int(sdl.KeyCode.d) || sym == int(sdl.KeyCode.right) {
						app.key_right = false
					} else if sym == int(sdl.KeyCode.space) || sym == int(sdl.KeyCode.up) || sym == int(sdl.KeyCode.z) {
						app.key_jump = false
					} else if sym == int(sdl.KeyCode.down) || sym == int(sdl.KeyCode.x) {
						app.key_shoot = false
					}
				}
				else {}
			}
		}

		if !app.paused {
			app.game.update(math.min(dt, 0.05), app.key_left, app.key_right, app.key_jump, app.key_shoot)
		}

		if app.game.last_sound_event != '' {
			app.sound_mgr.play_sound(app.game.last_sound_event)
			app.game.last_sound_event = ''
		}

		render_downwell_game(app.renderer, &app.game, app.tex_mgr.sprite_texture)

		// UI Buttons
		app.btn_restart.render(app.renderer, app.mouse_x, app.mouse_y)
		app.btn_sound.render(app.renderer, app.mouse_x, app.mouse_y)

		prod_fx_render(app.renderer)
		sdl.render_present(app.renderer)
		sdl.delay(16)
	}
}
