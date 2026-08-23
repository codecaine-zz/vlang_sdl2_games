module main

import math
import os
import sdl
import sdl.image

pub struct SnakeTextureManager {
pub mut:
	sprite_texture &sdl.Texture = unsafe { nil }
}

pub fn new_snake_texture_manager() SnakeTextureManager {
	return SnakeTextureManager{}
}

pub fn (mut tm SnakeTextureManager) init(renderer &sdl.Renderer) {
	_ = image.init(int(image.InitFlags.png))
	paths := [
		'assets/sprites/snake.png',
		'../assets/sprites/snake.png',
		'snake/assets/sprites/snake.png',
		os.join_path('assets', 'sprites', 'snake.png'),
		os.join_path('..', 'assets', 'sprites', 'snake.png'),
	]
	for p in paths {
		if os.exists(p) {
			surface := image.load(p.str)
			if !isnil(surface) {
				tm.sprite_texture = sdl.create_texture_from_surface(renderer, surface)
				sdl.free_surface(surface)
				if !isnil(tm.sprite_texture) {
					sdl.set_texture_blend_mode(tm.sprite_texture, .blend)
					println('Snake Texture Loaded Successfully: ' + p)
					return
				}
			}
		}
	}
}

// 16x16 Pixel Art Red Apple Sprite (0 = trans, 1 = outline, 2 = red flesh, 3 = highlight, 4 = stem, 5 = leaf)
const apple_sprite = [
	[0,0,0,0,0,0,4,4,5,5,5,0,0,0,0,0],
	[0,0,0,0,0,4,4,0,5,5,5,5,0,0,0,0],
	[0,0,0,0,4,4,0,0,0,5,5,0,0,0,0,0],
	[0,0,1,1,1,0,0,0,1,1,1,1,0,0,0,0],
	[0,1,2,2,2,1,0,1,2,2,2,2,1,0,0,0],
	[1,2,3,3,2,2,1,2,2,2,2,2,2,1,0,0],
	[1,3,3,3,2,2,2,2,2,2,2,2,2,1,0,0],
	[1,3,3,2,2,2,2,2,2,2,2,2,2,1,0,0],
	[1,2,2,2,2,2,2,2,2,2,2,2,2,1,0,0],
	[1,2,2,2,2,2,2,2,2,2,2,2,2,1,0,0],
	[1,2,2,2,2,2,2,2,2,2,2,2,2,1,0,0],
	[0,1,2,2,2,2,2,2,2,2,2,2,1,0,0,0],
	[0,1,2,2,2,2,2,2,2,2,2,2,1,0,0,0],
	[0,0,1,2,2,2,2,2,2,2,2,1,0,0,0,0],
	[0,0,0,1,1,2,2,2,2,1,1,0,0,0,0,0],
	[0,0,0,0,0,1,1,1,1,0,0,0,0,0,0,0]
]

// 16x16 Pixel Art Golden Apple Sprite
const gold_apple_sprite = [
	[0,0,0,0,0,0,4,4,5,5,5,0,0,0,0,0],
	[0,0,0,0,0,4,4,0,5,5,5,5,0,0,0,0],
	[0,0,0,0,4,4,0,0,0,5,5,0,0,0,0,0],
	[0,0,1,1,1,0,0,0,1,1,1,1,0,0,0,0],
	[0,1,2,2,2,1,0,1,2,2,2,2,1,0,0,0],
	[1,2,3,3,2,2,1,2,2,2,2,2,2,1,0,0],
	[1,3,3,3,2,2,2,2,2,2,2,2,2,1,0,0],
	[1,3,3,2,2,2,2,2,2,2,2,2,2,1,0,0],
	[1,2,2,2,2,2,2,2,2,2,2,2,2,1,0,0],
	[1,2,2,2,2,2,2,2,2,2,2,2,2,1,0,0],
	[1,2,2,2,2,2,2,2,2,2,2,2,2,1,0,0],
	[0,1,2,2,2,2,2,2,2,2,2,2,1,0,0,0],
	[0,1,2,2,2,2,2,2,2,2,2,2,1,0,0,0],
	[0,0,1,2,2,2,2,2,2,2,2,1,0,0,0,0],
	[0,0,0,1,1,2,2,2,2,1,1,0,0,0,0,0],
	[0,0,0,0,0,1,1,1,1,0,0,0,0,0,0,0]
]

