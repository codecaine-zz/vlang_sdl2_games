module main

import math
import os
import sdl
import sdl.image

const frogger_sprite_sz = 32

pub struct FroggerTextureManager {
pub mut:
	sprite_texture &sdl.Texture = unsafe { nil }
}

pub fn new_frogger_texture_manager() FroggerTextureManager {
	return FroggerTextureManager{}
}

pub fn (mut tm FroggerTextureManager) init(renderer &sdl.Renderer) {
	_ = image.init(int(image.InitFlags.png))
	paths := [
		'assets/sprites/frogger.png',
		'../assets/sprites/frogger.png',
		'frogger/assets/sprites/frogger.png',
		os.join_path('assets', 'sprites', 'frogger.png'),
		os.join_path('..', 'assets', 'sprites', 'frogger.png'),
	]
	for p in paths {
		if os.exists(p) {
			surface := image.load(p.str)
			if !isnil(surface) {
				tm.sprite_texture = sdl.create_texture_from_surface(renderer, surface)
				sdl.free_surface(surface)
				if !isnil(tm.sprite_texture) {
					sdl.set_texture_blend_mode(tm.sprite_texture, .blend)
					println('Frogger Texture Loaded Successfully: ' + p)
					return
				}
			}
		}
	}
}

// 16x16 Frog Idle / Crouch Sprite (Facing Up)
const frog_idle_sprite = [
	[0,0,1,1,1,0,0,0,0,0,0,1,1,1,0,0],
	[0,1,4,4,5,1,0,0,0,0,1,5,4,4,1,0],
	[0,1,4,5,5,1,1,1,1,1,1,5,5,4,1,0],
	[0,0,1,1,1,2,2,2,2,2,2,1,1,1,0,0],
	[1,1,0,0,1,2,2,3,3,2,2,1,0,0,1,1],
	[1,2,1,1,2,2,3,3,3,3,2,2,1,1,2,1],
	[1,2,2,2,2,2,3,3,3,3,2,2,2,2,2,1],
	[0,1,1,2,2,2,3,3,3,3,2,2,2,1,1,0],
	[0,0,1,2,2,2,2,3,3,2,2,2,2,1,0,0],
	[0,1,2,2,2,2,2,2,2,2,2,2,2,2,1,0],
	[1,2,2,1,1,2,2,2,2,2,2,1,1,2,2,1],
	[1,2,1,0,0,1,2,2,2,2,1,0,0,1,2,1],
	[1,2,1,0,0,1,2,2,2,2,1,0,0,1,2,1],
	[1,2,2,1,1,2,2,1,1,2,2,1,1,2,2,1],
	[0,1,2,2,2,1,1,0,0,1,1,2,2,2,1,0],
	[0,0,1,1,1,0,0,0,0,0,0,1,1,1,0,0]
]

// 16x16 Frog Mid-Air Leap / Stretch Sprite (Extended Hind Legs & Paws)
const frog_leap_sprite = [
	[1,1,0,0,1,1,0,0,0,0,1,1,0,0,1,1],
	[0,1,1,1,4,4,5,0,0,5,4,4,1,1,1,0],
	[0,0,1,4,5,5,1,1,1,1,5,5,4,1,0,0],
	[0,0,1,1,1,2,2,2,2,2,2,1,1,1,0,0],
	[0,0,0,1,2,2,3,3,3,3,2,2,1,0,0,0],
	[0,0,1,2,2,3,3,3,3,3,3,2,2,1,0,0],
	[0,1,2,2,2,3,3,3,3,3,3,2,2,2,1,0],
	[0,1,2,2,2,2,3,3,3,3,2,2,2,2,1,0],
	[0,0,1,2,2,2,2,2,2,2,2,2,2,1,0,0],
	[0,0,1,2,2,2,2,2,2,2,2,2,2,1,0,0],
	[0,1,2,2,1,0,0,0,0,0,0,1,2,2,1,0],
	[1,2,2,1,0,0,0,0,0,0,0,0,1,2,2,1],
	[1,2,1,0,0,0,0,0,0,0,0,0,0,1,2,1],
	[1,2,1,0,0,0,0,0,0,0,0,0,0,1,2,1],
	[1,2,2,1,0,0,0,0,0,0,0,0,1,2,2,1],
	[0,1,1,1,0,0,0,0,0,0,0,0,1,1,1,0]
]

