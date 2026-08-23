module main

import math
import sdl

fn draw_uno_game(renderer &sdl.Renderer, g &UnoGame) {
	// Screen shake calculation
	mut shake_x := 0
	mut shake_y := 0
	if g.shake_timer > 0.0 && g.shake_intensity > 0.0 {
		decay := g.shake_timer / 0.45
		s := g.shake_intensity * decay
		shake_x = int(math.sin(g.anim_timer * 45.0) * s)
		shake_y = int(math.cos(g.anim_timer * 40.0) * s)
	}

	// Deep Casino / Arcade Floor
	draw_uno_table_background(renderer, shake_x, shake_y)

	draw_table_center(renderer, shake_x, shake_y, g)
	draw_player_hands(renderer, shake_x, shake_y, g)
	draw_flying_cards(renderer, shake_x, shake_y, g)
	draw_special_effects(renderer, shake_x, shake_y, g)
	draw_action_prompts(renderer, shake_x, shake_y, g)

	if g.celebration != '' {
		draw_celebration_banner(renderer, shake_x, shake_y, g)
	}

	if g.state == .color_pick {
		draw_color_picker_modal(renderer, shake_x, shake_y)
	}
}

fn draw_uno_table_background(renderer &sdl.Renderer, sx int, sy int) {
	// Outer stadium table with deep indigo felt gradient
	for y := 0; y < 600; y += 4 {
		shade := u8(12 + (y * 8) / 600)
		sdl.set_render_draw_color(renderer, shade + 2, shade + 8, shade + 28, 255)
		rect := sdl.Rect{ x: 0, y: y, w: 800, h: 4 }
		sdl.render_fill_rect(renderer, &rect)
	}

	// Polished Cherry Wood Outer Frame with Brass Corner Bolts
	sdl.set_render_draw_color(renderer, 58, 20, 16, 255)
	frame := sdl.Rect{ x: 6 + sx, y: 6 + sy, w: 788, h: 588 }
	sdl.render_draw_rect(renderer, &frame)

	sdl.set_render_draw_color(renderer, 95, 36, 26, 255)
	inner_rim := sdl.Rect{ x: 8 + sx, y: 8 + sy, w: 784, h: 584 }
	sdl.render_draw_rect(renderer, &inner_rim)

	// Gold Inlay Line
	sdl.set_render_draw_color(renderer, 215, 175, 45, 180)
	gold_line := sdl.Rect{ x: 12 + sx, y: 12 + sy, w: 776, h: 576 }
	sdl.render_draw_rect(renderer, &gold_line)
}

fn draw_table_center(renderer &sdl.Renderer, sx int, sy int, g &UnoGame) {
	cx := 400 + sx
	cy := 265 + sy

	// Center Felt Circle with Depth Ring
	draw_filled_circle(renderer, cx, cy, 114, Color{ r: 16, g: 22, b: 42 })

	// Active Color Indicator Halo Ring with pulsing thickness
	col_rgb := get_color_rgb(g.active_color)
	pulse := (math.sin(g.anim_timer * 6.0) + 1.0) * 0.5
	ring_thick := int(5.0 + pulse * 3.0)
	draw_circle_ring(renderer, cx, cy, 110, ring_thick, col_rgb)
	draw_circle_ring(renderer, cx, cy, 114, 1, Color{ r: 255, g: 255, b: 255, a: 180 })

	// Direction Rotation Indicator
	dir_str := if g.direction == 1 { 'ROTATION: CLOCKWISE ↻' } else { '↺ ROTATION: COUNTER-CW' }
	draw_text_centered(renderer, cx, cy - 96, dir_str, 1, Color{ r: 240, g: 230, b: 150 })

	// Draw Pile (Stacked Face Down Cards)
	draw_pile_x := cx - 78
	draw_pile_y := cy - 48
	card_w := 62
	card_h := 90

	// Deck thickness shadows
	draw_card_back(renderer, draw_pile_x + 3, draw_pile_y - 3, card_w, card_h)
	draw_card_back(renderer, draw_pile_x, draw_pile_y, card_w, card_h)

	draw_text_centered(renderer, draw_pile_x + card_w / 2, draw_pile_y + card_h + 8, 'DECK (${g.deck.len})', 1, Color{ r: 210, g: 230, b: 255 })

	// Discard Pile (Top Face Up Card)
	top_card := g.top_discard()
	dis_pile_x := cx + 16
	dis_pile_y := cy - 48
	draw_uno_card(renderer, dis_pile_x, dis_pile_y, card_w, card_h, top_card, false, true)

	// Active Color Badge Banner
	col_name := match g.active_color {
		.red        { 'RED' }
		.blue       { 'BLUE' }
		.green      { 'GREEN' }
		.yellow     { 'YELLOW' }
		.wild_color { 'ANY COLOR' }
	}
	draw_text_centered(renderer, cx, cy + 62, 'ACTIVE COLOR: ${col_name}', 1, col_rgb)
}