pub fn draw_food_sprite(renderer &sdl.Renderer, x int, y int, sz int, is_gold bool, tex &sdl.Texture) {
	if tex != unsafe { nil } {
		col_idx := if is_gold { 1 } else { 0 }
		src := sdl.Rect{x: col_idx * 32, y: 2 * 32, w: 32, h: 32}
		dst := sdl.Rect{x: x, y: y, w: sz, h: sz}
		sdl.render_copy(renderer, tex, &src, &dst)
		return
	}

	scale_x := f32(sz) / 16.0
	scale_y := f32(sz) / 16.0

	for r in 0 .. 16 {
		for c in 0 .. 16 {
			val := if is_gold { gold_apple_sprite[r][c] } else { apple_sprite[r][c] }
			if val == 0 {
				continue
			}

			col := if is_gold {
				match val {
					1 { Color{ r: 160, g: 110, b: 0 } }
					2 { Color{ r: 255, g: 215, b: 0 } }
					3 { Color{ r: 255, g: 255, b: 180 } }
					4 { Color{ r: 120, g: 80, b: 20 } }
					5 { Color{ r: 100, g: 230, b: 60 } }
					else { Color{ r: 255, g: 215, b: 0 } }
				}
			} else {
				match val {
					1 { Color{ r: 120, g: 15, b: 25 } }
					2 { Color{ r: 235, g: 35, b: 50 } }
					3 { Color{ r: 255, g: 150, b: 160 } }
					4 { Color{ r: 100, g: 60, b: 20 } }
					5 { Color{ r: 50, g: 190, b: 40 } }
					else { Color{ r: 235, g: 35, b: 50 } }
				}
			}

			px := x + int(f32(c) * scale_x)
			py := y + int(f32(r) * scale_y)
			pw := int(f32(c + 1) * scale_x) - int(f32(c) * scale_x)
			ph := int(f32(r + 1) * scale_y) - int(f32(r) * scale_y)

			sdl.set_render_draw_color(renderer, col.r, col.g, col.b, 255)
			rect := sdl.Rect{ x: px, y: py, w: if pw > 0 { pw } else { 1 }, h: if ph > 0 { ph } else { 1 } }
			sdl.render_fill_rect(renderer, &rect)
		}
	}
}