// 24x12 Sedan Car Sprite Matrix
const car_sprite = [
	[0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0],
	[0,0,0,0,1,4,4,4,4,4,4,4,4,1,0,0,0,0,0,0,0,0,0,0],
	[0,0,0,1,4,4,4,4,4,4,4,4,4,4,1,0,0,0,0,0,0,0,0,0],
	[0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0],
	[1,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,1],
	[1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,5,1],
	[1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,5,1],
	[1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1],
	[1,1,1,6,6,6,1,1,1,1,1,1,1,1,1,1,6,6,6,1,1,1,1,1],
	[0,0,6,6,6,6,6,0,0,0,0,0,0,0,0,6,6,6,6,6,0,0,0,0],
	[0,0,6,6,1,6,6,0,0,0,0,0,0,0,0,6,6,1,6,6,0,0,0,0],
	[0,0,0,6,6,6,0,0,0,0,0,0,0,0,0,0,6,6,6,0,0,0,0,0]
]

// 28x10 Formula Racer Sprite Matrix
const racer_sprite = [
	[0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0],
	[0,0,0,0,0,0,0,0,0,0,0,1,4,4,4,1,0,0,0,0,0,0,0,0,0,0,0,0],
	[1,1,1,0,0,0,0,0,0,0,1,2,4,4,4,2,1,0,0,0,0,0,0,0,0,0,0,0],
	[6,6,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,1,1,1,1,1,1,1,6,6,1,1],
	[6,6,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3,3,3,2,2,2,2,2,6,6,2,1],
	[6,6,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3,3,3,2,2,2,2,2,6,6,2,1],
	[6,6,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,1,1,1,1,1,1,1,6,6,1,1],
	[1,1,1,0,0,0,0,0,0,0,1,2,2,2,2,2,1,0,0,0,0,0,0,0,0,0,0,0],
	[0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0],
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
]

// 16x12 Swimming Turtle Sprite Matrix
const turtle_sprite = [
	[0,0,0,0,4,4,0,0,0,0,0,0,4,4,0,0],
	[0,0,0,4,4,4,4,1,1,1,1,4,4,4,4,0],
	[0,0,4,4,1,1,1,2,2,2,2,1,1,4,4,0],
	[0,4,4,1,2,2,3,3,3,3,2,2,1,4,4,0],
	[4,4,1,2,2,3,3,3,3,3,3,2,2,1,4,4],
	[4,4,1,2,3,3,2,2,2,2,3,3,2,1,4,4],
	[4,4,1,2,3,3,2,2,2,2,3,3,2,1,4,4],
	[4,4,1,2,2,3,3,3,3,3,3,2,2,1,4,4],
	[0,4,4,1,2,2,3,3,3,3,2,2,1,4,4,0],
	[0,0,4,4,1,1,1,2,2,2,2,1,1,4,4,0],
	[0,0,0,4,4,4,4,1,1,1,1,4,4,4,4,0],
	[0,0,0,0,4,4,0,0,0,0,0,0,4,4,0,0]
]

fn draw_animated_frog_sprite(renderer &sdl.Renderer, fx int, fy int, facing int, is_hopping bool, hop_prog f32, idle_t f32, tex &sdl.Texture) {
	if tex != unsafe { nil } {
		is_leap := is_hopping && hop_prog > 0.15 && hop_prog < 0.85
		col_x := if is_leap { 1 } else { 0 }
		src := sdl.Rect{x: col_x * frogger_sprite_sz, y: 0, w: frogger_sprite_sz, h: frogger_sprite_sz}
		dst := sdl.Rect{x: fx - 16, y: fy - 16, w: 32, h: 32}
		angle := match facing {
			1 { 90.0 }
			2 { 180.0 }
			3 { 270.0 }
			else { 0.0 }
		}
		sdl.render_copy_ex(renderer, tex, &src, &dst, angle, unsafe { nil }, .none)
		return
	}

	scale := 1
	start_x := fx - 8
	start_y := fy - 8

	// Choose animation frame
	// 0: Crouch/Idle, 1: Full Flight Leap, 2: Land/Impact
	is_leap := is_hopping && hop_prog > 0.15 && hop_prog < 0.85

	for r in 0 .. 16 {
		for c in 0 .. 16 {
			// Rotate source pixel coordinates based on facing (0: Up, 1: Right, 2: Down, 3: Left)
			src_r, src_c := match facing {
				1 { c, 15 - r }      // 90 deg CW (Right)
				2 { 15 - r, 15 - c } // 180 deg (Down)
				3 { 15 - c, r }      // 270 deg CW (Left)
				else { r, c }        // 0 deg (Up)
			}

			val := if is_leap { frog_leap_sprite[src_r][src_c] } else { frog_idle_sprite[src_r][src_c] }
			if val == 0 {
				continue
			}

			mut col := match val {
				1 { Color{ r: 15, g: 65, b: 25 } }
				2 { Color{ r: 45, g: 215, b: 70 } }
				3 { Color{ r: 210, g: 245, b: 90 } }
				4 { Color{ r: 255, g: 255, b: 255 } }
				5 { Color{ r: 10, g: 20, b: 15 } }
				else { Color{ r: 45, g: 215, b: 70 } }
			}

			// Idle Throat Sac Breathing Pulse
			if !is_hopping && val == 3 {
				pulse := int(math.sin(f64(idle_t * 6.0)) * 20.0)
				col = Color{
					r: u8(math.min(255, 210 + pulse)),
					g: u8(math.min(255, 245 + pulse / 2)),
					b: 90,
				}
			}

			sdl.set_render_draw_color(renderer, col.r, col.g, col.b, 255)
			rect := sdl.Rect{ x: start_x + c * scale, y: start_y + r * scale, w: scale, h: scale }
			sdl.render_fill_rect(renderer, &rect)
		}
	}
}

