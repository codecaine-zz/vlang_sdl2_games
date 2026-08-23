module main

import math
import sdl

pub fn render_kung_fu_game(renderer &sdl.Renderer, mut g KungFuGame) {
	// Screen shake offsets
	shake_x := if g.screen_shake > 0.0 { int(math.sin(f64(sdl.get_ticks()) * 0.05) * 4.0) } else { 0 }

	// 1. Pagoda Corridor Background
	render_pagoda_background(renderer, mut g)

	cam_x := int(g.camera_x) + shake_x

	// 2. Draw Floor & Wall Railings
	render_corridor_architecture(renderer, cam_x)

	// 3. Draw Sylvia on Floor 5
	if g.floor == 5 {
		render_sylvia(renderer, cam_x)
	}

	// 4. Draw Falling Pots
	render_falling_pots(renderer, mut g, cam_x)

	// 5. Draw Projectiles (Knives, Boomerangs, Fireballs)
	render_projectiles(renderer, mut g, cam_x)

	// 6. Draw Enemies & Bosses
	render_enemies(renderer, mut g, cam_x)

	// 7. Draw Player (Thomas)
	render_player(renderer, mut g, cam_x)

	// 8. Draw Particles
	render_particles(renderer, mut g, cam_x)

	// 9. Draw Score Popups
	render_score_popups(renderer, mut g, cam_x)

	// 10. Draw Banners
	render_gameplay_banners(renderer, mut g)

	// 11. Draw Arcade Top HUD & Dual Health Bars
	render_hud(renderer, mut g)

	// 12. CRT Filter
	if g.crt_filter {
		render_crt_overlay(renderer)
	}

	// 13. State Overlays
	if g.state == .title {
		render_title_screen(renderer)
	} else if g.state == .paused {
		render_paused_screen(renderer)
	} else if g.state == .floor_clear {
		render_floor_clear_screen(renderer, mut g)
	} else if g.state == .game_over {
		render_game_over_screen(renderer, mut g)
	} else if g.state == .victory {
		render_victory_screen(renderer, mut g)
	}
}

fn render_pagoda_background(renderer &sdl.Renderer, mut g KungFuGame) {
	// Sky outside windows (Sunset crimson & gold twilight)
	sdl.set_render_draw_color(renderer, 36, 12, 28, 255)
	sdl.render_clear(renderer)

	// Glowing Harvest Moon in distance
	sdl.set_render_draw_color(renderer, 255, 230, 160, 255)
	moon_x := 620 - int(g.camera_x * 0.04) % 800
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: moon_x, y: 140, w: 44, h: 44 })
	sdl.set_render_draw_color(renderer, 255, 245, 200, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: moon_x + 4, y: 144, w: 36, h: 36 })

	// Distant mountain silhouettes through open lattice windows
	for col := 0; col < 12; col++ {
		mx := col * 80 - int(g.camera_x * 0.15) % 80
		sdl.set_render_draw_color(renderer, 65, 22, 42, 255)
		poly := sdl.Rect{ x: mx, y: 180, w: 90, h: 150 }
		sdl.render_fill_rect(renderer, &poly)
		// Mountain peaks
		sdl.set_render_draw_color(renderer, 80, 28, 52, 255)
		sdl.render_fill_rect(renderer, &sdl.Rect{ x: mx + 16, y: 160, w: 48, h: 30 })
	}
}