pub fn draw_snake_head_sprite(renderer &sdl.Renderer, x int, y int, sz int, dir Direction, tex &sdl.Texture) {
	if tex != unsafe { nil } {
		dir_idx := match dir {
			.up { 0 }
			.right { 1 }
			.down { 2 }
			.left { 3 }
		}
		src := sdl.Rect{x: dir_idx * 32, y: 0, w: 32, h: 32}
		dst := sdl.Rect{x: x, y: y, w: sz, h: sz}
		sdl.render_copy(renderer, tex, &src, &dst)
		return
	}

	// Cyber Serpent Head with Beveled Scales and Glowing Eyes
	head_rect := sdl.Rect{ x: x + 1, y: y + 1, w: sz - 2, h: sz - 2 }
	sdl.set_render_draw_color(renderer, 0, 190, 180, 255)
	sdl.render_fill_rect(renderer, &head_rect)

	// Crown highlight
	inner_rect := sdl.Rect{ x: x + 3, y: y + 3, w: sz - 6, h: sz - 6 }
	sdl.set_render_draw_color(renderer, 60, 240, 230, 255)
	sdl.render_fill_rect(renderer, &inner_rect)

	sdl.set_render_draw_color(renderer, 0, 120, 120, 255)
	sdl.render_draw_rect(renderer, &head_rect)

	// Directional Eyes & Forked Tongue
	eye_col := Color{ r: 255, g: 255, b: 255 }
	pupil_col := Color{ r: 255, g: 40, b: 60 }

	cx := x + sz / 2
	cy := y + sz / 2

	mut e1_x, mut e1_y := cx - 4, cy - 4
	mut e2_x, mut e2_y := cx + 2, cy - 4

	match dir {
		.up {
			e1_x, e1_y = cx - 5, cy - 5
			e2_x, e2_y = cx + 3, cy - 5
			// Tongue
			sdl.set_render_draw_color(renderer, 255, 40, 60, 255)
			sdl.render_draw_line(renderer, cx, y, cx, y - 4)
			sdl.render_draw_line(renderer, cx, y - 4, cx - 2, y - 6)
			sdl.render_draw_line(renderer, cx, y - 4, cx + 2, y - 6)
		}
		.down {
			e1_x, e1_y = cx - 5, cy + 3
			e2_x, e2_y = cx + 3, cy + 3
			// Tongue
			sdl.set_render_draw_color(renderer, 255, 40, 60, 255)
			sdl.render_draw_line(renderer, cx, y + sz, cx, y + sz + 4)
			sdl.render_draw_line(renderer, cx, y + sz + 4, cx - 2, y + sz + 6)
			sdl.render_draw_line(renderer, cx, y + sz + 4, cx + 2, y + sz + 6)
		}
		.left {
			e1_x, e1_y = cx - 5, cy - 5
			e2_x, e2_y = cx - 5, cy + 3
			// Tongue
			sdl.set_render_draw_color(renderer, 255, 40, 60, 255)
			sdl.render_draw_line(renderer, x, cy, x - 4, cy)
			sdl.render_draw_line(renderer, x - 4, cy, x - 6, cy - 2)
			sdl.render_draw_line(renderer, x - 4, cy, x - 6, cy + 2)
		}
		.right {
			e1_x, e1_y = cx + 3, cy - 5
			e2_x, e2_y = cx + 3, cy + 3
			// Tongue
			sdl.set_render_draw_color(renderer, 255, 40, 60, 255)
			sdl.render_draw_line(renderer, x + sz, cy, x + sz + 4, cy)
			sdl.render_draw_line(renderer, x + sz + 4, cy, x + sz + 6, cy - 2)
			sdl.render_draw_line(renderer, x + sz + 4, cy, x + sz + 6, cy + 2)
		}
	}

	sdl.set_render_draw_color(renderer, eye_col.r, eye_col.g, eye_col.b, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: e1_x, y: e1_y, w: 3, h: 3 })
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: e2_x, y: e2_y, w: 3, h: 3 })

	sdl.set_render_draw_color(renderer, pupil_col.r, pupil_col.g, pupil_col.b, 255)
	sdl.render_draw_point(renderer, e1_x + 1, e1_y + 1)
	sdl.render_draw_point(renderer, e2_x + 1, e2_y + 1)
}

pub fn draw_snake_body_sprite(renderer &sdl.Renderer, x int, y int, sz int, seg_idx int, total_segs int, tex &sdl.Texture) {
	if tex != unsafe { nil } {
		src := sdl.Rect{x: 0, y: 1 * 32, w: 32, h: 32}
		dst := sdl.Rect{x: x, y: y, w: sz, h: sz}
		sdl.render_copy(renderer, tex, &src, &dst)
		return
	}

	// Scaled segment with shade gradient
	pct := f64(seg_idx) / f64(math.max(1, total_segs))
	r := u8(20.0 + pct * 20.0)
	g := u8(180.0 - pct * 60.0)
	b := u8(160.0 - pct * 50.0)

	rect := sdl.Rect{ x: x + 2, y: y + 2, w: sz - 4, h: sz - 4 }
	sdl.set_render_draw_color(renderer, r, g, b, 255)
	sdl.render_fill_rect(renderer, &rect)

	// Scale Pattern Core
	inner := sdl.Rect{ x: x + 4, y: y + 4, w: sz - 8, h: sz - 8 }
	sdl.set_render_draw_color(renderer, u8(math.min(255, int(r) + 30)), u8(math.min(255, int(g) + 30)), u8(math.min(255, int(b) + 30)), 255)
	sdl.render_fill_rect(renderer, &inner)

	sdl.set_render_draw_color(renderer, u8(math.max(0, int(r) - 20)), u8(math.max(0, int(g) - 30)), u8(math.max(0, int(b) - 30)), 255)
	sdl.render_draw_rect(renderer, &rect)
}