fn draw_car_sprite(renderer &sdl.Renderer, ox int, oy int, w int, h int, tex &sdl.Texture) {
	if tex != unsafe { nil } {
		src := sdl.Rect{x: 0, y: 1 * frogger_sprite_sz, w: frogger_sprite_sz, h: frogger_sprite_sz}
		dst := sdl.Rect{x: ox, y: oy, w: w, h: h}
		sdl.render_copy(renderer, tex, &src, &dst)
		return
	}

	scale_x := f32(w) / 24.0
	scale_y := f32(h) / 12.0

	for r in 0 .. 12 {
		for c in 0 .. 24 {
			val := car_sprite[r][c]
			if val == 0 {
				continue
			}

			col := match val {
				1 { Color{ r: 35, g: 15, b: 20 } }
				2 { Color{ r: 220, g: 30, b: 45 } }
				3 { Color{ r: 255, g: 100, b: 115 } }
				4 { Color{ r: 180, g: 230, b: 255 } }
				else { Color{ r: 220, g: 30, b: 45 } }
			}
			px := ox + int(f32(c) * scale_x)
			py := oy + int(f32(r) * scale_y)
			pw := int(f32(c + 1) * scale_x) - int(f32(c) * scale_x)
			ph := int(f32(r + 1) * scale_y) - int(f32(r) * scale_y)

			sdl.set_render_draw_color(renderer, col.r, col.g, col.b, 255)
			rect := sdl.Rect{ x: px, y: py, w: if pw > 0 { pw } else { 1 }, h: if ph > 0 { ph } else { 1 } }
			sdl.render_fill_rect(renderer, &rect)
		}
	}
}

fn draw_truck_sprite(renderer &sdl.Renderer, ox int, oy int, w int, h int, tex &sdl.Texture) {
	if tex != unsafe { nil } {
		src := sdl.Rect{x: 0, y: 2 * frogger_sprite_sz, w: frogger_sprite_sz, h: frogger_sprite_sz}
		dst := sdl.Rect{x: ox, y: oy, w: w, h: h}
		sdl.render_copy(renderer, tex, &src, &dst)
		return
	}

	box_w := w - 24
	cargo_rect := sdl.Rect{ x: ox, y: oy, w: box_w, h: h }
	sdl.set_render_draw_color(renderer, 240, 190, 25, 255)
	sdl.render_fill_rect(renderer, &cargo_rect)

	sdl.set_render_draw_color(renderer, 180, 130, 15, 255)
	sdl.render_draw_rect(renderer, &cargo_rect)
	for rx := ox + 8; rx < ox + box_w - 4; rx += 14 {
		sdl.render_draw_line(renderer, rx, oy + 2, rx, oy + h - 3)
	}

	cab_rect := sdl.Rect{ x: ox + box_w, y: oy + 2, w: 24, h: h - 4 }
	sdl.set_render_draw_color(renderer, 220, 160, 15, 255)
	sdl.render_fill_rect(renderer, &cab_rect)

	win_rect := sdl.Rect{ x: ox + box_w + 4, y: oy + 4, w: 12, h: h / 2 - 2 }
	sdl.set_render_draw_color(renderer, 160, 220, 255, 255)
	sdl.render_fill_rect(renderer, &win_rect)

	sdl.set_render_draw_color(renderer, 255, 255, 140, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: ox + w - 4, y: oy + 4, w: 4, h: 6 })

	sdl.set_render_draw_color(renderer, 30, 35, 40, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: ox + 6, y: oy + h - 6, w: 12, h: 6 })
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: ox + box_w - 14, y: oy + h - 6, w: 12, h: 6 })
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: ox + box_w + 6, y: oy + h - 6, w: 12, h: 6 })
}

