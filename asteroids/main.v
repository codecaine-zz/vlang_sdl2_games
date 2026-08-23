module main

import math
import os
import rand
import sdl

struct App {
mut:
	window        &sdl.Window   = unsafe { nil }
	renderer      &sdl.Renderer = unsafe { nil }
	game          AsteroidsGame
	sound_mgr     SoundManager
	tex_mgr       AsteroidsTextureManager
	particles     []Particle
	mouse_x       int
	mouse_y       int
	key_left      bool
	key_right     bool
	key_up        bool
	key_fire      bool
	key_hyper     bool
	key_shield    bool
	paused        bool
	btn_restart   Button
	btn_hyper     Button
	btn_shield    Button
	btn_sound     Button
}

fn new_app() App {
	mut app := App{
		game:        new_asteroids_game()
		sound_mgr:   new_sound_manager()
		btn_restart: Button{
			x:            50
			y:            540
			w:            150
			h:            40
			text:         'RESTART [R]'
			bg_color:     Color{r: 25, g: 35, b: 55}
			hover_color:  Color{r: 45, g: 60, b: 90}
			text_color:   Color{r: 255, g: 255, b: 255}
			border_color: Color{r: 70, g: 90, b: 140}
		}
		btn_hyper:   Button{
			x:            220
			y:            540
			w:            170
			h:            40
			text:         'HYPERSPACE [H]'
			bg_color:     Color{r: 25, g: 35, b: 55}
			hover_color:  Color{r: 45, g: 60, b: 90}
			text_color:   Color{r: 255, g: 255, b: 255}
			border_color: Color{r: 70, g: 90, b: 140}
		}
		btn_shield:  Button{
			x:            410
			y:            540
			w:            150
			h:            40
			text:         'SHIELD [S]'
			bg_color:     Color{r: 25, g: 35, b: 55}
			hover_color:  Color{r: 45, g: 60, b: 90}
			text_color:   Color{r: 255, g: 255, b: 255}
			border_color: Color{r: 70, g: 90, b: 140}
		}
		btn_sound:   Button{
			x:            580
			y:            540
			w:            170
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

fn (mut app App) spawn_particles(x f64, y f64, count int, color Color) {
	for _ in 0 .. count {
		angle := rand.f64() * 2.0 * math.pi
		speed := 30.0 + rand.f64() * 120.0
		life := 0.2 + rand.f64() * 0.4
		app.particles << Particle{
			x:        x
			y:        y
			dx:       math.cos(angle) * speed
			dy:       math.sin(angle) * speed
			life:     life
			max_life: life
			color:    color
		}
	}
}

fn (mut app App) reset_game() {
	app.sound_mgr.clear_audio()
	app.game.reset()
	app.game.last_sound_event = ''
}

fn (mut app App) update(dt f64) {
	if app.paused {
		return
	}

	mut rot_input := 0.0
	if app.key_left {
		rot_input -= 1.0
	}
	if app.key_right {
		rot_input += 1.0
	}

	app.game.step(dt, rot_input, app.key_up, app.key_fire, app.key_hyper, app.key_shield)

	// Consume one-shot triggers
	app.key_hyper = false
	app.key_shield = false

	// Particle thruster trail
	if app.game.ship.thrusting && !app.game.game_over {
		tx := app.game.ship.x - math.cos(app.game.ship.angle) * 14.0
		ty := app.game.ship.y - math.sin(app.game.ship.angle) * 14.0
		app.spawn_particles(tx, ty, 2, Color{r: 255, g: 150, b: 0})
	}

	// Process Sound Triggers & Sound FX Particles
	if app.game.last_sound_event != '' {
		event := app.game.last_sound_event
		app.game.last_sound_event = ''
		match event {
			'laser' {
				app.sound_mgr.play_laser_sound()
			}
			'plasma' {
				app.sound_mgr.play_plasma_sound()
			}
			'explosion' {
				app.sound_mgr.play_explosion_sound(app.game.last_sound_param)
			}
			'powerup' {
				app.sound_mgr.play_powerup_sound()
				app.spawn_particles(app.game.ship.x, app.game.ship.y, 25, Color{
					r: 255
					g: 255
					b: 0
				})
			}
			'emp' {
				app.sound_mgr.play_emp_sound()
				app.spawn_particles(world_w / 2, world_h / 2, 60, Color{
					r: 200
					g: 100
					b: 255
				})
			}
			'warp' {
				app.sound_mgr.play_warp_sound()
				app.spawn_particles(app.game.ship.x, app.game.ship.y, 30, Color{
					r: 0
					g: 255
					b: 255
				})
			}
			'shield' {
				app.sound_mgr.play_shield_sound()
			}
			else {}
		}
	}

	// Update Particle physics
	for i := app.particles.len - 1; i >= 0; i-- {
		mut p := app.particles[i]
		p.x += p.dx * dt
		p.y += p.dy * dt
		p.life -= dt

		if p.life <= 0.0 {
			app.particles.delete(i)
		} else {
			app.particles[i] = p
		}
	}
}

fn main() {
	if os.args.contains('--snapshot') || os.args.contains('--snap') {
		sdl.init(sdl.init_video)
		surface := sdl.create_rgb_surface(0, world_w, world_h, 32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000)
		s_renderer := sdl.create_software_renderer(surface)
		mut app := new_app()
		app.renderer = s_renderer
		app.tex_mgr.init(s_renderer)
		app.game.score = 5400
		app.game.wave = 2
		app.game.asteroids = [
			Asteroid{x: 200, y: 150, dx: 10, dy: 5, size: .large, radius: 40, rot: 0.4, rot_speed: 0.5, shape: [40.0, 36.0, 42.0, 38.0, 44.0, 37.0, 41.0, 39.0, 43.0, 35.0]},
			Asteroid{x: 620, y: 220, dx: -8, dy: 12, size: .large, radius: 40, rot: 1.2, rot_speed: -0.4, shape: [38.0, 42.0, 36.0, 44.0, 39.0, 41.0, 37.0, 43.0, 40.0, 38.0]},
			Asteroid{x: 180, y: 440, dx: 15, dy: -10, size: .medium, radius: 24, rot: 2.1, rot_speed: 0.8, shape: [24.0, 22.0, 25.0, 21.0, 24.0, 23.0, 26.0, 22.0, 25.0, 23.0]},
			Asteroid{x: 580, y: 460, dx: -12, dy: -8, size: .small, radius: 14, rot: 0.8, rot_speed: 1.2, shape: [14.0, 13.0, 15.0, 12.0, 14.0, 13.0, 15.0, 14.0, 13.0, 14.0]},
		]
		app.game.powerups = [
			PowerUp{x: 320, y: 220, dx: 0, dy: 0, kind: .spread_shot, timer: 8.0}
		]
		app.game.ufos = [
			Ufo{x: 680, y: 120, dx: -40, dy: 0, is_hunter: true, fire_timer: 1.0}
		]
		app.game.bullets = [
			Bullet{x: 400, y: 260, dx: 0, dy: -400, life: 1.0, is_plasma: true},
			Bullet{x: 390, y: 270, dx: -100, dy: -380, life: 0.9, is_plasma: false},
			Bullet{x: 410, y: 270, dx: 100, dy: -380, life: 0.9, is_plasma: false},
		]
		render_asteroids_game(app.renderer, &app.game, app.particles, app.tex_mgr.sprite_texture)
		sdl.save_bmp(surface, 'screenshots/asteroids.bmp'.str)
		sdl.destroy_renderer(s_renderer)
		sdl.free_surface(surface)
		sdl.quit()
		return
	}

	if sdl.init(sdl.init_video | sdl.init_audio) < 0 {
		eprintln('Failed to initialize SDL')
		return
	}
	defer {
		sdl.quit()
	}

	mut app := new_app()

	app.window = sdl.create_window('Asteroids Pro: Top-Down Space Shooter'.str, sdl.windowpos_centered,
		sdl.windowpos_centered, world_w, world_h, u32(sdl.WindowFlags.shown) | u32(sdl.WindowFlags.fullscreen_desktop) | u32(sdl.WindowFlags.resizable))
	if unsafe { app.window == nil } {
		eprintln('Failed to create SDL Window')
		return
	}
	defer {
		sdl.destroy_window(app.window)
	}

	app.renderer = sdl.create_renderer(app.window, -1, u32(sdl.RendererFlags.accelerated) | u32(sdl.RendererFlags.presentvsync))
	if unsafe { app.renderer == nil } {
		eprintln('Failed to create SDL Renderer')
		return
	}
	defer {
		sdl.destroy_renderer(app.renderer)
	}
	sdl.render_set_logical_size(app.renderer, world_w, world_h)
	app.tex_mgr.init(app.renderer)

	mut last_ticks := sdl.get_ticks()

	for {
		mut event := sdl.Event{}
		mut quit := false

		for 0 < sdl.poll_event(&event) {
			match event.@type {
				.quit {
					quit = true
				}
				.mousemotion {
					app.mouse_x = event.motion.x
					app.mouse_y = event.motion.y
				}
				.mousebuttondown {
					if event.button.button == u8(sdl.button_left) {
						mx := event.button.x
						my := event.button.y

						if app.btn_restart.contains(mx, my) {
							app.reset_game()
						} else if app.btn_hyper.contains(mx, my) {
							app.key_hyper = true
						} else if app.btn_shield.contains(mx, my) {
							app.key_shield = true
						} else if app.btn_sound.contains(mx, my) {
							muted := !app.sound_mgr.toggle_sound()
							app.btn_sound.text = if muted { 'SOUND: OFF [O]' } else { 'SOUND: ON [O]' }
						}
					}
				}
				.keydown {
					sym := event.key.keysym.sym
					if sym == int(sdl.KeyCode.f11) {
						toggle_fullscreen(app.window)
					} else if sym == int(sdl.KeyCode.left) || sym == int(sdl.KeyCode.a) {
						app.key_left = true
					} else if sym == int(sdl.KeyCode.right) || sym == int(sdl.KeyCode.d) {
						app.key_right = true
					} else if sym == int(sdl.KeyCode.up) || sym == int(sdl.KeyCode.w) {
						app.key_up = true
					} else if sym == int(sdl.KeyCode.space) || sym == int(sdl.KeyCode.j) {
						app.key_fire = true
					} else if sym == int(sdl.KeyCode.h) || sym == int(sdl.KeyCode.k) {
						app.key_hyper = true
					} else if sym == int(sdl.KeyCode.s) || sym == int(sdl.KeyCode.down) {
						app.key_shield = true
					} else if sym == int(sdl.KeyCode.r) {
						app.reset_game()
					} else if sym == int(sdl.KeyCode.p) {
						app.paused = !app.paused
					} else if sym == int(sdl.KeyCode.o) {
						muted := !app.sound_mgr.toggle_sound()
						app.btn_sound.text = if muted { 'SOUND: OFF [O]' } else { 'SOUND: ON [O]' }
					} else if sym == int(sdl.KeyCode.escape) {
						quit = true
					}
				}
				.keyup {
					sym := event.key.keysym.sym
					if sym == int(sdl.KeyCode.left) || sym == int(sdl.KeyCode.a) {
						app.key_left = false
					} else if sym == int(sdl.KeyCode.right) || sym == int(sdl.KeyCode.d) {
						app.key_right = false
					} else if sym == int(sdl.KeyCode.up) || sym == int(sdl.KeyCode.w) {
						app.key_up = false
					} else if sym == int(sdl.KeyCode.space) || sym == int(sdl.KeyCode.j) {
						app.key_fire = false
					}
				}
				else {}
			}
		}

		if quit {
			break
		}

		current_ticks := sdl.get_ticks()
		dt := f64(current_ticks - last_ticks) / 1000.0
		last_ticks = current_ticks

		app.update(math.min(dt, 0.05))
		app.sound_mgr.update_bgm(!app.paused && !app.game.game_over)

		render_asteroids_game(app.renderer, &app.game, app.particles, app.tex_mgr.sprite_texture)

		// Render UI buttons
		app.btn_restart.render(app.renderer, app.mouse_x, app.mouse_y)
		app.btn_hyper.render(app.renderer, app.mouse_x, app.mouse_y)
		app.btn_shield.render(app.renderer, app.mouse_x, app.mouse_y)
		app.btn_sound.render(app.renderer, app.mouse_x, app.mouse_y)

		if app.paused {
			draw_text_centered(app.renderer, world_w / 2, 280, 'PAUSED', 4, Color{
				r: 255
				g: 255
				b: 0
			})
		}

		prod_fx_render(app.renderer)
		sdl.render_present(app.renderer)
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
