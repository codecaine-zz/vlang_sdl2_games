import math
import os
import sdl
import sdl.image

pub struct Connect4TextureManager {
pub mut:
	sprite_texture &sdl.Texture = unsafe { nil }
}

pub fn (mut tm Connect4TextureManager) init(renderer &sdl.Renderer) {
	_ = image.init(int(image.InitFlags.png))
	candidates := [
		'assets/sprites/connect4.png',
		'./assets/sprites/connect4.png',
		'../assets/sprites/connect4.png',
		'connect4/assets/sprites/connect4.png',
	]
	for p in candidates {
		if os.exists(p) {
			surface := image.load(p.str)
			if surface != unsafe { nil } {
				tm.sprite_texture = sdl.create_texture_from_surface(renderer, surface)
				sdl.free_surface(surface)
				if tm.sprite_texture != unsafe { nil } {
					println('Connect4 Texture Loaded Successfully: ' + p)
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

fn draw_circle_outline(renderer &sdl.Renderer, cx int, cy int, r int, thickness int, color Color) {
	if r <= 0 {
		return
	}
	sdl.set_render_draw_color(renderer, color.r, color.g, color.b, color.a)
	for t := 0; t < thickness; t++ {
		radius := r - t
		if radius <= 0 {
			break
		}
		mut x := radius
		mut y := 0
		mut err := 0

		for x >= y {
			sdl.render_draw_point(renderer, cx + x, cy + y)
			sdl.render_draw_point(renderer, cx + y, cy + x)
			sdl.render_draw_point(renderer, cx - y, cy + x)
			sdl.render_draw_point(renderer, cx - x, cy + y)
			sdl.render_draw_point(renderer, cx - x, cy - y)
			sdl.render_draw_point(renderer, cx - y, cy - x)
			sdl.render_draw_point(renderer, cx + y, cy - x)
			sdl.render_draw_point(renderer, cx + x, cy - y)

			if err <= 0 {
				y++
				err += 2 * y + 1
			}
			if err > 0 {
				x--
				err -= 2 * x + 1
			}
		}
	}
}

fn draw_disc(renderer &sdl.Renderer, cx int, cy int, r int, player int, is_win bool, tex &sdl.Texture) {
	if tex != unsafe { nil } {
		if player == 1 {
			src := if is_win { sdl.Rect{x: 0, y: 96, w: 96, h: 96} } else { sdl.Rect{x: 0, y: 0, w: 96, h: 96} }
			dst := sdl.Rect{x: cx - r, y: cy - r, w: r * 2, h: r * 2}
			sdl.render_copy(renderer, tex, &src, &dst)
			return
		} else if player == 2 {
			src := if is_win { sdl.Rect{x: 96, y: 96, w: 96, h: 96} } else { sdl.Rect{x: 96, y: 0, w: 96, h: 96} }
			dst := sdl.Rect{x: cx - r, y: cy - r, w: r * 2, h: r * 2}
			sdl.render_copy(renderer, tex, &src, &dst)
			return
		}
	}

	if player == 1 {
		// Premium Crimson Red Disc
		draw_filled_circle(renderer, cx + 2, cy + 3, r, Color{ r: 10, g: 12, b: 24, a: 160 }) // Drop shadow
		draw_filled_circle(renderer, cx, cy, r, Color{ r: 160, g: 20, b: 35 })
		draw_filled_circle(renderer, cx, cy, r - 3, Color{ r: 235, g: 45, b: 60 })
		draw_filled_circle(renderer, cx - r / 3, cy - r / 3, r / 3 + 1, Color{
			r: 255
			g: 120
			b: 135
		})
		draw_filled_circle(renderer, cx - r / 3 - 2, cy - r / 3 - 2, r / 6, Color{
			r: 255
			g: 210
			b: 215
		})
		draw_circle_outline(renderer, cx, cy, r, 2, Color{ r: 110, g: 10, b: 20 })
	} else if player == 2 {
		// Premium Amber Gold Disc
		draw_filled_circle(renderer, cx + 2, cy + 3, r, Color{ r: 10, g: 12, b: 24, a: 160 }) // Drop shadow
		draw_filled_circle(renderer, cx, cy, r, Color{ r: 180, g: 135, b: 5 })
		draw_filled_circle(renderer, cx, cy, r - 3, Color{ r: 255, g: 200, b: 25 })
		draw_filled_circle(renderer, cx - r / 3, cy - r / 3, r / 3 + 1, Color{
			r: 255
			g: 240
			b: 120
		})
		draw_filled_circle(renderer, cx - r / 3 - 2, cy - r / 3 - 2, r / 6, Color{
			r: 255
			g: 255
			b: 210
		})
		draw_circle_outline(renderer, cx, cy, r, 2, Color{ r: 125, g: 85, b: 0 })
	}
}

fn draw_ghost_disc(renderer &sdl.Renderer, cx int, cy int, r int, player int) {
	if player == 1 {
		draw_filled_circle(renderer, cx, cy, r, Color{ r: 235, g: 45, b: 60, a: 100 })
		draw_circle_outline(renderer, cx, cy, r, 3, Color{ r: 255, g: 110, b: 125, a: 220 })
	} else {
		draw_filled_circle(renderer, cx, cy, r, Color{ r: 255, g: 200, b: 25, a: 100 })
		draw_circle_outline(renderer, cx, cy, r, 3, Color{ r: 255, g: 235, b: 90, a: 220 })
	}
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

	// Outer glow shadow when hovered
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

	// Draw button fill
	bg_rect := sdl.Rect{
		x: btn.x
		y: btn.y
		w: btn.w
		h: btn.h
	}
	sdl.set_render_draw_color(renderer, current_bg.r, current_bg.g, current_bg.b, current_bg.a)
	sdl.render_fill_rect(renderer, &bg_rect)

	// Draw top highlight line for 3D metallic feel
	top_line_rect := sdl.Rect{
		x: btn.x + 1
		y: btn.y + 1
		w: btn.w - 2
		h: 2
	}
	sdl.set_render_draw_color(renderer, 255, 255, 255, 60)
	sdl.render_fill_rect(renderer, &top_line_rect)

	// Draw button border
	sdl.set_render_draw_color(renderer, btn.border_color.r, btn.border_color.g, btn.border_color.b,
		btn.border_color.a)
	sdl.render_draw_rect(renderer, &bg_rect)

	// Draw text centered inside button
	cx := btn.x + btn.w / 2
	ty := btn.y + (btn.h - 16) / 2
	draw_text_centered(renderer, cx, ty, btn.text, 2, btn.text_color)
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

	// Outer border
	sdl.set_render_draw_color(renderer, border_color.r, border_color.g, border_color.b,
		border_color.a)
	sdl.render_draw_rect(renderer, &bg_rect)

	// Subtle inner glow
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