fn draw_racer_sprite(renderer &sdl.Renderer, ox int, oy int, w int, h int) {
	scale_x := f32(w) / 28.0
	scale_y := f32(h) / 10.0

	for r in 0 .. 10 {
		for c in 0 .. 28 {
			val := racer_sprite[r][c]
			if val == 0 {
				continue
			}

			col := match val {
				1 { Color{ r: 20, g: 30, b: 40 } }
				2 { Color{ r: 0, g: 210, b: 245 } }
				3 { Color{ r: 255, g: 220, b: 30 } }
				4 { Color{ r: 255, g: 255, b: 255 } }
				6 { Color{ r: 35, g: 40, b: 45 } }
				else { Color{ r: 0, g: 200, b: 230 } }
			}

			px := ox + int(f32(c) * scale_x)
			py := oy + int(f32(r) * scale_y)
			pw := int(f32(c + 1) * scale_x) - int(f32(c) * scale_x)
			ph := int(f32(r + 1) * scale_y) - int(f32(r) * scale_y)

			sdl.set_render_draw_color(renderer, col.r, col.g, col.b, 255)
			rect := sdl.Rect{ x: px, y: py, w: if pw > 0 { pw } else { 1 }, h: if ph > 0 { ph } else { 1 } }
			sdl.render_fill_rect(renderer, &rect)
		}
	}
}

fn draw_log_sprite(renderer &sdl.Renderer, ox int, oy int, w int, h int, tex &sdl.Texture) {
	if tex != unsafe { nil } {
		src := sdl.Rect{x: 0, y: 3 * frogger_sprite_sz, w: frogger_sprite_sz, h: frogger_sprite_sz}
		dst := sdl.Rect{x: ox, y: oy, w: w, h: h}
		sdl.render_copy(renderer, tex, &src, &dst)
		return
	}

	rect := sdl.Rect{ x: ox, y: oy, w: w, h: h }
	sdl.set_render_draw_color(renderer, 135, 75, 25, 255)
	sdl.render_fill_rect(renderer, &rect)

	sdl.set_render_draw_color(renderer, 175, 110, 45, 255)
	sdl.render_draw_line(renderer, ox + 6, oy + 3, ox + w - 6, oy + 3)
	sdl.render_draw_line(renderer, ox + 10, oy + 8, ox + w - 10, oy + 8)
	sdl.render_draw_line(renderer, ox + 8, oy + 14, ox + w - 8, oy + 14)

	sdl.set_render_draw_color(renderer, 85, 40, 15, 255)
	sdl.render_draw_rect(renderer, &rect)
	sdl.render_draw_line(renderer, ox + 6, oy + 1, ox + 6, oy + h - 2)
	sdl.render_draw_line(renderer, ox + w - 6, oy + 1, ox + w - 6, oy + h - 2)
}

fn draw_turtle_sprite(renderer &sdl.Renderer, tx int, ty int, tex &sdl.Texture) {
	if tex != unsafe { nil } {
		src := sdl.Rect{x: 1 * frogger_sprite_sz, y: 3 * frogger_sprite_sz, w: frogger_sprite_sz, h: frogger_sprite_sz}
		dst := sdl.Rect{x: tx - 4, y: ty - 4, w: 28, h: 28}
		sdl.render_copy(renderer, tex, &src, &dst)
		return
	}

	for r in 0 .. 12 {
		for c in 0 .. 16 {
			val := turtle_sprite[r][c]
			if val == 0 {
				continue
			}

			col := match val {
				1 { Color{ r: 100, g: 20, b: 20 } }
				2 { Color{ r: 215, g: 45, b: 45 } }
				3 { Color{ r: 255, g: 130, b: 130 } }
				4 { Color{ r: 35, g: 170, b: 50 } }
				5 { Color{ r: 255, g: 255, b: 255 } }
				else { Color{ r: 200, g: 40, b: 40 } }
			}

			sdl.set_render_draw_color(renderer, col.r, col.g, col.b, 255)
			rect := sdl.Rect{ x: tx + c, y: ty + r * 2, w: 1, h: 2 }
			sdl.render_fill_rect(renderer, &rect)
		}
	}
}

