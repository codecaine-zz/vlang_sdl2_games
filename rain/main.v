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
	window       &sdl.Window   = unsafe { nil }
	renderer     &sdl.Renderer = unsafe { nil }
	game         RainGame
	sound_mgr    SoundManager
	mouse_x      int
	mouse_y      int
	btn_theme    Button
	btn_mode     Button
	btn_preset   Button
	btn_sound    Button
	last_ticks   u32
}

fn new_app() App {
	return App{
		game:      new_rain_game()
		sound_mgr: new_sound_manager()
		btn_theme: Button{
			x:            10
			y:            60
			w:            110
			h:            28
			text:         'THEME [TAB]'
			bg_color:     Color{r: 25, g: 35, b: 55}
			hover_color:  Color{r: 45, g: 65, b: 100}
			text_color:   Color{r: 255, g: 255, b: 255}
			border_color: Color{r: 0, g: 180, b: 255}
		}
		btn_mode:  Button{
			x:            130
			y:            60
			w:            110
			h:            28
			text:         'MODE [B]'
			bg_color:     Color{r: 25, g: 35, b: 55}
			hover_color:  Color{r: 45, g: 65, b: 100}
			text_color:   Color{r: 255, g: 255, b: 255}
			border_color: Color{r: 0, g: 180, b: 255}
		}
		btn_preset: Button{
			x:            250
			y:            60
			w:            110
			h:            28
			text:         'STRESS [5]'
			bg_color:     Color{r: 45, g: 25, b: 55}
			hover_color:  Color{r: 85, g: 45, b: 110}
			text_color:   Color{r: 255, g: 220, b: 100}
			border_color: Color{r: 255, g: 0, b: 180}
		}
		btn_sound: Button{
			x:            370
			y:            60
			w:            110
			h:            28
			text:         'SOUND [M]'
			bg_color:     Color{r: 25, g: 35, b: 55}
			hover_color:  Color{r: 45, g: 65, b: 100}
			text_color:   Color{r: 255, g: 255, b: 255}
			border_color: Color{r: 0, g: 180, b: 255}
		}
	}
}

