module main

import math
import os
import sdl
import sdl.image

const invader_sprite_sz = 36

pub struct SpaceInvadersTextureManager {
pub mut:
	sprite_texture &sdl.Texture = unsafe { nil }
}

pub fn new_spaceinvaders_texture_manager() SpaceInvadersTextureManager {
	return SpaceInvadersTextureManager{}
}

pub fn (mut tm SpaceInvadersTextureManager) init(renderer &sdl.Renderer) {
	_ = image.init(int(image.InitFlags.png))
	paths := [
		'assets/sprites/spaceinvaders.png',
		'../assets/sprites/spaceinvaders.png',
		'spaceinvaders/assets/sprites/spaceinvaders.png',
		os.join_path('assets', 'sprites', 'spaceinvaders.png'),
		os.join_path('..', 'assets', 'sprites', 'spaceinvaders.png'),
	]
	for p in paths {
		if os.exists(p) {
			surface := image.load(p.str)
			if !isnil(surface) {
				tm.sprite_texture = sdl.create_texture_from_surface(renderer, surface)
				sdl.free_surface(surface)
				if !isnil(tm.sprite_texture) {
					sdl.set_texture_blend_mode(tm.sprite_texture, .blend)
					println('Space Invaders Texture Loaded Successfully: ' + p)
					return
				}
			}
		}
	}
}

// Pixel sprite patterns (8x8 or custom bitmap grids)
// 1 = solid pixel, 0 = transparent

// Squid Alien (8x8)
const squid_f0 = [
	0x18, 0x3C, 0x7E, 0xDB, 0xFF, 0x24, 0x5A, 0xA5
]
const squid_f1 = [
	0x18, 0x3C, 0x7E, 0xDB, 0xFF, 0x24, 0x42, 0x24
]

// Crab Alien (11x8 mapped to 12-wide)
const crab_f0 = [
	0x92, 0x49, 0xFE, 0x6D, 0x7F, 0x24, 0x42, 0x81
]
const crab_f1 = [
	0x92, 0x49, 0xFE, 0x6D, 0x7F, 0x24, 0x24, 0x42
]

// Octopus Alien (12x8)
const octopus_f0 = [
	0x3C, 0x7E, 0xFF, 0xDB, 0xFF, 0x3C, 0x66, 0xC3
]
const octopus_f1 = [
	0x3C, 0x7E, 0xFF, 0xDB, 0xFF, 0x3C, 0x5A, 0x81
]

pub fn draw_alien_sprite(renderer &sdl.Renderer, x int, y int, kind AlienType, frame int, color Color, tex &sdl.Texture) {
	if tex != unsafe { nil } {
		col_x := match kind {
			.squid { if frame == 0 { 0 } else { 1 } }
			.crab { if frame == 0 { 2 } else { 3 } }
			.octopus { if frame == 0 { 4 } else { 5 } }
		}
		src := sdl.Rect{x: col_x * invader_sprite_sz, y: 0, w: invader_sprite_sz, h: invader_sprite_sz}
		dst := sdl.Rect{x: x - 2, y: y - 4, w: 36, h: 36}
		sdl.render_copy(renderer, tex, &src, &dst)
		return
	}

	scale := 3

	pattern := match kind {
		.squid {
			if frame == 0 { squid_f0 } else { squid_f1 }
		}
		.crab {
			if frame == 0 { crab_f0 } else { crab_f1 }
		}
		.octopus {
			if frame == 0 { octopus_f0 } else { octopus_f1 }
		}
	}

	for row_idx in 0 .. 8 {
		row_bits := pattern[row_idx]
		for col_idx in 0 .. 8 {
			if (row_bits & (1 << u32(7 - col_idx))) != 0 {
				px := x + col_idx * scale + 4
				py := y + row_idx * scale

				// 16-Bit Dual-Tone Sprite Fill: Top highlight, Bottom base
				c := if row_idx <= 2 {
					Color{ r: u8(math.min(255, int(color.r) + 60)), g: u8(math.min(255, int(color.g) + 60)), b: u8(math.min(255, int(color.b) + 60)), a: 255 }
				} else {
					color
				}

				sdl.set_render_draw_color(renderer, c.r, c.g, c.b, c.a)
				rect := sdl.Rect{
					x: px
					y: py
					w: scale
					h: scale
				}
				sdl.render_fill_rect(renderer, &rect)
			}
		}
	}
}

