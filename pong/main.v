module main

import math
import os
import rand
import sdl

struct App {
mut:
	window      &sdl.Window   = unsafe { nil }
	renderer    &sdl.Renderer = unsafe { nil }
	game        PongGame
	sound_mgr   SoundManager
	tex_mgr     PongTextureManager
	particles   []Particle
	mouse_x     int
	mouse_y     int
	key_w       bool
	key_s       bool
	key_up      bool
	key_down    bool
	btn_restart Button
	btn_mode    Button
	btn_sound   Button
}

fn new_app() App {
	mut app := App{
		game:        new_pong_game()
		sound_mgr:   new_sound_manager()
		btn_restart: Button{
			x:            70
			y:            620
			w:            220
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
		btn_mode:    Button{
			x:            340
			y:            620
			w:            220
			h:            44
			text:         'MODE: 1P [M]'
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
			x:            610
			y:            620
			w:            220
			h:            44
			text:         'SOUND: ON [O]'
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

	app.window = sdl.create_window(c'Hyper Pong - V & SDL2', sdl.windowpos_centered, sdl.windowpos_centered,
		court_w, court_h, u32(sdl.WindowFlags.shown) | u32(sdl.WindowFlags.fullscreen_desktop) | u32(sdl.WindowFlags.resizable) | u32(sdl.WindowFlags.fullscreen_desktop) | u32(sdl.WindowFlags.resizable))

	if app.window == unsafe { nil } {
		eprintln('Failed to create SDL Window')
		return false
	}

	app.renderer = sdl.create_renderer(app.window, -1, u32(sdl.RendererFlags.accelerated) | u32(sdl.RendererFlags.presentvsync))
	if app.renderer == unsafe { nil } {
		eprintln('Failed to create SDL Renderer')
		return false
	}

	sdl.render_set_logical_size(app.renderer, court_w, court_h)
	app.tex_mgr.init(app.renderer)

	return true
}

fn (mut app App) spawn_hit_particles(cx f64, cy f64, color Color) {
	for _ in 0 .. 12 {
		angle := rand.f64() * math.pi * 2.0
		speed := 1.5 + rand.f64() * 5.0
		app.particles << Particle{
			x:     cx
			y:     cy
			vx:    math.cos(angle) * speed
			vy:    math.sin(angle) * speed
			life:  1.0
			color: color
			size:  3 + rand.intn(3) or { 3 }
		}
	}
}

fn (mut app App) update_particles() {
	for i := app.particles.len - 1; i >= 0; i-- {
		app.particles[i].x += app.particles[i].vx
		app.particles[i].y += app.particles[i].vy
		app.particles[i].life -= 0.035
		if app.particles[i].life <= 0 {
			app.particles.delete(i)
		}
	}
}

fn (mut app App) update_game() {
	if app.game.mode == .pve {
		p1_up := app.key_w || app.key_up
		p1_down := app.key_s || app.key_down
		app.game.update_p1(p1_up, p1_down)
		app.game.update_p2(false, false)
	} else {
		app.game.update_p1(app.key_w, app.key_s)
		app.game.update_p2(app.key_up, app.key_down)
	}

	hit_paddle, hit_wall, scored_goal := app.game.step()
	if hit_paddle {
		app.sound_mgr.play_hit_sound()
		app.spawn_hit_particles(app.game.ball.x, app.game.ball.y, Color{ r: 40, g: 220, b: 240 })
	} else if hit_wall {
		app.sound_mgr.play_wall_sound()
	} else if scored_goal {
		app.sound_mgr.play_score_sound()
		app.spawn_hit_particles(app.game.ball.x, app.game.ball.y, Color{ r: 255, g: 220, b: 40 })
		if app.game.game_over {
			app.sound_mgr.play_win_sound()
		}
	}

	// Spawn sparkling plasma embers drifting from the ball
	if !app.game.game_over && !app.game.is_paused {
		speed := math.sqrt(app.game.ball.vx * app.game.ball.vx + app.game.ball.vy * app.game.ball.vy)
		particle_col := if speed >= 11.0 {
			Color{ r: 255, g: 230, b: 120 }
		} else if speed >= 8.5 {
			Color{ r: 255, g: 100, b: 240 }
		} else {
			Color{ r: 70, g: 210, b: 255 }
		}
		app.particles << Particle{
			x:     app.game.ball.x + ball_size / 2.0 + (rand.f64() * 4.0 - 2.0)
			y:     app.game.ball.y + ball_size / 2.0 + (rand.f64() * 4.0 - 2.0)
			vx:    -app.game.ball.vx * 0.12 + (rand.f64() * 1.5 - 0.75)
			vy:    -app.game.ball.vy * 0.12 + (rand.f64() * 1.5 - 0.75)
			life:  0.4
			color: particle_col
			size:  if speed > 9.0 { 3 } else { 2 }
		}
	}
}

fn (mut app App) toggle_sound() {
	is_on := app.sound_mgr.toggle_sound()
	app.btn_sound.text = if is_on { 'SOUND: ON [O]' } else { 'SOUND: OFF [O]' }
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

fn (mut app App) toggle_mode() {
	app.sound_mgr.play_click_sound()
	app.game.toggle_mode()
	app.btn_mode.text = if app.game.mode == .pve { 'MODE: 1P [M]' } else { 'MODE: 2P [M]' }
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
	if app.btn_mode.is_hovered(x, y) {
		app.toggle_mode()
		return
	}
	if app.btn_sound.is_hovered(x, y) {
		app.toggle_sound()
		return
	}
}

fn (mut app App) render() {
	sdl.set_render_draw_color(app.renderer, 15, 18, 30, 255)
	sdl.render_clear(app.renderer)

	// Top Title Header
	draw_text_centered(app.renderer, court_w / 2, 14, 'HYPER PONG', 3, Color{ r: 255, g: 255, b: 255 })

	// Score Header Row
	draw_glass_card(app.renderer, 40, 48, 220, 44, Color{ r: 235, g: 45, b: 60 })
	draw_text_centered(app.renderer, 150, 62, 'P1: ${app.game.score_p1}', 2, Color{
		r: 255
		g: 120
		b: 135
	})

	draw_glass_card(app.renderer, court_w - 260, 48, 220, 44, Color{ r: 40, g: 220, b: 240 })
	p2_label := if app.game.mode == .pve {
		'AI: ${app.game.score_p2}'
	} else {
		'P2: ${app.game.score_p2}'
	}
	draw_text_centered(app.renderer, court_w - 150, 62, p2_label, 2, Color{ r: 120, g: 240, b: 255 })

	// Status Badge
	mut status_text := 'FIRST TO 7'
	mut status_color := Color{
		r: 255
		g: 220
		b: 60
	}
	mut badge_border := Color{
		r: 255
		g: 200
		b: 25
	}

	if app.game.game_over {
		winner_name := if app.game.winner_p1 {
			'PLAYER 1 WINS!'
		} else if app.game.mode == .pve {
			'AI WINS!'
		} else {
			'PLAYER 2 WINS!'
		}
		status_text = winner_name
		status_color = Color{
			r: 80
			g: 240
			b: 140
		}
		badge_border = Color{
			r: 50
			g: 200
			b: 120
		}
	}

	draw_glass_card(app.renderer, court_w / 2 - 160, 48, 320, 44, badge_border)
	draw_text_centered(app.renderer, court_w / 2, 62, status_text, 2, status_color)

	// Center Court Dashed Divider Line
	sdl.set_render_draw_color(app.renderer, 45, 60, 95, 255)
	for y := 100; y < court_h - 90; y += 24 {
		dash_rect := sdl.Rect{
			x: court_w / 2 - 2
			y: y
			w: 4
			h: 12
		}
		sdl.render_fill_rect(app.renderer, &dash_rect)
	}

	// Court Top & Bottom Rail Borders
	top_rail := sdl.Rect{
		x: 0
		y: 98
		w: court_w
		h: 4
	}
	bot_rail := sdl.Rect{
		x: 0
		y: court_h - 92
		w: court_w
		h: 4
	}
	sdl.set_render_draw_color(app.renderer, 65, 90, 140, 255)
	sdl.render_fill_rect(app.renderer, &top_rail)
	sdl.render_fill_rect(app.renderer, &bot_rail)

	// Calculate Exact Ball Center Coordinates
	ball_speed := math.sqrt(app.game.ball.vx * app.game.ball.vx + app.game.ball.vy * app.game.ball.vy)
	cx := int(app.game.ball.x + ball_size / 2.0)
	cy := int(app.game.ball.y + ball_size / 2.0)

	// Render Speed-Reactive Ball Ribbon Trail aligned to current center
	draw_ball_trail(app.renderer, app.game.ball.trail, f64(cx), f64(cy), ball_speed)

	// Render Particles
	for p in app.particles {
		draw_filled_circle(app.renderer, int(p.x), int(p.y), p.size, Color{
			r: p.color.r
			g: p.color.g
			b: p.color.b
			a: u8(p.life * 255.0)
		})
	}

	// Render Sprite Paddles
	draw_paddle_sprite(app.renderer, int(app.game.p1.x), int(app.game.p1.y), paddle_w, paddle_h, true, app.tex_mgr.sprite_texture)
	draw_paddle_sprite(app.renderer, int(app.game.p2.x), int(app.game.p2.y), paddle_w, paddle_h, false, app.tex_mgr.sprite_texture)

	// Render Ball Radial Halo Glow & Sprite directly at center
	glow_col := if ball_speed >= 11.0 {
		Color{ r: 255, g: 220, b: 90, a: 110 }
	} else if ball_speed >= 8.5 {
		Color{ r: 240, g: 80, b: 230, a: 100 }
	} else {
		Color{ r: 60, g: 200, b: 255, a: 85 }
	}
	draw_filled_circle(app.renderer, cx, cy, ball_size / 2 + 5, glow_col)
	draw_ball_sprite(app.renderer, cx, cy, ball_size, app.tex_mgr.sprite_texture)

	// Draw Control Buttons
	app.btn_restart.draw(app.renderer, app.mouse_x, app.mouse_y)
	app.btn_mode.draw(app.renderer, app.mouse_x, app.mouse_y)
	app.btn_sound.draw(app.renderer, app.mouse_x, app.mouse_y)

	prod_fx_render(app.renderer)
	sdl.render_present(app.renderer)
}

fn (mut app App) run() {
	mut should_close := false

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
					} else if sym == int(sdl.KeyCode.m) {
						app.toggle_mode()
					} else if sym == int(sdl.KeyCode.o) {
						app.toggle_sound()
					} else if sym == int(sdl.KeyCode.w) {
						app.key_w = true
					} else if sym == int(sdl.KeyCode.s) {
						app.key_s = true
					} else if sym == int(sdl.KeyCode.up) {
						app.key_up = true
					} else if sym == int(sdl.KeyCode.down) {
						app.key_down = true
					} else if sym == int(sdl.KeyCode.escape) {
						should_close = true
					}
				}
				.keyup {
					sym := evt.key.keysym.sym
					if sym == int(sdl.KeyCode.w) {
						app.key_w = false
					} else if sym == int(sdl.KeyCode.s) {
						app.key_s = false
					} else if sym == int(sdl.KeyCode.up) {
						app.key_up = false
					} else if sym == int(sdl.KeyCode.down) {
						app.key_down = false
					}
				}
				else {}
			}
		}

		app.update_game()
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
		surface := sdl.create_rgb_surface(0, court_w, court_h, 32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000)
		s_renderer := sdl.create_software_renderer(surface)
		mut app := new_app()
		app.renderer = s_renderer
		app.game.score_p1 = 5
		app.game.score_p2 = 4
		app.game.ball.x = 420
		app.game.ball.y = 280
		app.render()
		sdl.save_bmp(surface, 'screenshots/pong.bmp'.str)
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
