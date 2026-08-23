module main

import os
import rand
import sdl

struct App {
mut:
	window    &sdl.Window   = unsafe { nil }
	renderer  &sdl.Renderer = unsafe { nil }
	templates []ScreensaverTemplate
	state     ScreensaverState
	gui       GuiState
	sound_mgr SoundManager
}

fn new_app() App {
	return App{
		templates: get_all_templates()
		state: ScreensaverState{}
		gui: GuiState{
			show_menu: false
			show_hud: true
			is_fullscreen: false
			selected_index: 0
			auto_cycle: true
			cycle_interval: 15.0
			show_crt_filter: true
		}
		sound_mgr: new_sound_manager()
	}
}

fn (app &App) init() bool {
	if sdl.init(sdl.init_video | sdl.init_audio) < 0 {
		eprintln('Failed to init SDL')
		return false
	}

	mut mutable_app := unsafe { &App(app) }
	mutable_app.sound_mgr.init()

	window_flags := u32(sdl.WindowFlags.shown) | u32(sdl.WindowFlags.fullscreen_desktop) | u32(sdl.WindowFlags.resizable)
	mutable_app.window = sdl.create_window('The Ultimate Retro Screensaver Emulator (102 Classic Templates)'.str,
		sdl.windowpos_centered, sdl.windowpos_centered, 800, 600, window_flags)

	if mutable_app.window == unsafe { nil } {
		eprintln('Failed to create window')
		return false
	}

	render_flags := u32(sdl.RendererFlags.accelerated) | u32(sdl.RendererFlags.presentvsync)
	mutable_app.renderer = sdl.create_renderer(mutable_app.window, -1, render_flags)

	if mutable_app.renderer == unsafe { nil } {
		eprintln('Failed to create renderer')
		return false
	}

	sdl.render_set_logical_size(mutable_app.renderer, 800, 600)

	sdl.set_render_draw_blend_mode(mutable_app.renderer, .blend)
	return true
}

fn (mut app App) toggle_fullscreen() {
	app.gui.is_fullscreen = !app.gui.is_fullscreen
	if app.gui.is_fullscreen {
		sdl.set_window_fullscreen(app.window, u32(sdl.WindowFlags.fullscreen_desktop))
	} else {
		sdl.set_window_fullscreen(app.window, 0)
	}
}

fn (mut app App) next_screensaver() {
	app.gui.selected_index = (app.gui.selected_index + 1) % app.templates.len
	app.state = ScreensaverState{} // Reset engine state for fresh simulation
	app.gui.cycle_timer = 0
	app.sound_mgr.play_switch()
}

fn (mut app App) prev_screensaver() {
	app.gui.selected_index = (app.gui.selected_index - 1 + app.templates.len) % app.templates.len
	app.state = ScreensaverState{}
	app.gui.cycle_timer = 0
	app.sound_mgr.play_switch()
}

fn (mut app App) random_screensaver() {
	app.gui.selected_index = rand.int_in_range(0, app.templates.len) or { 0 }
	app.state = ScreensaverState{}
	app.gui.cycle_timer = 0
	app.sound_mgr.play_switch()
}

