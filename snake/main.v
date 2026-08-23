module main

import math
import os
import rand
import sdl

const win_width = 880
const win_height = 740

const cell_px = 32
const grid_start_x = (win_width - (grid_cols * cell_px)) / 2
const grid_start_y = 110

struct Particle {
mut:
	x     f64
	y     f64
	vx    f64
	vy    f64
	life  f64
	color Color
	size  int
}

struct App {
mut:
	window        &sdl.Window   = unsafe { nil }
	renderer      &sdl.Renderer = unsafe { nil }
	game          SnakeGame
	sound_mgr     SoundManager
	tex_mgr       SnakeTextureManager
	particles     []Particle
	shake_timer   f64
	last_step_t   u32
	step_interval u32 = 110 // milliseconds per snake step
	mouse_x       int
	mouse_y       int
	btn_restart   Button
	btn_pause     Button
	btn_sound     Button
}

fn new_app() App {
	mut app := App{
		game:        new_snake_game()
		sound_mgr:   new_sound_manager()
		tex_mgr:     new_snake_texture_manager()
		btn_restart: Button{
			x:            100
			y:            680
			w:            200
			h:            44
			text:         'RESTART [R]'
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
		btn_pause:   Button{
			x:            340
			y:            680
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
		btn_sound:   Button{
			x:            580
			y:            680
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
				r: 80
				g: 240
				b: 140
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
		eprintln('Failed to initialize SDL')
		return false
	}

	app.window = sdl.create_window(c'Cyberpunk Snake - V & SDL2', sdl.windowpos_centered,
		sdl.windowpos_centered, win_width, win_height, u32(sdl.WindowFlags.shown) | u32(sdl.WindowFlags.fullscreen_desktop) | u32(sdl.WindowFlags.resizable) | u32(sdl.WindowFlags.fullscreen_desktop) | u32(sdl.WindowFlags.resizable))

	if app.window == unsafe { nil } {
		eprintln('Failed to create SDL Window')
		return false
	}

	app.renderer = sdl.create_renderer(app.window, -1, u32(sdl.RendererFlags.accelerated) | u32(sdl.RendererFlags.presentvsync))
	if app.renderer == unsafe { nil } {
		eprintln('Failed to create SDL Renderer')
		return false
	}

	sdl.render_set_logical_size(app.renderer, win_width, win_height)
	app.tex_mgr.init(app.renderer)

	return true
}

fn (mut app App) spawn_eat_particles(pt Point, is_gold bool) {
	cx := f64(grid_start_x + pt.x * cell_px + cell_px / 2)
	cy := f64(grid_start_y + pt.y * cell_px + cell_px / 2)
	p_color := if is_gold {
		Color{
			r: 255
			g: 220
			b: 40
		}
	} else {
		Color{
			r: 255
			g: 60
			b: 80
		}
	}

	count := if is_gold { 25 } else { 12 }
	for _ in 0 .. count {
		angle := rand.f64() * math.pi * 2.0
		speed := 1.5 + rand.f64() * 5.0
		app.particles << Particle{
			x:     cx
			y:     cy
			vx:    math.cos(angle) * speed
			vy:    math.sin(angle) * speed
			life:  1.0
			color: p_color
			size:  3 + rand.intn(3) or { 3 }
		}
	}
}

fn (mut app App) update_particles() {
	if app.shake_timer > 0 {
		app.shake_timer -= 0.016
		if app.shake_timer < 0 {
			app.shake_timer = 0
		}
	}

	for i := app.particles.len - 1; i >= 0; i-- {
		app.particles[i].x += app.particles[i].vx
		app.particles[i].y += app.particles[i].vy
		app.particles[i].life -= 0.03
		if app.particles[i].life <= 0 {
			app.particles.delete(i)
		}
	}
}

fn (mut app App) update_game_step() {
	now := sdl.get_ticks()
	if now - app.last_step_t >= app.step_interval {
		app.last_step_t = now

		ate_reg, ate_gold := app.game.step()
		if ate_reg {
			app.sound_mgr.play_eat_sound(app.game.body.len)
			app.spawn_eat_particles(app.game.body[0], false)
			app.shake_timer = 0.08
		} else if ate_gold {
			app.sound_mgr.play_gold_sound()
			app.spawn_eat_particles(app.game.body[0], true)
			app.shake_timer = 0.16
		} else if app.game.game_over {
			app.sound_mgr.play_die_sound()
			app.shake_timer = 0.35
			if app.game.body.len > 0 {
				app.spawn_eat_particles(app.game.body[0], false)
			}
		}
	}
}

fn (mut app App) toggle_sound() {
	is_on := app.sound_mgr.toggle_sound()
	app.btn_sound.text = if is_on { 'SOUND: ON [S]' } else { 'SOUND: OFF [S]' }
	app.btn_sound.text_color = if is_on {
		Color{
			r: 80
			g: 240
			b: 140
		}
	} else {
		Color{
			r: 240
			g: 90
			b: 90
		}
	}
	if is_on {
		app.sound_mgr.play_click_sound()
	}
}

fn (mut app App) toggle_pause() {
	app.sound_mgr.play_click_sound()
	app.game.is_paused = !app.game.is_paused
	app.btn_pause.text = if app.game.is_paused { 'RESUME [P]' } else { 'PAUSE [P]' }
}

fn (mut app App) reset_game() {
	app.sound_mgr.play_click_sound()
	app.game.reset()
	app.particles.clear()
}

fn (mut app App) handle_mouse_click(x int, y int) {
	if app.btn_restart.is_hovered(x, y) {
		app.reset_game()
		return
	}
	if app.btn_pause.is_hovered(x, y) {
		app.toggle_pause()
		return
	}
	if app.btn_sound.is_hovered(x, y) {
		app.toggle_sound()
		return
	}
}

fn (mut app App) render() {
	sdl.set_render_draw_color(app.renderer, 14, 18, 28, 255)
	sdl.render_clear(app.renderer)

	// Top Title Header
	draw_text_centered(app.renderer, win_width / 2, 14, 'CYBERPUNK SNAKE', 3, Color{
		r: 255
		g: 255
		b: 255
	})

	// Glassmorphic Score Cards
	draw_glass_card(app.renderer, 40, 50, 240, 42, Color{ r: 50, g: 220, b: 130 })
	draw_text_centered(app.renderer, 160, 62, 'SCORE: ${app.game.score}', 2, Color{
		r: 100
		g: 255
		b: 160
	})

	draw_glass_card(app.renderer, win_width - 280, 50, 240, 42, Color{ r: 255, g: 200, b: 40 })
	draw_text_centered(app.renderer, win_width - 160, 62, 'HIGH: ${app.game.high_score}',
		2, Color{ r: 255, g: 235, b: 120 })

	// Status Badge
	mut status_text := 'PLAYING'
	mut status_color := Color{
		r: 80
		g: 240
		b: 140
	}
	mut badge_border := Color{
		r: 50
		g: 200
		b: 120
	}

	if app.game.game_over {
		status_text = 'GAME OVER! PRESS [R]'
		status_color = Color{
			r: 255
			g: 80
			b: 90
		}
		badge_border = Color{
			r: 235
			g: 45
			b: 60
		}
	} else if app.game.is_paused {
		status_text = 'PAUSED'
		status_color = Color{
			r: 255
			g: 220
			b: 60
		}
		badge_border = Color{
			r: 255
			g: 200
			b: 25
		}
	}

	draw_glass_card(app.renderer, win_width / 2 - 170, 50, 340, 42, badge_border)
	draw_text_centered(app.renderer, win_width / 2, 62, status_text, 2, status_color)

	// Main Grid Matrix Area with Screen Shake
	mut gx := grid_start_x
	mut gy := grid_start_y
	if app.shake_timer > 0 {
		shake_mag := app.shake_timer * 18.0
		gx += int((rand.f64() * 2.0 - 1.0) * shake_mag)
		gy += int((rand.f64() * 2.0 - 1.0) * shake_mag)
	}

	grid_rect := sdl.Rect{
		x: gx
		y: gy
		w: grid_cols * cell_px
		h: grid_rows * cell_px
	}
	sdl.set_render_draw_color(app.renderer, 20, 26, 42, 255)
	sdl.render_fill_rect(app.renderer, &grid_rect)

	// Grid Border
	sdl.set_render_draw_color(app.renderer, 45, 60, 95, 255)
	sdl.render_draw_rect(app.renderer, &grid_rect)

	// Subtle Grid Lines
	sdl.set_render_draw_color(app.renderer, 25, 33, 54, 255)
	for c in 1 .. grid_cols {
		line_x := gx + c * cell_px
		sdl.render_draw_line(app.renderer, line_x, gy, line_x, gy + grid_rows * cell_px)
	}
	for r in 1 .. grid_rows {
		line_y := gy + r * cell_px
		sdl.render_draw_line(app.renderer, gx, line_y, gx + grid_cols * cell_px, line_y)
	}

	// Draw Food Sprite (Pixel Art Apple)
	fx := gx + app.game.food.x * cell_px
	fy := gy + app.game.food.y * cell_px
	draw_food_sprite(app.renderer, fx, fy, cell_px, false, app.tex_mgr.sprite_texture)

	// Draw Golden Star Apple (if active)
	if app.game.has_gold {
		gold_x := gx + app.game.gold_food.x * cell_px
		gold_y := gy + app.game.gold_food.y * cell_px
		draw_food_sprite(app.renderer, gold_x, gold_y, cell_px, true, app.tex_mgr.sprite_texture)
	}

	// Draw Snake Body & Head Sprites
	for idx, pt in app.game.body {
		sx := gx + pt.x * cell_px
		sy := gy + pt.y * cell_px

		if idx == 0 {
			draw_snake_head_sprite(app.renderer, sx, sy, cell_px, app.game.dir, app.tex_mgr.sprite_texture)
		} else {
			draw_snake_body_sprite(app.renderer, sx, sy, cell_px, idx, app.game.body.len, app.tex_mgr.sprite_texture)
		}
	}

	// Render Particles
	for p in app.particles {
		draw_filled_circle(app.renderer, int(p.x), int(p.y), p.size, Color{
			r: p.color.r
			g: p.color.g
			b: p.color.b
			a: u8(p.life * 255.0)
		})
	}

	// Draw Control Buttons
	app.btn_restart.draw(app.renderer, app.mouse_x, app.mouse_y)
	app.btn_pause.draw(app.renderer, app.mouse_x, app.mouse_y)
	app.btn_sound.draw(app.renderer, app.mouse_x, app.mouse_y)

	prod_fx_render(app.renderer)
	sdl.render_present(app.renderer)
}

fn (mut app App) run() {
	mut should_close := false
	app.last_step_t = sdl.get_ticks()

	for !should_close {
		evt := sdl.Event{}
		for 0 < sdl.poll_event(&evt) {
			match evt.@type {
				.quit {
					should_close = true
				}
				.mousebuttondown {
					if evt.button.button == u8(sdl.button_left) {
						app.handle_mouse_click(evt.button.x, evt.button.y)
					}
				}
				.mousemotion {
					app.mouse_x = evt.motion.x
					app.mouse_y = evt.motion.y
				}
				.keydown {
					sym := evt.key.keysym.sym
					if sym == int(sdl.KeyCode.f11) {
						toggle_fullscreen(app.window)
					} else if sym == int(sdl.KeyCode.r) {
						app.reset_game()
					} else if sym == int(sdl.KeyCode.p) {
						app.toggle_pause()
					} else if sym == int(sdl.KeyCode.s) {
						app.toggle_sound()
					} else if sym == int(sdl.KeyCode.up) || sym == int(sdl.KeyCode.w) {
						app.game.set_direction(.up)
					} else if sym == int(sdl.KeyCode.down) || sym == int(sdl.KeyCode.s) {
						app.game.set_direction(.down)
					} else if sym == int(sdl.KeyCode.left) || sym == int(sdl.KeyCode.a) {
						app.game.set_direction(.left)
					} else if sym == int(sdl.KeyCode.right) || sym == int(sdl.KeyCode.d) {
						app.game.set_direction(.right)
					} else if sym == int(sdl.KeyCode.escape) {
						should_close = true
					}
				}
				else {}
			}
		}

		app.update_game_step()
		app.update_particles()
		app.sound_mgr.update_bgm(!app.game.is_paused && !app.game.game_over)
		app.render()
		sdl.delay(16) // ~60 FPS loop
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
	if os.args.contains('--snapshot') || os.args.contains('--snap') {
		sdl.init(sdl.init_video)
		surface := sdl.create_rgb_surface(0, win_width, win_height, 32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000)
		s_renderer := sdl.create_software_renderer(surface)
		mut app := new_app()
		app.renderer = s_renderer
		app.tex_mgr.init(s_renderer)
		app.game.score = 280
		app.game.high_score = 450
		app.game.has_gold = true
		app.game.gold_food = Point{x: 14, y: 8}
		// Create a nice winding snake body for the preview
		app.game.body = [
			Point{x: 12, y: 8},
			Point{x: 11, y: 8},
			Point{x: 10, y: 8},
			Point{x: 10, y: 9},
			Point{x: 9, y: 9},
			Point{x: 8, y: 9},
			Point{x: 8, y: 10},
			Point{x: 7, y: 10},
			Point{x: 6, y: 10},
		]
		app.render()
		sdl.save_bmp(surface, 'screenshots/snake.bmp'.str)
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
