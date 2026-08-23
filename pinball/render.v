import math
import os
import sdl
import sdl.image

pub struct PinballTextureManager {
pub mut:
	sprite_texture &sdl.Texture = unsafe { nil }
}

pub fn (mut tm PinballTextureManager) init(renderer &sdl.Renderer) {
	_ = image.init(int(image.InitFlags.png))
	candidates := [
		'assets/sprites/pinball.png',
		'./assets/sprites/pinball.png',
		'../assets/sprites/pinball.png',
		'pinball/assets/sprites/pinball.png',
	]
	for p in candidates {
		if os.exists(p) {
			surface := image.load(p.str)
			if surface != unsafe { nil } {
				tm.sprite_texture = sdl.create_texture_from_surface(renderer, surface)
				sdl.free_surface(surface)
				if tm.sprite_texture != unsafe { nil } {
					println('Pinball Texture Loaded Successfully: ' + p)
					return
				}
			}
		}
	}
}

fn draw_circle(renderer &sdl.Renderer, cx int, cy int, radius int, color Color) {
	sdl.set_render_draw_color(renderer, color.r, color.g, color.b, color.a)
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

		y++
		err += 1 + 2 * y
		if 2 * (err - x) + 1 > 0 {
			x--
			err += 1 - 2 * x
		}
	}
}

fn fill_circle(renderer &sdl.Renderer, cx int, cy int, radius int, color Color) {
	sdl.set_render_draw_color(renderer, color.r, color.g, color.b, color.a)
	for dy := -radius; dy <= radius; dy++ {
		dx := int(math.sqrt(f64(radius * radius - dy * dy)))
		sdl.render_draw_line(renderer, cx - dx, cy + dy, cx + dx, cy + dy)
	}
}

fn draw_thick_line(renderer &sdl.Renderer, x1 int, y1 int, x2 int, y2 int, thickness int, color Color) {
	sdl.set_render_draw_color(renderer, color.r, color.g, color.b, color.a)
	for t := -thickness / 2; t <= thickness / 2; t++ {
		dx := x2 - x1
		dy := y2 - y1
		len := math.sqrt(f64(dx * dx + dy * dy))
		if len < 0.001 {
			continue
		}
		nx := int(-f64(dy) / len * f64(t))
		ny := int(f64(dx) / len * f64(t))
		sdl.render_draw_line(renderer, x1 + nx, y1 + ny, x2 + nx, y2 + ny)
	}
}

