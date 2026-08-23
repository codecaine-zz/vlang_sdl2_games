module main

import math
import sdl

const win_w = 1100
const win_h = 840

const cell_w = 150
const cell_h = 95
const grid_start_x = (win_w - (grid_cols * cell_w)) / 2 // 175
const grid_start_y = 160

struct Button {
pub mut:
	x            int
	y            int
	w            int
	h            int
	text         string
	bg_color     Color
	hover_color  Color
	text_color   Color
	border_color Color
}

fn (b &Button) contains(px int, py int) bool {
	return px >= b.x && px <= b.x + b.w && py >= b.y && py <= b.y + b.h
}

fn (b &Button) draw(renderer &sdl.Renderer, mouse_x int, mouse_y int) {
	is_hover := b.contains(mouse_x, mouse_y)
	bg := if is_hover { b.hover_color } else { b.bg_color }

	rect := sdl.Rect{
		x: b.x
		y: b.y
		w: b.w
		h: b.h
	}

	// Fill background
	sdl.set_render_draw_color(renderer, bg.r, bg.g, bg.b, bg.a)
	sdl.render_fill_rect(renderer, &rect)

	// Border
	sdl.set_render_draw_color(renderer, b.border_color.r, b.border_color.g, b.border_color.b, b.border_color.a)
	sdl.render_draw_rect(renderer, &rect)

	// Inner double border highlight
	inner_rect := sdl.Rect{
		x: b.x + 1
		y: b.y + 1
		w: b.w - 2
		h: b.h - 2
	}
	sdl.render_draw_rect(renderer, &inner_rect)

	// Text
	text_y := b.y + (b.h - 16) / 2
	draw_text_centered(renderer, b.x + b.w / 2, text_y, b.text, 2, b.text_color)
}

fn draw_muncher_sprite(renderer &sdl.Renderer, x int, y int, mouth_open bool) {
	cx := x + cell_w / 2
	cy := y + cell_h / 2
	radius := 34

	// Main body glow / outline
	sdl.set_render_draw_color(renderer, 20, 180, 40, 255)
	for r in radius - 2 .. radius + 2 {
		for ang := 0.0; ang < 2.0 * math.pi; ang += 0.08 {
			px := cx + int(math.cos(ang) * f64(r))
			py := cy + int(math.sin(ang) * f64(r))
			sdl.render_draw_point(renderer, px, py)
		}
	}

	// Main body fill (Green Muncher)
	sdl.set_render_draw_color(renderer, 40, 230, 70, 255)
	for ry in -radius .. radius {
		rx_max := int(math.sqrt(f64(radius * radius - ry * ry)))
		rect := sdl.Rect{
			x: cx - rx_max
			y: cy + ry
			w: rx_max * 2
			h: 1
		}
		sdl.render_fill_rect(renderer, &rect)
	}

	// Big cartoon eyes (Left & Right)
	eye_r := 9
	eye1_x := cx - 12
	eye1_y := cy - 10
	eye2_x := cx + 12
	eye2_y := cy - 10

	sdl.set_render_draw_color(renderer, 255, 255, 255, 255)
	for ry in -eye_r .. eye_r {
		rx := int(math.sqrt(f64(eye_r * eye_r - ry * ry)))
		r1 := sdl.Rect{x: eye1_x - rx, y: eye1_y + ry, w: rx * 2, h: 1}
		r2 := sdl.Rect{x: eye2_x - rx, y: eye2_y + ry, w: rx * 2, h: 1}
		sdl.render_fill_rect(renderer, &r1)
		sdl.render_fill_rect(renderer, &r2)
	}

	// Pupils
	pupil_r := 4
	sdl.set_render_draw_color(renderer, 10, 20, 40, 255)
	for ry in -pupil_r .. pupil_r {
		rx := int(math.sqrt(f64(pupil_r * pupil_r - ry * ry)))
		r1 := sdl.Rect{x: eye1_x - rx + 2, y: eye1_y + ry, w: rx * 2, h: 1}
		r2 := sdl.Rect{x: eye2_x - rx + 2, y: eye2_y + ry, w: rx * 2, h: 1}
		sdl.render_fill_rect(renderer, &r1)
		sdl.render_fill_rect(renderer, &r2)
	}

	// Chomping mouth
	sdl.set_render_draw_color(renderer, 15, 25, 10, 255)
	mouth_w := 28
	mouth_h := if mouth_open { 22 } else { 8 }
	mouth_rect := sdl.Rect{
		x: cx - mouth_w / 2
		y: cy + 6
		w: mouth_w
		h: mouth_h
	}
	sdl.render_fill_rect(renderer, &mouth_rect)

	// White teeth in mouth
	sdl.set_render_draw_color(renderer, 255, 255, 255, 255)
	t1 := sdl.Rect{x: cx - 10, y: cy + 6, w: 6, h: 5}
	t2 := sdl.Rect{x: cx + 4, y: cy + 6, w: 6, h: 5}
	sdl.render_fill_rect(renderer, &t1)
	sdl.render_fill_rect(renderer, &t2)

	// Antennae
	sdl.set_render_draw_color(renderer, 40, 230, 70, 255)
	a1 := sdl.Rect{x: cx - 18, y: cy - radius - 8, w: 4, h: 10}
	a2 := sdl.Rect{x: cx + 14, y: cy - radius - 8, w: 4, h: 10}
	sdl.render_fill_rect(renderer, &a1)
	sdl.render_fill_rect(renderer, &a2)
}