fn render_corridor_architecture(renderer &sdl.Renderer, cam_x int) {
	// Upper ceiling beam with red lacquer & ornamental brackets
	sdl.set_render_draw_color(renderer, 150, 24, 24, 255)
	top_beam := sdl.Rect{ x: 0, y: 80, w: 800, h: 36 }
	sdl.render_fill_rect(renderer, &top_beam)

	// Golden bracket trim along rafters
	sdl.set_render_draw_color(renderer, 240, 195, 45, 255)
	gold_trim := sdl.Rect{ x: 0, y: 112, w: 800, h: 4 }
	sdl.render_fill_rect(renderer, &gold_trim)

	// Bracket teeth
	for bx := 0; bx < 800; bx += 40 {
		sdl.render_fill_rect(renderer, &sdl.Rect{ x: bx + 12, y: 112, w: 16, h: 6 })
	}

	// Wooden Corridor Support Pillars
	pillar_spacing := 240
	for px := -pillar_spacing; px < 800 + pillar_spacing; px += pillar_spacing {
		world_x := px - (cam_x % pillar_spacing)

		// Dark Vermilion Wooden Pillar
		sdl.set_render_draw_color(renderer, 120, 25, 25, 255)
		pillar := sdl.Rect{ x: world_x, y: 80, w: 22, h: 384 }
		sdl.render_fill_rect(renderer, &pillar)

		// Pillar highlight stripe
		sdl.set_render_draw_color(renderer, 185, 55, 45, 255)
		hl := sdl.Rect{ x: world_x + 3, y: 80, w: 4, h: 384 }
		sdl.render_fill_rect(renderer, &hl)

		// Swaying Hanging Lantern with physics
		sway := int(math.sin(f64(world_x) * 0.02 + f64(sdl.get_ticks()) * 0.003) * 3.0)
		lantern_x := world_x + 28 + sway

		sdl.set_render_draw_color(renderer, 240, 45, 35, 255)
		lantern := sdl.Rect{ x: lantern_x, y: 120, w: 16, h: 22 }
		sdl.render_fill_rect(renderer, &lantern)
		sdl.set_render_draw_color(renderer, 255, 225, 100, 255)
		l_core := sdl.Rect{ x: lantern_x + 4, y: 124, w: 8, h: 14 }
		sdl.render_fill_rect(renderer, &l_core)
		// Golden Tassel
		sdl.set_render_draw_color(renderer, 240, 210, 40, 255)
		tassel := sdl.Rect{ x: lantern_x + 6 + sway, y: 142, w: 4, h: 10 }
		sdl.render_fill_rect(renderer, &tassel)
	}

	// Ornamental Corridor Handrail
	sdl.set_render_draw_color(renderer, 100, 50, 25, 255)
	rail_bar := sdl.Rect{ x: 0, y: 320, w: 800, h: 14 }
	sdl.render_fill_rect(renderer, &rail_bar)

	// Balusters
	sdl.set_render_draw_color(renderer, 75, 38, 18, 255)
	for bx := 0; bx < 800; bx += 18 {
		sdl.render_fill_rect(renderer, &sdl.Rect{ x: bx, y: 334, w: 4, h: 130 })
	}

	// Polished Dojo Arena Floor (Y: 464..600)
	sdl.set_render_draw_color(renderer, 85, 48, 22, 255)
	floor_rect := sdl.Rect{ x: 0, y: 464, w: 800, h: 136 }
	sdl.render_fill_rect(renderer, &floor_rect)

	// Floorboard top specular highlight
	sdl.set_render_draw_color(renderer, 130, 78, 38, 255)
	top_f_line := sdl.Rect{ x: 0, y: 464, w: 800, h: 5 }
	sdl.render_fill_rect(renderer, &top_f_line)

	// Perspective floor planks & woodgrain lines
	sdl.set_render_draw_color(renderer, 60, 32, 14, 255)
	for y := 492; y < 600; y += 26 {
		sdl.render_draw_line(renderer, 0, y, 800, y)
	}
	for fx := 0; fx < 800; fx += 110 {
		sdl.render_draw_line(renderer, fx, 464, fx - 40, 600)
	}
}

fn render_sylvia(renderer &sdl.Renderer, cam_x int) {
	sx := 2320 - cam_x
	sy := 396

	// Wooden Chair
	sdl.set_render_draw_color(renderer, 110, 55, 25, 255)
	chair := sdl.Rect{ x: sx - 4, y: sy + 16, w: 32, h: 52 }
	sdl.render_fill_rect(renderer, &chair)

	// Sylvia in Flowing Pink Gown
	sdl.set_render_draw_color(renderer, 245, 130, 180, 255)
	dress := sdl.Rect{ x: sx, y: sy + 14, w: 24, h: 50 }
	sdl.render_fill_rect(renderer, &dress)

	// Face & Eyes
	sdl.set_render_draw_color(renderer, 255, 200, 150, 255)
	face := sdl.Rect{ x: sx + 4, y: sy, w: 16, h: 16 }
	sdl.render_fill_rect(renderer, &face)

	sdl.set_render_draw_color(renderer, 30, 30, 40, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: sx + 6, y: sy + 6, w: 2, h: 3 })
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: sx + 12, y: sy + 6, w: 2, h: 3 })

	// Blonde Hair & Ribbon
	sdl.set_render_draw_color(renderer, 245, 215, 60, 255)
	hair := sdl.Rect{ x: sx + 2, y: sy - 4, w: 20, h: 10 }
	sdl.render_fill_rect(renderer, &hair)

	sdl.set_render_draw_color(renderer, 230, 40, 80, 255)
	ribbon := sdl.Rect{ x: sx + 6, y: sy - 6, w: 12, h: 3 }
	sdl.render_fill_rect(renderer, &ribbon)

	// Binding Ropes
	sdl.set_render_draw_color(renderer, 190, 150, 60, 255)
	sdl.render_draw_line(renderer, sx, sy + 24, sx + 24, sy + 24)
	sdl.render_draw_line(renderer, sx, sy + 38, sx + 24, sy + 38)
}