fn render_game(renderer &sdl.Renderer, game &GameEngine, tex &sdl.Texture) {
	// 1. Clear Screen
	sdl.set_render_draw_color(renderer, 12, 16, 28, 255)
	sdl.render_clear(renderer)

	if game.state == .title {
		render_title_screen(renderer, game)
		return
	}

	cam_y := int(game.camera_y)

	// 2. Playfield Cabinet Felt Background
	table_bg := sdl.Rect{
		x: 145
		y: 70 - cam_y
		w: 515
		h: 820
	}
	sdl.set_render_draw_color(renderer, 18, 26, 44, 255)
	sdl.render_fill_rect(renderer, &table_bg)

	// Outer Cabinet Rails
	draw_thick_line(renderer, 145, 70 - cam_y, 145, 890 - cam_y, 6, Color{60, 80, 120, 255})
	draw_thick_line(renderer, 660, 70 - cam_y, 660, 890 - cam_y, 6, Color{60, 80, 120, 255})
	draw_thick_line(renderer, 625, 70 - cam_y, 625, 890 - cam_y, 4, Color{100, 120, 160, 255})

	// 3. Playfield Walls
	for seg in game.table_walls {
		draw_thick_line(renderer, int(seg.p1.x), int(seg.p1.y) - cam_y, int(seg.p2.x),
			int(seg.p2.y) - cam_y, 4, Color{0, 220, 255, 255})
	}

	// 4. Rollover Lanes (A, B, C)
	for lane in game.rollovers {
		l_rect := sdl.Rect{
			x: int(lane.pos.x)
			y: int(lane.pos.y) - cam_y
			w: int(lane.width)
			h: int(lane.height)
		}
		color := if lane.active { Color{255, 255, 0, 255} } else { Color{70, 70, 90, 255} }
		sdl.set_render_draw_color(renderer, color.r, color.g, color.b, color.a)
		sdl.render_draw_rect(renderer, &l_rect)
		draw_text_centered(renderer, int(lane.pos.x + lane.width / 2.0), int(lane.pos.y + 12.0) - cam_y,
			lane.label, 2, color)
	}

	// 5. Bumpers
	for bumper in game.bumpers {
		bx := int(bumper.pos.x)
		by := int(bumper.pos.y) - cam_y
		if tex != unsafe { nil } {
			col_x := if bumper.hit_timer > 0 { 64 } else { 0 }
			src := sdl.Rect{x: col_x, y: 64, w: 64, h: 64}
			r := int(bumper.radius)
			dst := sdl.Rect{x: bx - r, y: by - r, w: r * 2, h: r * 2}
			sdl.render_copy(renderer, tex, &src, &dst)
			continue
		}
		b_color := if bumper.hit_timer > 0 {
			Color{255, 255, 100, 255}
		} else {
			Color{255, 80, 80, 255}
		}
		fill_circle(renderer, bx, by, int(bumper.radius), b_color)
		draw_circle(renderer, bx, by, int(bumper.radius) + 3, Color{255, 255, 255, 255})
		fill_circle(renderer, bx, by, 10, Color{40, 40, 80, 255})
		draw_text_centered(renderer, bx, by - 6, '100', 1, Color{255, 255, 255, 255})
	}

	// 6. Drop Card Targets (10, J, Q, K, A)
	for target in game.card_targets {
		if target.active {
			t_rect := sdl.Rect{
				x: int(target.pos.x)
				y: int(target.pos.y) - cam_y
				w: int(target.width)
				h: int(target.height)
			}
			sdl.set_render_draw_color(renderer, 240, 240, 255, 255)
			sdl.render_fill_rect(renderer, &t_rect)
			sdl.set_render_draw_color(renderer, 200, 40, 40, 255)
			sdl.render_draw_rect(renderer, &t_rect)
			draw_text_centered(renderer, int(target.pos.x + target.width / 2.0),
				int(target.pos.y + 2.0) - cam_y, target.label, 1, Color{200, 20, 20, 255})
		}
	}

	// 7. Slingshots
	for seg in game.slingshot_left {
		draw_thick_line(renderer, int(seg.p1.x), int(seg.p1.y) - cam_y, int(seg.p2.x),
			int(seg.p2.y) - cam_y, 3, Color{255, 140, 0, 255})
	}
	for seg in game.slingshot_right {
		draw_thick_line(renderer, int(seg.p1.x), int(seg.p1.y) - cam_y, int(seg.p2.x),
			int(seg.p2.y) - cam_y, 3, Color{255, 140, 0, 255})
	}

	// 8. Flippers
	render_flipper(renderer, &game.left_flipper_lower, cam_y)
	render_flipper(renderer, &game.right_flipper_lower, cam_y)
	render_flipper(renderer, &game.left_flipper_upper, cam_y)
	render_flipper(renderer, &game.right_flipper_upper, cam_y)

	// 9. Spinner Target
	sp_x := int(game.spinner_pos.x)
	sp_y := int(game.spinner_pos.y) - cam_y
	sp_len := int(math.abs(math.cos(game.spinner_angle)) * 20.0)
	draw_thick_line(renderer, sp_x - sp_len, sp_y, sp_x + sp_len, sp_y, 4, Color{255, 200, 50, 255})

	// 10. Kickback Saver Post
	if game.kickback_active {
		fill_circle(renderer, 390, 840 - cam_y, 8, Color{50, 255, 100, 255})
	}

	// 11. Mario Bonus Sub-Stage Render
	if game.camera_y > 600.0 || game.zone == .mario_bonus {
		render_mario_stage(renderer, game, cam_y)
	}

	// 12. Plunger Spring
	plunge_y := 840 - cam_y + int(game.plunger_tension * 0.4)
	draw_thick_line(renderer, 637, 860 - cam_y, 637, plunge_y, 5, Color{200, 200, 200, 255})
	p_knob := sdl.Rect{
		x: 628
		y: plunge_y
		w: 18
		h: 22
	}
	sdl.set_render_draw_color(renderer, 220, 50, 50, 255)
	sdl.render_fill_rect(renderer, &p_knob)

	// 13. Ball Graphic
	if game.ball.active {
		bx := int(game.ball.pos.x)
		by := int(game.ball.pos.y) - cam_y
		if tex != unsafe { nil } {
			src := sdl.Rect{x: 0, y: 0, w: 64, h: 64}
			r := int(game.ball.radius)
			dst := sdl.Rect{x: bx - r, y: by - r, w: r * 2, h: r * 2}
			sdl.render_copy(renderer, tex, &src, &dst)
		} else {
			fill_circle(renderer, bx, by, int(game.ball.radius), Color{240, 240, 240, 255})
			fill_circle(renderer, bx - 2, by - 2, 3, Color{255, 255, 255, 255})
		}
	}

	// 14. Score Popups
	for popup in game.popups {
		draw_text_centered(renderer, int(popup.pos.x), int(popup.pos.y) - cam_y, popup.text,
			1, popup.color)
	}

	// 15. Dynamic HUD Overlay (Pinned to Screen Header)
	render_hud(renderer, game)
}

