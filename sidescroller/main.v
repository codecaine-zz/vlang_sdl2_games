module main

import os

import sdl

struct App {
mut:
	window        &sdl.Window   = unsafe { nil }
	renderer      &sdl.Renderer = unsafe { nil }
	game          GameEngine
	sound_mgr     SoundManager
	tex_mgr       SidescrollerTextureManager
	key_left      bool
	key_right     bool
	key_up        bool
	key_down      bool
	key_jump      bool
	key_fire      bool
	key_dash      bool
	mouse_down    bool
}

fn new_app() App {
	return App{
		game:      new_game_engine()
		sound_mgr: new_sound_manager()
	}
}

fn (app &App) init() bool {
	if sdl.init(sdl.init_video | sdl.init_audio) < 0 {
		eprintln('Failed to init SDL')
		return false
	}

	mut mutable_app := unsafe { &App(app) }

	window_flags := u32(sdl.WindowFlags.shown) | u32(sdl.WindowFlags.fullscreen_desktop) | u32(sdl.WindowFlags.resizable)
	mutable_app.window = sdl.create_window('Cyberpunk Vanguard - Advanced 2D Side-Scroller'.str,
		sdl.windowpos_centered, sdl.windowpos_centered, 960, 540, window_flags)

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

	sdl.render_set_logical_size(mutable_app.renderer, 960, 540)
	mutable_app.tex_mgr.init(mutable_app.renderer)

	sdl.set_render_draw_blend_mode(mutable_app.renderer, .blend)
	return true
}