fn render_falling_pots(renderer &sdl.Renderer, mut g KungFuGame, cam_x int) {
	for pot in g.falling_pots {
		if !pot.active {
			continue
		}
		px := int(pot.x) - cam_x
		py := int(pot.y)

		// Terracotta Pot
		sdl.set_render_draw_color(renderer, 185, 85, 45, 255)
		body := sdl.Rect{ x: px, y: py + 4, w: 20, h: 20 }
		sdl.render_fill_rect(renderer, &body)

		// Rim
		sdl.set_render_draw_color(renderer, 225, 115, 55, 255)
		rim := sdl.Rect{ x: px - 2, y: py, w: 24, h: 6 }
		sdl.render_fill_rect(renderer, &rim)
	}
}

fn render_projectiles(renderer &sdl.Renderer, mut g KungFuGame, cam_x int) {
	for p in g.projectiles {
		if !p.active {
			continue
		}
		px := int(p.x) - cam_x
		py := int(p.y)

		if p.is_fire {
			// Black Magician Fireball
			sdl.set_render_draw_color(renderer, 255, 80, 20, 255)
			c1 := sdl.Rect{ x: px - 2, y: py - 2, w: 16, h: 16 }
			sdl.render_fill_rect(renderer, &c1)
			sdl.set_render_draw_color(renderer, 255, 230, 50, 255)
			c2 := sdl.Rect{ x: px + 2, y: py + 2, w: 8, h: 8 }
			sdl.render_fill_rect(renderer, &c2)
		} else if p.is_boomerang {
			// Boomerang
			sdl.set_render_draw_color(renderer, 215, 165, 50, 255)
			bm := sdl.Rect{ x: px, y: py, w: 16, h: 10 }
			sdl.render_fill_rect(renderer, &bm)
		} else {
			// Steel Throwing Knife with shiny highlight
			sdl.set_render_draw_color(renderer, 245, 245, 255, 255)
			blade := sdl.Rect{ x: px, y: py, w: 16, h: 4 }
			sdl.render_fill_rect(renderer, &blade)
			sdl.set_render_draw_color(renderer, 110, 55, 25, 255)
			hilt := sdl.Rect{ x: if p.vx > 0.0 { px } else { px + 12 }, y: py - 2, w: 4, h: 8 }
			sdl.render_fill_rect(renderer, &hilt)
		}
	}
}

fn render_enemies(renderer &sdl.Renderer, mut g KungFuGame, cam_x int) {
	for e in g.enemies {
		if !e.active {
			continue
		}
		ex := int(e.x) - cam_x
		ey := int(e.y)
		ew := int(e.width)
		eh := int(e.height)

		match e.enemy_type {
			.gripper {
				render_gripper(renderer, ex, ey, ew, eh, e.facing_right)
			}
			.knife_thrower {
				render_knife_thrower(renderer, ex, ey, ew, eh, e.facing_right)
			}
			.tom_tom {
				render_tom_tom(renderer, ex, ey, ew, eh)
			}
			.snake {
				render_snake(renderer, ex, ey)
			}
			.moth {
				render_moth(renderer, ex, ey)
			}
			.boss_stick {
				render_boss_stick(renderer, ex, ey, ew, eh, e.facing_right)
			}
			.boss_boomerang {
				render_boss_boomerang(renderer, ex, ey, ew, eh)
			}
			.boss_giant {
				render_boss_giant(renderer, ex, ey, ew, eh)
			}
			.boss_magician {
				render_boss_magician(renderer, ex, ey, ew, eh)
			}
			.boss_mrx {
				render_boss_mrx(renderer, ex, ey, ew, eh)
			}
		}
	}
}

fn render_gripper(renderer &sdl.Renderer, x int, y int, w int, h int, facing_right bool) {
	// Purple Tunic
	sdl.set_render_draw_color(renderer, 125, 60, 185, 255)
	tunic := sdl.Rect{ x: x + 4, y: y + 20, w: w - 8, h: 26 }
	sdl.render_fill_rect(renderer, &tunic)

	// Head & Face
	sdl.set_render_draw_color(renderer, 240, 190, 140, 255)
	head := sdl.Rect{ x: x + 6, y: y + 2, w: w - 12, h: 18 }
	sdl.render_fill_rect(renderer, &head)

	// Yellow Band
	sdl.set_render_draw_color(renderer, 245, 220, 40, 255)
	band := sdl.Rect{ x: x + 4, y: y + 4, w: w - 8, h: 5 }
	sdl.render_fill_rect(renderer, &band)

	// Outstretched grabbing arms
	sdl.set_render_draw_color(renderer, 240, 190, 140, 255)
	arm_x := if facing_right { x + w - 4 } else { x - 8 }
	arm := sdl.Rect{ x: arm_x, y: y + 22, w: 12, h: 8 }
	sdl.render_fill_rect(renderer, &arm)

	// Dark Pants & Shoes
	sdl.set_render_draw_color(renderer, 45, 30, 65, 255)
	pants := sdl.Rect{ x: x + 4, y: y + 46, w: w - 8, h: h - 46 }
	sdl.render_fill_rect(renderer, &pants)
}