fn main() {
	if sdl.init(sdl.init_video | sdl.init_events | sdl.init_audio) < 0 {
		eprintln('Failed to initialize SDL')
		return
	}
	defer { sdl.quit() }

	mut app := new_app()
	app.window = sdl.create_window(
		'Monsoon Overdrive - Realistic Rain Simulator & M4 Hardware Benchmark'.str,
		sdl.windowpos_centered,
		sdl.windowpos_centered,
		960,
		640,
		u32(sdl.WindowFlags.shown) | u32(sdl.WindowFlags.fullscreen_desktop) | u32(sdl.WindowFlags.resizable)
	)
	if unsafe { app.window == nil } {
		eprintln('Failed to create SDL Window')
		return
	}
	defer { sdl.destroy_window(app.window) }

	app.renderer = sdl.create_renderer(app.window, -1, u32(int(sdl.RendererFlags.accelerated) | int(sdl.RendererFlags.presentvsync)))
	if unsafe { app.renderer == nil } {
		app.renderer = sdl.create_renderer(app.window, -1, 0)
	}
	if unsafe { app.renderer == nil } {
		eprintln('Failed to create SDL Renderer')
		return
	}
	defer { sdl.destroy_renderer(app.renderer) }
	sdl.render_set_logical_size(app.renderer, 960, 640)

	app.last_ticks = sdl.get_ticks()
	mut running := true

	for running {
		if os.getenv('SNAPSHOT') == '1' {
			surface := sdl.create_rgb_surface(0, 960, 640, 32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000)
			if unsafe { surface != nil } {
				sw_rend := sdl.create_software_renderer(surface)
				if unsafe { sw_rend != nil } {
					app.game.update(0.5)
					render_rain_game(sw_rend, mut app.game)
					sdl.save_bmp(surface, 'screenshots/rain.bmp'.str)
					sdl.destroy_renderer(sw_rend)
				}
				sdl.free_surface(surface)
			}
			break
		}
		now := sdl.get_ticks()
		dt := f64(now - app.last_ticks) / 1000.0
		app.last_ticks = now
		clamped_dt := if dt > 0.1 { 0.1 } else if dt < 0.001 { 0.016 } else { dt }

		ev := sdl.Event{}
		for sdl.poll_event(&ev) != 0 {
			match unsafe { ev.@type } {
				.quit {
					running = false
				}
				.mousemotion {
					motion := unsafe { ev.motion }
					app.mouse_x = motion.x
					app.mouse_y = motion.y
					app.game.umbrella.x = f64(motion.x)
					app.game.umbrella.y = f64(motion.y)
				}
				.mousebuttondown {
					btn := unsafe { ev.button }
					if btn.button == u8(sdl.button_left) {
						if app.btn_theme.contains(btn.x, btn.y) {
							app.game.cycle_theme()
						} else if app.btn_mode.contains(btn.x, btn.y) {
							app.game.mode = match app.game.mode {
								.atmospheric { GameMode.defense }
								.defense { GameMode.benchmark }
								.benchmark { GameMode.atmospheric }
							}
						} else if app.btn_preset.contains(btn.x, btn.y) {
							app.game.set_intensity_preset(5)
						} else if app.btn_sound.contains(btn.x, btn.y) {
							app.sound_mgr.toggle_sound()
						} else {
							// Spawn thunder lightning on click
							app.game.trigger_lightning()
							app.sound_mgr.play_lightning_strike()
						}
					}
				}
				.keydown {
					sym := ev.key.keysym.sym
					if sym == int(sdl.KeyCode.f11) {
						toggle_fullscreen(app.window)
					} else if sym == int(sdl.KeyCode.escape) {
						running = false
					} else if sym == int(sdl.KeyCode.tab) {
						app.game.cycle_theme()
					} else if sym == int(sdl.KeyCode.b) {
						app.game.mode = match app.game.mode {
							.atmospheric { GameMode.defense }
							.defense { GameMode.benchmark }
							.benchmark { GameMode.atmospheric }
						}
					} else if sym == int(sdl.KeyCode.m) {
						app.sound_mgr.toggle_sound()
					} else if sym == int(sdl.KeyCode.r) {
						app.game.init_particle_pools()
					} else if sym == int(sdl.KeyCode._1) {
						app.game.set_intensity_preset(1)
					} else if sym == int(sdl.KeyCode._2) {
						app.game.set_intensity_preset(2)
					} else if sym == int(sdl.KeyCode._3) {
						app.game.set_intensity_preset(3)
					} else if sym == int(sdl.KeyCode._4) {
						app.game.set_intensity_preset(4)
					} else if sym == int(sdl.KeyCode._5) {
						app.game.set_intensity_preset(5)
					} else if sym == int(sdl.KeyCode.up) {
						new_p := app.game.max_drops + 5000
						app.game.set_particle_count(new_p)
					} else if sym == int(sdl.KeyCode.down) {
						new_p := app.game.max_drops - 5000
						app.game.set_particle_count(new_p)
					} else if sym == int(sdl.KeyCode.pageup) || sym == int(sdl.KeyCode.rightbracket) || sym == int(sdl.KeyCode.equals) {
						new_ram := app.game.ram_allocated_mb + 1024
						app.game.allocate_ram_benchmark(new_ram)
					} else if sym == int(sdl.KeyCode.pagedown) || sym == int(sdl.KeyCode.leftbracket) || sym == int(sdl.KeyCode.minus) {
						new_ram := app.game.ram_allocated_mb - 1024
						app.game.allocate_ram_benchmark(new_ram)
					} else if sym == int(sdl.KeyCode.left) {
						app.game.wind_force -= 0.5
					} else if sym == int(sdl.KeyCode.right) {
						app.game.wind_force += 0.5
					}
				}
				else {}
			}
		}

		// Update physics
		app.game.update(clamped_dt)

		// Audio Patter Update
		if app.game.rain_intensity > 0.2 {
			app.sound_mgr.play_rain_patter(app.game.rain_intensity)
		}

		// Render Frame
		render_rain_game(app.renderer, mut app.game)

		// Draw Buttons
		app.btn_theme.draw(app.renderer, app.mouse_x, app.mouse_y)
		app.btn_mode.draw(app.renderer, app.mouse_x, app.mouse_y)
		app.btn_preset.draw(app.renderer, app.mouse_x, app.mouse_y)
		prod_fx_render(app.renderer)
		sdl.render_present(app.renderer)

		frame_time := sdl.get_ticks() - now
		if frame_time < 16 {
			sdl.delay(u32(16 - frame_time))
		}
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
