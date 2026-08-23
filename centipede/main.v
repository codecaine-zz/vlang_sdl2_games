module main

import os

import sdl

struct App {
mut:
	window      &sdl.Window   = unsafe { nil }
	renderer    &sdl.Renderer = unsafe { nil }
	game        CentipedeGame
	sound_mgr   SoundManager
	mouse_x     int
	mouse_y     int
	key_left    bool
	key_right   bool
	key_up      bool
	key_down    bool
	key_fire    bool
	btn_restart Button
	btn_sound   Button
	btn_pause   Button
}

fn new_app() App {
	mut app := App{
		game:      new_centipede_game()
		sound_mgr: new_sound_manager()
		btn_restart: Button{
			x:            50
			y:            640
			w:            170
			h:            34
			text:         'RESTART [R]'
			bg_color:     Color{r: 25, g: 35, b: 55}
			hover_color:  Color{r: 45, g: 60, b: 90}
			text_color:   Color{r: 255, g: 255, b: 255}
			border_color: Color{r: 70, g: 90, b: 140}
		}
		btn_sound: Button{
			x:            580
			y:            640
			w:            170
			h:            34
			text:         'SOUND: ON [O]'
			bg_color:     Color{r: 25, g: 35, b: 55}
			hover_color:  Color{r: 45, g: 60, b: 90}
			text_color:   Color{r: 255, g: 255, b: 255}
			border_color: Color{r: 70, g: 90, b: 140}
		}
		btn_pause: Button{
			x:            315
			y:            640
			w:            170
			h:            34
			text:         'PAUSE [P]'
			bg_color:     Color{r: 25, g: 35, b: 55}
			hover_color:  Color{r: 45, g: 60, b: 90}
			text_color:   Color{r: 255, g: 255, b: 255}
			border_color: Color{r: 70, g: 90, b: 140}
		}
	}
	return app
}

fn (mut app App) init_sdl() bool {
	if sdl.init(sdl.init_video | sdl.init_audio) < 0 {
		eprintln('Failed to init SDL')
		return false
	}

	app.window = sdl.create_window(
		'Cyber Centipede Pro - Advanced Atari Centipede Classic'.str,
		sdl.windowpos_centered,
		sdl.windowpos_centered,
		800,
		680,
		u32(sdl.WindowFlags.shown) | u32(sdl.WindowFlags.fullscreen_desktop) | u32(sdl.WindowFlags.resizable)
	)

	if unsafe { app.window == nil } {
		eprintln('Failed to create window')
		return false
	}

	app.renderer = sdl.create_renderer(app.window, -1, u32(sdl.RendererFlags.accelerated) | u32(sdl.RendererFlags.presentvsync))
	if unsafe { app.renderer == nil } {
		eprintln('Failed to create renderer')
		return false
	}

	sdl.render_set_logical_size(app.renderer, 800, 680)
	sdl.set_render_draw_blend_mode(app.renderer, sdl.BlendMode.blend)
	app.game.init_textures(app.renderer)
	return true
}

fn (mut app App) reset_game() {
	app.sound_mgr.clear_audio()
	app.game.reset()
}

fn (mut app App) handle_events() bool {
	ev := sdl.Event{}
	for 0 < sdl.poll_event(&ev) {
		match ev.@type {
			.quit {
				return false
			}
			.keydown {
				sym := ev.key.keysym.sym
				if sym == int(sdl.KeyCode.f11) {
					toggle_fullscreen(app.window)
				} else if sym == int(sdl.KeyCode.a) || sym == int(sdl.KeyCode.left) {
					app.key_left = true
				} else if sym == int(sdl.KeyCode.d) || sym == int(sdl.KeyCode.right) {
					app.key_right = true
				} else if sym == int(sdl.KeyCode.w) || sym == int(sdl.KeyCode.up) {
					app.key_up = true
				} else if sym == int(sdl.KeyCode.s) || sym == int(sdl.KeyCode.down) {
					app.key_down = true
				} else if sym == int(sdl.KeyCode.space) || sym == int(sdl.KeyCode.j) {
					app.key_fire = true
				} else if sym == int(sdl.KeyCode.r) {
					app.reset_game()
				} else if sym == int(sdl.KeyCode.p) {
					app.game.paused = !app.game.paused
				} else if sym == int(sdl.KeyCode.o) {
					enabled := app.sound_mgr.toggle_sound()
					app.btn_sound.text = if enabled { 'SOUND: ON [O]' } else { 'SOUND: OFF [O]' }
				}
			}
			.keyup {
				sym := ev.key.keysym.sym
				if sym == int(sdl.KeyCode.a) || sym == int(sdl.KeyCode.left) {
					app.key_left = false
				} else if sym == int(sdl.KeyCode.d) || sym == int(sdl.KeyCode.right) {
					app.key_right = false
				} else if sym == int(sdl.KeyCode.w) || sym == int(sdl.KeyCode.up) {
					app.key_up = false
				} else if sym == int(sdl.KeyCode.s) || sym == int(sdl.KeyCode.down) {
					app.key_down = false
				} else if sym == int(sdl.KeyCode.space) || sym == int(sdl.KeyCode.j) {
					app.key_fire = false
				}
			}
			.mousemotion {
				app.mouse_x = ev.motion.x
				app.mouse_y = ev.motion.y
			}
			.mousebuttondown {
				mx := ev.button.x
				my := ev.button.y
				if app.btn_restart.contains(mx, my) {
					app.reset_game()
				} else if app.btn_sound.contains(mx, my) {
					enabled := app.sound_mgr.toggle_sound()
					app.btn_sound.text = if enabled { 'SOUND: ON [O]' } else { 'SOUND: OFF [O]' }
				} else if app.btn_pause.contains(mx, my) {
					app.game.paused = !app.game.paused
				}
			}
			else {}
		}
	}
	return true
}