fn render_knife_thrower(renderer &sdl.Renderer, x int, y int, w int, h int, facing_right bool) {
	// Bare Chest
	sdl.set_render_draw_color(renderer, 240, 180, 130, 255)
	chest := sdl.Rect{ x: x + 4, y: y + 18, w: w - 8, h: 24 }
	sdl.render_fill_rect(renderer, &chest)

	// Head & Hair
	head := sdl.Rect{ x: x + 6, y: y + 2, w: w - 12, h: 16 }
	sdl.render_fill_rect(renderer, &head)
	sdl.set_render_draw_color(renderer, 40, 30, 20, 255)
	hair := sdl.Rect{ x: x + 4, y: y, w: w - 8, h: 6 }
	sdl.render_fill_rect(renderer, &hair)

	// Dark Orange Pants
	sdl.set_render_draw_color(renderer, 215, 95, 30, 255)
	pants := sdl.Rect{ x: x + 4, y: y + 42, w: w - 8, h: h - 42 }
	sdl.render_fill_rect(renderer, &pants)

	// Raised Knife in Hand
	sdl.set_render_draw_color(renderer, 245, 245, 245, 255)
	hand_x := if facing_right { x + w } else { x - 6 }
	knife := sdl.Rect{ x: hand_x, y: y + 16, w: 8, h: 4 }
	sdl.render_fill_rect(renderer, &knife)
}

fn render_tom_tom(renderer &sdl.Renderer, x int, y int, w int, h int) {
	// Red / Yellow Acrobat Suit
	sdl.set_render_draw_color(renderer, 230, 40, 40, 255)
	body := sdl.Rect{ x: x + 4, y: y + 12, w: w - 8, h: h - 12 }
	sdl.render_fill_rect(renderer, &body)

	// Head
	sdl.set_render_draw_color(renderer, 240, 190, 140, 255)
	head := sdl.Rect{ x: x + 6, y: y, w: w - 12, h: 14 }
	sdl.render_fill_rect(renderer, &head)
}

fn render_snake(renderer &sdl.Renderer, x int, y int) {
	// Green Coiled Viper
	sdl.set_render_draw_color(renderer, 40, 185, 50, 255)
	body := sdl.Rect{ x: x, y: y + 4, w: 26, h: 12 }
	sdl.render_fill_rect(renderer, &body)

	// Head
	sdl.set_render_draw_color(renderer, 220, 240, 40, 255)
	head := sdl.Rect{ x: x + 20, y: y + 2, w: 8, h: 8 }
	sdl.render_fill_rect(renderer, &head)
}

fn render_moth(renderer &sdl.Renderer, x int, y int) {
	// Purple Dragon Moth with fluttering wings
	sdl.set_render_draw_color(renderer, 205, 85, 225, 255)
	w1 := sdl.Rect{ x: x, y: y, w: 10, h: 14 }
	w2 := sdl.Rect{ x: x + 12, y: y, w: 10, h: 14 }
	sdl.render_fill_rect(renderer, &w1)
	sdl.render_fill_rect(renderer, &w2)
}

fn render_boss_stick(renderer &sdl.Renderer, x int, y int, w int, h int, facing_right bool) {
	// Yellow Silk Kung Fu Robe
	sdl.set_render_draw_color(renderer, 235, 190, 30, 255)
	robe := sdl.Rect{ x: x + 4, y: y + 18, w: w - 8, h: h - 18 }
	sdl.render_fill_rect(renderer, &robe)

	// Head
	sdl.set_render_draw_color(renderer, 240, 180, 130, 255)
	head := sdl.Rect{ x: x + 6, y: y + 2, w: w - 12, h: 16 }
	sdl.render_fill_rect(renderer, &head)

	// Long Wooden Bo Staff
	sdl.set_render_draw_color(renderer, 150, 75, 25, 255)
	staff_x := if facing_right { x + w + 4 } else { x - 8 }
	staff := sdl.Rect{ x: staff_x, y: y - 10, w: 6, h: 86 }
	sdl.render_fill_rect(renderer, &staff)
}

fn render_boss_boomerang(renderer &sdl.Renderer, x int, y int, w int, h int) {
	// Red Martial Artist
	sdl.set_render_draw_color(renderer, 220, 40, 40, 255)
	suit := sdl.Rect{ x: x + 4, y: y + 18, w: w - 8, h: h - 18 }
	sdl.render_fill_rect(renderer, &suit)

	// Head
	sdl.set_render_draw_color(renderer, 240, 180, 130, 255)
	head := sdl.Rect{ x: x + 6, y: y + 2, w: w - 12, h: 16 }
	sdl.render_fill_rect(renderer, &head)
}

