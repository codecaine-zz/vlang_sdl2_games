module main

import math
import os
import sdl

const win_w = 920
const win_h = 660

struct App {
mut:
	window    &sdl.Window   = unsafe { nil }
	renderer  &sdl.Renderer = unsafe { nil }
	game      YahtzeeGame
	sound_mgr SoundManager
	tex_mgr   YahtzeeTextureManager
	mouse_x   int
	mouse_y   int
}

fn new_app() App {
	return App{
		game:      new_yahtzee_game()
		sound_mgr: new_sound_manager()
		tex_mgr:   YahtzeeTextureManager{}
	}
}

fn main() {
	if sdl.init(sdl.init_video | sdl.init_audio | sdl.init_events | sdl.init_timer) < 0 {
		eprintln('Failed to initialize SDL2')
		return
	}
	defer { sdl.quit() }

	// Snapshot mode for README showcase
	if os.args.contains('--snap') {
		surface := sdl.create_rgb_surface(0, win_w, win_h, 32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000)
		if unsafe { surface == nil } { return }
		defer { sdl.free_surface(surface) }

		renderer := sdl.create_software_renderer(surface)
		if unsafe { renderer == nil } { return }
		defer { sdl.destroy_renderer(renderer) }
	sdl.render_set_logical_size(renderer, win_w, win_h)

		mut snap_game := new_yahtzee_game()
		snap_game.players[0].scores[Category.ones.str()] = 3
		snap_game.players[0].scores[Category.twos.str()] = 6
		snap_game.players[0].scores[Category.threes.str()] = 9
		snap_game.players[0].scores[Category.full_house.str()] = 25
		snap_game.players[0].scores[Category.small_straight.str()] = 30
		snap_game.dice[0].value = 5
		snap_game.dice[1].value = 5
		snap_game.dice[2].value = 5
		snap_game.dice[3].value = 5
		snap_game.dice[4].value = 5
		snap_game.dice[0].held = true
		snap_game.dice[1].held = true
		snap_game.dice[2].held = true
		snap_game.dice[3].held = true
		snap_game.dice[4].held = true
		snap_game.rolls_left = 1
		snap_game.round = 6

		render_yahtzee_game(renderer, mut snap_game, win_w, win_h, 0, 0, true, unsafe { nil })
		sdl.save_bmp(surface, 'screenshots/yahtzee.bmp'.str)
		return
	}

	mut app := new_app()

	window := sdl.create_window(
		'Yahtzee Deluxe - 16-Bit Casino Dice Game'.str,
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

	app.window = window
	app.renderer = renderer
	app.tex_mgr.init(renderer)

	mut event := sdl.Event{}
	mut running := true
	mut last_ticks := sdl.get_ticks()

	for running {
		now := sdl.get_ticks()
		dt := math.min(f64(now - last_ticks) / 1000.0, 0.05)
		last_ticks = now

		for sdl.poll_event(&event) != 0 {
			match event.@type {
				.quit {
					running = false
				}
				.mousemotion {
					app.mouse_x = int(event.motion.x)
					app.mouse_y = int(event.motion.y)
				}
				.mousebuttondown {
					mx := int(event.button.x)
					my := int(event.button.y)
					app.mouse_x = mx
					app.mouse_y = my

					if event.button.button == u8(sdl.button_left) {
						// 1. Check Top Sound Toggle Button
						sound_x := win_w - 145
						if mx >= sound_x && mx <= sound_x + 125 && my >= 12 && my <= 38 {
							app.sound_mgr.toggle_sound()
						}

						// 2. Check Mode Selector Tabs
						for i in 0 .. 3 {
							tab_x := 460 + i * 90
							if mx >= tab_x && mx <= tab_x + 80 && my >= 12 && my <= 38 {
								app.game.mode = match i {
									0 { GameMode.solo }
									1 { GameMode.vs_ai }
									else { GameMode.two_player }
								}
								app.game.reset_game()
								app.sound_mgr.play_score_recorded()
							}
						}

						// 3. Check Dice Clicks (Toggle Hold)
						for i, d in app.game.dice {
							half := 32
							dx := int(d.x)
							dy := int(d.y)
							if mx >= dx - half && mx <= dx + half && my >= dy - half && my <= dy + half {
								app.game.toggle_hold(i)
								app.sound_mgr.play_dice_toggle(app.game.dice[i].held)
							}
						}

						// 4. Check Big ROLL DICE Button
						btn_x := 30 + 50
						btn_y := 70 + 570 - 85
						btn_w := 460 - 100
						btn_h := 55
						if mx >= btn_x && mx <= btn_x + btn_w && my >= btn_y && my <= btn_y + btn_h {
							if app.game.roll_dice() {
								app.sound_mgr.play_cup_shake()
							}
						}

						// 5. Check Scorecard Category Clicks
						score_x := 510
						score_y := 70
						score_w := 380
						row_h := 24

						// Upper categories
						mut cur_y := score_y + 30 + 18
						upper_cats := [Category.ones, .twos, .threes, .fours, .fives, .sixes]
						for cat in upper_cats {
							if mx >= score_x && mx <= score_x + score_w && my >= cur_y && my <= cur_y + row_h {
								if app.game.choose_category(cat) {
									app.sound_mgr.play_score_recorded()
								}
							}
							cur_y += row_h
						}

						// Lower categories
						cur_y += row_h * 2 + 4 + 18
						lower_cats := [
							Category.three_of_kind,
							.four_of_kind,
							.full_house,
							.small_straight,
							.large_straight,
							.yahtzee,
							.chance,
						]
						for cat in lower_cats {
							if mx >= score_x && mx <= score_x + score_w && my >= cur_y && my <= cur_y + row_h {
								if app.game.choose_category(cat) {
									app.sound_mgr.play_score_recorded()
								}
							}
							cur_y += row_h
						}
					}
				}
				.keydown {
					sym := int(event.key.keysym.sym)
					match sym {
						int(sdl.KeyCode.f11) {
							toggle_fullscreen(window)
						}
						int(sdl.KeyCode.escape) {
							running = false
						}
						int(sdl.KeyCode.space) {
							if app.game.roll_dice() {
								app.sound_mgr.play_cup_shake()
							}
						}
						int(sdl.KeyCode._1) {
							app.game.toggle_hold(0)
							app.sound_mgr.play_dice_toggle(app.game.dice[0].held)
						}
						int(sdl.KeyCode._2) {
							app.game.toggle_hold(1)
							app.sound_mgr.play_dice_toggle(app.game.dice[1].held)
						}
						int(sdl.KeyCode._3) {
							app.game.toggle_hold(2)
							app.sound_mgr.play_dice_toggle(app.game.dice[2].held)
						}
						int(sdl.KeyCode._4) {
							app.game.toggle_hold(3)
							app.sound_mgr.play_dice_toggle(app.game.dice[3].held)
						}
						int(sdl.KeyCode._5) {
							app.game.toggle_hold(4)
							app.sound_mgr.play_dice_toggle(app.game.dice[4].held)
						}
						int(sdl.KeyCode.r) {
							app.game.reset_game()
						}
						int(sdl.KeyCode.m), int(sdl.KeyCode.o) {
							app.sound_mgr.toggle_sound()
						}
						else {}
					}
				}
				else {}
			}
		}

		app.game.update(dt)

		// Play sound events
		if app.game.sound_event != '' {
			ev := app.game.sound_event
			app.game.sound_event = ''
			match ev {
				'clatter' { app.sound_mgr.play_dice_clatter() }
				'yahtzee' { app.sound_mgr.play_yahtzee_fanfare() }
				'bonus' { app.sound_mgr.play_bonus_fanfare() }
				'score' { app.sound_mgr.play_score_recorded() }
				'win' { app.sound_mgr.play_bonus_fanfare() }
				else {}
			}
		}

		render_yahtzee_game(renderer, mut app.game, win_w, win_h, app.mouse_x, app.mouse_y, app.sound_mgr.enabled, app.tex_mgr.sprite_texture)
		prod_fx_render(renderer)
		sdl.render_present(renderer)
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
