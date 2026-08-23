module main

import math
import os
import sdl

struct App {
mut:
	window      &sdl.Window   = unsafe { nil }
	renderer    &sdl.Renderer = unsafe { nil }
	game        SlotsGame
	sound_mgr   SoundManager
	tex_mgr     SlotsTextureManager
}

fn new_app() App {
	return App{
		game:      new_slots_game()
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
	mutable_app.window = sdl.create_window('Vegas Jackpot Slots - 777 & Neon Cyber'.str,
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
	mutable_app.tex_mgr.init(mutable_app.renderer)

	sdl.set_render_draw_blend_mode(mutable_app.renderer, .blend)
	return true
}

fn (app &App) run() {
	mut mutable_app := unsafe { &App(app) }
	mut event := sdl.Event{}
	mut last_ticks := sdl.get_ticks()
	mut running := true

	for running {
		if os.getenv('SNAPSHOT') == '1' || os.args.contains('--snap') || os.args.contains('--snapshot') {
			surface := sdl.create_rgb_surface(0, 800, 600, 32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000)
			if unsafe { surface != nil } {
				sw_rend := sdl.create_software_renderer(surface)
				if unsafe { sw_rend != nil } {
					mutable_app.tex_mgr.init(sw_rend)
					mutable_app.game.balance = 2450
					mutable_app.game.last_win = 250
					mutable_app.game.winning_lines << WinningLine{
						line_idx: 0
						symbol: .seven
						count: 3
						payout: 250
						positions: [CellPos{ reel: 0, row: 1 }, CellPos{ reel: 1, row: 1 }, CellPos{ reel: 2, row: 1 }]
					}
					draw_slots_game(sw_rend, &mutable_app.game, mutable_app.tex_mgr.sprite_texture)
					sdl.save_bmp(surface, 'screenshots/slots.bmp'.str)
					sdl.destroy_renderer(sw_rend)
				}
				sdl.free_surface(surface)
			}
			break
		}

		current_ticks := sdl.get_ticks()
		raw_dt := f64(current_ticks - last_ticks) / 1000.0
		last_ticks = current_ticks
		dt := math.min(0.033, if raw_dt > 0.001 { raw_dt } else { 1.0 / 60.0 })

		for sdl.poll_event(&event) != 0 {
			match unsafe { event.type } {
				.quit {
					running = false
				}
				.mousebuttondown {
					if event.button.button == u8(sdl.button_left) {
						mx := event.button.x
						my := event.button.y

						// Click Lever Handle on right
						if mx >= 690 && mx <= 770 && my >= 200 && my <= 400 {
							mutable_app.game.pull_lever(mut mutable_app.sound_mgr)
						}
						// Click Spin Button
						else if mx >= 550 && mx <= 660 && my >= 490 && my <= 520 {
							mutable_app.game.pull_lever(mut mutable_app.sound_mgr)
						}
						// Click Hold Buttons (3-reel mode)
						else if mutable_app.game.theme == .vegas_classic && my >= 170 && my <= 410 {
							rx := int(mutable_app.game.grid_x)
							rw := int(mutable_app.game.reel_w)
							for r := 0; r < 3; r++ {
								if mx >= rx + r * rw && mx < rx + (r + 1) * rw {
									mutable_app.game.toggle_hold(r)
								}
							}
						}
					}
				}
				.keydown {
					sym := event.key.keysym.sym
					if sym == int(sdl.KeyCode.f11) {
						toggle_fullscreen(mutable_app.window)
					} else if sym == int(sdl.KeyCode.escape) {
						if mutable_app.game.show_paytable {
							mutable_app.game.show_paytable = false
						} else {
							running = false
						}
					} else if sym == int(sdl.KeyCode.space) || sym == int(sdl.KeyCode.return) {
						mutable_app.game.pull_lever(mut mutable_app.sound_mgr)
					} else if sym == int(sdl.KeyCode.tab) || sym == int(sdl.KeyCode.p) {
						mutable_app.game.show_paytable = !mutable_app.game.show_paytable
					} else if sym == int(sdl.KeyCode.t) {
						// Toggle theme between 3-Reel Vegas and 5-Reel Cyber
						new_th := if mutable_app.game.theme == .vegas_classic { SlotTheme.neon_cyber } else { SlotTheme.vegas_classic }
						mutable_app.game.init_theme(new_th)
					} else if sym == int(sdl.KeyCode.up) || sym == int(sdl.KeyCode.w) {
						mutable_app.game.adjust_bet(5)
					} else if sym == int(sdl.KeyCode.down) || sym == int(sdl.KeyCode.s) {
						mutable_app.game.adjust_bet(-5)
					} else if sym == int(sdl.KeyCode.right) || sym == int(sdl.KeyCode.d) {
						mutable_app.game.adjust_lines(1)
					} else if sym == int(sdl.KeyCode.left) || sym == int(sdl.KeyCode.a) {
						mutable_app.game.adjust_lines(-1)
					} else if sym == int(sdl.KeyCode.m) {
						mutable_app.game.max_bet()
					} else if sym == int(sdl.KeyCode.c) {
						mutable_app.game.add_credits(500)
						mutable_app.sound_mgr.play_coin_payout()
					} else if sym == int(sdl.KeyCode.s) {
						mutable_app.sound_mgr.toggle_sound()
					} else if sym == int(sdl.KeyCode._1) {
						mutable_app.game.toggle_hold(0)
					} else if sym == int(sdl.KeyCode._2) {
						mutable_app.game.toggle_hold(1)
					} else if sym == int(sdl.KeyCode._3) {
						mutable_app.game.toggle_hold(2)
					}
				}
				else {}
			}
		}

		mutable_app.game.update(dt, mut mutable_app.sound_mgr)
		mutable_app.sound_mgr.update_bgm(true)

		draw_slots_game(mutable_app.renderer, &mutable_app.game, mutable_app.tex_mgr.sprite_texture)
		prod_fx_render(mutable_app.renderer)
		sdl.render_present(mutable_app.renderer)
		sdl.delay(1)
	}

	sdl.destroy_renderer(mutable_app.renderer)
	sdl.destroy_window(mutable_app.window)
	sdl.quit()
}

fn main() {
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
