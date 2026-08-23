module main

import math
import os
import rand
import sdl
import sdl.image

const puyo_sprite_sz = 48

pub struct PuyoTextureManager {
pub mut:
	sprite_texture &sdl.Texture = unsafe { nil }
}

pub fn new_puyo_texture_manager() PuyoTextureManager {
	return PuyoTextureManager{}
}

pub fn (mut tm PuyoTextureManager) init(renderer &sdl.Renderer) {
	_ = image.init(int(image.InitFlags.png))
	paths := [
		'assets/sprites/puyopuyo.png',
		'../assets/sprites/puyopuyo.png',
		'puyopuyo/assets/sprites/puyopuyo.png',
		os.join_path('assets', 'sprites', 'puyopuyo.png'),
		os.join_path('..', 'assets', 'sprites', 'puyopuyo.png'),
	]
	for p in paths {
		if os.exists(p) {
			surface := image.load(p.str)
			if !isnil(surface) {
				tm.sprite_texture = sdl.create_texture_from_surface(renderer, surface)
				sdl.free_surface(surface)
				if !isnil(tm.sprite_texture) {
					sdl.set_texture_blend_mode(tm.sprite_texture, .blend)
					println('Puyo Puyo Texture Loaded Successfully: ' + p)
					return
				}
			}
		}
	}
}

pub struct PuyoParticle {
pub mut:
	x        f64
	y        f64
	vx       f64
	vy       f64
	life     f64
	max_life f64
	color    Color
	size     f64
}

pub fn create_puyo_burst(cx f64, cy f64, col Color) []PuyoParticle {
	mut parts := []PuyoParticle{cap: 20}
	for _ in 0 .. 16 {
		angle := (f64(rand.intn(360) or { 0 }) * math.pi) / 180.0
		speed := 30.0 + f64(rand.intn(140) or { 70 })
		life := 0.4 + f64(rand.intn(30) or { 15 }) / 100.0
		parts << PuyoParticle{
			x:        cx
			y:        cy
			vx:       math.cos(angle) * speed
			vy:       math.sin(angle) * speed
			life:     life
			max_life: life
			color:    col
			size:     3.0 + f64(rand.intn(4) or { 2 })
		}
	}
	return parts
}

pub fn update_puyo_particles(mut particles []PuyoParticle, dt f64) {
	for mut p in particles {
		p.x += p.vx * dt
		p.y += p.vy * dt
		p.life -= dt
	}
	mut alive := []PuyoParticle{cap: particles.len}
	for p in particles {
		if p.life > 0 {
			alive << p
		}
	}
	particles = alive.clone()
}

pub fn render_puyo_particles(renderer &sdl.Renderer, particles []PuyoParticle) {
	for p in particles {
		alpha := u8(math.clamp(p.life / p.max_life * 255.0, 0, 255))
		sdl.set_render_draw_color(renderer, p.color.r, p.color.g, p.color.b, alpha)
		sz := int(p.size)
		rect := sdl.Rect{x: int(p.x) - sz / 2, y: int(p.y) - sz / 2, w: sz, h: sz}
		sdl.render_fill_rect(renderer, &rect)
	}
}

pub fn get_puyo_colors(color_id int) (Color, Color, Color) {
	// Returns (body_color, light_color, shadow_color)
	match color_id {
		1 { // Red
			return Color{r: 240, g: 50, b: 60}, Color{r: 255, g: 150, b: 160}, Color{r: 160, g: 20, b: 30}
		}
		2 { // Green
			return Color{r: 50, g: 210, b: 70}, Color{r: 160, g: 255, b: 180}, Color{r: 20, g: 130, b: 35}
		}
		3 { // Blue
			return Color{r: 40, g: 140, b: 245}, Color{r: 160, g: 215, b: 255}, Color{r: 20, g: 70, b: 160}
		}
		4 { // Yellow
			return Color{r: 245, g: 210, b: 35}, Color{r: 255, g: 245, b: 160}, Color{r: 160, g: 130, b: 15}
		}
		5 { // Purple
			return Color{r: 190, g: 60, b: 240}, Color{r: 235, g: 165, b: 255}, Color{r: 110, g: 20, b: 150}
		}
		else {
			return Color{r: 180, g: 180, b: 180}, Color{r: 230, g: 230, b: 230}, Color{r: 100, g: 100, b: 100}
		}
	}
}