fn (app &App) run() {
	mut mutable_app := unsafe { &App(app) }
	mut event := sdl.Event{}
	mut running := true
	target_dt := 1.0 / 60.0

	for running {
		for sdl.poll_event(&event) != 0 {
			match unsafe { event.type } {
				.quit {
					running = false
				}
				.keydown {
					sym := event.key.keysym.sym
					if sym == int(sdl.KeyCode.f11) {
						toggle_fullscreen(mutable_app.window)
					} else if sym == int(sdl.KeyCode.left) || sym == int(sdl.KeyCode.a) {
						mutable_app.key_left = true
					} else if sym == int(sdl.KeyCode.right) || sym == int(sdl.KeyCode.d) {
						mutable_app.key_right = true
					} else if sym == int(sdl.KeyCode.up) || sym == int(sdl.KeyCode.w) {
						mutable_app.key_up = true
						mutable_app.key_jump = true
					} else if sym == int(sdl.KeyCode.down) || sym == int(sdl.KeyCode.s) {
						mutable_app.key_down = true
					} else if sym == int(sdl.KeyCode.space) {
						mutable_app.key_jump = true
						if mutable_app.game.state == .title || mutable_app.game.state == .game_over || mutable_app.game.state == .victory {
							mutable_app.game.start_game()
						} else if mutable_app.game.state == .stage_clear {
							mutable_app.game.state = .playing
						}
					} else if sym == int(sdl.KeyCode.j) || sym == int(sdl.KeyCode.z) {
						mutable_app.key_fire = true
					} else if sym == int(sdl.KeyCode.k) || sym == int(sdl.KeyCode.lshift) || sym == int(sdl.KeyCode.rshift) {
						mutable_app.key_dash = true
					} else if sym == int(sdl.KeyCode.b) {
						mutable_app.game.trigger_emp_bomb(&mutable_app.sound_mgr)
					} else if sym == int(sdl.KeyCode.q) {
						mutable_app.game.switch_weapon(false)
					} else if sym == int(sdl.KeyCode.e) {
						mutable_app.game.switch_weapon(true)
					} else if sym == int(sdl.KeyCode._1) {
						mutable_app.game.set_weapon_by_idx(0)
					} else if sym == int(sdl.KeyCode._2) {
						mutable_app.game.set_weapon_by_idx(1)
					} else if sym == int(sdl.KeyCode._3) {
						mutable_app.game.set_weapon_by_idx(2)
					} else if sym == int(sdl.KeyCode._4) {
						mutable_app.game.set_weapon_by_idx(3)
					} else if sym == int(sdl.KeyCode._5) {
						mutable_app.game.set_weapon_by_idx(4)
					} else if sym == int(sdl.KeyCode._6) {
						mutable_app.game.set_weapon_by_idx(5)
					} else if sym == int(sdl.KeyCode._7) {
						mutable_app.game.set_weapon_by_idx(6)
					} else if sym == int(sdl.KeyCode._8) {
						mutable_app.game.set_weapon_by_idx(7)
					} else if sym == int(sdl.KeyCode.p) {
						if mutable_app.game.state == .playing {
							mutable_app.game.state = .paused
						} else if mutable_app.game.state == .paused {
							mutable_app.game.state = .playing
						}
					} else if sym == int(sdl.KeyCode.r) {
						mutable_app.game.start_game()
					} else if sym == int(sdl.KeyCode.m) {
						mutable_app.sound_mgr.toggle_sound()
					} else if sym == int(sdl.KeyCode.return) {
						if mutable_app.game.state == .title {
							mutable_app.game.start_game()
						}
					}
				}
				.keyup {
					sym := event.key.keysym.sym
					if sym == int(sdl.KeyCode.left) || sym == int(sdl.KeyCode.a) {
						mutable_app.key_left = false
					} else if sym == int(sdl.KeyCode.right) || sym == int(sdl.KeyCode.d) {
						mutable_app.key_right = false
					} else if sym == int(sdl.KeyCode.up) || sym == int(sdl.KeyCode.w) {
						mutable_app.key_up = false
						mutable_app.key_jump = false
					} else if sym == int(sdl.KeyCode.down) || sym == int(sdl.KeyCode.s) {
						mutable_app.key_down = false
					} else if sym == int(sdl.KeyCode.space) {
						mutable_app.key_jump = false
					} else if sym == int(sdl.KeyCode.j) || sym == int(sdl.KeyCode.z) {
						mutable_app.key_fire = false
					} else if sym == int(sdl.KeyCode.k) || sym == int(sdl.KeyCode.lshift) || sym == int(sdl.KeyCode.rshift) {
						mutable_app.key_dash = false
					}
				}
				.mousebuttondown {
					mutable_app.key_fire = true
				}
				.mousebuttonup {
					mutable_app.key_fire = false
				}
				else {}
			}
		}

		// Update game logic
		mutable_app.game.update(target_dt, mutable_app.key_left, mutable_app.key_right,
			mutable_app.key_up, mutable_app.key_down, mutable_app.key_jump, mutable_app.key_fire,
			mutable_app.key_dash, &mutable_app.sound_mgr)

		mutable_app.sound_mgr.update_bgm(mutable_app.game.state == .playing)

		// Render frame
		draw_game(mutable_app.renderer, &mutable_app.game, mutable_app.tex_mgr.sprite_texture)
		prod_fx_render(mutable_app.renderer)
		sdl.render_present(mutable_app.renderer)
		sdl.delay(16)
	}

	sdl.destroy_renderer(mutable_app.renderer)
	sdl.destroy_window(mutable_app.window)
	sdl.quit()
}

fn main() {
	if os.args.contains("--snapshot") || os.args.contains("--snap") || os.getenv("SNAPSHOT") == "1" {
		if sdl.init(sdl.init_video) != 0 { return }
		defer { sdl.quit() }
		surface := sdl.create_rgb_surface(0, 960, 540, 32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000)
		s_renderer := sdl.create_software_renderer(surface)
		mut app := new_app()
		draw_game(s_renderer, &app.game, app.tex_mgr.sprite_texture)
		sdl.save_bmp(surface, 'screenshots/sidescroller.bmp'.str)
		sdl.destroy_renderer(s_renderer)
		sdl.free_surface(surface)
		return
	}
	mut app := new_app()
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
