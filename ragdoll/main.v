module main

import os

import sdl

struct Button {
	x            int
	y            int
	w            int
	h            int
	text         string
	bg_color     Color
	hover_color  Color
	text_color   Color
	border_color Color
}

fn (b &Button) contains(px int, py int) bool {
	return px >= b.x && px <= b.x + b.w && py >= b.y && py <= b.y + b.h
}

fn (b &Button) draw(renderer &sdl.Renderer, mouse_x int, mouse_y int) {
	is_hover := b.contains(mouse_x, mouse_y)
	c := if is_hover { b.hover_color } else { b.bg_color }
	sdl.set_render_draw_color(renderer, c.r, c.g, c.b, 255)
	rect := sdl.Rect{
		x: b.x
		y: b.y
		w: b.w
		h: b.h
	}
	sdl.render_fill_rect(renderer, &rect)

	sdl.set_render_draw_color(renderer, b.border_color.r, b.border_color.g, b.border_color.b, 255)
	sdl.render_draw_rect(renderer, &rect)

	draw_text_centered(renderer, b.x + b.w / 2, b.y + (b.h - 16) / 2, b.text, 1, b.text_color)
}

struct App {
mut:
	window        &sdl.Window   = unsafe { nil }
	renderer      &sdl.Renderer = unsafe { nil }
	game          RagdollGame
	sound_mgr     SoundManager
	mouse_x       int
	mouse_y       int
	mouse_down    bool
	mouse_clicked bool
	paused        bool
	btn_restart   Button
	btn_sound     Button
}

fn new_app() App {
	return App{
		game:        new_ragdoll_game()
		sound_mgr:   new_sound_manager()
		btn_restart: Button{
			x:            675
			y:            560
			w:            110
			h:            32
			text:         'RESET [R]'
			bg_color:     Color{r: 35, g: 25, b: 45}
			hover_color:  Color{r: 65, g: 45, b: 85}
			text_color:   Color{r: 255, g: 255, b: 255}
			border_color: Color{r: 140, g: 70, b: 180}
		}
		btn_sound:   Button{
			x:            575
			y:            560
			w:            90
			h:            32
			text:         'SOUND [S]'
			bg_color:     Color{r: 25, g: 35, b: 55}
			hover_color:  Color{r: 45, g: 60, b: 90}
			text_color:   Color{r: 255, g: 255, b: 255}
			border_color: Color{r: 70, g: 90, b: 140}
		}
	}
}