fn draw_player_hands(renderer &sdl.Renderer, sx int, sy int, g &UnoGame) {
	// Top Player (Bot Bob)
	draw_bot_horizontal_hand(renderer, 400 + sx, 35 + sy, &g.players[2], g.current_p_idx == 2)

	// Left Player (Bot Alice)
	draw_bot_vertical_hand(renderer, 80 + sx, 260 + sy, &g.players[1], g.current_p_idx == 1)

	// Right Player (Bot Charlie)
	draw_bot_vertical_hand(renderer, 720 + sx, 260 + sy, &g.players[3], g.current_p_idx == 3)

	// Bottom Player (Human Player 1)
	draw_human_hand(renderer, sx, sy, g)
}

fn draw_human_hand(renderer &sdl.Renderer, sx int, sy int, g &UnoGame) {
	p := &g.players[0]
	hand_len := p.hand.len
	if hand_len == 0 {
		return
	}

	card_w := 62
	card_h := 90
	spacing := math.min(54.0, 540.0 / f64(math.max(1, hand_len)))
	total_w := int(f64(hand_len - 1) * spacing) + card_w
	start_x := 400 + sx - total_w / 2
	base_y := 472 + sy

	// Player Turn Indicator
	is_my_turn := g.current_p_idx == 0
	turn_col := if is_my_turn { Color{ r: 255, g: 220, b: 50 } } else { Color{ r: 200, g: 200, b: 200 } }
	draw_text_centered(renderer, 400 + sx, 428 + sy, '${p.name} - ${hand_len} CARDS ${if is_my_turn { '(YOUR TURN!)' } else { '' }}', 1, turn_col)

	for i := 0; i < hand_len; i++ {
		card := p.hand[i]
		cx := start_x + int(f64(i) * spacing)
		is_selected := i == g.selected_card
		is_playable := is_my_turn && g.is_card_playable(card)

		cy := if is_selected { base_y - 22 } else { base_y }
		draw_uno_card(renderer, cx, cy, card_w, card_h, card, is_selected, is_playable)
	}
}

fn draw_bot_horizontal_hand(renderer &sdl.Renderer, cx int, cy int, p &UnoPlayer, is_turn bool) {
	hand_len := p.hand.len
	name_col := if is_turn { Color{ r: 255, g: 215, b: 0 } } else { Color{ r: 220, g: 220, b: 220 } }
	draw_text_centered(renderer, cx, cy, '${p.name} (${hand_len} cards)${if is_turn { ' *' } else { '' }}', 1, name_col)

	if hand_len == 0 { return }
	card_w := 34
	card_h := 46
	spacing := math.min(22.0, 240.0 / f64(math.max(1, hand_len)))
	total_w := int(f64(hand_len - 1) * spacing) + card_w
	start_x := cx - total_w / 2
	cards_y := cy + 14

	for i := 0; i < hand_len; i++ {
		bx := start_x + int(f64(i) * spacing)
		draw_card_back(renderer, bx, cards_y, card_w, card_h)
	}
}