fn draw_filled_circle(renderer &sdl.Renderer, cx int, cy int, r int, color Color) {
	if r <= 0 {
		return
	}
	sdl.set_render_draw_color(renderer, color.r, color.g, color.b, color.a)
	r_sq := r * r
	for dy := -r; dy <= r; dy++ {
		dx := int(math.sqrt(f64(r_sq - dy * dy)))
		if dx < 0 {
			continue
		}
		rect := sdl.Rect{
			x: cx - dx
			y: cy + dy
			w: dx * 2 + 1
			h: 1
		}
		sdl.render_fill_rect(renderer, &rect)
	}
}

fn draw_glass_card(renderer &sdl.Renderer, x int, y int, w int, h int, border_color Color) {
	bg_rect := sdl.Rect{
		x: x
		y: y
		w: w
		h: h
	}
	sdl.set_render_draw_color(renderer, 24, 30, 50, 230)
	sdl.render_fill_rect(renderer, &bg_rect)

	sdl.set_render_draw_color(renderer, border_color.r, border_color.g, border_color.b,
		border_color.a)
	sdl.render_draw_rect(renderer, &bg_rect)

	inner_rect := sdl.Rect{
		x: x + 1
		y: y + 1
		w: w - 2
		h: h - 2
	}
	sdl.set_render_draw_color(renderer, border_color.r, border_color.g, border_color.b,
		60)
	sdl.render_draw_rect(renderer, &inner_rect)
}

struct Button {
	x int
	y int
	w int
	h int
mut:
	text         string
	bg_color     Color
	hover_color  Color
	text_color   Color
	border_color Color
}

fn (btn &Button) is_hovered(mx int, my int) bool {
	return mx >= btn.x && mx <= btn.x + btn.w && my >= btn.y && my <= btn.y + btn.h
}

fn (btn &Button) draw(renderer &sdl.Renderer, mx int, my int) {
	hovered := btn.is_hovered(mx, my)
	current_bg := if hovered { btn.hover_color } else { btn.bg_color }

	if hovered {
		glow_rect := sdl.Rect{
			x: btn.x - 2
			y: btn.y - 2
			w: btn.w + 4
			h: btn.h + 4
		}
		sdl.set_render_draw_color(renderer, btn.border_color.r, btn.border_color.g, btn.border_color.b,
			90)
		sdl.render_draw_rect(renderer, &glow_rect)
	}

	bg_rect := sdl.Rect{
		x: btn.x
		y: btn.y
		w: btn.w
		h: btn.h
	}
	sdl.set_render_draw_color(renderer, current_bg.r, current_bg.g, current_bg.b, current_bg.a)
	sdl.render_fill_rect(renderer, &bg_rect)

	top_line_rect := sdl.Rect{
		x: btn.x + 1
		y: btn.y + 1
		w: btn.w - 2
		h: 2
	}
	sdl.set_render_draw_color(renderer, 255, 255, 255, 60)
	sdl.render_fill_rect(renderer, &top_line_rect)

	sdl.set_render_draw_color(renderer, btn.border_color.r, btn.border_color.g, btn.border_color.b,
		btn.border_color.a)
	sdl.render_draw_rect(renderer, &bg_rect)

	cx := btn.x + btn.w / 2
	ty := btn.y + (btn.h - 16) / 2
	draw_text_centered(renderer, cx, ty, btn.text, 2, btn.text_color)
}
