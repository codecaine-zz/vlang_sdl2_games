import math
import os
import sdl
import sdl.image

pub struct YieArKungFuTextureManager {
pub mut:
	sprite_texture &sdl.Texture = unsafe { nil }
}

pub fn (mut tm YieArKungFuTextureManager) init(renderer &sdl.Renderer) {
	_ = image.init(int(image.InitFlags.png))
	candidates := [
		'assets/sprites/yiearkungfu.png',
		'./assets/sprites/yiearkungfu.png',
		'../assets/sprites/yiearkungfu.png',
		'yiearkungfu/assets/sprites/yiearkungfu.png',
	]
	for p in candidates {
		if os.exists(p) {
			surface := image.load(p.str)
			if surface != unsafe { nil } {
				tm.sprite_texture = sdl.create_texture_from_surface(renderer, surface)
				sdl.free_surface(surface)
				if tm.sprite_texture != unsafe { nil } {
					println('Yie Ar Kung-Fu Texture Loaded Successfully: ' + p)
					return
				}
			}
		}
	}
}

pub fn render_yie_ar_kung_fu_game(renderer &sdl.Renderer, mut g YieArKungFuGame, tex &sdl.Texture) {
	// Screen shake offsets
	shake_x := if g.screen_shake > 0.0 { int(math.sin(f64(sdl.get_ticks()) * 0.05) * 4.0) } else { 0 }
	shake_y := if g.screen_shake > 0.0 { int(math.cos(f64(sdl.get_ticks()) * 0.05) * 4.0) } else { 0 }

	// 1. Dojo Arena Background
	render_dojo_arena(renderer, shake_x, shake_y)

	// 2. Fighter Ground Shadows
	render_fighter_shadows(renderer, mut g, shake_x, shake_y)

	// 3. Projectiles (Fireballs & Shurikens)
	render_projectiles(renderer, mut g, shake_x, shake_y)

	// 4. Fighters (Oolong & Opponent Master)
	render_player_oolong(renderer, mut g, shake_x, shake_y, tex)
	render_opponent_master(renderer, mut g, shake_x, shake_y, tex)

	// 5. Particles & Popups
	render_particles(renderer, mut g)
	render_score_popups(renderer, mut g)

	// 6. Dual Health Bars & HUD
	render_fighting_hud(renderer, mut g)

	// 7. CRT Filter
	if g.crt_filter {
		render_crt_overlay(renderer)
	}

	// 8. State Overlays
	if g.state == .title {
		render_title_screen(renderer)
	} else if g.state == .paused {
		render_paused_screen(renderer)
	} else if g.state == .round_clear {
		render_round_clear_screen(renderer)
	} else if g.state == .game_over {
		render_game_over_screen(renderer, mut g)
	} else if g.state == .victory {
		render_victory_screen(renderer)
	}
}