fn draw_bot_vertical_hand(renderer &sdl.Renderer, cx int, cy int, p &UnoPlayer, is_turn bool) {
	hand_len := p.hand.len
	if hand_len == 0 { return }
	card_w := 44
	card_h := 28
	spacing := math.min(16.0, 140.0 / f64(math.max(1, hand_len)))
	total_h := int(f64(hand_len - 1) * spacing) + card_h
	start_y := cy - total_h / 2 + 10
	cards_x := cx - card_w / 2

	name_col := if is_turn { Color{ r: 255, g: 215, b: 0 } } else { Color{ r: 220, g: 220, b: 220 } }
	draw_text_centered(renderer, cx, start_y - 24, '${p.name}', 1, name_col)
	draw_text_centered(renderer, cx, start_y - 12, '(${hand_len})', 1, Color{ r: 180, g: 200, b: 220 })

	for i := 0; i < hand_len; i++ {
		by := start_y + int(f64(i) * spacing)
		draw_card_back(renderer, cards_x, by, card_w, card_h)
	}
}

// -------------------------------------------------------------
// High-Definition Uno Card Graphics
// -------------------------------------------------------------

fn draw_uno_card(renderer &sdl.Renderer, x int, y int, w int, h int, card UnoCard, is_selected bool, is_playable bool) {
	// Drop Shadow
	sdl.set_render_draw_color(renderer, 0, 0, 0, 110)
	shadow := sdl.Rect{ x: x + 2, y: y + 3, w: w, h: h }
	sdl.render_fill_rect(renderer, &shadow)

	// Outer White Border Base
	bg := sdl.Rect{ x: x, y: y, w: w, h: h }
	sdl.set_render_draw_color(renderer, 252, 252, 255, 255)
	sdl.render_fill_rect(renderer, &bg)

	// Card Color Fill
	card_bg := get_color_rgb(card.color)
	inner := sdl.Rect{ x: x + 2, y: y + 2, w: w - 4, h: h - 4 }
	sdl.set_render_draw_color(renderer, card_bg.r, card_bg.g, card_bg.b, 255)
	sdl.render_fill_rect(renderer, &inner)

	// Inner Gradient / Gloss Highlight
	sdl.set_render_draw_color(renderer, 255, 255, 255, 60)
	for gy := 0; gy < h / 3; gy++ {
		sdl.render_draw_line(renderer, x + 3, y + 3 + gy, x + w - 4, y + 3 + gy)
	}

	cx := x + w / 2
	cy := y + h / 2

	if card.color == .wild_color {
		draw_wild_quadrant_disc(renderer, cx, cy, int(f64(w) * 0.32))
	} else {
		// Standard White Center Oval
		draw_filled_circle(renderer, cx, cy, int(f64(w) * 0.30), Color{ r: 255, g: 255, b: 255 })
		draw_circle_ring(renderer, cx, cy, int(f64(w) * 0.30), 1, Color{ r: 220, g: 220, b: 225 })
	}

	// Center Card Symbol Artwork
	draw_uno_symbol_artwork(renderer, cx, cy, card.typ, card.color, w)

	// Top-Left & Bottom-Right Corner Symbols
	sym_str := get_card_symbol_str(card.typ)
	corner_col := if card.color == .wild_color { Color{ r: 255, g: 215, b: 0 } } else { Color{ r: 255, g: 255, b: 255 } }

	draw_text(renderer, x + 4, y + 4, sym_str, 1, corner_col)
	draw_text(renderer, x + w - 12, y + h - 12, sym_str, 1, corner_col)

	// Outer Playable Highlight / Selection Glow
	if is_selected {
		draw_circle_ring(renderer, cx, cy, int(f64(w) * 0.55), 2, Color{ r: 255, g: 220, b: 40 })
		sdl.set_render_draw_color(renderer, 255, 220, 40, 255)
		sdl.render_draw_rect(renderer, &bg)
	} else if is_playable {
		sdl.set_render_draw_color(renderer, 255, 255, 255, 255)
		sdl.render_draw_rect(renderer, &bg)
	} else {
		sdl.set_render_draw_color(renderer, 70, 75, 85, 255)
		sdl.render_draw_rect(renderer, &bg)
	}
}