fn render_frogger_game(renderer &sdl.Renderer, mut g FroggerGame, tex &sdl.Texture) {
	// Clear Background to dark blue
	sdl.set_render_draw_color(renderer, 10, 15, 30, 255)
	sdl.render_clear(renderer)

	// 1. Draw Zones
	// River (Rows 1..5) -> Y 80 to 280
	sdl.set_render_draw_color(renderer, 15, 45, 110, 255)
	river_rect := sdl.Rect{ x: 0, y: 80, w: 800, h: 200 }
	sdl.render_fill_rect(renderer, &river_rect)

	// Water Current Lines
	sdl.set_render_draw_color(renderer, 30, 80, 175, 255)
	for y := 95; y < 280; y += 40 {
		sdl.render_draw_line(renderer, 0, y, 800, y)
	}

	// Purple Safe Island (Row 6) -> Y 280 to 320
	sdl.set_render_draw_color(renderer, 65, 25, 95, 255)
	mid_rect := sdl.Rect{ x: 0, y: 280, w: 800, h: 40 }
	sdl.render_fill_rect(renderer, &mid_rect)
	sdl.set_render_draw_color(renderer, 95, 45, 140, 255)
	sdl.render_draw_line(renderer, 0, 280, 800, 280)
	sdl.render_draw_line(renderer, 0, 320, 800, 320)

	// Asphalt Highway (Rows 7..11) -> Y 320 to 520
	sdl.set_render_draw_color(renderer, 20, 22, 28, 255)
	road_rect := sdl.Rect{ x: 0, y: 320, w: 800, h: 200 }
	sdl.render_fill_rect(renderer, &road_rect)

	// Dashed Highway Lane Dividers
	sdl.set_render_draw_color(renderer, 240, 240, 240, 180)
	for lane in 1 .. 5 {
		ly := 320 + lane * 40
		for x := 10; x < 800; x += 40 {
			sdl.render_draw_line(renderer, x, ly, x + 20, ly)
		}
	}

	// Purple Bottom Starting Bank (Row 12) -> Y 520 to 560
	sdl.set_render_draw_color(renderer, 65, 25, 95, 255)
	bottom_rect := sdl.Rect{ x: 0, y: 520, w: 800, h: 40 }
	sdl.render_fill_rect(renderer, &bottom_rect)
	sdl.set_render_draw_color(renderer, 95, 45, 140, 255)
	sdl.render_draw_line(renderer, 0, 520, 800, 520)

	// Top Lily Pad Bay Bank (Row 0) -> Y 40 to 80
	sdl.set_render_draw_color(renderer, 10, 75, 40, 255)
	top_rect := sdl.Rect{ x: 0, y: 40, w: 800, h: 40 }
	sdl.render_fill_rect(renderer, &top_rect)

	// 2. Draw 5 Docking Bays (Lily Pads)
	for d in g.docks {
		dx := int(d.x)
		dy := 60

		// Dock Lily Pad Inlet
		sdl.set_render_draw_color(renderer, 15, 45, 110, 255)
		bay := sdl.Rect{ x: dx - 24, y: 40, w: 48, h: 40 }
		sdl.render_fill_rect(renderer, &bay)

		if d.filled {
			draw_animated_frog_sprite(renderer, dx, dy, 0, false, 1.0, 0.0, tex)
		}
	}

	// 3. Draw Lane Objects using Sprite Renderers
	for obj in g.objects {
		ox := int(obj.x)
		oy := 40 + obj.row * 40 + 6

		match obj.obj_type {
			.car {
				draw_car_sprite(renderer, ox, oy, int(obj.width), 28, tex)
			}
			.truck {
				draw_truck_sprite(renderer, ox, oy, int(obj.width), 28, tex)
			}
			.race_car {
				draw_racer_sprite(renderer, ox, oy + 2, int(obj.width), 24)
			}
			.log_small, .log_medium, .log_large {
				draw_log_sprite(renderer, ox, oy + 2, int(obj.width), 24, tex)
			}
			.turtles {
				if obj.submerged { continue }
				count := int(obj.width / 25.0)
				for i in 0 .. count {
					tx := ox + i * 25
					draw_turtle_sprite(renderer, tx, oy + 2, tex)
				}
			}
		}
	}

	// 4. Animated Frog Player Sprite with Parabolic Arc & Soft Drop Shadow
	if g.state == .playing || g.state == .paused {
		fx := int(g.frog_x)
		ground_fy := int(g.frog_y)

		// Parabolic Leap Arc (Elevates up by up to 14px in mid-air)
		jump_arc := if g.is_hopping { int(math.sin(f64(g.hop_progress) * math.pi) * 14.0) } else { 0 }
		render_fy := ground_fy - jump_arc

		// Dynamic Drop Shadow (Stays at ground level, shrinks when high in air)
		shadow_w := if g.is_hopping { int(14.0 - f64(jump_arc) * 0.4) } else { 14 }
		shadow_h := if g.is_hopping { int(6.0 - f64(jump_arc) * 0.2) } else { 6 }
		sdl.set_render_draw_color(renderer, 10, 12, 20, 180)
		sdl.render_fill_rect(renderer, &sdl.Rect{
			x: fx - shadow_w / 2,
			y: ground_fy + 5,
			w: shadow_w,
			h: shadow_h,
		})

		draw_animated_frog_sprite(renderer, fx, render_fy, g.frog_facing, g.is_hopping, g.hop_progress, g.idle_timer, tex)
	}

	// 5. Draw HUD
	draw_text(renderer, 20, 10, "SCORE: ${g.score}", 2, Color{ r: 255, g: 255, b: 255, a: 255 })
	draw_text(renderer, 300, 10, "HIGH: ${g.high_score}", 2, Color{ r: 255, g: 215, b: 0, a: 255 })
	draw_text(renderer, 620, 10, "LEVEL ${g.level}", 2, Color{ r: 0, g: 255, b: 255, a: 255 })

	// Timer Bar
	timer_w := int((g.timer / g.max_timer) * 300.0)
	if timer_w > 0 {
		timer_color := if g.timer < 8.0 { Color{ r: 255, g: 50, b: 50, a: 255 } } else { Color{ r: 0, g: 255, b: 100, a: 255 } }
		sdl.set_render_draw_color(renderer, timer_color.r, timer_color.g, timer_color.b, 255)
		bar := sdl.Rect{ x: 250, y: 570, w: timer_w, h: 14 }
		sdl.render_fill_rect(renderer, &bar)
	}
	draw_text(renderer, 180, 568, "TIME", 2, Color{ r: 200, g: 200, b: 200, a: 255 })

	// Lives Icons as Mini Frog Sprites
	for l in 0 .. g.lives {
		draw_animated_frog_sprite(renderer, 28 + l * 24, 575, 0, false, 1.0, 0.0, tex)
	}

	// 6. Overlay Menus
	if g.state == .menu {
		draw_text_centered(renderer, 400, 180, "CYBER CROSSER", 4, Color{ r: 0, g: 255, b: 100, a: 255 })
		draw_text_centered(renderer, 400, 240, "SPRITE HIGHWAY & RIVER CROSSING", 2, Color{ r: 0, g: 200, b: 255, a: 255 })
		draw_text_centered(renderer, 400, 340, "PRESS SPACE TO START", 2, Color{ r: 255, g: 255, b: 255, a: 255 })
		draw_text_centered(renderer, 400, 400, "CONTROLS: WASD OR ARROW KEYS HOP", 1, Color{ r: 180, g: 180, b: 180, a: 255 })
	} else if g.state == .game_over {
		draw_text_centered(renderer, 400, 240, "GAME OVER", 4, Color{ r: 255, g: 50, b: 50, a: 255 })
		draw_text_centered(renderer, 400, 310, "FINAL SCORE: ${g.score}", 2, Color{ r: 255, g: 255, b: 255, a: 255 })
		draw_text_centered(renderer, 400, 370, "PRESS SPACE OR R TO RESTART", 2, Color{ r: 0, g: 255, b: 100, a: 255 })
	} else if g.state == .paused {
		draw_text_centered(renderer, 400, 280, "- PAUSED -", 3, Color{ r: 255, g: 255, b: 0, a: 255 })
	}

	prod_fx_render(renderer)
	sdl.render_present(renderer)
}