pub fn draw_alien_explosion(renderer &sdl.Renderer, cx int, cy int, color Color, tex &sdl.Texture) {
	if tex != unsafe { nil } {
		src := sdl.Rect{x: 2 * invader_sprite_sz, y: 1 * invader_sprite_sz, w: invader_sprite_sz, h: invader_sprite_sz}
		dst := sdl.Rect{x: cx - 18, y: cy - 18, w: 36, h: 36}
		sdl.render_copy(renderer, tex, &src, &dst)
		return
	}

	sdl.set_render_draw_color(renderer, color.r, color.g, color.b, color.a)
	scale := 3
	lines := [
		[0, -4, 0, -2],
		[0, 2, 0, 4],
		[-4, 0, -2, 0],
		[2, 0, 4, 0],
		[-3, -3, -1, -1],
		[1, 1, 3, 3],
		[-3, 3, -1, 1],
		[1, -1, 3, -3],
	]
	for l in lines {
		rect := sdl.Rect{
			x: cx + l[0] * scale
			y: cy + l[1] * scale
			w: (l[2] - l[0] + 1) * scale
			h: (l[3] - l[1] + 1) * scale
		}
		sdl.render_fill_rect(renderer, &rect)
	}
}

pub fn draw_player_cannon(renderer &sdl.Renderer, x int, y int, w int, h int, tex &sdl.Texture) {
	if tex != unsafe { nil } {
		src := sdl.Rect{x: 1 * invader_sprite_sz, y: 1 * invader_sprite_sz, w: invader_sprite_sz, h: invader_sprite_sz}
		dst := sdl.Rect{x: x, y: y - 8, w: w, h: h + 8}
		sdl.render_copy(renderer, tex, &src, &dst)
		return
	}

	// 16-Bit Metallic Emerald Laser Cannon Base
	// Treads Base
	sdl.set_render_draw_color(renderer, 20, 160, 50, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{x: x, y: y + 10, w: w, h: 10})

	// Armor Hull Body
	sdl.set_render_draw_color(renderer, 50, 230, 80, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{x: x + 4, y: y + 4, w: w - 8, h: 8})

	// Hull Specular Highlight
	sdl.set_render_draw_color(renderer, 160, 255, 180, 255)
	sdl.render_draw_line(renderer, x + 5, y + 5, x + w - 5, y + 5)

	// Central Turret Dome & Nozzle
	sdl.set_render_draw_color(renderer, 240, 255, 240, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{x: x + w / 2 - 2, y: y - 2, w: 4, h: 8})
}

pub fn draw_ufo_saucer(renderer &sdl.Renderer, x int, y int, tex &sdl.Texture) {
	if tex != unsafe { nil } {
		src := sdl.Rect{x: 0, y: 1 * invader_sprite_sz, w: invader_sprite_sz, h: invader_sprite_sz}
		dst := sdl.Rect{x: x, y: y - 6, w: 48, h: 32}
		sdl.render_copy(renderer, tex, &src, &dst)
		return
	}

	// Red Saucer Hull
	sdl.set_render_draw_color(renderer, 255, 40, 60, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{x: x + 8, y: y + 6, w: 32, h: 10})

	// Top Dome
	sdl.set_render_draw_color(renderer, 255, 230, 80, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{x: x + 16, y: y, w: 16, h: 8})

	// Windows / Thrusters
	sdl.set_render_draw_color(renderer, 100, 220, 255, 255)
	for i in 0 .. 4 {
		sdl.render_fill_rect(renderer, &sdl.Rect{x: x + 10 + i * 8, y: y + 8, w: 4, h: 4})
	}
}