fn draw_uno_symbol_artwork(renderer &sdl.Renderer, cx int, cy int, typ UnoCardType, col UnoColor, _w int) {
	match typ {
		.num_0, .num_1, .num_2, .num_3, .num_4, .num_5, .num_6, .num_7, .num_8, .num_9 {
			num_str := get_card_symbol_str(typ)
			txt_col := get_color_rgb(col)
			draw_text_centered(renderer, cx + 1, cy - 7, num_str, 2, Color{ r: 180, g: 180, b: 180 })
			draw_text_centered(renderer, cx, cy - 8, num_str, 2, txt_col)
		}
		.skip {
			// Prohibition Slash Circle (⊘)
			draw_circle_ring(renderer, cx, cy, 11, 2, Color{ r: 225, g: 35, b: 45 })
			sdl.set_render_draw_color(renderer, 225, 35, 45, 255)
			sdl.render_draw_line(renderer, cx - 7, cy + 7, cx + 7, cy - 7)
			sdl.render_draw_line(renderer, cx - 7, cy + 6, cx + 6, cy - 7)
		}
		.reverse {
			// Looping Twin Arrows (⇄)
			sdl.set_render_draw_color(renderer, 0, 115, 220, 255)
			// Top right arrow
			sdl.render_draw_line(renderer, cx - 8, cy - 4, cx + 6, cy - 4)
			sdl.render_draw_line(renderer, cx + 6, cy - 4, cx + 2, cy - 8)
			sdl.render_draw_line(renderer, cx + 6, cy - 4, cx + 2, cy)
			// Bottom left arrow
			sdl.render_draw_line(renderer, cx + 8, cy + 4, cx - 6, cy + 4)
			sdl.render_draw_line(renderer, cx - 6, cy + 4, cx - 2, cy)
			sdl.render_draw_line(renderer, cx - 6, cy + 4, cx - 2, cy + 8)
		}
		.draw_two {
			// Stacked Mini Cards +2
			sdl.set_render_draw_color(renderer, 40, 170, 60, 255)
			c1 := sdl.Rect{ x: cx - 9, y: cy - 9, w: 10, h: 14 }
			c2 := sdl.Rect{ x: cx - 4, y: cy - 5, w: 10, h: 14 }
			sdl.render_fill_rect(renderer, &c1)
			sdl.set_render_draw_color(renderer, 255, 255, 255, 255)
			sdl.render_draw_rect(renderer, &c1)
			sdl.set_render_draw_color(renderer, 40, 170, 60, 255)
			sdl.render_fill_rect(renderer, &c2)
			sdl.set_render_draw_color(renderer, 255, 255, 255, 255)
			sdl.render_draw_rect(renderer, &c2)
			draw_text_centered(renderer, cx + 8, cy - 4, '+2', 1, Color{ r: 255, g: 255, b: 255 })
		}
		.wild {
			// Center "WILD" Gold Banner
			draw_text_centered(renderer, cx + 1, cy - 3, 'WILD', 1, Color{ r: 10, g: 10, b: 15 })
			draw_text_centered(renderer, cx, cy - 4, 'WILD', 1, Color{ r: 255, g: 255, b: 255 })
		}
		.wild_draw_four {
			// +4 Badge in Center of 4-Color Disc
			draw_text_centered(renderer, cx + 1, cy - 5, '+4', 2, Color{ r: 10, g: 10, b: 15 })
			draw_text_centered(renderer, cx, cy - 6, '+4', 2, Color{ r: 255, g: 255, b: 255 })
		}
	}
}