fn (mut app App) run() {
	if !app.init_sdl() {
		return
	}

	mut last_ticks := sdl.get_ticks()

	for {
		if !app.handle_events() {
			break
		}

		current_ticks := sdl.get_ticks()
		dt := f64(current_ticks - last_ticks) / 1000.0
		last_ticks = current_ticks

		// Clamp dt to avoid huge jumps on lag
		clamped_dt := if dt > 0.05 { 0.05 } else { dt }

		// Handle continuous keyboard input
		mut dx := 0.0
		mut dy := 0.0
		if app.key_left { dx -= 1.0 }
		if app.key_right { dx += 1.0 }
		if app.key_up { dy -= 1.0 }
		if app.key_down { dy += 1.0 }

		if dx != 0.0 || dy != 0.0 {
			app.game.move_player(dx, dy, clamped_dt)
		}

		if app.key_fire {
			app.game.player_fire(&app.sound_mgr)
		}

		app.game.update(clamped_dt, &app.sound_mgr)
		app.sound_mgr.update_bgm(!app.game.game_over && !app.game.paused)
		render_game(app.renderer, &app.game, app.mouse_x, app.mouse_y, app.btn_restart, app.btn_sound, app.btn_pause)
	}

	if app.game.sprite_texture != unsafe { nil } {
		sdl.destroy_texture(app.game.sprite_texture)
	}
	app.sound_mgr.cleanup()
	sdl.destroy_renderer(app.renderer)
	sdl.destroy_window(app.window)
	sdl.quit()
}

fn main() {
	if os.args.contains("--snapshot") || os.args.contains("--snap") || os.getenv("SNAPSHOT") == "1" {
		if sdl.init(sdl.init_video) != 0 { return }
		defer { sdl.quit() }
		surface := sdl.create_rgb_surface(0, 800, 700, 32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000)
		s_renderer := sdl.create_software_renderer(surface)
		mut app := new_app()
		app.game.init_textures(s_renderer)
		app.game.score = 7850
		app.game.high_score = 25000
		app.game.wave = 3

		// Setup spider & scorpion
		app.game.spiders << Spider{
			x: 320.0
			y: 520.0
			dir_x: 1.0
			dir_y: -1.0
			speed: 140.0
			active: true
		}
		app.game.scorpions << Scorpion{
			row: 14
			x: 240.0
			dir_x: 1.0
			speed: 160.0
			active: true
		}
		// Setup powerup & lasers
		app.game.powerups << DroppedPowerUp{
			x: 420.0
			y: 460.0
			ptype: .triple_spread
			active: true
		}
		app.game.lasers << Laser{
			x: 400.0
			y: 540.0
			dx: 0.0
			dy: -600.0
			is_plasma: false
			active: true
		}
		app.game.lasers << Laser{
			x: 390.0
			y: 540.0
			dx: -120.0
			dy: -580.0
			is_plasma: false
			active: true
		}
		app.game.lasers << Laser{
			x: 410.0
			y: 540.0
			dx: 120.0
			dy: -580.0
			is_plasma: false
			active: true
		}

		render_game(s_renderer, &app.game, 0, 0, app.btn_restart, app.btn_sound, app.btn_pause)
		sdl.save_bmp(surface, 'screenshots/centipede.bmp'.str)
		if app.game.sprite_texture != unsafe { nil } {
			sdl.destroy_texture(app.game.sprite_texture)
		}
		sdl.destroy_renderer(s_renderer)
		sdl.free_surface(surface)
		return
	}
	mut app := new_app()
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