fn render_boss_giant(renderer &sdl.Renderer, x int, y int, w int, h int) {
	// Massive Bruiser
	sdl.set_render_draw_color(renderer, 50, 40, 40, 255)
	vest := sdl.Rect{ x: x + 4, y: y + 22, w: w - 8, h: 26 }
	sdl.render_fill_rect(renderer, &vest)

	// Head
	sdl.set_render_draw_color(renderer, 235, 175, 120, 255)
	head := sdl.Rect{ x: x + 8, y: y + 2, w: w - 16, h: 20 }
	sdl.render_fill_rect(renderer, &head)

	// Heavy Pants
	sdl.set_render_draw_color(renderer, 30, 25, 35, 255)
	pants := sdl.Rect{ x: x + 4, y: y + 48, w: w - 8, h: h - 48 }
	sdl.render_fill_rect(renderer, &pants)
}

fn render_boss_magician(renderer &sdl.Renderer, x int, y int, w int, h int) {
	// Black Magic Robes
	sdl.set_render_draw_color(renderer, 30, 25, 45, 255)
	robe := sdl.Rect{ x: x + 4, y: y + 18, w: w - 8, h: h - 18 }
	sdl.render_fill_rect(renderer, &robe)

	// Gold Trim
	sdl.set_render_draw_color(renderer, 240, 210, 40, 255)
	trim := sdl.Rect{ x: x + 6, y: y + 20, w: 4, h: h - 20 }
	sdl.render_fill_rect(renderer, &trim)

	// Head & Hat
	sdl.set_render_draw_color(renderer, 240, 180, 130, 255)
	head := sdl.Rect{ x: x + 6, y: y + 2, w: w - 12, h: 16 }
	sdl.render_fill_rect(renderer, &head)
}

fn render_boss_mrx(renderer &sdl.Renderer, x int, y int, w int, h int) {
	// Crimson Grandmaster Robes
	sdl.set_render_draw_color(renderer, 200, 20, 30, 255)
	robe := sdl.Rect{ x: x + 4, y: y + 18, w: w - 8, h: h - 18 }
	sdl.render_fill_rect(renderer, &robe)

	// Dragon Emblem
	sdl.set_render_draw_color(renderer, 255, 220, 40, 255)
	emb := sdl.Rect{ x: x + 10, y: y + 24, w: 10, h: 12 }
	sdl.render_fill_rect(renderer, &emb)

	// Head & White Beard
	sdl.set_render_draw_color(renderer, 240, 180, 130, 255)
	head := sdl.Rect{ x: x + 6, y: y + 2, w: w - 12, h: 16 }
	sdl.render_fill_rect(renderer, &head)
	sdl.set_render_draw_color(renderer, 240, 240, 240, 255)
	beard := sdl.Rect{ x: x + 8, y: y + 14, w: 8, h: 8 }
	sdl.render_fill_rect(renderer, &beard)
}