fn draw_wild_quadrant_disc(renderer &sdl.Renderer, cx int, cy int, r int) {
	for dy := -r; dy <= r; dy++ {
		for dx := -r; dx <= r; dx++ {
			if dx * dx + dy * dy <= r * r {
				col := if dx < 0 && dy < 0 {
					Color{ r: 225, g: 35, b: 45 } // Top-left: Red
				} else if dx >= 0 && dy < 0 {
					Color{ r: 35, g: 110, b: 225 } // Top-right: Blue
				} else if dx < 0 && dy >= 0 {
					Color{ r: 235, g: 195, b: 25 } // Bottom-left: Yellow
				} else {
					Color{ r: 45, g: 175, b: 55 } // Bottom-right: Green
				}
				sdl.set_render_draw_color(renderer, col.r, col.g, col.b, 255)
				sdl.render_draw_point(renderer, cx + dx, cy + dy)
			}
		}
	}
	draw_circle_ring(renderer, cx, cy, r, 1, Color{ r: 255, g: 255, b: 255 })
}

fn draw_card_back(renderer &sdl.Renderer, x int, y int, w int, h int) {
	// Drop Shadow
	sdl.set_render_draw_color(renderer, 0, 0, 0, 90)
	shadow := sdl.Rect{ x: x + 2, y: y + 3, w: w, h: h }
	sdl.render_fill_rect(renderer, &shadow)

	// White Border Base
	bg := sdl.Rect{ x: x, y: y, w: w, h: h }
	sdl.set_render_draw_color(renderer, 250, 250, 255, 255)
	sdl.render_fill_rect(renderer, &bg)

	// Obsidian Black Body
	inner := sdl.Rect{ x: x + 2, y: y + 2, w: w - 4, h: h - 4 }
	sdl.set_render_draw_color(renderer, 20, 22, 28, 255)
	sdl.render_fill_rect(renderer, &inner)

	// Crimson Center Oval
	cx := x + w / 2
	cy := y + h / 2
	draw_filled_circle(renderer, cx, cy, int(f64(w) * 0.32), Color{ r: 220, g: 30, b: 42 })

	// "UNO" 3D Shadowed Gold Logo
	draw_text_centered(renderer, cx + 1, cy - 3, 'UNO', 1, Color{ r: 30, g: 15, b: 0 })
	draw_text_centered(renderer, cx, cy - 4, 'UNO', 1, Color{ r: 255, g: 215, b: 45 })
}

// -------------------------------------------------------------
// Flying Cards & Visual Special Effects
// -------------------------------------------------------------

fn draw_flying_cards(renderer &sdl.Renderer, sx int, sy int, g &UnoGame) {
	card_w := 62
	card_h := 90
	for fc in g.flying_cards {
		fx := int(fc.x) + sx
		fy := int(fc.y) + sy

		if fc.is_face_up {
			flip_factor := math.abs(math.cos(fc.flip_progress * math.pi))
			cur_w := int(f64(card_w) * (0.2 + flip_factor * 0.8))
			cur_x := fx + (card_w - cur_w) / 2
			draw_uno_card(renderer, cur_x, fy, cur_w, card_h, fc.card, false, true)
		} else {
			draw_card_back(renderer, fx, fy, card_w, card_h)
		}
	}
}

