module main

import math
import os
import sdl

struct App {
mut:
	window      &sdl.Window   = unsafe { nil }
	renderer    &sdl.Renderer = unsafe { nil }
	game        TexasGame
	sound_mgr   SoundManager
}

fn new_app() App {
	return App{
		game:      new_texas_game()
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
	mutable_app.window = sdl.create_window('Texas Hold\'em Poker Pro - 4-Player Table'.str,
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
					mutable_app.game.pot = 380
					mutable_app.game.community_cards = [
						Card{ rank: 14, suit: .spades },   // Ace
						Card{ rank: 13, suit: .spades },   // King
						Card{ rank: 12, suit: .spades },   // Queen
						Card{ rank: 11, suit: .spades },   // Jack
						Card{ rank: 7, suit: .diamonds }
					]
					mutable_app.game.players[0].hole_cards = [
						Card{ rank: 10, suit: .spades },   // 10 of Spades -> Royal Flush!
						Card{ rank: 2, suit: .hearts }
					]
					mutable_app.game.stage = .round_over
					mutable_app.game.celebration = 'YOU (P1) WINS $380 WITH ROYAL FLUSH!'
					mutable_app.game.spawn_confetti(400, 240, 50)
					mutable_app.game.spawn_shockwave(400, 240, Color{ r: 255, g: 215, b: 0 })
					mutable_app.game.spawn_floating_text(400, 310, '★ ROYAL FLUSH! +$380 ★', Color{ r: 255, g: 220, b: 50 }, 1)
					draw_texas_game(sw_rend, &mutable_app.game)
					sdl.save_bmp(surface, 'screenshots/texas.bmp'.str)
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
				.keydown {
					sym := event.key.keysym.sym
					if sym == int(sdl.KeyCode.f11) {
						toggle_fullscreen(mutable_app.window)
					} else if sym == int(sdl.KeyCode.escape) {
						running = false
					} else if mutable_app.game.stage == .round_over {
						if sym == int(sdl.KeyCode.space) || sym == int(sdl.KeyCode.return) {
							mutable_app.game.start_new_hand()
						}
					} else if mutable_app.game.current_turn_idx == 0 && !mutable_app.game.players[0].is_folded && !mutable_app.game.players[0].is_all_in {
						if sym == int(sdl.KeyCode.c) || sym == int(sdl.KeyCode.space) || sym == int(sdl.KeyCode.return) {
							mutable_app.game.player_action_check_call(0, mut mutable_app.sound_mgr)
						} else if sym == int(sdl.KeyCode.f) {
							mutable_app.game.player_action_fold(0, mut mutable_app.sound_mgr)
						} else if sym == int(sdl.KeyCode.r) {
							mutable_app.game.player_action_raise(0, mutable_app.game.raise_amount, mut mutable_app.sound_mgr)
						} else if sym == int(sdl.KeyCode.a) {
							all_in_amt := mutable_app.game.players[0].chips + mutable_app.game.players[0].current_bet
							mutable_app.game.player_action_raise(0, all_in_amt, mut mutable_app.sound_mgr)
						} else if sym == int(sdl.KeyCode.up) || sym == int(sdl.KeyCode.w) {
							max_p := mutable_app.game.players[0].chips + mutable_app.game.players[0].current_bet
							mutable_app.game.raise_amount = math.min(max_p, mutable_app.game.raise_amount + mutable_app.game.big_blind)
						} else if sym == int(sdl.KeyCode.down) || sym == int(sdl.KeyCode.s) {
							mutable_app.game.raise_amount = math.max(mutable_app.game.current_bet + mutable_app.game.big_blind, mutable_app.game.raise_amount - mutable_app.game.big_blind)
						}
					}

					if sym == int(sdl.KeyCode.m) {
						mutable_app.sound_mgr.toggle_sound()
					}
				}
				else {}
			}
		}

		mutable_app.game.update(dt, mut mutable_app.sound_mgr)

		draw_texas_game(mutable_app.renderer, &mutable_app.game)
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
