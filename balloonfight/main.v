module main

import os

import sdl

struct App {
mut:
	window    &sdl.Window   = unsafe { nil }
	renderer  &sdl.Renderer = unsafe { nil }
	game      GameEngine
	sound_mgr SoundManager
	p1_left   bool
	p1_right  bool
	p1_flap   bool
	p2_left   bool
	p2_right  bool
	p2_flap   bool
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
	mutable_app.window = sdl.create_window('NES Balloon Fight - 1984 Arcade Recreation'.str,
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
	mutable_app.game.init_textures(mutable_app.renderer)
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
						mutable_app.p1_left = true
					} else if sym == int(sdl.KeyCode.right) || sym == int(sdl.KeyCode.d) {
						mutable_app.p1_right = true
					} else if sym == int(sdl.KeyCode.up) || sym == int(sdl.KeyCode.w) || sym == int(sdl.KeyCode.space) {
						mutable_app.p1_flap = true
						if mutable_app.game.state == .phase_clear {
							mutable_app.game.state = .playing
							mutable_app.game.setup_stage()
						} else if mutable_app.game.state == .title {
							mutable_app.game.start_game(.mode_a_1p)
						} else if mutable_app.game.state == .game_over {
							mutable_app.game.start_game(.mode_a_1p)
						}
					} else if sym == int(sdl.KeyCode.j) {
						mutable_app.p2_left = true
					} else if sym == int(sdl.KeyCode.l) {
						mutable_app.p2_right = true
					} else if sym == int(sdl.KeyCode.i) || sym == int(sdl.KeyCode.o) {
						mutable_app.p2_flap = true
					} else if sym == int(sdl.KeyCode._1) {
						mutable_app.game.start_game(.mode_a_1p)
					} else if sym == int(sdl.KeyCode._2) {
						mutable_app.game.start_game(.mode_b_2p)
					} else if sym == int(sdl.KeyCode._3) {
						mutable_app.game.start_game(.balloon_trip)
					} else if sym == int(sdl.KeyCode.p) {
						if mutable_app.game.state == .playing {
							mutable_app.game.state = .paused
						} else if mutable_app.game.state == .paused {
							mutable_app.game.state = .playing
						}
					} else if sym == int(sdl.KeyCode.r) {
						mutable_app.game.start_game(mutable_app.game.mode)
					} else if sym == int(sdl.KeyCode.m) {
						mutable_app.sound_mgr.toggle_sound()
					}
				}
				.keyup {
					sym := event.key.keysym.sym
					if sym == int(sdl.KeyCode.left) || sym == int(sdl.KeyCode.a) {
						mutable_app.p1_left = false
					} else if sym == int(sdl.KeyCode.right) || sym == int(sdl.KeyCode.d) {
						mutable_app.p1_right = false
					} else if sym == int(sdl.KeyCode.up) || sym == int(sdl.KeyCode.w) || sym == int(sdl.KeyCode.space) {
						mutable_app.p1_flap = false
					} else if sym == int(sdl.KeyCode.j) {
						mutable_app.p2_left = false
					} else if sym == int(sdl.KeyCode.l) {
						mutable_app.p2_right = false
					} else if sym == int(sdl.KeyCode.i) || sym == int(sdl.KeyCode.o) {
						mutable_app.p2_flap = false
					}
				}
				else {}
			}
		}

		// Update game logic
		mutable_app.game.update(target_dt, mutable_app.p1_left, mutable_app.p1_right,
			mutable_app.p1_flap, mutable_app.p2_left, mutable_app.p2_right, mutable_app.p2_flap,
			&mutable_app.sound_mgr)
		mutable_app.sound_mgr.update_bgm(mutable_app.game.state != .game_over)

		// Render frame
		draw_game(mutable_app.renderer, &mutable_app.game)
		prod_fx_render(mutable_app.renderer)
		sdl.render_present(mutable_app.renderer)
		sdl.delay(16)
	}

	if mutable_app.game.sprite_texture != unsafe { nil } {
		sdl.destroy_texture(mutable_app.game.sprite_texture)
	}
	mutable_app.sound_mgr.cleanup()
	sdl.destroy_renderer(mutable_app.renderer)
	sdl.destroy_window(mutable_app.window)
	sdl.quit()
}

fn main() {
	if os.args.contains("--snapshot") || os.args.contains("--snap") || os.getenv("SNAPSHOT") == "1" {
		if sdl.init(sdl.init_video) != 0 { return }
		defer { sdl.quit() }
		surface := sdl.create_rgb_surface(0, 800, 600, 32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000)
		s_renderer := sdl.create_software_renderer(surface)
		mut game := new_game_engine()
		game.init_textures(s_renderer)
		game.start_game(.mode_a_1p)
		game.score = 6450
		game.phase = 2

		// Position player in flight
		if game.players.len > 0 {
			game.players[0].motion.x = 240.0
			game.players[0].motion.y = 310.0
			game.players[0].balloons = 2
		}

		// Add enemies across ranks
		game.enemies << Enemy{
			id: 10
			rank: .yellow
			motion: MotionState{ x: 420.0, y: 220.0 }
			balloons: 2
			state: .flying
			active: true
		}
		game.enemies << Enemy{
			id: 11
			rank: .pink
			motion: MotionState{ x: 580.0, y: 180.0 }
			balloons: 1
			state: .flying
			active: true
		}
		game.enemies << Enemy{
			id: 12
			rank: .red
			motion: MotionState{ x: 160.0, y: 190.0 }
			balloons: 0
			state: .parachuting
			active: true
		}

		// Activate leaping giant fish
		game.fish.active = true
		game.fish.x = 360.0
		game.fish.y = 510.0

		// Add spark
		game.sparks << Spark{
			x: 650.0
			y: 350.0
			vx: -50.0
			vy: 40.0
			radius: 10.0
		}

		draw_game(s_renderer, &game)
		sdl.save_bmp(surface, 'screenshots/balloonfight.bmp'.str)
		if game.sprite_texture != unsafe { nil } {
			sdl.destroy_texture(game.sprite_texture)
		}
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
