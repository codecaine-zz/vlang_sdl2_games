module main

import math
import os
import sdl
import sdl.image

pub struct PongTextureManager {
pub mut:
	sprite_texture &sdl.Texture = unsafe { nil }
}

pub fn (mut tm PongTextureManager) init(renderer &sdl.Renderer) {
	_ = image.init(int(image.InitFlags.png))
	candidates := [
		'assets/sprites/pong.png',
		'./assets/sprites/pong.png',
		'../assets/sprites/pong.png',
		'pong/assets/sprites/pong.png',
	]
	for p in candidates {
		if os.exists(p) {
			surface := image.load(p.str)
			if surface != unsafe { nil } {
				tm.sprite_texture = sdl.create_texture_from_surface(renderer, surface)
				sdl.free_surface(surface)
				if tm.sprite_texture != unsafe { nil } {
					println('Pong Texture Loaded Successfully: ' + p)
					return
				}
			}
		}
	}
}

struct Particle {
mut:
	x     f64
	y     f64
	vx    f64
	vy    f64
	life  f64
	color Color
	size  int
}

// 12x12 Ball Plasma Orb Sprite Matrix
const ball_sprite = [
	[0,0,0,0,1,1,1,1,0,0,0,0],
	[0,0,1,1,2,2,2,2,1,1,0,0],
	[0,1,2,2,3,3,3,2,2,2,1,0],
	[0,1,2,3,4,4,3,3,2,2,1,0],
	[1,2,3,4,4,4,4,3,3,2,2,1],
	[1,2,3,4,4,4,4,3,3,2,2,1],
	[1,2,2,3,4,4,3,3,2,2,2,1],
	[1,2,2,3,3,3,3,2,2,2,2,1],
	[0,1,2,2,2,2,2,2,2,2,1,0],
	[0,1,2,2,2,2,2,2,2,2,1,0],
	[0,0,1,1,2,2,2,2,1,1,0,0],
	[0,0,0,0,1,1,1,1,0,0,0,0]
]

pub fn draw_ball_trail(renderer &sdl.Renderer, trail []TrailPoint, cur_x f64, cur_y f64, speed f64) {
	if trail.len < 1 {
		return
	}
	sdl.set_render_draw_blend_mode(renderer, .blend)

	// Pick trail color theme based on ball speed
	base_color := if speed >= 11.0 {
		Color{ r: 255, g: 220, b: 80 } // White Hot / Solar Gold
	} else if speed >= 8.5 {
		Color{ r: 245, g: 70, b: 235 } // Neon Magenta / Laser Violet
	} else {
		Color{ r: 60, g: 200, b: 255 } // Electric Cyan / Aqua Glow
	}

	// Connect current ball center to the first trail point
	first_pt := trail[0]
	sdl.set_render_draw_color(renderer, 255, 255, 255, 240)
	sdl.render_draw_line(renderer, int(cur_x), int(cur_y), int(first_pt.x), int(first_pt.y))
	sdl.set_render_draw_color(renderer, base_color.r, base_color.g, base_color.b, 180)
	sdl.render_draw_line(renderer, int(cur_x) - 1, int(cur_y), int(first_pt.x) - 1, int(first_pt.y))
	sdl.render_draw_line(renderer, int(cur_x) + 1, int(cur_y), int(first_pt.x) + 1, int(first_pt.y))

	for i in 0 .. trail.len {
		pt := trail[i]
		t := 1.0 - (f64(i) / f64(trail.len)) // 1.0 at front down to 0.0 at tail
		radius := int(f64(ball_size / 2) * t * 0.9)
		alpha := u8(t * t * 200.0)

		if radius > 0 {
			draw_filled_circle(renderer, int(pt.x), int(pt.y), radius, Color{
				r: base_color.r
				g: base_color.g
				b: base_color.b
				a: alpha
			})
		}

		if i + 1 < trail.len {
			next_pt := trail[i + 1]
			line_alpha := u8(t * 220.0)
			sdl.set_render_draw_color(renderer, 255, 255, 255, line_alpha)
			sdl.render_draw_line(renderer, int(pt.x), int(pt.y), int(next_pt.x), int(next_pt.y))
			// Outer soft ribbon border
			sdl.set_render_draw_color(renderer, base_color.r, base_color.g, base_color.b, u8(t * 140.0))
			sdl.render_draw_line(renderer, int(pt.x) - 1, int(pt.y), int(next_pt.x) - 1, int(next_pt.y))
			sdl.render_draw_line(renderer, int(pt.x) + 1, int(pt.y), int(next_pt.x) + 1, int(next_pt.y))
			sdl.render_draw_line(renderer, int(pt.x), int(pt.y) - 1, int(next_pt.x), int(next_pt.y) - 1)
			sdl.render_draw_line(renderer, int(pt.x), int(pt.y) + 1, int(next_pt.x), int(next_pt.y) + 1)
		}
	}
}