fn render_flipper(renderer &sdl.Renderer, flipper &Flipper, cam_y int) {
	px := int(flipper.pivot.x)
	py := int(flipper.pivot.y) - cam_y
	tip := flipper.get_tip()
	tx := int(tip.x)
	ty := int(tip.y) - cam_y

	draw_thick_line(renderer, px, py, tx, ty, 10, Color{255, 220, 0, 255})
	fill_circle(renderer, px, py, 6, Color{200, 50, 50, 255})
	fill_circle(renderer, tx, ty, 4, Color{200, 50, 50, 255})
}

fn render_mario_stage(renderer &sdl.Renderer, game &GameEngine, cam_y int) {
	// Sub-Stage Container Box
	box := sdl.Rect{
		x: 170
		y: 1100 - cam_y
		w: 460
		h: 380
	}
	sdl.set_render_draw_color(renderer, 30, 20, 50, 255)
	sdl.render_fill_rect(renderer, &box)
	sdl.set_render_draw_color(renderer, 255, 100, 200, 255)
	sdl.render_draw_rect(renderer, &box)

	draw_text_centered(renderer, 400, 1115 - cam_y, 'MARIO BONUS STAGE', 2, Color{255, 220, 80,
		255})

	// Bricks
	for brk in game.mario_stage.bricks {
		if brk.active {
			b_rect := sdl.Rect{
				x: int(brk.x)
				y: int(brk.y) - cam_y
				w: int(brk.width)
				h: int(brk.height)
			}
			b_color := match brk.color_idx {
				0 { Color{240, 60, 60, 255} }
				1 { Color{240, 220, 60, 255} }
				else { Color{60, 160, 240, 255} }
			}
			sdl.set_render_draw_color(renderer, b_color.r, b_color.g, b_color.b, b_color.a)
			sdl.render_fill_rect(renderer, &b_rect)
			sdl.set_render_draw_color(renderer, 255, 255, 255, 255)
			sdl.render_draw_rect(renderer, &b_rect)
		}
	}

	// Damsel (Pauline)
	dx := int(game.mario_stage.damsel_x)
	dy := int(game.mario_stage.damsel_y) - cam_y
	draw_text_centered(renderer, dx, dy, 'LADY', 1, Color{255, 150, 200, 255})

	// Mario & Shield Paddle
	mx := int(game.mario_stage.mario_x)
	mw := int(game.mario_stage.shield_width)
	paddle := sdl.Rect{
		x: mx - mw / 2
		y: 1430 - cam_y
		w: mw
		h: 12
	}
	sdl.set_render_draw_color(renderer, 220, 40, 40, 255)
	sdl.render_fill_rect(renderer, &paddle)
	draw_text_centered(renderer, mx, 1450 - cam_y, 'MARIO', 1, Color{255, 255, 255, 255})
}