fn draw_special_effects(renderer &sdl.Renderer, sx int, sy int, g &UnoGame) {
	for sw in g.shockwaves {
		alpha := u8(255.0 * (1.0 - sw.life / sw.max_life))
		c := Color{ r: sw.color.r, g: sw.color.g, b: sw.color.b, a: alpha }
		draw_circle_ring(renderer, int(sw.cx) + sx, int(sw.cy) + sy, int(sw.radius), int(sw.thickness), c)
	}

	for p in g.particles {
		alpha := u8(255.0 * (1.0 - p.life / p.max_life))
		col := Color{ r: p.color.r, g: p.color.g, b: p.color.b, a: alpha }
		px := int(p.x) + sx
		py := int(p.y) + sy
		sz := int(p.size)

		if p.shape_type == 0 {
			sdl.set_render_draw_color(renderer, col.r, col.g, col.b, col.a)
			sdl.render_draw_line(renderer, px, py, px + int(p.vx * 0.04), py + int(p.vy * 0.04))
			draw_filled_circle(renderer, px, py, sz, col)
		} else if p.shape_type == 2 {
			c_rect := sdl.Rect{ x: px - sz, y: py - sz / 2, w: sz * 2, h: sz }
			sdl.set_render_draw_color(renderer, col.r, col.g, col.b, col.a)
			sdl.render_fill_rect(renderer, &c_rect)
		} else {
			draw_filled_circle(renderer, px, py, sz, col)
		}
	}

	for ft in g.floating_texts {
		alpha := u8(255.0 * (1.0 - ft.life / ft.max_life))
		col := Color{ r: ft.color.r, g: ft.color.g, b: ft.color.b, a: alpha }
		tx := int(ft.x) + sx
		ty := int(ft.y) + sy

		draw_status_pill(renderer, tx, ty, ft.text, Color{ r: 12, g: 18, b: 30 }, col)
	}
}

fn draw_status_pill(renderer &sdl.Renderer, cx int, cy int, text string, bg_col Color, txt_col Color) {
	tw := text.len * 8 + 18
	pill := sdl.Rect{ x: cx - tw / 2, y: cy - 9, w: tw, h: 18 }
	sdl.set_render_draw_color(renderer, bg_col.r, bg_col.g, bg_col.b, 240)
	sdl.render_fill_rect(renderer, &pill)
	sdl.set_render_draw_color(renderer, txt_col.r, txt_col.g, txt_col.b, 255)
	sdl.render_draw_rect(renderer, &pill)
	draw_text_centered(renderer, cx, cy - 4, text, 1, txt_col)
}

fn draw_action_prompts(renderer &sdl.Renderer, sx int, sy int, g &UnoGame) {
	// Bottom Controls Bar
	bar_rect := sdl.Rect{ x: 20 + sx, y: 568 + sy, w: 760, h: 26 }
	sdl.set_render_draw_color(renderer, 10, 15, 25, 245)
	sdl.render_fill_rect(renderer, &bar_rect)
	sdl.set_render_draw_color(renderer, 220, 180, 50, 255)
	sdl.render_draw_rect(renderer, &bar_rect)

	prompt_str := if g.state == .player_turn {
		'[LEFT/RIGHT] SELECT | [SPACE/ENTER] PLAY | [D] DRAW CARD | [U] SHOUT UNO | [M] SOUND'
	} else if g.state == .round_over {
		'[SPACE/ENTER] NEXT ROUND | [M] SOUND'
	} else {
		'OPPONENTS ARE PLAYING... | [M] SOUND'
	}

	draw_text_centered(renderer, 400 + sx, 575 + sy, prompt_str, 1, Color{ r: 255, g: 235, b: 120 })
}

fn draw_celebration_banner(renderer &sdl.Renderer, sx int, sy int, g &UnoGame) {
	box_w := 540
	box_h := 38
	bx := (800 - box_w) / 2 + sx
	by := 148 + sy

	sdl.set_render_draw_color(renderer, 12, 18, 30, 250)
	b_rect := sdl.Rect{ x: bx, y: by, w: box_w, h: box_h }
	sdl.render_fill_rect(renderer, &b_rect)

	sdl.set_render_draw_color(renderer, 255, 215, 50, 255)
	sdl.render_draw_rect(renderer, &b_rect)

	draw_text_centered(renderer, 400 + sx, by + 13, g.celebration, 1, Color{ r: 255, g: 230, b: 70 })
}