fn render_dojo_arena(renderer &sdl.Renderer, ox int, oy int) {
	// Sky gradient
	sdl.set_render_draw_color(renderer, 24, 42, 70, 255)
	sdl.render_clear(renderer)

	// Dojo Pagoda Wall
	sdl.set_render_draw_color(renderer, 130, 26, 26, 255)
	wall := sdl.Rect{ x: 40 + ox, y: 120 + oy, w: 720, h: 360 }
	sdl.render_fill_rect(renderer, &wall)

	// Golden Rafters & Wooden Brackets
	sdl.set_render_draw_color(renderer, 220, 180, 40, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: 30 + ox, y: 110 + oy, w: 740, h: 16 })

	// Chinese Lattice Windows
	sdl.set_render_draw_color(renderer, 20, 20, 20, 255)
	for i in 0 .. 5 {
		wx := 90 + i * 130 + ox
		sdl.render_fill_rect(renderer, &sdl.Rect{ x: wx, y: 160 + oy, w: 90, h: 120 })
		sdl.set_render_draw_color(renderer, 220, 180, 40, 255)
		sdl.render_draw_rect(renderer, &sdl.Rect{ x: wx, y: 160 + oy, w: 90, h: 120 })
		sdl.render_draw_line(renderer, wx + 45, 160 + oy, wx + 45, 280 + oy)
		sdl.render_draw_line(renderer, wx, 220 + oy, wx + 90, 220 + oy)
		sdl.set_render_draw_color(renderer, 20, 20, 20, 255)
	}

	// Red Pillars
	sdl.set_render_draw_color(renderer, 170, 30, 30, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: 40 + ox, y: 120 + oy, w: 24, h: 360 })
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: 736 + ox, y: 120 + oy, w: 24, h: 360 })

	// Hanging Lanterns
	for i in 0 .. 4 {
		lx := 140 + i * 150 + ox
		sdl.set_render_draw_color(renderer, 230, 40, 40, 255)
		sdl.render_fill_rect(renderer, &sdl.Rect{ x: lx, y: 126 + oy, w: 22, h: 28 })
		sdl.set_render_draw_color(renderer, 255, 220, 40, 255)
		sdl.render_fill_rect(renderer, &sdl.Rect{ x: lx + 4, y: 132 + oy, w: 14, h: 16 })
	}

	// Arena Stone / Sand Floor
	sdl.set_render_draw_color(renderer, 205, 170, 115, 255)
	floor := sdl.Rect{ x: 0, y: 480 + oy, w: 800, h: 120 }
	sdl.render_fill_rect(renderer, &floor)

	// Cobblestone border
	sdl.set_render_draw_color(renderer, 155, 125, 80, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: 0, y: 480 + oy, w: 800, h: 10 })

	// Drifting Cherry Blossom Petals
	ticks := f64(sdl.get_ticks())
	sdl.set_render_draw_color(renderer, 255, 185, 205, 220)
	for i := 0; i < 14; i++ {
		seed := f64(i * 123)
		px := int(math.fmod(ticks * 0.06 + seed * 50.0, 800.0))
		py := int(math.fmod(ticks * 0.04 + seed * 80.0, 500.0)) + 60
		sway := int(math.sin(ticks * 0.003 + seed) * 12.0)
		sdl.render_fill_rect(renderer, &sdl.Rect{ x: px + sway, y: py, w: 5, h: 4 })
	}
}

fn render_fighter_shadows(renderer &sdl.Renderer, mut g YieArKungFuGame, ox int, oy int) {
	sdl.set_render_draw_color(renderer, 140, 110, 70, 255)

	// Player Shadow
	p_height_above_ground := math.max(0.0, 384.0 - g.player.y)
	p_scale := math.max(0.4, 1.0 - p_height_above_ground / 200.0)
	p_sw := int(36.0 * p_scale)
	sdl.render_fill_rect(renderer, &sdl.Rect{
		x: int(g.player.x) + 24 - p_sw / 2 + ox
		y: 480 + oy
		w: p_sw
		h: 6
	})

	// Opponent Shadow
	op_height_above_ground := math.max(0.0, 384.0 - g.opponent.y)
	op_scale := math.max(0.4, 1.0 - op_height_above_ground / 200.0)
	op_sw := int(36.0 * op_scale)
	sdl.render_fill_rect(renderer, &sdl.Rect{
		x: int(g.opponent.x) + 24 - op_sw / 2 + ox
		y: 480 + oy
		w: op_sw
		h: 6
	})
}

fn render_projectiles(renderer &sdl.Renderer, mut g YieArKungFuGame, ox int, oy int) {
	for p in g.projectiles {
		if !p.active {
			continue
		}
		px := int(p.x) + ox
		py := int(p.y) + oy

		if p.is_fire {
			// Tao's Fireball
			sdl.set_render_draw_color(renderer, 255, 70, 20, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: px - 6, y: py - 6, w: 16, h: 16 })
			sdl.set_render_draw_color(renderer, 255, 220, 40, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: px - 2, y: py - 2, w: 8, h: 8 })
		} else {
			// Lang's Steel Shuriken
			sdl.set_render_draw_color(renderer, 240, 240, 255, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: px - 4, y: py - 4, w: 10, h: 10 })
			sdl.set_render_draw_color(renderer, 140, 160, 190, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: px - 6, y: py - 1, w: 14, h: 3 })
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: px - 1, y: py - 6, w: 3, h: 14 })
		}
	}
}