fn render_hud(renderer &sdl.Renderer, game &GameEngine) {
	// Top Header Bar
	bar := sdl.Rect{
		x: 0
		y: 0
		w: 800
		h: 65
	}
	sdl.set_render_draw_color(renderer, 10, 12, 20, 255)
	sdl.render_fill_rect(renderer, &bar)
	sdl.set_render_draw_color(renderer, 0, 180, 220, 255)
	sdl.render_draw_rect(renderer, &bar)

	// Player 1 & High Score & Player 2
	p1_str := '1P: ${game.p1_score:06d}'
	draw_text(renderer, 30, 15, p1_str, 2, Color{255, 255, 100, 255})

	hi_str := 'HIGH: ${game.high_score:06d}'
	draw_text_centered(renderer, 400, 15, hi_str, 2, Color{100, 255, 100, 255})

	p2_str := '2P: ${game.p2_score:06d}'
	draw_text(renderer, 610, 15, p2_str, 2, Color{255, 100, 255, 255})

	// Sub-bar info: Ball count, Multiplier, Player indicator
	ball_str := 'BALL: ${game.p1_balls}'
	draw_text(renderer, 30, 42, ball_str, 1, Color{200, 200, 200, 255})

	mult_str := 'MULT: ${game.multiplier}X'
	draw_text_centered(renderer, 400, 42, mult_str, 1, Color{255, 220, 0, 255})

	mode_str := if game.mode == .mode_1p { '1-PLAYER MODE' } else { '2-PLAYER MODE' }
	draw_text(renderer, 610, 42, mode_str, 1, Color{180, 180, 220, 255})

	// TILT Warning
	if game.is_tilted {
		draw_text_centered(renderer, 400, 400, '*** TILT! ***', 4, Color{255, 40, 40, 255})
	}

	if game.state == .paused {
		overlay := sdl.Rect{
			x: 0
			y: 0
			w: 800
			h: 900
		}
		sdl.set_render_draw_color(renderer, 0, 0, 0, 180)
		sdl.render_fill_rect(renderer, &overlay)
		draw_text_centered(renderer, 400, 420, 'PAUSED', 4, Color{255, 255, 255, 255})
	}

	if game.state == .game_over {
		overlay := sdl.Rect{
			x: 0
			y: 0
			w: 800
			h: 900
		}
		sdl.set_render_draw_color(renderer, 0, 0, 0, 200)
		sdl.render_fill_rect(renderer, &overlay)
		draw_text_centered(renderer, 400, 380, 'GAME OVER', 4, Color{255, 40, 40, 255})
		draw_text_centered(renderer, 400, 450, 'PRESS [R] TO PLAY AGAIN', 2, Color{
			255, 255, 255, 255})
	}
}

fn render_title_screen(renderer &sdl.Renderer, _ &GameEngine) {
	draw_text_centered(renderer, 400, 140, 'N I N T E N D O', 2, Color{255, 50, 50, 255})
	draw_text_centered(renderer, 400, 200, 'P I N B A L L', 5, Color{255, 220, 0, 255})
	draw_text_centered(renderer, 400, 270, '1984 NES ARCADE RECREATION', 2, Color{
		100, 220, 255, 255
	})

	// Decorative Animated Pinball Cabinet Graphics
	fill_circle(renderer, 400, 400, 40, Color{255, 80, 80, 255})
	draw_circle(renderer, 400, 400, 45, Color{255, 255, 255, 255})
	draw_text_centered(renderer, 400, 392, '100', 2, Color{255, 255, 255, 255})

	fill_circle(renderer, 310, 440, 30, Color{50, 200, 255, 255})
	fill_circle(renderer, 490, 440, 30, Color{50, 200, 255, 255})

	// Options
	draw_text_centered(renderer, 400, 550, 'PRESS [1] - 1 PLAYER GAME', 2, Color{
		255, 255, 255, 255
	})
	draw_text_centered(renderer, 400, 600, 'PRESS [2] - 2 PLAYER GAME', 2, Color{
		255, 255, 255, 255
	})
	draw_text_centered(renderer, 400, 670, 'CONTROLS:', 2, Color{255, 220, 0, 255})
	draw_text_centered(renderer, 400, 710, 'Z / LEFT ARROW - LEFT FLIPPER / MARIO LEFT', 1,
		Color{200, 200, 200, 255})
	draw_text_centered(renderer, 400, 735, 'X / RIGHT ARROW - RIGHT FLIPPER / MARIO RIGHT',
		1, Color{200, 200, 200, 255})
	draw_text_centered(renderer, 400, 760, 'SPACE / DOWN ARROW - HOLD & RELEASE PLUNGER', 1,
		Color{200, 200, 200, 255})
	draw_text_centered(renderer, 400, 785, 'T - TILT NUDGE TABLE | S - SOUND MUTE', 1,
		Color{200, 200, 200, 255})
}