pub fn draw_jelly_puyo(renderer &sdl.Renderer, cx f64, cy f64, rad f64, color_id int, eye_dx f64, eye_dy f64, tex &sdl.Texture) {
	if color_id == 0 {
		return
	}

	if tex != unsafe { nil } {
		col_idx := color_id - 1
		if col_idx >= 0 && col_idx <= 5 {
			s := int(rad * 2.0)
			src := sdl.Rect{x: col_idx * puyo_sprite_sz, y: 0, w: puyo_sprite_sz, h: puyo_sprite_sz}
			dst := sdl.Rect{x: int(cx - rad), y: int(cy - rad), w: s, h: s}
			sdl.render_copy(renderer, tex, &src, &dst)
			return
		}
	}

	// Fallback procedural jelly drawing
	body_c, high_c, shad_c := get_puyo_colors(color_id)
	int_rad := int(rad)
	icx := int(cx)
	icy := int(cy)

	// Jelly Outer Body
	sdl.set_render_draw_color(renderer, body_c.r, body_c.g, body_c.b, 255)
	for dy := -int_rad; dy <= int_rad; dy++ {
		dx_max := int(math.sqrt(f64(int_rad * int_rad - dy * dy)))
		sdl.render_draw_line(renderer, icx - dx_max, icy + dy, icx + dx_max, icy + dy)
	}

	// Bottom Shadow
	sdl.set_render_draw_color(renderer, shad_c.r, shad_c.g, shad_c.b, 180)
	for dy := 3; dy <= int_rad; dy++ {
		dx_max := int(math.sqrt(f64(int_rad * int_rad - dy * dy)))
		if dx_max > 4 {
			sdl.render_draw_line(renderer, icx - dx_max + 3, icy + dy, icx + dx_max - 3, icy + dy)
		}
	}

	// Specular Highlight
	sdl.set_render_draw_color(renderer, high_c.r, high_c.g, high_c.b, 220)
	hl_rad := int(rad * 0.35)
	for dy := -hl_rad; dy <= hl_rad; dy++ {
		dx_max := int(math.sqrt(f64(hl_rad * hl_rad - dy * dy)))
		sdl.render_draw_line(renderer, icx - int_rad / 3 - dx_max, icy - int_rad / 3 + dy, icx - int_rad / 3 + dx_max, icy - int_rad / 3 + dy)
	}

	// Two Big Cartoon Eyes
	eye_spacing := 6.0
	eye_y := cy - 2.0 + eye_dy * 2.0

	// Left Eye White
	sdl.set_render_draw_color(renderer, 255, 255, 255, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{x: int(cx - eye_spacing - 4.0), y: int(eye_y - 4.0), w: 8, h: 9})
	// Right Eye White
	sdl.render_fill_rect(renderer, &sdl.Rect{x: int(cx + eye_spacing - 4.0), y: int(eye_y - 4.0), w: 8, h: 9})

	// Black Pupils looking in direction
	sdl.set_render_draw_color(renderer, 15, 15, 25, 255)
	pdx := int(eye_dx * 2.0)
	pdy := int(eye_dy * 2.0)
	sdl.render_fill_rect(renderer, &sdl.Rect{x: int(cx - eye_spacing - 2.0) + pdx, y: int(eye_y - 2.0) + pdy, w: 4, h: 5})
	sdl.render_fill_rect(renderer, &sdl.Rect{x: int(cx + eye_spacing - 2.0) + pdx, y: int(eye_y - 2.0) + pdy, w: 4, h: 5})
}