fn render_player_oolong(renderer &sdl.Renderer, mut g YieArKungFuGame, ox int, oy int, tex &sdl.Texture) {
	p := g.player
	px := int(p.x) + ox
	py := int(p.y) + oy
	ph := int(p.height)

	if p.hit_timer > 0.0 && (int(p.hit_timer * 18.0) % 2 == 0) {
		return
	}

	if tex != unsafe { nil } {
		col_idx := match p.move {
			.idle, .walk_forward, .walk_backward { 0 }
			.high_punch, .mid_punch, .low_punch, .jump_punch { 1 }
			.high_kick, .mid_kick, .low_kick { 2 }
			.jump_kick, .flying_kick { 3 }
			.crouch { 4 }
			.hit_stun { 5 }
			.knockdown { 6 }
			else { 0 }
		}
		src := sdl.Rect{ x: col_idx * 64, y: 0, w: 64, h: 64 }
		dst := sdl.Rect{ x: px - 8, y: py - 20, w: 64, h: 96 }
		flip := if !p.facing_right { sdl.RendererFlip.horizontal } else { sdl.RendererFlip.none }
		sdl.render_copy_ex(renderer, tex, &src, &dst, 0.0, unsafe { nil }, flip)
		return
	}

	is_aerial := p.move in [.jump_straight, .jump_forward, .jump_backward, .jump_punch, .jump_kick, .flying_kick]

	// 1. Head & Hair Queue
	head_y := if p.move == .crouch { py + 6 } else if is_aerial { py - 18 } else { py - 24 }
	sdl.set_render_draw_color(renderer, 255, 200, 150, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: px + 12, y: head_y, w: 24, h: 22 })

	// Hair Top & Braid queue
	sdl.set_render_draw_color(renderer, 20, 20, 20, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: px + 12, y: head_y - 4, w: 24, h: 6 })
	q_x := if p.facing_right { px + 4 } else { px + 36 }
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: q_x, y: head_y, w: 6, h: 22 })

	// Eyes & Eyebrows
	eye_x := if p.facing_right { px + 26 } else { px + 16 }
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: eye_x, y: head_y + 8, w: 6, h: 4 })

	// 2. Bare Torso / Chest & Muscular Definition
	sdl.set_render_draw_color(renderer, 255, 200, 150, 255)
	torso_y := head_y + 22
	torso_h := if p.move == .crouch { 24 } else { 38 }
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: px + 8, y: torso_y, w: 32, h: torso_h })

	// White Sash Belt
	sdl.set_render_draw_color(renderer, 250, 250, 250, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: px + 4, y: torso_y + torso_h - 6, w: 40, h: 8 })

	// 3. Pink Kung-Fu Pants & Shoes
	sdl.set_render_draw_color(renderer, 235, 75, 140, 255)
	pants_y := torso_y + torso_h

	if p.move == .flying_kick {
		// Outstretched flying kick leg
		k_x := if p.facing_right { px + 28 } else { px - 44 }
		sdl.render_fill_rect(renderer, &sdl.Rect{ x: k_x, y: torso_y + 10, w: 52, h: 18 })
		// Tucked back leg
		b_x := if p.facing_right { px - 12 } else { px + 28 }
		sdl.render_fill_rect(renderer, &sdl.Rect{ x: b_x, y: torso_y + 20, w: 24, h: 16 })
		// Shoe on kicking foot
		sdl.set_render_draw_color(renderer, 15, 15, 15, 255)
		shoe_x := if p.facing_right { k_x + 44 } else { k_x }
		sdl.render_fill_rect(renderer, &sdl.Rect{ x: shoe_x, y: torso_y + 6, w: 12, h: 26 })
	} else if p.move in [.high_kick, .jump_kick] {
		// High kick pose
		k_x := if p.facing_right { px + 24 } else { px - 38 }
		sdl.render_fill_rect(renderer, &sdl.Rect{ x: k_x, y: head_y + 2, w: 44, h: 18 })
		// Supporting leg
		sdl.render_fill_rect(renderer, &sdl.Rect{ x: px + 12, y: pants_y, w: 20, h: ph - (pants_y - py) })
		sdl.set_render_draw_color(renderer, 15, 15, 15, 255)
		shoe_x := if p.facing_right { k_x + 36 } else { k_x }
		sdl.render_fill_rect(renderer, &sdl.Rect{ x: shoe_x, y: head_y - 2, w: 12, h: 24 })
	} else if p.move == .mid_kick {
		k_x := if p.facing_right { px + 24 } else { px - 38 }
		sdl.render_fill_rect(renderer, &sdl.Rect{ x: k_x, y: torso_y + 14, w: 44, h: 18 })
		sdl.render_fill_rect(renderer, &sdl.Rect{ x: px + 12, y: pants_y, w: 20, h: ph - (pants_y - py) })
		sdl.set_render_draw_color(renderer, 15, 15, 15, 255)
		shoe_x := if p.facing_right { k_x + 36 } else { k_x }
		sdl.render_fill_rect(renderer, &sdl.Rect{ x: shoe_x, y: torso_y + 10, w: 12, h: 24 })
	} else {
		// Standing / Walking legs
		pants_h := ph - (pants_y - py)
		sdl.render_fill_rect(renderer, &sdl.Rect{ x: px + 6, y: pants_y, w: 16, h: pants_h })
		sdl.render_fill_rect(renderer, &sdl.Rect{ x: px + 26, y: pants_y, w: 16, h: pants_h })
		// Black Shoes
		sdl.set_render_draw_color(renderer, 15, 15, 15, 255)
		sdl.render_fill_rect(renderer, &sdl.Rect{ x: px + 2, y: py + ph - 8, w: 22, h: 10 })
		sdl.render_fill_rect(renderer, &sdl.Rect{ x: px + 24, y: py + ph - 8, w: 22, h: 10 })
	}

	// 4. Punching arms
	if p.move == .high_punch {
		sdl.set_render_draw_color(renderer, 255, 200, 150, 255)
		arm_x := if p.facing_right { px + 36 } else { px - 36 }
		sdl.render_fill_rect(renderer, &sdl.Rect{ x: arm_x, y: head_y + 4, w: 38, h: 14 })
	} else if p.move == .mid_punch {
		sdl.set_render_draw_color(renderer, 255, 200, 150, 255)
		arm_x := if p.facing_right { px + 36 } else { px - 36 }
		sdl.render_fill_rect(renderer, &sdl.Rect{ x: arm_x, y: torso_y + 10, w: 38, h: 14 })
	} else if p.move == .low_punch {
		sdl.set_render_draw_color(renderer, 255, 200, 150, 255)
		arm_x := if p.facing_right { px + 34 } else { px - 34 }
		sdl.render_fill_rect(renderer, &sdl.Rect{ x: arm_x, y: torso_y + 26, w: 36, h: 14 })
	} else if !is_aerial && p.move != .high_kick && p.move != .mid_kick {
		// Guarding stance arms
		sdl.set_render_draw_color(renderer, 255, 200, 150, 255)
		guard_x := if p.facing_right { px + 28 } else { px + 6 }
		sdl.render_fill_rect(renderer, &sdl.Rect{ x: guard_x, y: torso_y + 8, w: 14, h: 22 })
	}
}