fn draw_color_picker_modal(renderer &sdl.Renderer, sx int, sy int) {
	// Modal backdrop
	modal := sdl.Rect{ x: 260 + sx, y: 160 + sy, w: 280, h: 220 }
	sdl.set_render_draw_color(renderer, 14, 18, 28, 250)
	sdl.render_fill_rect(renderer, &modal)

	sdl.set_render_draw_color(renderer, 255, 215, 0, 255)
	sdl.render_draw_rect(renderer, &modal)

	draw_text_centered(renderer, 400 + sx, 180 + sy, 'CHOOSE ACTIVE COLOR', 1, Color{ r: 255, g: 255, b: 255 })

	// 4 Color Buttons
	cols := [
		Color{ r: 225, g: 35, b: 45 },
		Color{ r: 35, g: 110, b: 225 },
		Color{ r: 45, g: 175, b: 55 },
		Color{ r: 235, g: 195, b: 25 },
	]
	labels := ['[1] RED', '[2] BLUE', '[3] GREEN', '[4] YELLOW']

	for i := 0; i < 4; i++ {
		bx := 290 + sx + (i % 2) * 115
		by := 210 + sy + (i / 2) * 65
		b_rect := sdl.Rect{ x: bx, y: by, w: 105, h: 50 }

		sdl.set_render_draw_color(renderer, cols[i].r, cols[i].g, cols[i].b, 255)
		sdl.render_fill_rect(renderer, &b_rect)

		sdl.set_render_draw_color(renderer, 255, 255, 255, 255)
		sdl.render_draw_rect(renderer, &b_rect)

		draw_text_centered(renderer, bx + 52, by + 20, labels[i], 1, Color{ r: 255, g: 255, b: 255 })
	}
}

fn get_color_rgb(col UnoColor) Color {
	return match col {
		.red        { Color{ r: 225, g: 35, b: 45 } }
		.blue       { Color{ r: 30, g: 115, b: 225 } }
		.green      { Color{ r: 40, g: 170, b: 60 } }
		.yellow     { Color{ r: 240, g: 195, b: 25 } }
		.wild_color { Color{ r: 28, g: 30, b: 36 } }
	}
}

fn get_card_symbol_str(typ UnoCardType) string {
	return match typ {
		.num_0          { '0' }
		.num_1          { '1' }
		.num_2          { '2' }
		.num_3          { '3' }
		.num_4          { '4' }
		.num_5          { '5' }
		.num_6          { '6' }
		.num_7          { '7' }
		.num_8          { '8' }
		.num_9          { '9' }
		.skip           { '⊘' }
		.reverse        { '⇄' }
		.draw_two       { '+2' }
		.wild           { 'W' }
		.wild_draw_four { '+4' }
	}
}

fn draw_filled_circle(renderer &sdl.Renderer, cx int, cy int, r int, c Color) {
	sdl.set_render_draw_color(renderer, c.r, c.g, c.b, c.a)
	for dy := -r; dy <= r; dy++ {
		for dx := -r; dx <= r; dx++ {
			if dx * dx + dy * dy <= r * r {
				sdl.render_draw_point(renderer, cx + dx, cy + dy)
			}
		}
	}
}

fn draw_circle_ring(renderer &sdl.Renderer, cx int, cy int, r int, thickness int, c Color) {
	sdl.set_render_draw_color(renderer, c.r, c.g, c.b, c.a)
	r_outer := r + thickness / 2
	r_inner := r - thickness / 2
	for dy := -r_outer; dy <= r_outer; dy++ {
		for dx := -r_outer; dx <= r_outer; dx++ {
			d2 := dx * dx + dy * dy
			if d2 <= r_outer * r_outer && d2 >= r_inner * r_inner {
				sdl.render_draw_point(renderer, cx + dx, cy + dy)
			}
		}
	}
}