fn draw_troggle_sprite(renderer &sdl.Renderer, x int, y int, kind TroggleType) {
	cx := x + cell_w / 2
	cy := y + cell_h / 2

	match kind {
		.reggie {
			// Reggie: Red Troggle with horns
			sdl.set_render_draw_color(renderer, 230, 40, 60, 255)
			r := sdl.Rect{x: cx - 26, y: cy - 20, w: 52, h: 42}
			sdl.render_fill_rect(renderer, &r)

			// Horns
			sdl.set_render_draw_color(renderer, 255, 180, 0, 255)
			h1 := sdl.Rect{x: cx - 22, y: cy - 32, w: 8, h: 12}
			h2 := sdl.Rect{x: cx + 14, y: cy - 32, w: 8, h: 12}
			sdl.render_fill_rect(renderer, &h1)
			sdl.render_fill_rect(renderer, &h2)

			// Big Cyclops Eye
			sdl.set_render_draw_color(renderer, 255, 255, 255, 255)
			eye := sdl.Rect{x: cx - 10, y: cy - 14, w: 20, h: 16}
			sdl.render_fill_rect(renderer, &eye)
			sdl.set_render_draw_color(renderer, 0, 0, 0, 255)
			pupil := sdl.Rect{x: cx - 4, y: cy - 10, w: 8, h: 8}
			sdl.render_fill_rect(renderer, &pupil)

			// Fanged mouth
			sdl.set_render_draw_color(renderer, 0, 0, 0, 255)
			m := sdl.Rect{x: cx - 16, y: cy + 8, w: 32, h: 8}
			sdl.render_fill_rect(renderer, &m)
		}
		.glitch {
			// Glitch: Teal spiky enemy
			sdl.set_render_draw_color(renderer, 30, 210, 220, 255)
			r := sdl.Rect{x: cx - 24, y: cy - 24, w: 48, h: 48}
			sdl.render_fill_rect(renderer, &r)

			// Spikes
			sdl.set_render_draw_color(renderer, 255, 255, 100, 255)
			s1 := sdl.Rect{x: cx - 30, y: cy - 10, w: 6, h: 20}
			s2 := sdl.Rect{x: cx + 24, y: cy - 10, w: 6, h: 20}
			s3 := sdl.Rect{x: cx - 10, y: cy - 30, w: 20, h: 6}
			s4 := sdl.Rect{x: cx - 10, y: cy + 24, w: 20, h: 6}
			sdl.render_fill_rect(renderer, &s1)
			sdl.render_fill_rect(renderer, &s2)
			sdl.render_fill_rect(renderer, &s3)
			sdl.render_fill_rect(renderer, &s4)

			// Angry Eyes
			sdl.set_render_draw_color(renderer, 255, 50, 50, 255)
			e1 := sdl.Rect{x: cx - 14, y: cy - 10, w: 8, h: 8}
			e2 := sdl.Rect{x: cx + 6, y: cy - 10, w: 8, h: 8}
			sdl.render_fill_rect(renderer, &e1)
			sdl.render_fill_rect(renderer, &e2)
		}
		.bashful {
			// Bashful: Purple shy Troggle
			sdl.set_render_draw_color(renderer, 170, 60, 220, 255)
			r := sdl.Rect{x: cx - 24, y: cy - 22, w: 48, h: 44}
			sdl.render_fill_rect(renderer, &r)

			// Drooping ears
			sdl.set_render_draw_color(renderer, 120, 30, 160, 255)
			ear1 := sdl.Rect{x: cx - 32, y: cy - 16, w: 8, h: 24}
			ear2 := sdl.Rect{x: cx + 24, y: cy - 16, w: 8, h: 24}
			sdl.render_fill_rect(renderer, &ear1)
			sdl.render_fill_rect(renderer, &ear2)

			// Wide eyes
			sdl.set_render_draw_color(renderer, 255, 255, 255, 255)
			e1 := sdl.Rect{x: cx - 16, y: cy - 12, w: 12, h: 14}
			e2 := sdl.Rect{x: cx + 4, y: cy - 12, w: 12, h: 14}
			sdl.render_fill_rect(renderer, &e1)
			sdl.render_fill_rect(renderer, &e2)
			sdl.set_render_draw_color(renderer, 0, 0, 0, 255)
			p1 := sdl.Rect{x: cx - 12, y: cy - 8, w: 5, h: 6}
			p2 := sdl.Rect{x: cx + 8, y: cy - 8, w: 5, h: 6}
			sdl.render_fill_rect(renderer, &p1)
			sdl.render_fill_rect(renderer, &p2)
		}
	}
}