fn (app &App) run() {
	mut mutable_app := unsafe { &App(app) }
	mut event := sdl.Event{}
	mut last_ticks := sdl.get_ticks()
	mut running := true

	for running {
		mut win_w := 800
		mut win_h := 600
		sdl.get_renderer_output_size(mutable_app.renderer, &win_w, &win_h)
		if win_w < 100 { win_w = 800 }
		if win_h < 100 { win_h = 600 }

		if os.getenv('SNAPSHOT') == '1' {
			surface := sdl.create_rgb_surface(0, 800, 600, 32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000)
			if unsafe { surface != nil } {
				sw_rend := sdl.create_software_renderer(surface)
				if unsafe { sw_rend != nil } {
					draw_screensaver_scene(sw_rend, mutable_app.templates, mut mutable_app.state, mut mutable_app.gui, 800, 600)
					os.mkdir_all('screenshots') or {}
					sdl.save_bmp(surface, 'screenshots/screensaver.bmp'.str)
					sdl.destroy_renderer(sw_rend)
				}
				sdl.free_surface(surface)
			}
			break
		}

		current_ticks := sdl.get_ticks()
		dt := f64(current_ticks - last_ticks) / 1000.0
		last_ticks = current_ticks
		clamped_dt := if dt > 0.1 { 0.1 } else { dt }

		mutable_app.state.time_elapsed += clamped_dt
		mutable_app.state.frame_count++

		// Auto cycle timer
		if mutable_app.gui.auto_cycle && !mutable_app.gui.show_menu {
			mutable_app.gui.cycle_timer += clamped_dt
			if mutable_app.gui.cycle_timer >= mutable_app.gui.cycle_interval {
				mutable_app.next_screensaver()
			}
		}

		for sdl.poll_event(&event) != 0 {
			match unsafe { event.type } {
				.quit {
					running = false
				}
				.mousemotion {
					mutable_app.state.mouse_x = event.motion.x
					mutable_app.state.mouse_y = event.motion.y
				}
				.mousebuttondown {
					if event.button.button == u8(sdl.button_left) {
						mutable_app.state.mouse_down = true
						mutable_app.state.mouse_x = event.button.x
						mutable_app.state.mouse_y = event.button.y
					} else if event.button.button == u8(sdl.button_right) {
						mutable_app.state.mouse_right_down = true
					}
				}
				.mousebuttonup {
					if event.button.button == u8(sdl.button_left) {
						mutable_app.state.mouse_down = false
					} else if event.button.button == u8(sdl.button_right) {
						mutable_app.state.mouse_right_down = false
					}
				}
				.keydown {
					sym := event.key.keysym.sym
					if sym == int(sdl.KeyCode.escape) {
						if mutable_app.gui.show_menu {
							mutable_app.gui.show_menu = false
						} else {
							running = false
						}
					} else if sym == int(sdl.KeyCode.f) || sym == int(sdl.KeyCode.f11) {
						mutable_app.toggle_fullscreen()
					} else if sym == int(sdl.KeyCode.h) {
						// Toggle HUD on / off
						mutable_app.gui.show_hud = !mutable_app.gui.show_hud
						if !mutable_app.gui.show_hud {
							mutable_app.gui.show_menu = false
						}
					} else if sym == int(sdl.KeyCode.tab) || sym == int(sdl.KeyCode.f1) {
						mutable_app.gui.show_menu = !mutable_app.gui.show_menu
						if mutable_app.gui.show_menu {
							mutable_app.gui.show_hud = true
						}
					} else if sym == int(sdl.KeyCode.c) {
						mutable_app.gui.auto_cycle = !mutable_app.gui.auto_cycle
					} else if sym == int(sdl.KeyCode.v) {
						mutable_app.gui.show_crt_filter = !mutable_app.gui.show_crt_filter
					} else if sym == int(sdl.KeyCode.m) {
						mutable_app.sound_mgr.toggle_sound()
					} else if sym == int(sdl.KeyCode.r) {
						mutable_app.random_screensaver()
					} else if sym == int(sdl.KeyCode.right) || sym == int(sdl.KeyCode.n) || sym == int(sdl.KeyCode.rightbracket) {
						mutable_app.next_screensaver()
					} else if sym == int(sdl.KeyCode.left) || sym == int(sdl.KeyCode.p) || sym == int(sdl.KeyCode.leftbracket) {
						mutable_app.prev_screensaver()
					} else if sym == int(sdl.KeyCode.up) {
						if mutable_app.gui.show_menu {
							if mutable_app.gui.selected_index > 0 {
								mutable_app.gui.selected_index--
								if mutable_app.gui.selected_index < mutable_app.gui.scroll_offset {
									mutable_app.gui.scroll_offset = mutable_app.gui.selected_index
								}
							}
						}
					} else if sym == int(sdl.KeyCode.down) {
						if mutable_app.gui.show_menu {
							if mutable_app.gui.selected_index < mutable_app.templates.len - 1 {
								mutable_app.gui.selected_index++
								if mutable_app.gui.selected_index >= mutable_app.gui.scroll_offset + 12 {
									mutable_app.gui.scroll_offset = mutable_app.gui.selected_index - 11
								}
							}
						}
					} else if sym == int(sdl.KeyCode.return) {
						if mutable_app.gui.show_menu {
							mutable_app.gui.show_menu = false
							mutable_app.state = ScreensaverState{}
							mutable_app.sound_mgr.play_switch()
						}
					}
				}
				else {}
			}
		}

		sdl.set_render_draw_color(mutable_app.renderer, 0, 0, 0, 255)
		sdl.render_clear(mutable_app.renderer)
		draw_screensaver_scene(mutable_app.renderer, mutable_app.templates, mut mutable_app.state, mut mutable_app.gui, win_w, win_h)
		prod_fx_render(mutable_app.renderer)
		sdl.render_present(mutable_app.renderer)
		sdl.delay(16)
	}

	if mutable_app.renderer != unsafe { nil } {
		sdl.destroy_renderer(mutable_app.renderer)
	}
	if mutable_app.window != unsafe { nil } {
		sdl.destroy_window(mutable_app.window)
	}
	sdl.quit()
}

fn main() {
	app := new_app()
	if app.init() {
		app.run()
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