fn main() {
	if sdl.init(sdl.init_video | sdl.init_audio | sdl.init_events) < 0 {
		eprintln('Failed to init SDL')
		return
	}
	defer { sdl.quit() }

	if os.args.contains('--snapshot') || os.args.contains('--snap') || os.getenv('SNAPSHOT') == '1' {
		surface := sdl.create_rgb_surface(0, 800, 600, 32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000)
		s_renderer := sdl.create_software_renderer(surface)
		mut app := new_app()
		app.game.update(0.1, 400, 300, false, false)
		app.game.render(s_renderer, 400, 300)
		app.btn_restart.draw(s_renderer, 0, 0)
		app.btn_sound.draw(s_renderer, 0, 0)
		sdl.save_bmp(surface, 'screenshots/ragdoll.bmp'.str)
		sdl.destroy_renderer(s_renderer)
		sdl.free_surface(surface)
		return
	}

	window := sdl.create_window(
		'Advanced Ragdoll Physics Playground'.str,
		sdl.windowpos_centered,
		sdl.windowpos_centered,
		800,
		600,
		u32(sdl.WindowFlags.shown) | u32(sdl.WindowFlags.fullscreen_desktop) | u32(sdl.WindowFlags.resizable)
	)
	if unsafe { window == nil } {
		eprintln('Failed to create window')
		return
	}
	defer { sdl.destroy_window(window) }

	renderer := sdl.create_renderer(window, -1, u32(sdl.RendererFlags.accelerated) | u32(sdl.RendererFlags.presentvsync))
	if unsafe { renderer == nil } {
		eprintln('Failed to create renderer')
		return
	}
	defer { sdl.destroy_renderer(renderer) }
	sdl.render_set_logical_size(renderer, 800, 600)

	mut app := new_app()
	app.window = window
	app.renderer = renderer

	mut running := true
	mut event := sdl.Event{}
	mut last_ticks := sdl.get_ticks()

	for running {
		current_ticks := sdl.get_ticks()
		dt := f64(current_ticks - last_ticks) / 1000.0
		last_ticks = current_ticks
		app.mouse_clicked = false

		for sdl.poll_event(&event) != 0 {
			match event.@type {
				.quit {
					running = false
				}
				.mousemotion {
					app.mouse_x = event.motion.x
					app.mouse_y = event.motion.y
				}
				.mousebuttondown {
					app.mouse_down = true
					app.mouse_clicked = true

					// Check button clicks
					if app.btn_restart.contains(app.mouse_x, app.mouse_y) {
						app.game.load_arena(app.game.active_arena)
						app.mouse_clicked = false
					} else if app.btn_sound.contains(app.mouse_x, app.mouse_y) {
						app.sound_mgr.toggle_sound()
						app.mouse_clicked = false
					} else if app.mouse_y <= 48 {
						// Toolbar clicks
						tools := [
							ToolType.grab,
							ToolType.grav_gun,
							ToolType.impulse_blaster,
							ToolType.tether,
							ToolType.spawn_ragdoll,
							ToolType.spawn_barrel,
							ToolType.slice,
							ToolType.bomb,
						]
						for i in 0 .. tools.len {
							bx := 315 + i * 58
							if app.mouse_x >= bx && app.mouse_x <= bx + 54 {
								app.game.active_tool = tools[i]
							}
						}
						app.mouse_clicked = false
					} else if app.mouse_y >= 552 {
						// Arena selection clicks
						arenas := [ArenaType.funhouse, ArenaType.staircase, ArenaType.zero_g]
						for i in 0 .. arenas.len {
							bx := 15 + i * 110
							if app.mouse_x >= bx && app.mouse_x <= bx + 102 {
								app.game.load_arena(arenas[i])
							}
						}
						app.mouse_clicked = false
					}
				}
				.mousebuttonup {
					app.mouse_down = false
				}
				.keydown {
					sym := event.key.keysym.sym
					if sym == int(sdl.KeyCode.f11) {
						toggle_fullscreen(window)
					} else if sym == int(sdl.KeyCode._1) {
						app.game.load_arena(.funhouse)
					} else if sym == int(sdl.KeyCode._2) {
						app.game.load_arena(.staircase)
					} else if sym == int(sdl.KeyCode._3) {
						app.game.load_arena(.zero_g)
					} else if sym == int(sdl.KeyCode.q) {
						app.game.active_tool = .grab
					} else if sym == int(sdl.KeyCode.w) {
						app.game.active_tool = .grav_gun
					} else if sym == int(sdl.KeyCode.e) {
						app.game.active_tool = .impulse_blaster
					} else if sym == int(sdl.KeyCode.t) {
						app.game.active_tool = .tether
					} else if sym == int(sdl.KeyCode.y) {
						app.game.active_tool = .spawn_ragdoll
					} else if sym == int(sdl.KeyCode.u) {
						app.game.active_tool = .spawn_barrel
					} else if sym == int(sdl.KeyCode.i) {
						app.game.active_tool = .slice
					} else if sym == int(sdl.KeyCode.b) {
						app.game.active_tool = .bomb
					} else if sym == int(sdl.KeyCode.r) {
						app.game.load_arena(app.game.active_arena)
					} else if sym == int(sdl.KeyCode.p) {
						app.paused = !app.paused
					} else if sym == int(sdl.KeyCode.g) {
						app.game.gravity = -app.game.gravity
					} else if sym == int(sdl.KeyCode.up) {
						app.game.timescale = if app.game.timescale < 2.0 { app.game.timescale + 0.25 } else { 2.0 }
					} else if sym == int(sdl.KeyCode.down) {
						app.game.timescale = if app.game.timescale > 0.25 { app.game.timescale - 0.25 } else { 0.25 }
					}
				}
				else {}
			}
		}

		if !app.paused {
			app.game.update(dt, app.mouse_x, app.mouse_y, app.mouse_down, app.mouse_clicked)

			// Audio triggers
			if app.game.sound_event_thud { app.sound_mgr.play_thud_sound(app.game.thud_intensity) }
			if app.game.sound_event_crunch { app.sound_mgr.play_crunch_sound() }
			if app.game.sound_event_explosion { app.sound_mgr.play_explosion_sound() }
			if app.game.sound_event_zap { app.sound_mgr.play_gravgun_zap() }
			if app.game.sound_event_boing { app.sound_mgr.play_boing_sound() }
			if app.game.sound_event_bumper { app.sound_mgr.play_bumper_chime() }
			if app.game.sound_event_tether { app.sound_mgr.play_tether_snap() }
		}

		app.game.render(app.renderer, app.mouse_x, app.mouse_y)
		app.btn_restart.draw(app.renderer, app.mouse_x, app.mouse_y)
		app.btn_sound.draw(app.renderer, app.mouse_x, app.mouse_y)

		prod_fx_render(app.renderer)
		sdl.render_present(app.renderer)
		sdl.delay(10)
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