fn render_player(renderer &sdl.Renderer, mut g KungFuGame, cam_x int) {
	px := int(g.player.x) - cam_x
	py := int(g.player.y)
	pw := int(g.player.width)
	ph := int(g.player.height)

	// Flashing if invulnerable
	if g.player.invuln_timer > 0.0 && (int(g.player.invuln_timer * 18.0) % 2 == 0) {
		return
	}

	// Dead Pose
	if g.player.is_dead {
		sdl.set_render_draw_color(renderer, 245, 245, 245, 255)
		body := sdl.Rect{ x: px, y: py + ph - 16, w: ph, h: 16 }
		sdl.render_fill_rect(renderer, &body)
		return
	}

	// 1. Head & Hair
	sdl.set_render_draw_color(renderer, 255, 195, 140, 255)
	head_y := if g.player.is_crouching { py + 20 } else { py + 2 }
	head := sdl.Rect{ x: px + 6, y: head_y, w: pw - 12, h: 16 }
	sdl.render_fill_rect(renderer, &head)

	// Eye
	sdl.set_render_draw_color(renderer, 20, 20, 30, 255)
	eye_x := if g.player.facing_right { px + pw - 9 } else { px + 7 }
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: eye_x, y: head_y + 5, w: 2, h: 3 })

	// Black Hair
	sdl.set_render_draw_color(renderer, 30, 25, 25, 255)
	hair := sdl.Rect{ x: px + 4, y: head_y - 2, w: pw - 8, h: 6 }
	sdl.render_fill_rect(renderer, &hair)

	// 2. White Gi Top
	sdl.set_render_draw_color(renderer, 245, 245, 245, 255)
	gi_y := if g.player.is_crouching { py + 34 } else { py + 18 }
	gi := sdl.Rect{ x: px + 4, y: gi_y, w: pw - 8, h: 24 }
	sdl.render_fill_rect(renderer, &gi)

	// Red Sash Belt
	sdl.set_render_draw_color(renderer, 230, 30, 30, 255)
	belt := sdl.Rect{ x: px + 3, y: gi_y + 18, w: pw - 6, h: 5 }
	sdl.render_fill_rect(renderer, &belt)

	// 3. Extended Attack Arms / Legs
	match g.player.attack {
		.high_punch {
			sdl.set_render_draw_color(renderer, 245, 245, 245, 255)
			arm_x := if g.player.facing_right { px + pw - 2 } else { px - 22 }
			arm := sdl.Rect{ x: arm_x, y: py + 20, w: 24, h: 8 }
			sdl.render_fill_rect(renderer, &arm)
			// Fist
			sdl.set_render_draw_color(renderer, 255, 195, 140, 255)
			fist := sdl.Rect{ x: if g.player.facing_right { arm_x + 16 } else { arm_x }, y: py + 19, w: 8, h: 10 }
			sdl.render_fill_rect(renderer, &fist)
		}
		.high_kick {
			sdl.set_render_draw_color(renderer, 245, 245, 245, 255)
			leg_x := if g.player.facing_right { px + pw - 4 } else { px - 28 }
			leg := sdl.Rect{ x: leg_x, y: py + 26, w: 30, h: 10 }
			sdl.render_fill_rect(renderer, &leg)
			// Dark Kung Fu Shoe
			sdl.set_render_draw_color(renderer, 30, 25, 25, 255)
			shoe := sdl.Rect{ x: if g.player.facing_right { leg_x + 22 } else { leg_x }, y: py + 24, w: 8, h: 14 }
			sdl.render_fill_rect(renderer, &shoe)
		}
		.low_punch {
			sdl.set_render_draw_color(renderer, 245, 245, 245, 255)
			arm_x := if g.player.facing_right { px + pw - 2 } else { px - 20 }
			arm := sdl.Rect{ x: arm_x, y: py + 40, w: 22, h: 8 }
			sdl.render_fill_rect(renderer, &arm)
		}
		.low_kick {
			sdl.set_render_draw_color(renderer, 245, 245, 245, 255)
			leg_x := if g.player.facing_right { px + pw - 4 } else { px - 32 }
			leg := sdl.Rect{ x: leg_x, y: py + 50, w: 34, h: 10 }
			sdl.render_fill_rect(renderer, &leg)
		}
		.jump_kick {
			sdl.set_render_draw_color(renderer, 245, 245, 245, 255)
			leg_x := if g.player.facing_right { px + pw - 4 } else { px - 28 }
			leg := sdl.Rect{ x: leg_x, y: py + 28, w: 30, h: 10 }
			sdl.render_fill_rect(renderer, &leg)
		}
		else {}
	}

	// 4. White Gi Pants & Animated Steps
	sdl.set_render_draw_color(renderer, 245, 245, 245, 255)
	if g.player.is_crouching {
		pants := sdl.Rect{ x: px + 2, y: py + 52, w: pw - 4, h: 12 }
		sdl.render_fill_rect(renderer, &pants)
	} else {
		pants := sdl.Rect{ x: px + 4, y: py + 42, w: pw - 8, h: ph - 42 }
		sdl.render_fill_rect(renderer, &pants)

		// Walking foot stride animation
		sdl.set_render_draw_color(renderer, 30, 25, 25, 255)
		if g.player.walk_frame % 2 == 1 {
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: px + 2, y: py + ph - 6, w: 8, h: 6 })
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: px + pw - 10, y: py + ph - 8, w: 8, h: 6 })
		} else {
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: px + 4, y: py + ph - 6, w: 8, h: 6 })
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: px + pw - 12, y: py + ph - 6, w: 8, h: 6 })
		}
	}
}

fn render_particles(renderer &sdl.Renderer, mut g KungFuGame, cam_x int) {
	for pt in g.particles {
		if !pt.active {
			continue
		}
		sdl.set_render_draw_color(renderer, pt.color.r, pt.color.g, pt.color.b, 255)
		rect := sdl.Rect{
			x: int(pt.x) - cam_x
			y: int(pt.y)
			w: int(pt.size)
			h: int(pt.size)
		}
		sdl.render_fill_rect(renderer, &rect)
	}
}

fn render_score_popups(renderer &sdl.Renderer, mut g KungFuGame, cam_x int) {
	for sp in g.score_popups {
		if !sp.active {
			continue
		}
		draw_text_centered_shadow(renderer, int(sp.x) - cam_x, int(sp.y), sp.text, 2,
			sp.color, Color{ r: 0, g: 0, b: 0, a: 255 })
	}
}