pub fn render_space_invaders_game(renderer &sdl.Renderer, game &SpaceInvadersGame, tex &sdl.Texture) {
	// Deep Cyber Space Background
	sdl.set_render_draw_color(renderer, 12, 10, 24, 255)
	sdl.render_clear(renderer)

	// Subtle Starfield
	star_positions := [
		[45, 120], [180, 240], [320, 95], [450, 290], [620, 140],
		[710, 260], [110, 480], [280, 540], [530, 470], [670, 520],
		[90, 310], [230, 180], [390, 420], [580, 350], [740, 430]
	]
	sdl.set_render_draw_color(renderer, 200, 220, 255, 160)
	for pos in star_positions {
		sdl.render_draw_point(renderer, pos[0], pos[1])
	}

	// HUD Top Bar: Score, Hi-Score, Wave
	draw_text(renderer, 30, 15, 'SCORE<1>', 2, Color{r: 255, g: 255, b: 255})
	draw_text(renderer, 45, 38, '${game.score:05d}', 2, Color{r: 50, g: 255, b: 120})

	draw_text(renderer, 320, 15, 'HI-SCORE', 2, Color{r: 255, g: 255, b: 255})
	draw_text(renderer, 330, 38, '${game.high_score:05d}', 2, Color{r: 255, g: 220, b: 80})

	draw_text(renderer, 620, 15, 'WAVE', 2, Color{r: 255, g: 255, b: 255})
	draw_text(renderer, 640, 38, '${game.wave:02d}', 2, Color{r: 80, g: 220, b: 255})

	// Top header separator line
	sdl.set_render_draw_color(renderer, 40, 45, 65, 255)
	sdl.render_draw_line(renderer, 20, 65, world_w - 20, 65)

	// UFO Flying Saucer
	if game.ufo.active {
		draw_ufo_saucer(renderer, int(game.ufo.x), int(game.ufo.y), tex)
	} else if game.ufo.show_score {
		draw_text(renderer, int(game.ufo.x), int(game.ufo.y), '+${game.ufo.score_val}', 2, Color{r: 255, g: 50, b: 80})
	}

	// Render 55 Aliens
	alien_colors := [
		Color{r: 255, g: 70, b: 120},  // Squids: Magenta/Pink
		Color{r: 80, g: 220, b: 255},  // Crabs: Cyan
		Color{r: 255, g: 220, b: 60},  // Octopuses: Yellow
	]

	for r in 0 .. 5 {
		col_idx := if r == 0 { 0 } else if r <= 2 { 1 } else { 2 }
		for c in 0 .. 11 {
			al := game.aliens[r][c]
			if al.alive {
				draw_alien_sprite(renderer, int(al.x), int(al.y), al.kind, al.frame, alien_colors[col_idx], tex)
			} else if al.exploding {
				draw_alien_explosion(renderer, int(al.x) + 16, int(al.y) + 14, Color{r: 255, g: 255, b: 255}, tex)
			}
		}
	}

	// Render Bunker Shields
	for s in game.shields {
		for row in 0 .. bunker_rows {
			for col in 0 .. bunker_cols {
				if s.grid[row][col] {
					b_rect := sdl.Rect{
						x: int(s.x) + col * bunker_block_sz
						y: int(s.y) + row * bunker_block_sz
						w: bunker_block_sz
						h: bunker_block_sz
					}
					// Gradient emerald armor blocks
					sdl.set_render_draw_color(renderer, 50, u8(200 + col % 3 * 15), 90, 255)
					sdl.render_fill_rect(renderer, &b_rect)
				}
			}
		}
	}

	// Render Bullets with glowing laser corona
	for b in game.bullets {
		if !b.alive {
			continue
		}
		if b.is_player {
			// Orange/Red laser core with outer glow
			sdl.set_render_draw_color(renderer, 255, 100, 30, 140)
			glow_rect := sdl.Rect{x: int(b.x) - 1, y: int(b.y) - 1, w: 5, h: 14}
			sdl.render_fill_rect(renderer, &glow_rect)

			sdl.set_render_draw_color(renderer, 255, 240, 160, 255)
			b_rect := sdl.Rect{x: int(b.x), y: int(b.y), w: 3, h: 12}
			sdl.render_fill_rect(renderer, &b_rect)
		} else {
			// Cyan zigzag alien projectile with photon aura
			sdl.set_render_draw_color(renderer, 40, 180, 255, 140)
			glow_rect := sdl.Rect{x: int(b.x) - 1, y: int(b.y) - 1, w: 5, h: 12}
			sdl.render_fill_rect(renderer, &glow_rect)

			sdl.set_render_draw_color(renderer, 200, 250, 255, 255)
			b_rect := sdl.Rect{x: int(b.x), y: int(b.y), w: 3, h: 10}
			sdl.render_fill_rect(renderer, &b_rect)
		}
	}

	// Render Player Cannon
	if game.player.alive {
		draw_player_cannon(renderer, int(game.player.x), int(game.player.y), int(game.player.w), int(game.player.h), tex)
	} else if game.lives > 0 {
		// Player explosion animation
		draw_alien_explosion(renderer, int(game.player.x) + int(game.player.w / 2), int(game.player.y) + 12, Color{r: 255, g: 80, b: 40}, tex)
	}

	// Bottom Green Ground Line
	sdl.set_render_draw_color(renderer, 50, 240, 70, 255)
	sdl.render_draw_line(renderer, 20, world_h - 45, world_w - 20, world_h - 45)

	// Bottom Lives Display & Controls Prompt
	draw_text(renderer, 30, world_h - 35, '${game.lives}', 2, Color{r: 255, g: 255, b: 255})
	for i in 0 .. (game.lives - 1) {
		lx := 60 + i * 36
		draw_player_cannon(renderer, lx, world_h - 35, 26, 16, tex)
	}

	draw_text_centered(renderer, world_w / 2 + 60, world_h - 32, '[A/D or ARROWS] MOVE  [SPACE] FIRE  [R] RESTART  [F11] Fullscreen', 1, Color{r: 160, g: 180, b: 210})

	// Game Over / Wave Clear Overlays
	if game.state == .game_over {
		draw_text_centered(renderer, world_w / 2, world_h / 2 - 20, 'GAME OVER', 4, Color{r: 255, g: 50, b: 50})
		draw_text_centered(renderer, world_w / 2, world_h / 2 + 25, 'PRESS [R] OR [SPACE] TO RETRY', 2, Color{r: 255, g: 255, b: 255})
	} else if game.state == .wave_clear {
		draw_text_centered(renderer, world_w / 2, world_h / 2 - 20, 'WAVE CLEAR!', 4, Color{r: 80, g: 255, b: 120})
		draw_text_centered(renderer, world_w / 2, world_h / 2 + 25, 'GET READY FOR WAVE ${game.wave + 1}...', 2, Color{r: 255, g: 255, b: 255})
	}

	prod_fx_render(renderer)
	sdl.render_present(renderer)
}