fn render_opponent_master(renderer &sdl.Renderer, mut g YieArKungFuGame, ox_offset int, oy_offset int, tex &sdl.Texture) {
	op := g.opponent
	ox := int(op.x) + ox_offset
	oy := int(op.y) + oy_offset
	ow := int(op.width)
	oh := int(op.height)

	if op.hit_timer > 0.0 && (int(op.hit_timer * 18.0) % 2 == 0) {
		return
	}

	if tex != unsafe { nil } {
		row_y := match g.opponent_type {
			.wang { 64 }
			.tao { 128 }
			.chen { 192 }
			.lang { 256 }
			.mu { 320 }
		}
		col_idx := if op.move in [.high_punch, .mid_punch, .low_punch, .high_kick, .mid_kick, .low_kick, .flying_kick] { 1 } else { 0 }
		src := sdl.Rect{ x: col_idx * 64, y: row_y, w: 64, h: 64 }
		dst := sdl.Rect{ x: ox - 8, y: oy - 20, w: 64, h: 96 }
		flip := if !op.facing_right { sdl.RendererFlip.horizontal } else { sdl.RendererFlip.none }
		sdl.render_copy_ex(renderer, tex, &src, &dst, 0.0, unsafe { nil }, flip)
		return
	}

	match g.opponent_type {
		.wang {
			// Bo Staff Master (Orange Robe, Arms & Long Pole)
			// Robe Torso
			sdl.set_render_draw_color(renderer, 245, 130, 25, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: ox + 6, y: oy, w: ow - 12, h: oh - 20 })

			// Robe skirt & legs
			sdl.set_render_draw_color(renderer, 215, 100, 15, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: ox + 8, y: oy + oh - 24, w: ow - 16, h: 24 })

			// Bald Head & Facial Hair
			sdl.set_render_draw_color(renderer, 255, 195, 140, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: ox + 12, y: oy - 24, w: 24, h: 24 })
			sdl.set_render_draw_color(renderer, 40, 40, 40, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: ox + 14, y: oy - 6, w: 20, h: 6 })

			// Arms Gripping Staff
			sdl.set_render_draw_color(renderer, 255, 195, 140, 255)
			arm_x := if op.facing_right { ox + ow - 10 } else { ox - 4 }
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: arm_x, y: oy + 12, w: 18, h: 12 })
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: arm_x, y: oy + 32, w: 18, h: 12 })

			// Wooden Bo Staff
			sdl.set_render_draw_color(renderer, 160, 95, 30, 255)
			staff_x := if op.facing_right { ox + ow + 2 } else { ox - 14 }
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: staff_x, y: oy - 28, w: 8, h: oh + 34 })
		}
		.tao {
			// Fireball Master (Purple Vest & Green Trousers)
			sdl.set_render_draw_color(renderer, 150, 45, 180, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: ox + 6, y: oy, w: ow - 12, h: 42 })

			sdl.set_render_draw_color(renderer, 45, 160, 75, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: ox + 6, y: oy + 42, w: ow - 12, h: oh - 42 })

			// Head & Fire Spitting Open Mouth
			sdl.set_render_draw_color(renderer, 255, 195, 140, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: ox + 12, y: oy - 24, w: 24, h: 24 })
			sdl.set_render_draw_color(renderer, 20, 20, 20, 255)
			m_x := if op.facing_right { ox + 26 } else { ox + 14 }
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: m_x, y: oy - 8, w: 8, h: 8 })
		}
		.chen {
			// Chain Whip Master (Yellow Robe & Steel Chain)
			sdl.set_render_draw_color(renderer, 240, 210, 35, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: ox + 6, y: oy, w: ow - 12, h: oh })

			// Head & Beard
			sdl.set_render_draw_color(renderer, 255, 195, 140, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: ox + 12, y: oy - 24, w: 24, h: 24 })
			sdl.set_render_draw_color(renderer, 40, 40, 40, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: ox + 10, y: oy - 10, w: 28, h: 12 })

			// Chain Whip Links
			sdl.set_render_draw_color(renderer, 200, 210, 225, 255)
			whip_x := if op.facing_right { ox + ow + 6 } else { ox - 36 }
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: whip_x, y: oy + 28, w: 36, h: 6 })
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: whip_x + (if op.facing_right { 30 } else { -6 }), y: oy + 22, w: 12, h: 18 })
		}
		.lang {
			// Shuriken Fan Master (Blue Robe & Topknot)
			sdl.set_render_draw_color(renderer, 40, 110, 230, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: ox + 6, y: oy, w: ow - 12, h: oh })

			// Head & Hair Bun
			sdl.set_render_draw_color(renderer, 255, 200, 150, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: ox + 12, y: oy - 24, w: 24, h: 24 })
			sdl.set_render_draw_color(renderer, 30, 30, 30, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: ox + 18, y: oy - 32, w: 12, h: 12 })
		}
		.mu {
			// Flying Somersault Master (Black Wingsuit & Cape)
			sdl.set_render_draw_color(renderer, 30, 30, 35, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: ox + 6, y: oy, w: ow - 12, h: oh })

			// Red Cape & Wing Flaps
			sdl.set_render_draw_color(renderer, 220, 40, 40, 255)
			cape_x := if op.facing_right { ox - 18 } else { ox + ow }
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: cape_x, y: oy + 6, w: 18, h: oh - 14 })

			// Head & Mask
			sdl.set_render_draw_color(renderer, 245, 195, 140, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: ox + 12, y: oy - 24, w: 24, h: 24 })
		}
	}
}