fn render_gameplay_banners(renderer &sdl.Renderer, mut g KungFuGame) {
	if g.banner_timer > 0.0 && g.state == .playing {
		draw_text_centered_shadow(renderer, 400, 220, 'FLOOR ${g.floor}F - FIGHT!', 3,
			Color{ r: 255, g: 220, b: 50, a: 255 }, Color{ r: 10, g: 10, b: 10, a: 255 })
	}
}

fn render_hud(renderer &sdl.Renderer, mut g KungFuGame) {
	// Top Score Bar
	draw_text_shadow(renderer, 30, 15, '1P  ${g.player.score:06d}', 2,
		Color{ r: 255, g: 255, b: 255, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })

	draw_text_centered_shadow(renderer, 400, 15, 'HIGH  ${g.high_score:06d}', 2,
		Color{ r: 255, g: 215, b: 40, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })

	draw_text_shadow(renderer, 670, 15, '${g.floor}F', 2,
		Color{ r: 100, g: 220, b: 255, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })

	// Time bar
	draw_text_shadow(renderer, 610, 40, 'TIME ${int(g.floor_timer):03d}', 2,
		Color{ r: 255, g: 160, b: 40, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })

	// Dual Health Meters
	// 1. PLAYER Health Bar
	draw_text_shadow(renderer, 30, 42, 'PLAYER', 2, Color{ r: 255, g: 255, b: 255, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	for i in 0 .. 16 {
		p_color := if i < g.player.health { Color{ r: 60, g: 180, b: 255, a: 255 } } else { Color{ r: 50, g: 50, b: 70, a: 255 } }
		sdl.set_render_draw_color(renderer, p_color.r, p_color.g, p_color.b, 255)
		pip := sdl.Rect{ x: 140 + i * 11, y: 44, w: 8, h: 14 }
		sdl.render_fill_rect(renderer, &pip)
	}

	// 2. ENEMY / BOSS Health Bar
	mut enemy_hp := 0
	mut enemy_max := 16
	for e in g.enemies {
		if e.active && e.enemy_type in [.boss_stick, .boss_boomerang, .boss_giant, .boss_magician, .boss_mrx] {
			enemy_hp = e.health
			enemy_max = e.max_health
			break
		}
	}
	draw_text_shadow(renderer, 330, 42, 'ENEMY', 2, Color{ r: 255, g: 255, b: 255, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	for i in 0 .. 16 {
		scaled_hp := int(f32(enemy_hp) / f32(enemy_max) * 16.0)
		e_color := if i < scaled_hp { Color{ r: 255, g: 80, b: 50, a: 255 } } else { Color{ r: 60, g: 40, b: 40, a: 255 } }
		sdl.set_render_draw_color(renderer, e_color.r, e_color.g, e_color.b, 255)
		pip := sdl.Rect{ x: 420 + i * 11, y: 44, w: 8, h: 14 }
		sdl.render_fill_rect(renderer, &pip)
	}

	// Lives Counter
	draw_text(renderer, 30, 568, 'LIVES:', 2, Color{ r: 240, g: 240, b: 240, a: 255 })
	for i in 0 .. g.player.lives {
		sdl.set_render_draw_color(renderer, 245, 245, 245, 255)
		icon := sdl.Rect{ x: 130 + i * 18, y: 566, w: 12, h: 14 }
		sdl.render_fill_rect(renderer, &icon)
	}
}

fn render_crt_overlay(renderer &sdl.Renderer) {
	sdl.set_render_draw_blend_mode(renderer, .blend)
	sdl.set_render_draw_color(renderer, 0, 0, 0, 26)
	for y := 0; y < 600; y += 3 {
		line := sdl.Rect{ x: 0, y: y, w: 800, h: 1 }
		sdl.render_fill_rect(renderer, &line)
	}
}

fn render_title_screen(renderer &sdl.Renderer) {
	sdl.set_render_draw_blend_mode(renderer, .blend)
	sdl.set_render_draw_color(renderer, 8, 5, 12, 225)
	scrim := sdl.Rect{ x: 0, y: 0, w: 800, h: 600 }
	sdl.render_fill_rect(renderer, &scrim)

	// Arcade Title
	draw_text_centered_shadow(renderer, 400, 80, 'KUNG-FU MASTER', 4,
		Color{ r: 255, g: 45, b: 45, a: 255 }, Color{ r: 245, g: 220, b: 30, a: 255 })

	draw_text_centered_shadow(renderer, 400, 140, '1984 IREM / 1985 NES SPARTAN X', 2,
		Color{ r: 80, g: 210, b: 255, a: 255 }, Color{ r: 10, g: 20, b: 40, a: 255 })

	draw_text_centered_shadow(renderer, 400, 220, 'RESCUE SYLVIA FROM MR. X ACROSS 5 TEMPLE FLOORS!', 1,
		Color{ r: 245, g: 245, b: 245, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })

	draw_text_centered_shadow(renderer, 400, 270, 'PRESS SPACE OR ENTER TO START', 2,
		Color{ r: 255, g: 240, b: 40, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })

	// Controls Summary
	draw_text_centered_shadow(renderer, 400, 340, 'CONTROLS & COMBAT', 2,
		Color{ r: 255, g: 180, b: 40, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 375, 'A / D (LEFT / RIGHT) : MOVE (WIGGLE TO SHAKE OFF GRIPPERS!)', 1,
		Color{ r: 230, g: 230, b: 230, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 400, 'S (DOWN) : CROUCH (DUCK UNDER HIGH KNIVES & BOOMERANGS)', 1,
		Color{ r: 230, g: 230, b: 230, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 425, 'SPACE / W : JUMP (DIAGONAL JUMP KICKS)', 1,
		Color{ r: 230, g: 230, b: 230, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 450, 'J / Z : PUNCH (HIGH / LOW PUNCH - 200 PTS)', 1,
		Color{ r: 100, g: 240, b: 120, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 475, 'K / X : KICK (HIGH / LOW / JUMP KICK - 100 PTS)', 1,
		Color{ r: 100, g: 240, b: 120, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 500, '[P] PAUSE  [M] MUTE  [C] CRT SCANLINES  [R] RESTART  [F11] Fullscreen', 1,
		Color{ r: 255, g: 215, b: 110, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })

	draw_text_centered_shadow(renderer, 400, 560, '(C) 1984 IREM CORP. / NINTENDO', 1,
		Color{ r: 150, g: 150, b: 160, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
}

fn render_paused_screen(renderer &sdl.Renderer) {
	sdl.set_render_draw_blend_mode(renderer, .blend)
	sdl.set_render_draw_color(renderer, 0, 0, 0, 190)
	scrim := sdl.Rect{ x: 0, y: 0, w: 800, h: 600 }
	sdl.render_fill_rect(renderer, &scrim)

	draw_text_centered_shadow(renderer, 400, 270, 'PAUSED', 4,
		Color{ r: 255, g: 230, b: 40, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 320, 'PRESS P TO RESUME', 2,
		Color{ r: 255, g: 255, b: 255, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
}

fn render_floor_clear_screen(renderer &sdl.Renderer, mut g KungFuGame) {
	sdl.set_render_draw_blend_mode(renderer, .blend)
	sdl.set_render_draw_color(renderer, 0, 0, 0, 180)
	scrim := sdl.Rect{ x: 0, y: 0, w: 800, h: 600 }
	sdl.render_fill_rect(renderer, &scrim)

	draw_text_centered_shadow(renderer, 400, 230, 'FLOOR ${g.floor}F CLEAR!', 4,
		Color{ r: 80, g: 255, b: 100, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 290, 'TIME BONUS: +${int(g.floor_timer) * 10} PTS', 2,
		Color{ r: 255, g: 230, b: 60, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 345, 'PRESS SPACE FOR NEXT FLOOR', 2,
		Color{ r: 255, g: 255, b: 255, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
}

fn render_game_over_screen(renderer &sdl.Renderer, mut g KungFuGame) {
	sdl.set_render_draw_blend_mode(renderer, .blend)
	sdl.set_render_draw_color(renderer, 0, 0, 0, 210)
	scrim := sdl.Rect{ x: 0, y: 0, w: 800, h: 600 }
	sdl.render_fill_rect(renderer, &scrim)

	draw_text_centered_shadow(renderer, 400, 230, 'GAME OVER', 5,
		Color{ r: 255, g: 40, b: 40, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 300, 'FINAL SCORE: ${g.player.score}', 2,
		Color{ r: 255, g: 255, b: 255, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 360, 'PRESS SPACE TO RETRY', 2,
		Color{ r: 255, g: 230, b: 40, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
}

fn render_victory_screen(renderer &sdl.Renderer, mut g KungFuGame) {
	sdl.set_render_draw_blend_mode(renderer, .blend)
	sdl.set_render_draw_color(renderer, 0, 0, 0, 200)
	scrim := sdl.Rect{ x: 0, y: 0, w: 800, h: 600 }
	sdl.render_fill_rect(renderer, &scrim)

	draw_text_centered_shadow(renderer, 400, 180, 'CONGRATULATIONS!', 4,
		Color{ r: 255, g: 220, b: 40, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 240, 'YOU DEFEATED MR. X AND RESCUED SYLVIA!', 2,
		Color{ r: 255, g: 140, b: 180, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 300, 'FINAL SCORE: ${g.player.score}', 2,
		Color{ r: 255, g: 255, b: 255, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 360, 'PRESS SPACE TO PLAY AGAIN', 2,
		Color{ r: 80, g: 240, b: 120, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
}