pub fn draw_ball_sprite(renderer &sdl.Renderer, cx int, cy int, sz int, tex &sdl.Texture) {
	if tex != unsafe { nil } {
		src := sdl.Rect{ x: 0, y: 96, w: 32, h: 32 }
		dst := sdl.Rect{ x: cx - sz / 2, y: cy - sz / 2, w: sz, h: sz }
		sdl.render_copy(renderer, tex, &src, &dst)
		return
	}

	scale := sz / 12
	eff_scale := if scale < 1 { 1 } else { scale }
	top_left_x := cx - sz / 2
	top_left_y := cy - sz / 2

	for r in 0 .. 12 {
		for c in 0 .. 12 {
			val := ball_sprite[r][c]
			if val == 0 {
				continue
			}

			col := match val {
				1 { Color{ r: 70, g: 180, b: 255, a: 160 } }
				2 { Color{ r: 140, g: 220, b: 255, a: 220 } }
				3 { Color{ r: 210, g: 245, b: 255, a: 255 } }
				4 { Color{ r: 255, g: 255, b: 255, a: 255 } }
				else { Color{ r: 255, g: 255, b: 255, a: 255 } }
			}

			px := top_left_x + c * eff_scale
			py := top_left_y + r * eff_scale

			sdl.set_render_draw_color(renderer, col.r, col.g, col.b, col.a)
			if eff_scale == 1 {
				sdl.render_draw_point(renderer, px, py)
			} else {
				rect := sdl.Rect{ x: px, y: py, w: eff_scale, h: eff_scale }
				sdl.render_fill_rect(renderer, &rect)
			}
		}
	}
}

pub fn draw_paddle_sprite(renderer &sdl.Renderer, x int, y int, w int, h int, is_p1 bool, tex &sdl.Texture) {
	if tex != unsafe { nil } {
		src := if is_p1 { sdl.Rect{ x: 0, y: 0, w: 24, h: 88 } } else { sdl.Rect{ x: 32, y: 0, w: 24, h: 88 } }
		dst := sdl.Rect{ x: x, y: y, w: w, h: h }
		sdl.render_copy(renderer, tex, &src, &dst)
		return
	}
	// Base Paddle Background
	bg_rect := sdl.Rect{ x: x, y: y, w: w, h: h }
	sdl.set_render_draw_color(renderer, 20, 24, 36, 255)
	sdl.render_fill_rect(renderer, &bg_rect)

	// Top & Bottom Neon Energy Caps
	cap_col := if is_p1 {
		Color{ r: 255, g: 70, b: 90 }
	} else {
		Color{ r: 50, g: 230, b: 255 }
	}

	top_cap := sdl.Rect{ x: x, y: y, w: w, h: 4 }
	bot_cap := sdl.Rect{ x: x, y: y + h - 4, w: w, h: 4 }
	sdl.set_render_draw_color(renderer, cap_col.r, cap_col.g, cap_col.b, 255)
	sdl.render_fill_rect(renderer, &top_cap)
	sdl.render_fill_rect(renderer, &bot_cap)

	// Carbon Texture Grips & Grooves
	for seg := y + 6; seg < y + h - 6; seg += 6 {
		glow_w := if is_p1 { (x + w - 3) } else { (x + 1) }
		groove_col := if is_p1 {
			Color{ r: 200, g: 40, b: 60 }
		} else {
			Color{ r: 30, g: 190, b: 220 }
		}
		sdl.set_render_draw_color(renderer, groove_col.r, groove_col.g, groove_col.b, 255)
		g_rect := sdl.Rect{ x: glow_w, y: seg, w: 2, h: 4 }
		sdl.render_fill_rect(renderer, &g_rect)

		inner_col := Color{ r: 45, g: 55, b: 75 }
		sdl.set_render_draw_color(renderer, inner_col.r, inner_col.g, inner_col.b, 255)
		i_rect := sdl.Rect{ x: x + 3, y: seg, w: w - 6, h: 3 }
		sdl.render_fill_rect(renderer, &i_rect)
	}

	// Bevel Outline
	sdl.set_render_draw_color(renderer, cap_col.r, cap_col.g, cap_col.b, 200)
	sdl.render_draw_rect(renderer, &bg_rect)
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