fn render_fighting_hud(renderer &sdl.Renderer, mut g YieArKungFuGame) {
	// Top Header Bar: Score & Round Timer
	draw_text_shadow(renderer, 40, 20, '1P  ${g.score:06d}', 2, Color{ r: 255, g: 255, b: 255, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 16, 'TIME', 1, Color{ r: 240, g: 220, b: 40, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 32, '${int(g.round_timer):02d}', 3, Color{ r: 255, g: 255, b: 255, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_shadow(renderer, 620, 20, 'HI  ${g.high_score:06d}', 2, Color{ r: 255, g: 215, b: 40, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })

	// Health Bars (Left = Oolong, Right = Master)
	// 1. Oolong Bar
	draw_text_shadow(renderer, 40, 56, 'OOLONG', 1, Color{ r: 255, g: 150, b: 190, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	sdl.set_render_draw_color(renderer, 40, 40, 40, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: 40, y: 72, w: 300, h: 16 })

	p_hp_w := (g.player.hp * 296) / g.player.max_hp
	sdl.set_render_draw_color(renderer, 60, 210, 80, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: 42, y: 74, w: p_hp_w, h: 12 })

	// 2. Opponent Master Bar
	op_name := match g.opponent_type {
		.wang { 'WANG (POLE)' }
		.tao { 'TAO (FIRE)' }
		.chen { 'CHEN (CHAIN)' }
		.lang { 'LANG (STAR)' }
		.mu { 'MU (FLY)' }
	}
	draw_text_shadow(renderer, 460, 56, op_name, 1, Color{ r: 255, g: 215, b: 40, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	sdl.set_render_draw_color(renderer, 40, 40, 40, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: 460, y: 72, w: 300, h: 16 })

	op_hp_w := (g.opponent.hp * 296) / g.opponent.max_hp
	sdl.set_render_draw_color(renderer, 235, 45, 45, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: 462 + (296 - op_hp_w), y: 74, w: op_hp_w, h: 12 })
}

fn render_particles(renderer &sdl.Renderer, mut g YieArKungFuGame) {
	for pt in g.particles {
		if !pt.active {
			continue
		}
		sdl.set_render_draw_color(renderer, pt.color.r, pt.color.g, pt.color.b, 255)
		rect := sdl.Rect{
			x: int(pt.x)
			y: int(pt.y)
			w: int(pt.size)
			h: int(pt.size)
		}
		sdl.render_fill_rect(renderer, &rect)
	}
}

fn render_score_popups(renderer &sdl.Renderer, mut g YieArKungFuGame) {
	for sp in g.score_popups {
		if !sp.active {
			continue
		}
		draw_text_centered_shadow(renderer, int(sp.x), int(sp.y), sp.text, 2,
			sp.color, Color{ r: 0, g: 0, b: 0, a: 255 })
	}
}

fn render_crt_overlay(renderer &sdl.Renderer) {
	sdl.set_render_draw_blend_mode(renderer, .blend)
	sdl.set_render_draw_color(renderer, 0, 0, 0, 24)
	for y := 0; y < 600; y += 3 {
		line := sdl.Rect{ x: 0, y: y, w: 800, h: 1 }
		sdl.render_fill_rect(renderer, &line)
	}
}

fn render_title_screen(renderer &sdl.Renderer) {
	sdl.set_render_draw_blend_mode(renderer, .blend)
	sdl.set_render_draw_color(renderer, 10, 16, 26, 225)
	scrim := sdl.Rect{ x: 0, y: 0, w: 800, h: 600 }
	sdl.render_fill_rect(renderer, &scrim)

	// Retro Title
	draw_text_centered_shadow(renderer, 400, 75, 'YIE AR KUNG-FU', 5,
		Color{ r: 255, g: 45, b: 45, a: 255 }, Color{ r: 245, g: 215, b: 35, a: 255 })

	draw_text_centered_shadow(renderer, 400, 135, '1985 KONAMI ARCADE / NES FIGHTING LEGEND', 2,
		Color{ r: 60, g: 210, b: 255, a: 255 }, Color{ r: 10, g: 20, b: 40, a: 255 })

	draw_text_centered_shadow(renderer, 400, 215, 'DEFEAT 5 WEAPON MASTERS: WANG, TAO, CHEN, LANG, \u0026 MU!', 1,
		Color{ r: 240, g: 240, b: 240, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })

	draw_text_centered_shadow(renderer, 400, 265, 'PRESS SPACE OR ENTER TO START', 2,
		Color{ r: 255, g: 235, b: 40, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })

	// Controls Summary
	draw_text_centered_shadow(renderer, 400, 335, '16-MOVE COMBAT SYSTEM', 2,
		Color{ r: 255, g: 180, b: 40, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 370, 'A / D (LEFT / RIGHT) : WALK FORWARD / BACKWARD', 1,
		Color{ r: 230, g: 230, b: 230, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 395, 'W / UP : JUMP HIGH (COMBINE WITH J/K FOR AERIAL KICKS)', 1,
		Color{ r: 230, g: 230, b: 230, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 420, 'J / Z : PUNCH (HIGH / MID / LOW BASED ON UP/DOWN)', 1,
		Color{ r: 110, g: 255, b: 130, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 445, 'K / X : KICK (HIGH KICK / MID KICK / CROUCH SWEEP / FLYING KICK)', 1,
		Color{ r: 110, g: 255, b: 130, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 470, 'DEFLECT INCOMING WEAPONS WITH TIMED STRIKES!', 1,
		Color{ r: 100, g: 220, b: 255, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 495, '[P] PAUSE  [M] MUTE  [C] CRT SCANLINES  [R] RESTART  [F11] Fullscreen', 1,
		Color{ r: 255, g: 215, b: 110, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })

	draw_text_centered_shadow(renderer, 400, 560, '(C) 1985 KONAMI INDUSTRY CO., LTD.', 1,
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

fn render_round_clear_screen(renderer &sdl.Renderer) {
	sdl.set_render_draw_blend_mode(renderer, .blend)
	sdl.set_render_draw_color(renderer, 0, 0, 0, 180)
	scrim := sdl.Rect{ x: 0, y: 0, w: 800, h: 600 }
	sdl.render_fill_rect(renderer, &scrim)

	draw_text_centered_shadow(renderer, 400, 230, 'K.O.! YOU WIN!', 4,
		Color{ r: 80, g: 255, b: 100, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 290, 'MASTER DEFEATED!', 2,
		Color{ r: 255, g: 230, b: 60, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 345, 'PRESS SPACE FOR NEXT MASTER', 2,
		Color{ r: 255, g: 255, b: 255, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
}

fn render_game_over_screen(renderer &sdl.Renderer, mut g YieArKungFuGame) {
	sdl.set_render_draw_blend_mode(renderer, .blend)
	sdl.set_render_draw_color(renderer, 0, 0, 0, 210)
	scrim := sdl.Rect{ x: 0, y: 0, w: 800, h: 600 }
	sdl.render_fill_rect(renderer, &scrim)

	draw_text_centered_shadow(renderer, 400, 230, 'GAME OVER', 5,
		Color{ r: 255, g: 40, b: 40, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 300, 'FINAL SCORE: ${g.score}', 2,
		Color{ r: 255, g: 255, b: 255, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 360, 'PRESS SPACE TO RETRY', 2,
		Color{ r: 255, g: 230, b: 40, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
}

fn render_victory_screen(renderer &sdl.Renderer) {
	sdl.set_render_draw_blend_mode(renderer, .blend)
	sdl.set_render_draw_color(renderer, 0, 0, 0, 220)
	scrim := sdl.Rect{ x: 0, y: 0, w: 800, h: 600 }
	sdl.render_fill_rect(renderer, &scrim)

	draw_text_centered_shadow(renderer, 400, 220, 'GRAND MASTER OF KUNG-FU!', 3,
		Color{ r: 255, g: 215, b: 40, a: 255 }, Color{ r: 255, g: 45, b: 45, a: 255 })
	draw_text_centered_shadow(renderer, 400, 280, 'ALL 5 WEAPON MASTERS VANQUISHED!', 2,
		Color{ r: 255, g: 255, b: 255, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 340, 'PRESS SPACE TO RESTART', 2,
		Color{ r: 100, g: 220, b: 255, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
}
