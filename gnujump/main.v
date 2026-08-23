module main

import os

import math
import rand
import sdl

struct App {
mut:
	window      &sdl.Window   = unsafe { nil }
	renderer    &sdl.Renderer = unsafe { nil }
	game        GNUJumpEngine
	sound_mgr   SoundManager
	tex_mgr     GNUJumpTextureManager
	particles   []Particle
	mouse_x     int
	mouse_y     int
	p1_left     bool
	p1_right    bool
	p1_up       bool
	p2_left     bool
	p2_right    bool
	p2_up       bool
	btn_1p      Button
	btn_2p      Button
	btn_start   Button
	btn_restart Button
	btn_sound   Button
}

fn new_app() App {
	mut app := App{
		game:        new_gnujump_engine()
		sound_mgr:   new_sound_manager()
		tex_mgr:     new_gnujump_texture_manager()
		btn_1p:      Button{
			x:            210
			y:            300
			w:            180
			h:            110
			text:         '1P SOLO'
			bg_color:     Color{
				r: 34
				g: 211
				b: 238
			}
			hover_color:  Color{
				r: 103
				g: 232
				b: 249
			}
			text_color:   Color{
				r: 15
				g: 23
				b: 42
			}
			border_color: Color{
				r: 250
				g: 204
				b: 21
			}
		}
		btn_2p:      Button{
			x:            410
			y:            300
			w:            180
			h:            110
			text:         '2P VERSUS'
			bg_color:     Color{
				r: 30
				g: 41
				b: 59
			}
			hover_color:  Color{
				r: 51
				g: 65
				b: 85
			}
			text_color:   Color{
				r: 255
				g: 255
				b: 255
			}
			border_color: Color{
				r: 71
				g: 85
				b: 105
			}
		}
		btn_start:   Button{
			x:            250
			y:            440
			w:            300
			h:            52
			text:         'START JUMPING'
			bg_color:     Color{
				r: 59
				g: 130
				b: 246
			}
			hover_color:  Color{
				r: 96
				g: 165
				b: 250
			}
			text_color:   Color{
				r: 255
				g: 255
				b: 255
			}
			border_color: Color{
				r: 250
				g: 204
				b: 21
			}
		}
		btn_restart: Button{
			x:            250
			y:            480
			w:            300
			h:            48
			text:         'RESTART GAME [R]'
			bg_color:     Color{
				r: 239
				g: 68
				b: 68
			}
			hover_color:  Color{
				r: 248
				g: 113
				b: 113
			}
			text_color:   Color{
				r: 255
				g: 255
				b: 255
			}
			border_color: Color{
				r: 250
				g: 204
				b: 21
			}
		}
		btn_sound:   Button{
			x:            630
			y:            10
			w:            150
			h:            36
			text:         'SOUND: ON [O]'
			bg_color:     Color{
				r: 30
				g: 41
				b: 59
			}
			hover_color:  Color{
				r: 51
				g: 65
				b: 85
			}
			text_color:   Color{
				r: 80
				g: 240
				b: 140
			}
			border_color: Color{
				r: 71
				g: 85
				b: 105
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

	app.window = sdl.create_window(c'GNUjump - V & SDL2', sdl.windowpos_centered, sdl.windowpos_centered,
		win_width, win_height, u32(sdl.WindowFlags.shown) | u32(sdl.WindowFlags.fullscreen_desktop) | u32(sdl.WindowFlags.resizable))

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

fn (mut app App) spawn_particles(cx f64, cy f64, color Color, count int) {
	for _ in 0 .. count {
		angle := rand.f64() * 6.28
		speed := 1.5 + rand.f64() * 4.0
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
		app.particles[i].life -= 0.03
		if app.particles[i].life <= 0 {
			app.particles.delete(i)
		}
	}
}

fn (mut app App) toggle_mode() {
	app.sound_mgr.play_click_sound()
	if app.game.game_mode == .solo {
		app.game.game_mode = .pvp
		app.btn_1p.bg_color = Color{
			r: 30
			g: 41
			b: 59
		}
		app.btn_1p.text_color = Color{
			r: 255
			g: 255
			b: 255
		}
		app.btn_2p.bg_color = Color{
			r: 245
			g: 158
			b: 11
		}
		app.btn_2p.text_color = Color{
			r: 15
			g: 23
			b: 42
		}
	} else {
		app.game.game_mode = .solo
		app.btn_1p.bg_color = Color{
			r: 34
			g: 211
			b: 238
		}
		app.btn_1p.text_color = Color{
			r: 15
			g: 23
			b: 42
		}
		app.btn_2p.bg_color = Color{
			r: 30
			g: 41
			b: 59
		}
		app.btn_2p.text_color = Color{
			r: 255
			g: 255
			b: 255
		}
	}
}

fn (mut app App) handle_mouse_click(x int, y int) {
	if app.btn_sound.is_hovered(x, y) {
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
		return
	}

	if app.game.mode == .menu {
		if app.btn_1p.is_hovered(x, y) || app.btn_2p.is_hovered(x, y) {
			app.toggle_mode()
		} else if app.btn_start.is_hovered(x, y) {
			app.sound_mgr.play_click_sound()
			app.game.start_game()
		}
	} else if app.game.mode == .game_over {
		if app.btn_restart.is_hovered(x, y) {
			app.sound_mgr.play_click_sound()
			app.game.start_game()
		}
	}
}

fn (mut app App) render() {
	ticks := sdl.get_ticks()
	sdl.set_render_draw_color(app.renderer, 15, 23, 42, 255)
	sdl.render_clear(app.renderer)

	render_tower_walls(app.renderer, ticks)

	if app.game.mode == .playing {
		// Render Platforms
		for p in app.game.platforms {
			render_platform(app.renderer, p, ticks, app.tex_mgr.sprite_texture)
		}

		// Render Lava Surface
		render_lava(app.renderer, app.game.lava_y, ticks, app.tex_mgr.sprite_texture)

		// Render Jumpers
		render_jumper(app.renderer, app.game.p1, app.tex_mgr.sprite_texture, false)
		if app.game.game_mode == .pvp {
			render_jumper(app.renderer, app.game.p2, app.tex_mgr.sprite_texture, true)
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

	// Top Glassmorphic HUD Card
	draw_glass_card(app.renderer, 0, 0, win_width, 56, Color{ r: 59, g: 130, b: 246 })
	draw_text(app.renderer, 20, 16, 'GNUJUMP', 3, Color{ r: 96, g: 165, b: 250 })

	if app.game.game_mode == .solo {
		draw_text(app.renderer, 200, 18, 'SCORE: ${app.game.score_p1}', 2, Color{
			r: 255
			g: 255
			b: 255
		})
		draw_text(app.renderer, 420, 18, 'LIVES: ${app.game.p1.lives}', 2, Color{
			r: 239
			g: 68
			b: 68
		})
	} else {
		// 2P Local Versus Split HUD
		draw_text(app.renderer, 180, 10, 'P1 CYAN: ${app.game.score_p1} L:${app.game.p1.lives}',
			2, Color{ r: 34, g: 211, b: 238 })
		draw_text(app.renderer, 180, 32, 'P2 AMBER: ${app.game.score_p2} L:${app.game.p2.lives}',
			2, Color{ r: 245, g: 158, b: 11 })

		// Live Race Leader Indicator Pill
		leader_text := if app.game.score_p1 > app.game.score_p2 {
			'P1 LEAD'
		} else if app.game.score_p2 > app.game.score_p1 {
			'P2 LEAD'
		} else {
			'TIED!'
		}
		leader_color := if app.game.score_p1 > app.game.score_p2 {
			Color{
				r: 34
				g: 211
				b: 238
			}
		} else if app.game.score_p2 > app.game.score_p1 {
			Color{
				r: 245
				g: 158
				b: 11
			}
		} else {
			Color{
				r: 250
				g: 204
				b: 21
			}
		}
		draw_text(app.renderer, 480, 18, leader_text, 2, leader_color)
	}

	app.btn_sound.draw(app.renderer, app.mouse_x, app.mouse_y)

	// Menu Overlay
	if app.game.mode == .menu {
		draw_glass_card(app.renderer, 160, 120, 480, 440, Color{ r: 59, g: 130, b: 246 })
		draw_text_centered(app.renderer, win_width / 2, 145, 'GNUJUMP TOWER', 3, Color{
			r: 96
			g: 165
			b: 250
		})
		draw_text_centered(app.renderer, win_width / 2, 185, 'VERTICAL SURVIVAL', 2, Color{
			r: 250
			g: 204
			b: 21
		})

		draw_text_centered(app.renderer, win_width / 2, 235, 'HIGH RECORD: ${app.game.high_score}',
			2, Color{ r: 148, g: 163, b: 184 })
		draw_text_centered(app.renderer, win_width / 2, 275, 'SELECT GAME MODE [M]:',
			2, Color{ r: 255, g: 255, b: 255 })

		// Draw 1P Solo Card
		app.btn_1p.draw(app.renderer, app.mouse_x, app.mouse_y)
		draw_text_centered(app.renderer, 300, 340, 'CLIMB ALONE', 1, Color{
			r: 15
			g: 23
			b: 42
		})
		status_1p := if app.game.game_mode == .solo { '[ SELECTED ]' } else { '[ CLICK TO SELECT ]' }
		draw_text_centered(app.renderer, 300, 375, status_1p, 1, Color{ r: 15, g: 23, b: 42 })

		// Draw 2P Local Versus Card
		app.btn_2p.draw(app.renderer, app.mouse_x, app.mouse_y)
		draw_text_centered(app.renderer, 500, 340, 'TOWER RACE', 1, Color{
			r: 255
			g: 255
			b: 255
		})
		status_2p := if app.game.game_mode == .pvp { '[ SELECTED ]' } else { '[ CLICK TO SELECT ]' }
		draw_text_centered(app.renderer, 500, 375, status_2p, 1, Color{
			r: 250
			g: 204
			b: 21
		})

		app.btn_start.draw(app.renderer, app.mouse_x, app.mouse_y)

		ctrl_text := if app.game.game_mode == .solo {
			'CONTROLS: ARROWS / WASD TO JUMP & STEER'
		} else {
			'CONTROLS: P1 = ARROWS | P2 = WASD'
		}
		draw_text_centered(app.renderer, win_width / 2, 520, ctrl_text, 1, Color{
			r: 148
			g: 163
			b: 184
		})
	} else if app.game.mode == .game_over {
		draw_glass_card(app.renderer, 180, 160, 440, 410, Color{ r: 239, g: 68, b: 68 })

		title_text := if app.game.game_mode == .pvp {
			if app.game.score_p1 > app.game.score_p2 {
				'P1 CYAN VICTORIOUS!'
			} else if app.game.score_p2 > app.game.score_p1 {
				'P2 AMBER VICTORIOUS!'
			} else {
				'STALEMATE TIE!'
			}
		} else {
			'TOWER FELL'
		}

		draw_text_centered(app.renderer, win_width / 2, 190, title_text, 3, Color{
			r: 248
			g: 113
			b: 113
		})
		draw_text_centered(app.renderer, win_width / 2, 235, 'CONSUMED BY LAVA', 2, Color{
			r: 255
			g: 255
			b: 255
		})

		draw_text_centered(app.renderer, win_width / 2, 300, 'P1 SCORE: ${app.game.score_p1}',
			2, Color{ r: 34, g: 211, b: 238 })
		if app.game.game_mode == .pvp {
			draw_text_centered(app.renderer, win_width / 2, 340, 'P2 SCORE: ${app.game.score_p2}',
				2, Color{ r: 245, g: 158, b: 11 })
		}
		draw_text_centered(app.renderer, win_width / 2, 390, 'HIGH RECORD: ${app.game.high_score}',
			2, Color{ r: 250, g: 204, b: 21 })

		app.btn_restart.draw(app.renderer, app.mouse_x, app.mouse_y)
	}

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
						if app.game.mode == .game_over {
							app.sound_mgr.play_click_sound()
							app.game.start_game()
						}
					} else if sym == int(sdl.KeyCode.m) {
						if app.game.mode == .menu {
							app.toggle_mode()
						}
					} else if sym == int(sdl.KeyCode.o) {
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
					} else if sym == int(sdl.KeyCode.left) {
						app.p1_left = true
					} else if sym == int(sdl.KeyCode.right) {
						app.p1_right = true
					} else if sym == int(sdl.KeyCode.up) || sym == int(sdl.KeyCode.space) {
						app.p1_up = true
					} else if sym == int(sdl.KeyCode.a) {
						if app.game.game_mode == .pvp {
							app.p2_left = true
						} else {
							app.p1_left = true
						}
					} else if sym == int(sdl.KeyCode.d) {
						if app.game.game_mode == .pvp {
							app.p2_right = true
						} else {
							app.p1_right = true
						}
					} else if sym == int(sdl.KeyCode.w) {
						if app.game.game_mode == .pvp {
							app.p2_up = true
						} else {
							app.p1_up = true
						}
					} else if sym == int(sdl.KeyCode.escape) {
						should_close = true
					}
				}
				.keyup {
					sym := evt.key.keysym.sym
					if sym == int(sdl.KeyCode.left) {
						app.p1_left = false
					} else if sym == int(sdl.KeyCode.right) {
						app.p1_right = false
					} else if sym == int(sdl.KeyCode.up) || sym == int(sdl.KeyCode.space) {
						app.p1_up = false
					} else if sym == int(sdl.KeyCode.a) {
						if app.game.game_mode == .pvp {
							app.p2_left = false
						} else {
							app.p1_left = false
						}
					} else if sym == int(sdl.KeyCode.d) {
						if app.game.game_mode == .pvp {
							app.p2_right = false
						} else {
							app.p1_right = false
						}
					} else if sym == int(sdl.KeyCode.w) {
						if app.game.game_mode == .pvp {
							app.p2_up = false
						} else {
							app.p1_up = false
						}
					}
				}
				else {}
			}
		}

		jumped, landed, springed, broken, combo := app.game.update_step(app.p1_left, app.p1_right,
			app.p1_up, app.p2_left, app.p2_right, app.p2_up)

		if jumped {
			app.sound_mgr.play_jump_sound()
		}
		if landed {
			app.sound_mgr.play_land_sound()
		}
		if springed {
			app.sound_mgr.play_spring_sound()
		}
		if broken {
			app.sound_mgr.play_crumbly_sound()
		}
		if combo {
			app.sound_mgr.play_combo_sound()
			app.spawn_particles(app.game.p1.x, app.game.p1.y, Color{ r: 250, g: 204, b: 21 },
				15)
		}

		app.update_particles()
		app.sound_mgr.update_bgm_stream(app.game.mode == .playing)
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
	if os.args.contains("--snapshot") || os.args.contains("--snap") || os.getenv("SNAPSHOT") == "1" {
		if sdl.init(sdl.init_video) != 0 { return }
		defer { sdl.quit() }
		surface := sdl.create_rgb_surface(0, 800, 600, 32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000)
		s_renderer := sdl.create_software_renderer(surface)
		mut app := new_app()
		app.renderer = s_renderer
		app.game.start_game()
		app.render()
		sdl.save_bmp(surface, 'screenshots/gnujump.bmp'.str)
		sdl.destroy_renderer(s_renderer)
		sdl.free_surface(surface)
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
