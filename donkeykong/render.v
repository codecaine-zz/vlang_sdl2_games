import math
import os
import sdl
import sdl.image

pub struct DonkeyKongTextureManager {
pub mut:
	sprite_texture &sdl.Texture = unsafe { nil }
}

pub fn (mut tm DonkeyKongTextureManager) init(renderer &sdl.Renderer) {
	_ = image.init(int(image.InitFlags.png))
	candidates := [
		'assets/sprites/donkeykong.png',
		'./assets/sprites/donkeykong.png',
		'../assets/sprites/donkeykong.png',
		'donkeykong/assets/sprites/donkeykong.png',
	]
	for p in candidates {
		if os.exists(p) {
			surface := image.load(p.str)
			if surface != unsafe { nil } {
				tm.sprite_texture = sdl.create_texture_from_surface(renderer, surface)
				sdl.free_surface(surface)
				if tm.sprite_texture != unsafe { nil } {
					println('DonkeyKong Texture Loaded Successfully: ' + p)
					return
				}
			}
		}
	}
}

fn render_donkeykong_game(renderer &sdl.Renderer, mut g DonkeyKongGame, tex &sdl.Texture) {
	// Arcade black background
	sdl.set_render_draw_color(renderer, 5, 5, 12, 255)
	sdl.render_clear(renderer)

	// 1. Draw Red Slanted Girders (Arcade lattice design)
	for g_line in g.girders {
		sdl.set_render_draw_color(renderer, 220, 40, 60, 255)
		sdl.render_draw_line(renderer, int(g_line.x1), int(g_line.y1), int(g_line.x2), int(g_line.y2))
		sdl.render_draw_line(renderer, int(g_line.x1), int(g_line.y1 + 6.0), int(g_line.x2), int(g_line.y2 + 6.0))
		
		// Cross-bracing girder lattice lines
		dx := g_line.x2 - g_line.x1
		dy := g_line.y2 - g_line.y1
		length := math.sqrt(dx * dx + dy * dy)
		steps := int(length / 20.0)
		if steps > 0 {
			sdl.set_render_draw_color(renderer, 160, 20, 40, 255)
			for i in 0 .. steps {
				t1 := f32(i) / f32(steps)
				t2 := f32(i + 1) / f32(steps)
				px1 := g_line.x1 + t1 * dx
				py1 := g_line.y1 + t1 * dy
				px2 := g_line.x1 + t2 * dx
				py2 := g_line.y1 + t2 * dy
				sdl.render_draw_line(renderer, int(px1), int(py1), int(px2), int(py2 + 6.0))
			}
		}
	}

	// 2. Draw Yellow Ladders
	sdl.set_render_draw_color(renderer, 240, 220, 30, 255)
	for l in g.ladders {
		lx := int(l.x)
		ty := int(l.top_y)
		by := int(l.bot_y)
		// Vertical sides
		sdl.render_draw_line(renderer, lx - 8, ty, lx - 8, by)
		sdl.render_draw_line(renderer, lx + 8, ty, lx + 8, by)
		// Rungs
		for y_step := ty; y_step <= by; y_step += 10 {
			sdl.render_draw_line(renderer, lx - 8, y_step, lx + 8, y_step)
		}
	}

	// 3. Draw Oil Drum at Bottom Left (X 65, Y 500)
	sdl.set_render_draw_color(renderer, 30, 100, 200, 255)
	oil_rect := sdl.Rect{ x: 65, y: 500, w: 32, h: 36 }
	sdl.render_fill_rect(renderer, &oil_rect)
	sdl.set_render_draw_color(renderer, 240, 240, 240, 255)
	oil_band := sdl.Rect{ x: 65, y: 514, w: 32, h: 8 }
	sdl.render_fill_rect(renderer, &oil_band)
	draw_text(renderer, 70, 514, "OIL", 1, Color{ r: 20, g: 20, b: 20, a: 255 })

	// Animated Fire on top of Oil Drum
	flicker := (sdl.get_ticks() / 100) % 2 == 0
	sdl.set_render_draw_color(renderer, 255, 120, 0, 255)
	fire1 := sdl.Rect{ x: 69, y: 486, w: 24, h: 14 }
	sdl.render_fill_rect(renderer, &fire1)
	fire_color2 := if flicker { Color{ r: 255, g: 240, b: 0, a: 255 } } else { Color{ r: 255, g: 60, b: 0, a: 255 } }
	sdl.set_render_draw_color(renderer, fire_color2.r, fire_color2.g, fire_color2.b, 255)
	fire2 := sdl.Rect{ x: 74, y: 482, w: 14, h: 10 }
	sdl.render_fill_rect(renderer, &fire2)

	// 4. Draw Stacked Barrels next to DK (X 70..110, Y 100..140)
	sdl.set_render_draw_color(renderer, 170, 90, 20, 255)
	b_stack1 := sdl.Rect{ x: 75, y: 100, w: 16, h: 38 }
	b_stack2 := sdl.Rect{ x: 94, y: 100, w: 16, h: 38 }
	sdl.render_fill_rect(renderer, &b_stack1)
	sdl.render_fill_rect(renderer, &b_stack2)
	sdl.set_render_draw_color(renderer, 240, 200, 50, 255)
	b_ring1 := sdl.Rect{ x: 75, y: 114, w: 16, h: 10 }
	b_ring2 := sdl.Rect{ x: 94, y: 114, w: 16, h: 10 }
	sdl.render_fill_rect(renderer, &b_ring1)
	sdl.render_fill_rect(renderer, &b_ring2)

	// 5. 16-Bit Donkey Kong Ape at Top
	if tex != unsafe { nil } {
		col_x := if g.dk_anim_timer > 0 { 64 } else { 0 }
		src := sdl.Rect{ x: col_x, y: 64, w: 64, h: 64 }
		dst := sdl.Rect{ x: 124, y: 84, w: 58, h: 58 }
		sdl.render_copy(renderer, tex, &src, &dst)
	} else {
		sdl.set_render_draw_color(renderer, 130, 60, 15, 255)
		dk_body := sdl.Rect{ x: 130, y: 90, w: 46, h: 48 }
		sdl.render_fill_rect(renderer, &dk_body)

		// Chest Fur (Tan/Peach)
		sdl.set_render_draw_color(renderer, 235, 185, 135, 255)
		chest := sdl.Rect{ x: 140, y: 104, w: 26, h: 28 }
		sdl.render_fill_rect(renderer, &chest)

		// DK Arms (Animated chest beating)
		sdl.set_render_draw_color(renderer, 130, 60, 15, 255)
		if g.dk_anim_timer > 0 {
			arm_l := sdl.Rect{ x: 118, y: 80, w: 16, h: 26 }
			arm_r := sdl.Rect{ x: 172, y: 80, w: 16, h: 26 }
			sdl.render_fill_rect(renderer, &arm_l)
			sdl.render_fill_rect(renderer, &arm_r)
		} else {
			arm_l := sdl.Rect{ x: 120, y: 100, w: 12, h: 30 }
			arm_r := sdl.Rect{ x: 174, y: 100, w: 12, h: 30 }
			sdl.render_fill_rect(renderer, &arm_l)
			sdl.render_fill_rect(renderer, &arm_r)
		}

		// DK Face & Snout
		sdl.set_render_draw_color(renderer, 235, 185, 135, 255)
		dk_face := sdl.Rect{ x: 142, y: 94, w: 22, h: 14 }
		sdl.render_fill_rect(renderer, &dk_face)
		sdl.set_render_draw_color(renderer, 20, 10, 5, 255)
		sdl.render_draw_point(renderer, 148, 98)
		sdl.render_draw_point(renderer, 156, 98)
	}

	// 6. 16-Bit Pauline Damsel in Distress
	sdl.set_render_draw_color(renderer, 245, 60, 140, 255)
	p_dress := sdl.Rect{ x: 350, y: 65, w: 18, h: 24 }
	sdl.render_fill_rect(renderer, &p_dress)

	// Blonde Hair & Face
	sdl.set_render_draw_color(renderer, 255, 220, 50, 255)
	hair := sdl.Rect{ x: 351, y: 52, w: 16, h: 10 }
	sdl.render_fill_rect(renderer, &hair)
	sdl.set_render_draw_color(renderer, 255, 200, 170, 255)
	p_head := sdl.Rect{ x: 354, y: 56, w: 10, h: 8 }
	sdl.render_fill_rect(renderer, &p_head)

	// Help Bubble
	draw_text(renderer, 380, 50, 'HELP!', 1, Color{ r: 255, g: 100, b: 180, a: 255 })

	// 7. Draw Hammer Items on Platforms
	for h in g.hammers {
		if !h.active { continue }
		hx := int(h.x)
		hy := int(h.y)
		// Wooden handle
		sdl.set_render_draw_color(renderer, 180, 120, 40, 255)
		handle := sdl.Rect{ x: hx - 2, y: hy - 4, w: 4, h: 14 }
		sdl.render_fill_rect(renderer, &handle)
		// Steel Mallet head
		sdl.set_render_draw_color(renderer, 220, 220, 230, 255)
		head := sdl.Rect{ x: hx - 8, y: hy - 12, w: 16, h: 10 }
		sdl.render_fill_rect(renderer, &head)
		sdl.set_render_draw_color(renderer, 140, 145, 160, 255)
		sdl.render_draw_rect(renderer, &head)
	}

	// 8. 16-Bit Rolling Barrels (Brown timber & Blue flame barrel)
	for b in g.barrels {
		if !b.active { continue }
		bx := int(b.x)
		by := int(b.y)
		if tex != unsafe { nil } {
			col_x := if b.b_type == .blue { 64 } else { 0 }
			src := sdl.Rect{ x: col_x, y: 128, w: 64, h: 64 }
			dst := sdl.Rect{ x: bx - 10, y: by - 10, w: 20, h: 20 }
			sdl.render_copy(renderer, tex, &src, &dst)
		} else {
			b_col := if b.b_type == .blue { Color{ r: 20, g: 160, b: 235 } } else { Color{ r: 175, g: 90, b: 25 } }
			sdl.set_render_draw_color(renderer, b_col.r, b_col.g, b_col.b, 255)
			barrel_rect := sdl.Rect{ x: bx - 10, y: by - 10, w: 20, h: 20 }
			sdl.render_fill_rect(renderer, &barrel_rect)

			// Gold/White Steel Hoops
			ring_col := if b.b_type == .blue { Color{ r: 230, g: 245, b: 255 } } else { Color{ r: 245, g: 205, b: 40 } }
			sdl.set_render_draw_color(renderer, ring_col.r, ring_col.g, ring_col.b, 255)
			sdl.render_draw_line(renderer, bx - 10, by - 5, bx + 9, by - 5)
			sdl.render_draw_line(renderer, bx - 10, by + 5, bx + 9, by + 5)
		}
	}

	// 9. Draw Fireball (Firebug) Enemies
	for f in g.fireballs {
		if !f.active { continue }
		fx := int(f.x)
		fy := int(f.y)
		f_tick := (int(f.anim_timer * 10.0)) % 2 == 0

		sdl.set_render_draw_color(renderer, 255, 90, 0, 255)
		f_body := sdl.Rect{ x: fx - 9, y: fy - 10, w: 18, h: 18 }
		sdl.render_fill_rect(renderer, &f_body)

		f_inner_color := if f_tick { Color{ r: 255, g: 240, b: 0, a: 255 } } else { Color{ r: 255, g: 40, b: 0, a: 255 } }
		sdl.set_render_draw_color(renderer, f_inner_color.r, f_inner_color.g, f_inner_color.b, 255)
		f_core := sdl.Rect{ x: fx - 5, y: fy - 7, w: 10, h: 12 }
		sdl.render_fill_rect(renderer, &f_core)

		// Firebug Eyes
		sdl.set_render_draw_color(renderer, 255, 255, 255, 255)
		eye_l := sdl.Rect{ x: fx - 4, y: fy - 5, w: 3, h: 4 }
		eye_r := sdl.Rect{ x: fx + 1, y: fy - 5, w: 3, h: 4 }
		sdl.render_fill_rect(renderer, &eye_l)
		sdl.render_fill_rect(renderer, &eye_r)
	}

	// 10. 16-Bit Jumpman Mario Sprite
	if g.state == .playing || g.state == .victory || g.state == .paused {
		px := int(g.player_x)
		py := int(g.player_y)

		body_color := if g.hammer_timer > 0 {
			if (sdl.get_ticks() / 100) % 2 == 0 { Color{ r: 255, g: 220, b: 0, a: 255 } } else { Color{ r: 255, g: 100, b: 0, a: 255 } }
		} else {
			Color{ r: 240, g: 30, b: 35, a: 255 }
		}

		// Red Cap & Shirt
		sdl.set_render_draw_color(renderer, body_color.r, body_color.g, body_color.b, body_color.a)
		cap := sdl.Rect{ x: px - 8, y: py - 14, w: 16, h: 6 }
		sdl.render_fill_rect(renderer, &cap)
		shirt := sdl.Rect{ x: px - 8, y: py - 8, w: 16, h: 14 }
		sdl.render_fill_rect(renderer, &shirt)

		// Blue Overalls with Yellow Buttons
		sdl.set_render_draw_color(renderer, 30, 75, 215, 255)
		overalls := sdl.Rect{ x: px - 7, y: py - 2, w: 14, h: 10 }
		sdl.render_fill_rect(renderer, &overalls)
		sdl.set_render_draw_color(renderer, 255, 220, 30, 255)
		sdl.render_draw_point(renderer, px - 4, py)
		sdl.render_draw_point(renderer, px + 3, py)

		// Face & Mustache
		sdl.set_render_draw_color(renderer, 255, 205, 165, 255)
		face := sdl.Rect{ x: px - 5, y: py - 9, w: 10, h: 6 }
		sdl.render_fill_rect(renderer, &face)
		sdl.set_render_draw_color(renderer, 20, 15, 10, 255)
		mustache := sdl.Rect{ x: px - 3, y: py - 5, w: 7, h: 2 }
		sdl.render_fill_rect(renderer, &mustache)

		// Swinging Hammer
		if g.hammer_timer > 0 {
			hammer_up := (sdl.get_ticks() / 150) % 2 == 0
			sdl.set_render_draw_color(renderer, 220, 220, 230, 255)
			if hammer_up {
				h_rect := sdl.Rect{ x: px - 8, y: py - 24, w: 16, h: 12 }
				sdl.render_fill_rect(renderer, &h_rect)
			} else {
				h_rect := sdl.Rect{ x: px + 10, y: py - 8, w: 12, h: 16 }
				sdl.render_fill_rect(renderer, &h_rect)
			}
		}
	}

	// 11. HUD
	draw_text(renderer, 20, 15, "SCORE: ${g.score}", 2, Color{ r: 255, g: 255, b: 255, a: 255 })
	draw_text(renderer, 320, 15, "HIGH: ${g.high_score}", 2, Color{ r: 255, g: 215, b: 0, a: 255 })
	draw_text(renderer, 650, 15, "LIVES: ${g.lives}", 2, Color{ r: 0, g: 255, b: 255, a: 255 })

	if g.hammer_timer > 0 {
		draw_text(renderer, 320, 40, "HAMMER: ${int(g.hammer_timer)}s", 2, Color{ r: 255, g: 240, b: 0, a: 255 })
	}

	// 12. Overlay Menus
	if g.state == .menu {
		draw_text_centered(renderer, 400, 180, "DONKEY KONG", 4, Color{ r: 255, g: 40, b: 60, a: 255 })
		draw_text_centered(renderer, 400, 240, "VERTICAL LADDER PLATFORMER", 2, Color{ r: 255, g: 215, b: 0, a: 255 })
		draw_text_centered(renderer, 400, 340, "PRESS SPACE TO START", 2, Color{ r: 255, g: 255, b: 255, a: 255 })
		draw_text_centered(renderer, 400, 400, "CONTROLS: WASD / ARROWS CLIMB & MOVE | SPACE JUMP | F11: Fullscreen", 1, Color{ r: 180, g: 180, b: 180, a: 255 })
		draw_text_centered(renderer, 400, 420, "CLIMB LADDERS, DODGE BARRELS & FIREBALLS TO RESCUE PAULINE!", 1, Color{ r: 180, g: 180, b: 180, a: 255 })
	} else if g.state == .victory {
		draw_text_centered(renderer, 400, 220, "PAULINE RESCUED! VICTORY!", 3, Color{ r: 0, g: 255, b: 100, a: 255 })
		draw_text_centered(renderer, 400, 310, "PRESS SPACE TO ADVANCE STAGE", 2, Color{ r: 255, g: 255, b: 255, a: 255 })
	} else if g.state == .game_over {
		draw_text_centered(renderer, 400, 220, "GAME OVER", 4, Color{ r: 255, g: 50, b: 50, a: 255 })
		draw_text_centered(renderer, 400, 310, "FINAL SCORE: ${g.score}", 2, Color{ r: 255, g: 255, b: 255, a: 255 })
		draw_text_centered(renderer, 400, 370, "PRESS SPACE OR R TO RESTART", 2, Color{ r: 0, g: 255, b: 100, a: 255 })
	} else if g.state == .paused {
		draw_text_centered(renderer, 400, 280, "- PAUSED -", 3, Color{ r: 255, g: 255, b: 0, a: 255 })
	}

	prod_fx_render(renderer)
	sdl.render_present(renderer)
}