fn draw_game(renderer &sdl.Renderer, game &Game, mouse_x int, mouse_y int, btn_reset &Button, btn_mode &Button, btn_sound &Button, btn_pause &Button) {
	// Background: Deep retro dark blue / Arcade black
	if game.flash_red_timer > 0 {
		sdl.set_render_draw_color(renderer, 90, 15, 20, 255)
	} else {
		sdl.set_render_draw_color(renderer, 12, 16, 28, 255)
	}
	sdl.render_clear(renderer)

	// Top Title Header
	header_rect := sdl.Rect{
		x: 20
		y: 15
		w: win_w - 40
		h: 125
	}
	sdl.set_render_draw_color(renderer, 22, 32, 55, 255)
	sdl.render_fill_rect(renderer, &header_rect)
	sdl.set_render_draw_color(renderer, 40, 180, 90, 255)
	sdl.render_draw_rect(renderer, &header_rect)

	// Outer border double line
	inner_header := sdl.Rect{
		x: 22
		y: 17
		w: win_w - 44
		h: 121
	}
	sdl.render_draw_rect(renderer, &inner_header)

	// Game Title
	draw_text(renderer, 45, 30, 'NUMBER MUNCHERS (MECC 1986)', 2, Color{
		r: 40
		g: 240
		b: 100
	})

	// Rule Banner (Vivid Yellow Box)
	rule_banner_rect := sdl.Rect{
		x: 45
		y: 65
		w: 640
		h: 55
	}
	sdl.set_render_draw_color(renderer, 40, 55, 30, 255)
	sdl.render_fill_rect(renderer, &rule_banner_rect)
	sdl.set_render_draw_color(renderer, 255, 220, 40, 255)
	sdl.render_draw_rect(renderer, &rule_banner_rect)

	draw_text(renderer, 65, 75, 'TARGET RULE:', 2, Color{
		r: 255
		g: 220, b: 40
	})
	draw_text(renderer, 260, 75, game.rule.description.to_upper(), 3, Color{
		r: 255
		g: 255
		b: 255
	})

	// Stats Panel (Right side of header)
	draw_text(renderer, 720, 30, 'SCORE:', 2, Color{
		r: 180
		g: 200
		b: 240
	})
	draw_text(renderer, 830, 30, '${game.score}', 2, Color{
		r: 255
		g: 255
		b: 255
	})

	draw_text(renderer, 720, 58, 'HI-SCORE:', 2, Color{
		r: 180
		g: 200
		b: 240
	})
	draw_text(renderer, 850, 58, '${game.high_score}', 2, Color{
		r: 255
		g: 220
		b: 50
	})

	draw_text(renderer, 720, 86, 'LEVEL:', 2, Color{
		r: 180
		g: 200
		b: 240
	})
	draw_text(renderer, 830, 86, '${game.level}', 2, Color{
		r: 50
		g: 220
		b: 255
	})

	draw_text(renderer, 720, 110, 'LIVES:', 2, Color{
		r: 180
		g: 200
		b: 240
	})
	// Draw small Muncher icons for lives
	for l in 0 .. game.lives {
		lx := 830 + l * 28
		ly := 108
		l_rect := sdl.Rect{x: lx, y: ly, w: 18, h: 18}
		sdl.set_render_draw_color(renderer, 40, 230, 70, 255)
		sdl.render_fill_rect(renderer, &l_rect)
	}

	// Draw 5x6 Board Grid
	grid_outline := sdl.Rect{
		x: grid_start_x - 6
		y: grid_start_y - 6
		w: grid_cols * cell_w + 12
		h: grid_rows * cell_h + 12
	}
	sdl.set_render_draw_color(renderer, 30, 180, 80, 255)
	sdl.render_draw_rect(renderer, &grid_outline)

	for r in 0 .. grid_rows {
		for c in 0 .. grid_cols {
			cell_x := grid_start_x + c * cell_w
			cell_y := grid_start_y + r * cell_h
			cell := game.grid[c][r]

			cell_rect := sdl.Rect{
				x: cell_x
				y: cell_y
				w: cell_w - 4
				h: cell_h - 4
			}

			// Hover or Muncher current cell highlight
			is_muncher_here := (c == game.muncher.col && r == game.muncher.row)
			is_mouse_hover := (mouse_x >= cell_x && mouse_x < cell_x + cell_w && mouse_y >= cell_y
				&& mouse_y < cell_y + cell_h)

			if is_muncher_here {
				sdl.set_render_draw_color(renderer, 20, 65, 45, 255)
			} else if is_mouse_hover {
				sdl.set_render_draw_color(renderer, 30, 45, 75, 255)
			} else if cell.is_munched {
				sdl.set_render_draw_color(renderer, 15, 20, 32, 255)
			} else {
				sdl.set_render_draw_color(renderer, 25, 34, 56, 255)
			}
			sdl.render_fill_rect(renderer, &cell_rect)

			// Cell Border
			if is_muncher_here {
				sdl.set_render_draw_color(renderer, 50, 255, 100, 255)
			} else {
				sdl.set_render_draw_color(renderer, 45, 70, 115, 255)
			}
			sdl.render_draw_rect(renderer, &cell_rect)

			// Render Cell Content if not munched
			if !cell.is_munched {
				color := if is_muncher_here {
					Color{
						r: 255
						g: 255
						b: 255
					}
				} else {
					Color{
						r: 200
						g: 220
						b: 255
					}
				}
				scale := if cell.display_text.len > 5 { 2 } else { 3 }
				text_y := cell_y + (cell_h - 8 * scale) / 2
				draw_text_centered(renderer, cell_x + cell_w / 2, text_y, cell.display_text, scale,
					color)
			} else {
				// Munched empty symbol
				draw_text_centered(renderer, cell_x + cell_w / 2, cell_y + (cell_h - 16) / 2,
					'-', 2, Color{
					r: 60
					g: 80
					b: 110
				})
			}
		}
	}

	// Render Troggles
	for t in game.troggles {
		if t.active {
			tx := grid_start_x + t.col * cell_w
			ty := grid_start_y + t.row * cell_h
			draw_troggle_sprite(renderer, tx, ty, t.kind)
		}
	}

	// Render Player Muncher
	mx := grid_start_x + game.muncher.col * cell_w
	my := grid_start_y + game.muncher.row * cell_h
	draw_muncher_sprite(renderer, mx, my, game.muncher.mouth_open)

	// Render Particles
	for p in game.particles {
		sdl.set_render_draw_color(renderer, p.color.r, p.color.g, p.color.b, u8(p.life * 255.0))
		r := sdl.Rect{
			x: int(p.x) - 2
			y: int(p.y) - 2
			w: 5
			h: 5
		}
		sdl.render_fill_rect(renderer, &r)
	}

	// Render Floating Score/Warning Popups
	for pop in game.popups {
		draw_text_centered(renderer, int(pop.x), int(pop.y), pop.text, 3, pop.color)
	}

	// Bottom UI Action Buttons
	btn_reset.draw(renderer, mouse_x, mouse_y)
	btn_mode.draw(renderer, mouse_x, mouse_y)
	btn_sound.draw(renderer, mouse_x, mouse_y)
	btn_pause.draw(renderer, mouse_x, mouse_y)

	// Controls Guide line
	draw_text_centered(renderer, win_w / 2, 810, 'CONTROLS: [ARROWS/WASD] MOVE  |  [SPACE/ENTER] MUNCH  |  [M] MODE  |  [R] RESET  |  [P] PAUSE',
		1, Color{
		r: 140
		g: 160
		b: 200
	})

	// Overlays for Level Clear / Game Over / Paused
	if game.status == .level_clear {
		overlay_rect := sdl.Rect{
			x: 200
			y: 300
			w: 700
			h: 220
		}
		sdl.set_render_draw_color(renderer, 10, 40, 20, 240)
		sdl.render_fill_rect(renderer, &overlay_rect)
		sdl.set_render_draw_color(renderer, 50, 255, 120, 255)
		sdl.render_draw_rect(renderer, &overlay_rect)

		draw_text_centered(renderer, win_w / 2, 340, 'GREAT MUNCHING!', 4, Color{
			r: 50
			g: 255
			b: 120
		})
		draw_text_centered(renderer, win_w / 2, 410, 'LEVEL ${game.level} CLEARED!  BONUS +500 PTS',
			2, Color{
			r: 255
			g: 255
			b: 255
		})
		draw_text_centered(renderer, win_w / 2, 460, 'GET READY FOR NEXT LEVEL...', 2, Color{
			r: 255
			g: 220
			b: 50
		})
	} else if game.status == .game_over {
		overlay_rect := sdl.Rect{
			x: 200
			y: 300
			w: 700
			h: 220
		}
		sdl.set_render_draw_color(renderer, 50, 10, 15, 240)
		sdl.render_fill_rect(renderer, &overlay_rect)
		sdl.set_render_draw_color(renderer, 255, 50, 60, 255)
		sdl.render_draw_rect(renderer, &overlay_rect)

		draw_text_centered(renderer, win_w / 2, 340, 'GAME OVER', 4, Color{
			r: 255
			g: 50
			b: 60
		})
		draw_text_centered(renderer, win_w / 2, 410, 'FINAL SCORE: ${game.score}', 3,
			Color{
			r: 255
			g: 255
			b: 255
		})
		draw_text_centered(renderer, win_w / 2, 465, 'PRESS [R] OR RESET TO REPLAY', 2, Color{
			r: 255
			g: 220
			b: 50
		})
	} else if game.status == .paused {
		overlay_rect := sdl.Rect{
			x: 300
			y: 320
			w: 500
			h: 180
		}
		sdl.set_render_draw_color(renderer, 15, 25, 45, 240)
		sdl.render_fill_rect(renderer, &overlay_rect)
		sdl.set_render_draw_color(renderer, 50, 180, 255, 255)
		sdl.render_draw_rect(renderer, &overlay_rect)

		draw_text_centered(renderer, win_w / 2, 360, 'GAME PAUSED', 4, Color{
			r: 50
			g: 200
			b: 255
		})
		draw_text_centered(renderer, win_w / 2, 430, 'PRESS [P] TO RESUME', 2, Color{
			r: 255
			g: 255
			b: 255
		})
	}
}
