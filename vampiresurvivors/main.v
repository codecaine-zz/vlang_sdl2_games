module main

import math
import os
import sdl

fn main() {
	if sdl.init(sdl.init_video | sdl.init_audio) != 0 {
		println('Failed to init SDL')
		return
	}
	defer {
		sdl.quit()
	}

	mut game := new_game()

	if os.args.contains('--snap') || os.args.contains('--snapshot') || os.getenv('SNAPSHOT') == '1' {
		surface := sdl.create_rgb_surface(0, win_width, win_height, 32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000)
		s_renderer := sdl.create_software_renderer(surface)
		game.init_textures(s_renderer)

		game.start_game(.antonio, .imelda, false)
		game.game_time = 185.0
		game.total_kills = 642
		game.players[0].level = 12
		game.players[0].exp = 78
		game.players[0].exp_next = 120
		game.players[0].gold = 850
		game.players[0].weapons << create_weapon(.bloody_tear)
		game.players[0].weapons << create_weapon(.unholy_vespers)
		game.players[0].passives << Passive{kind: .spinach, level: 3}
		game.players[0].passives << Passive{kind: .duplicator, level: 1}

		p_x := game.players[0].x
		p_y := game.players[0].y

		// Surrounding swarm
		for i in 0 .. 20 {
			ang := f64(i) * 0.314
			d := 110.0 + f64(i % 4) * 35.0
			sx := p_x + math.cos(ang) * d
			sy := p_y + math.sin(ang) * d
			game.enemies << create_enemy(if i % 4 == 0 { .werewolf } else if i % 4 == 1 { .red_skull } else if i % 4 == 2 { .zombie } else { .skeleton }, sx, sy, false)
		}
		game.enemies << create_enemy(.reaper_boss, p_x + 220.0, p_y - 80.0, true)

		// Floor items & Breakables
		game.breakables << BreakableProp{x: p_x - 120.0, y: p_y - 80.0, hp: 1.0, is_urn: false}
		game.breakables << BreakableProp{x: p_x + 140.0, y: p_y + 90.0, hp: 1.0, is_urn: true}
		game.floor_pickups << FloorPickup{kind: .vacuum_orb, x: p_x - 60.0, y: p_y - 45.0}
		game.floor_pickups << FloorPickup{kind: .floor_chicken, x: p_x + 55.0, y: p_y + 40.0}

		// Exp gems
		game.gems << ExpGem{kind: .blue, x: p_x - 40.0, y: p_y + 30.0, value: 1}
		game.gems << ExpGem{kind: .green, x: p_x + 70.0, y: p_y - 20.0, value: 5}
		game.gems << ExpGem{kind: .red, x: p_x + 100.0, y: p_y + 60.0, value: 25}

		// Floating damage numbers
		game.dmg_nums << DamageNum{x: p_x + 80.0, y: p_y - 30.0, val: 99, life: 0.8, is_crit: true}
		game.dmg_nums << DamageNum{x: p_x - 70.0, y: p_y + 20.0, val: 45, life: 0.8, is_crit: false}

		game.render(s_renderer)
		os.mkdir_all('screenshots') or {}
		sdl.save_bmp(surface, 'screenshots/vampiresurvivors.bmp'.str)
		sdl.destroy_renderer(s_renderer)
		sdl.free_surface(surface)
		return
	}

	window := sdl.create_window(
		'Vampire Survivors // Gothic Bullet-Hell Horde'.str,
		sdl.windowpos_centered,
		sdl.windowpos_centered,
		win_width,
		win_height,
		u32(sdl.WindowFlags.shown) | u32(sdl.WindowFlags.fullscreen_desktop) | u32(sdl.WindowFlags.resizable)
	)
	if window == unsafe { nil } {
		return
	}
	defer {
		sdl.destroy_window(window)
	}

	renderer := sdl.create_renderer(window, -1, u32(u32(sdl.RendererFlags.accelerated) | u32(sdl.RendererFlags.presentvsync)))
	if renderer == unsafe { nil } {
		return
	}
	defer {
		sdl.destroy_renderer(renderer)
	}
	sdl.render_set_logical_size(renderer, win_width, win_height)
	game.init_textures(renderer)

	mut last_ticks := sdl.get_ticks()

	for {
		ticks := sdl.get_ticks()
		dt := f64(ticks - last_ticks) / 1000.0
		last_ticks = ticks

		// Update Background Music
		is_active := game.state == .playing || game.state == .level_up || game.state == .chest_opened || game.state == .paused
		game.sound_mgr.update_bgm(dt, is_active)

		mut event := sdl.Event{}
		for sdl.poll_event(&event) != 0 {
			match event.@type {
				.quit {
					return
				}
				.keydown {
					sym := int(event.key.keysym.sym)
					if sym == int(sdl.KeyCode.f11) {
						toggle_fullscreen(window)
					} else if sym == int(sdl.KeyCode.escape) {
						if game.state == .playing {
							game.state = .paused
						} else if game.state == .paused {
							game.state = .playing
						} else {
							game.state = .character_select
						}
					}
					// Pause Toggle (P)
					if sym == int(sdl.KeyCode.p) {
						if game.state == .playing {
							game.state = .paused
						} else if game.state == .paused {
							game.state = .playing
						}
					}
					// Speed Toggle (H / F)
					if sym == int(sdl.KeyCode.h) || sym == int(sdl.KeyCode.f) {
						game.cycle_speed()
					}
					// Radar Toggle (Tab)
					if sym == int(sdl.KeyCode.tab) {
						game.show_radar = !game.show_radar
					}
					// Character Selection Screen
					if game.state == .character_select {
						if sym == int(sdl.KeyCode._1) {
							game.start_game(.antonio, .imelda, game.is_coop)
						} else if sym == int(sdl.KeyCode._2) {
							game.start_game(.imelda, .antonio, game.is_coop)
						} else if sym == int(sdl.KeyCode._3) {
							game.start_game(.pasqualina, .gennaro, game.is_coop)
						} else if sym == int(sdl.KeyCode._4) {
							game.start_game(.gennaro, .pasqualina, game.is_coop)
						} else if sym == int(sdl.KeyCode._5) {
							game.start_game(.mortaccio, .eleanor, game.is_coop)
						} else if sym == int(sdl.KeyCode._6) {
							game.start_game(.eleanor, .mortaccio, game.is_coop)
						} else if sym == int(sdl.KeyCode.c) {
							game.is_coop = !game.is_coop
						} else if sym == int(sdl.KeyCode.d) || sym == int(sdl.KeyCode.k) {
							game.cycle_difficulty()
						} else if sym == int(sdl.KeyCode.m) {
							game.cycle_stage()
						} else if sym == int(sdl.KeyCode.u) {
							game.state = .power_up_shop
						}
					}
					// Power-Up Metaprogression Shop Screen
					else if game.state == .power_up_shop {
						if sym == int(sdl.KeyCode._1) {
							game.buy_powerup('might')
						} else if sym == int(sdl.KeyCode._2) {
							game.buy_powerup('health')
						} else if sym == int(sdl.KeyCode._3) {
							game.buy_powerup('speed')
						} else if sym == int(sdl.KeyCode._4) {
							game.buy_powerup('greed')
						} else if sym == int(sdl.KeyCode._5) {
							game.buy_powerup('growth')
						} else if sym == int(sdl.KeyCode._6) {
							game.buy_powerup('rerolls')
						} else if sym == int(sdl.KeyCode._7) {
							game.buy_powerup('banish')
						} else if sym == int(sdl.KeyCode.u) || sym == int(sdl.KeyCode.escape) {
							game.state = .character_select
						}
					}
					// Level Up Upgrade Screen
					else if game.state == .level_up {
						if sym == int(sdl.KeyCode._1) {
							game.select_upgrade(0)
						} else if sym == int(sdl.KeyCode._2) {
							game.select_upgrade(1)
						} else if sym == int(sdl.KeyCode._3) {
							game.select_upgrade(2)
						} else if sym == int(sdl.KeyCode.r) {
							game.reroll_upgrades(0)
						} else if sym == int(sdl.KeyCode.s) {
							game.skip_upgrade(0)
						} else if sym == int(sdl.KeyCode.b) {
							game.banish_upgrade(0, game.selected_card)
						} else if sym == int(sdl.KeyCode.up) || sym == int(sdl.KeyCode.w) {
							if game.upgrade_cards.len > 0 {
								game.selected_card = (game.selected_card - 1 + game.upgrade_cards.len) % game.upgrade_cards.len
							}
						} else if sym == int(sdl.KeyCode.down) {
							if game.upgrade_cards.len > 0 {
								game.selected_card = (game.selected_card + 1) % game.upgrade_cards.len
							}
						} else if sym == int(sdl.KeyCode.space) || sym == int(sdl.KeyCode.@return) {
							game.select_upgrade(game.selected_card)
						}
					}
					// Chest Reward Screen
					else if game.state == .chest_opened {
						if sym == int(sdl.KeyCode.space) || sym == int(sdl.KeyCode.@return) {
							game.state = .playing
						}
					}
					// Game Over / Victory Screen
					else if game.state == .game_over || game.state == .victory {
						if sym == int(sdl.KeyCode.r) || sym == int(sdl.KeyCode.@return) {
							game.state = .character_select
						}
					}
					// Playing State Abilities
					else if game.state == .playing {
						if sym == int(sdl.KeyCode.lshift) || sym == int(sdl.KeyCode.rshift) {
							game.perform_dash(0)
						} else if sym == int(sdl.KeyCode.space) {
							game.activate_ultimate(0)
						}
					}
					// In-Game Directional Keys Pressed
					if sym == int(sdl.KeyCode.w) {
						game.p1_up = true
					} else if sym == int(sdl.KeyCode.s) {
						game.p1_down = true
					} else if sym == int(sdl.KeyCode.a) {
						game.p1_left = true
					} else if sym == int(sdl.KeyCode.d) {
						game.p1_right = true
					} else if sym == int(sdl.KeyCode.up) {
						if game.is_coop {
							game.p2_up = true
						} else {
							game.p1_up = true
						}
					} else if sym == int(sdl.KeyCode.down) {
						if game.is_coop {
							game.p2_down = true
						} else {
							game.p1_down = true
						}
					} else if sym == int(sdl.KeyCode.left) {
						if game.is_coop {
							game.p2_left = true
						} else {
							game.p1_left = true
						}
					} else if sym == int(sdl.KeyCode.right) {
						if game.is_coop {
							game.p2_right = true
						} else {
							game.p1_right = true
						}
					}
					// Common Shortcuts
					if sym == int(sdl.KeyCode.t) || sym == int(sdl.KeyCode.b) {
						game.sound_mgr.cycle_bgm()
					} else if sym == int(sdl.KeyCode.m) {
						game.sound_mgr.toggle_sound()
					}
				}
				.keyup {
					sym := int(event.key.keysym.sym)
					if sym == int(sdl.KeyCode.w) {
						game.p1_up = false
					} else if sym == int(sdl.KeyCode.s) {
						game.p1_down = false
					} else if sym == int(sdl.KeyCode.a) {
						game.p1_left = false
					} else if sym == int(sdl.KeyCode.d) {
						game.p1_right = false
					} else if sym == int(sdl.KeyCode.up) {
						if game.is_coop {
							game.p2_up = false
						} else {
							game.p1_up = false
						}
					} else if sym == int(sdl.KeyCode.down) {
						if game.is_coop {
							game.p2_down = false
						} else {
							game.p1_down = false
						}
					} else if sym == int(sdl.KeyCode.left) {
						if game.is_coop {
							game.p2_left = false
						} else {
							game.p1_left = false
						}
					} else if sym == int(sdl.KeyCode.right) {
						if game.is_coop {
							game.p2_right = false
						} else {
							game.p1_right = false
						}
					}
				}
				else {}
			}
		}

		// Update Player velocities from directional flags
		if game.state == .playing && game.players.len > 0 {
			mut p1_vx := 0.0
			mut p1_vy := 0.0
			if game.p1_up {
				p1_vy -= 1.0
			}
			if game.p1_down {
				p1_vy += 1.0
			}
			if game.p1_left {
				p1_vx -= 1.0
			}
			if game.p1_right {
				p1_vx += 1.0
			}
			p1_vx, p1_vy = normalize(p1_vx, p1_vy)
			game.players[0].vx = p1_vx
			game.players[0].vy = p1_vy

			if game.is_coop && game.players.len > 1 {
				mut p2_vx := 0.0
				mut p2_vy := 0.0
				if game.p2_up {
					p2_vy -= 1.0
				}
				if game.p2_down {
					p2_vy += 1.0
				}
				if game.p2_left {
					p2_vx -= 1.0
				}
				if game.p2_right {
					p2_vx += 1.0
				}
				p2_vx, p2_vy = normalize(p2_vx, p2_vy)
				game.players[1].vx = p2_vx
				game.players[1].vy = p2_vy
			}
		}

		game.update(dt)
		game.render(renderer)
		prod_fx_render(renderer)
		sdl.render_present(renderer)
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
