module main

import math
import os
import sdl

const win_w = 780
const win_h = 620

struct App {
mut:
	window    &sdl.Window   = unsafe { nil }
	renderer  &sdl.Renderer = unsafe { nil }
	game      BubbleShooterGame
	sound_mgr SoundManager
	particles []PopParticle
}

fn new_app() App {
	return App{
		game:      new_bubbleshooter_game()
		sound_mgr: new_sound_manager()
	}
}

fn main() {
	if sdl.init(sdl.init_video | sdl.init_audio | sdl.init_events | sdl.init_timer) < 0 {
		eprintln('Failed to initialize SDL2')
		return
	}
	defer { sdl.quit() }

	if os.args.contains('--snap') {
		surface := sdl.create_rgb_surface(0, win_w, win_h, 32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000)
		if unsafe { surface == nil } { return }
		defer { sdl.free_surface(surface) }

		renderer := sdl.create_software_renderer(surface)
		if unsafe { renderer == nil } { return }
		defer { sdl.destroy_renderer(renderer) }
	sdl.render_set_logical_size(renderer, win_w, win_h)

		mut snap_game := new_bubbleshooter_game()
		snap_game.score = 4800
		snap_game.aim_angle = math.pi * 0.58 // slight left tilt

		// Setup colorful board with some clusters
		snap_game.grid[0] = [1, 1, 2, 2, 3, 3, 4, 4]
		snap_game.grid[1] = [1, 2, 2, 3, 3, 4, 4, 0]
		snap_game.grid[2] = [5, 5, 2, 6, 6, 1, 1, 3]
		snap_game.grid[3] = [5, 6, 6, 1, 1, 3, 3, 0]
		snap_game.grid[4] = [0, 5, 6, 0, 0, 1, 0, 0]
		snap_game.current_color = 2
		snap_game.next_color = 6

		render_bubbleshooter_game(renderer, &snap_game, win_w, win_h, []PopParticle{}, unsafe { nil })
		bmp_path := 'screenshots/bubbleshooter.bmp'
		sdl.save_bmp(surface, bmp_path.str)
		return
	}

	mut app := new_app()

	window := sdl.create_window(
		'Bubble Shooter Pro - Puzzle Bobble Arcade'.str,
		sdl.windowpos_centered,
		sdl.windowpos_centered,
		win_w,
		win_h,
		u32(sdl.WindowFlags.shown) | u32(sdl.WindowFlags.fullscreen_desktop) | u32(sdl.WindowFlags.resizable)
	)
	if unsafe { window == nil } {
		eprintln('Failed to create SDL window')
		return
	}
	defer { sdl.destroy_window(window) }

	renderer := sdl.create_renderer(window, -1, u32(sdl.RendererFlags.accelerated) | u32(sdl.RendererFlags.presentvsync))
	if unsafe { renderer == nil } {
		eprintln('Failed to create SDL renderer')
		return
	}
	defer { sdl.destroy_renderer(renderer) }
	sdl.render_set_logical_size(renderer, win_w, win_h)

	mut tex_mgr := BubbleShooterTextureManager{}
	tex_mgr.init(renderer)

	app.window = window
	app.renderer = renderer

	mut event := sdl.Event{}
	mut running := true
	mut last_ticks := sdl.get_ticks()

	for running {
		now := sdl.get_ticks()
		dt := math.min(f64(now - last_ticks) / 1000.0, 0.05)
		last_ticks = now

		update_pop_particles(mut app.particles, dt)

		for sdl.poll_event(&event) != 0 {
			match event.@type {
				.quit {
					running = false
				}
				.mousemotion {
					if app.game.state == .aiming {
						launcher_x := app.game.arena_x + app.game.arena_w / 2.0
						launcher_y := app.game.arena_y + app.game.arena_h - 30.0
						dx := f64(event.motion.x) - launcher_x
						dy := launcher_y - f64(event.motion.y)
						if dy > 5.0 {
							angle := math.atan2(dy, dx)
							app.game.aim_angle = math.clamp(angle, 0.25, math.pi - 0.25)
						}
					}
				}
				.mousebuttondown {
					if event.button.button == sdl.button_left {
						if app.game.state == .aiming {
							if app.game.shoot() {
								app.sound_mgr.play_shoot_sound()
							}
						} else if app.game.state == .won || app.game.state == .game_over {
							app.game.reset_game()
						}
					}
				}
				.keydown {
					sym := int(event.key.keysym.sym)
					if sym == int(sdl.KeyCode.f11) {
						toggle_fullscreen(window)
					} else if sym == int(sdl.KeyCode.escape) {
						running = false
					} else if sym == int(sdl.KeyCode.r) {
						app.game.reset_game()
					} else if sym == int(sdl.KeyCode.s) {
						app.sound_mgr.toggle_sound()
					} else if sym == int(sdl.KeyCode.space) {
						if app.game.state == .aiming {
							if app.game.shoot() {
								app.sound_mgr.play_shoot_sound()
							}
						} else if app.game.state == .won || app.game.state == .game_over {
							app.game.reset_game()
						}
					} else if sym == int(sdl.KeyCode.left) || sym == int(sdl.KeyCode.a) {
						app.game.aim_angle = math.min(math.pi - 0.25, app.game.aim_angle + 0.08)
					} else if sym == int(sdl.KeyCode.right) || sym == int(sdl.KeyCode.d) {
						app.game.aim_angle = math.max(0.25, app.game.aim_angle - 0.08)
					}
				}
				else {}
			}
		}

		ev := app.game.update(dt)
		if ev.bounced {
			app.sound_mgr.play_bounce_sound()
		}
		if ev.popped_count > 0 {
			app.sound_mgr.play_pop_sound(ev.popped_count)
			main_col, _, _ := get_bubble_theme_colors(app.game.current_color)
			app.particles << create_pop_particles(app.game.projectile.x, app.game.projectile.y, main_col)
		}
		if ev.dropped_count > 0 {
			app.sound_mgr.play_drop_sound()
		}
		if ev.won {
			app.sound_mgr.play_win_sound()
		} else if ev.game_over {
			app.sound_mgr.play_game_over_sound()
		}

		render_bubbleshooter_game(app.renderer, &app.game, win_w, win_h, app.particles, tex_mgr.sprite_texture)
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