pub fn render_puyo_game(renderer &sdl.Renderer, game &PuyoGame, win_w int, win_h int, particles []PuyoParticle, tex &sdl.Texture) {
	// Deep Cyber Arcade Purple-Black Background
	sdl.set_render_draw_color(renderer, 16, 12, 28, 255)
	sdl.render_clear(renderer)

	// Board Playfield
	board_x := 180
	board_y := 60
	board_w := int(f64(puyo_cols) * cell_sz)
	board_h := int(f64(puyo_rows) * cell_sz)

	// Playfield Backdrop
	sdl.set_render_draw_color(renderer, 26, 20, 44, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{x: board_x, y: board_y, w: board_w, h: board_h})

	// Inner grid subtle lines
	sdl.set_render_draw_color(renderer, 38, 30, 60, 255)
	for r := 0; r <= puyo_rows; r++ {
		ly := board_y + int(f64(r) * cell_sz)
		sdl.render_draw_line(renderer, board_x, ly, board_x + board_w, ly)
	}
	for c := 0; c <= puyo_cols; c++ {
		lx := board_x + int(f64(c) * cell_sz)
		sdl.render_draw_line(renderer, lx, board_y, lx, board_y + board_h)
	}

	// Border Frame
	sdl.set_render_draw_color(renderer, 130, 80, 210, 255)
	sdl.render_draw_rect(renderer, &sdl.Rect{x: board_x, y: board_y, w: board_w, h: board_h})

	// Danger Cross Mark at top of Col 2 (Death Spawn)
	sdl.set_render_draw_color(renderer, 240, 50, 60, 200)
	dx := board_x + int(2.0 * cell_sz) + int(cell_sz / 2.0)
	dy := board_y + int(cell_sz / 2.0)
	sdl.render_draw_line(renderer, dx - 8, dy - 8, dx + 8, dy + 8)
	sdl.render_draw_line(renderer, dx - 8, dy + 8, dx + 8, dy - 8)

	// Draw Grid Puyos
	for r in 0 .. puyo_rows {
		for c in 0 .. puyo_cols {
			col := game.grid[r][c]
			if col > 0 {
				px := f64(board_x) + f64(c) * cell_sz + cell_sz / 2.0
				py := f64(board_y) + f64(r) * cell_sz + cell_sz / 2.0
				draw_jelly_puyo(renderer, px, py, cell_sz * 0.44, col, 0.0, 0.0, tex)
			}
		}
	}

	// Draw Falling Pair
	if game.state == .falling {
		r1 := game.pair.r1
		c1 := game.pair.c1
		sub_r, sub_c := game.get_sub_pos(int(r1), c1, game.pair.rot)

		p1_x := f64(board_x) + f64(c1) * cell_sz + cell_sz / 2.0
		p1_y := f64(board_y) + r1 * cell_sz + cell_sz / 2.0

		p2_x := f64(board_x) + f64(sub_c) * cell_sz + cell_sz / 2.0
		p2_y := f64(board_y) + f64(sub_r) * cell_sz + cell_sz / 2.0

		// Eye directional look toward each other
		dir_x := if sub_c > c1 { 1.0 } else if sub_c < c1 { -1.0 } else { 0.0 }
		dir_y := if sub_r > int(r1) { 1.0 } else if sub_r < int(r1) { -1.0 } else { 0.0 }

		draw_jelly_puyo(renderer, p1_x, p1_y, cell_sz * 0.44, game.pair.col1, dir_x, dir_y, tex)
		draw_jelly_puyo(renderer, p2_x, p2_y, cell_sz * 0.44, game.pair.col2, -dir_x, -dir_y, tex)
	}

	// Particles
	render_puyo_particles(renderer, particles)

	// Left HUD: Next Puyo Queue
	draw_text(renderer, 50, 70, 'NEXT', 2, Color{r: 180, g: 190, b: 220})
	sdl.set_render_draw_color(renderer, 26, 20, 44, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{x: 50, y: 100, w: 70, h: 120})
	sdl.set_render_draw_color(renderer, 130, 80, 210, 255)
	sdl.render_draw_rect(renderer, &sdl.Rect{x: 50, y: 100, w: 70, h: 120})

	draw_jelly_puyo(renderer, 85, 130, cell_sz * 0.4, game.next_pair.col2, 0.0, 1.0, tex)
	draw_jelly_puyo(renderer, 85, 175, cell_sz * 0.4, game.next_pair.col1, 0.0, -1.0, tex)

	// Chain Combo Notification
	if game.chain_count > 1 {
		draw_text_centered(renderer, board_x + board_w / 2, board_y - 35, '${game.chain_count}-CHAIN CASCADE!!', 2, Color{r: 255, g: 215, b: 0})
	}

	// Right HUD: Title, Score, High Score, Controls
	draw_text(renderer, board_x + board_w + 35, 60, 'PUYO PUYO', 3, Color{r: 255, g: 80, b: 120})
	draw_text(renderer, board_x + board_w + 35, 90, 'CASCADE', 3, Color{r: 60, g: 220, b: 255})

	draw_text(renderer, board_x + board_w + 35, 145, 'SCORE', 2, Color{r: 180, g: 190, b: 220})
	draw_text(renderer, board_x + board_w + 35, 170, '${game.score}', 3, Color{r: 255, g: 255, b: 255})

	draw_text(renderer, board_x + board_w + 35, 225, 'HIGH SCORE', 2, Color{r: 180, g: 190, b: 220})
	draw_text(renderer, board_x + board_w + 35, 250, '${game.high_score}', 3, Color{r: 255, g: 215, b: 0})

	draw_text(renderer, board_x + board_w + 35, 320, 'CONTROLS:', 1, Color{r: 255, g: 255, b: 255})
	draw_text(renderer, board_x + board_w + 35, 340, '[A / D / ARROWS] MOVE', 1, Color{r: 160, g: 180, b: 220})
	draw_text(renderer, board_x + board_w + 35, 360, '[W / UP / Z] ROTATE CW', 1, Color{r: 160, g: 180, b: 220})
	draw_text(renderer, board_x + board_w + 35, 380, '[X] ROTATE CCW', 1, Color{r: 160, g: 180, b: 220})
	draw_text(renderer, board_x + board_w + 35, 400, '[S / DOWN] FAST DROP', 1, Color{r: 160, g: 180, b: 220})
	draw_text(renderer, board_x + board_w + 35, 420, '[SPACE] HARD DROP', 1, Color{r: 160, g: 180, b: 220})
	draw_text(renderer, board_x + board_w + 35, 445, '[R] RESTART  |  [M] SOUND', 1, Color{r: 160, g: 180, b: 220})
	draw_text(renderer, board_x + board_w + 35, 465, '[F11] FULLSCREEN', 1, Color{r: 140, g: 160, b: 200})

	// Game Over Modal
	if game.state == .game_over {
		sdl.set_render_draw_color(renderer, 0, 0, 0, 190)
		sdl.render_fill_rect(renderer, &sdl.Rect{x: 0, y: 0, w: win_w, h: win_h})

		mx := (win_w - 420) / 2
		my := (win_h - 220) / 2
		modal_rect := sdl.Rect{x: mx, y: my, w: 420, h: 220}
		sdl.set_render_draw_color(renderer, 26, 20, 44, 255)
		sdl.render_fill_rect(renderer, &modal_rect)
		sdl.set_render_draw_color(renderer, 130, 80, 210, 255)
		sdl.render_draw_rect(renderer, &modal_rect)

		draw_text_centered(renderer, win_w / 2, my + 30, 'GAME OVER', 3, Color{r: 240, g: 50, b: 60})
		draw_text_centered(renderer, win_w / 2, my + 75, 'TOP COLUMN BLOCKED!', 2, Color{r: 220, g: 140, b: 160})
		draw_text_centered(renderer, win_w / 2, my + 120, 'FINAL SCORE: ${game.score}', 2, Color{r: 255, g: 255, b: 255})
		draw_text_centered(renderer, win_w / 2, my + 165, 'PRESS [SPACE] OR [R] TO RETRY', 1, Color{r: 140, g: 180, b: 240})
	}

	prod_fx_render(renderer)
	sdl.render_present(renderer)
}
