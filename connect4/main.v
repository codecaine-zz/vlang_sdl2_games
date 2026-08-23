module main

import math
import os
import rand
import sdl

const win_width = 1100
const win_height = 840

const cell_size = 96
const disc_r = 38
const board_start_x = (win_width - (board_cols * cell_size)) / 2
const board_start_y = 175

struct AnimPiece {
mut:
	active     bool
	col        int
	target_row int
	player     int
	curr_y     f64
	target_y   f64
	vy         f64
	bounce_cnt int
}

struct App {
mut:
	window       &sdl.Window   = unsafe { nil }
	renderer     &sdl.Renderer = unsafe { nil }
	board        Board
	sound_mgr    SoundManager
	tex_mgr      Connect4TextureManager
	mode         GameMode   = .pve
	diff         Difficulty = .hard
	selected_col int        = 3
	hover_col    int        = -1
	prev_hover   int        = -1
	p1_score     int
	p2_score     int
	draw_score   int
	anim         AnimPiece
	particles    []Particle
	mouse_x      int
	mouse_y      int
	ai_timer     u32
	ai_thinking  bool
	btn_restart  Button
	btn_undo     Button
	btn_mode     Button
	btn_diff     Button
	btn_sound    Button
}

fn new_app() App {
	mut app := App{
		board:       new_board()
		sound_mgr:   new_sound_manager()
		btn_restart: Button{
			x:            30
			y:            765
			w:            170
			h:            44
			text:         'RESET [R]'
			bg_color:     Color{
				r: 35
				g: 45
				b: 70
			}
			hover_color:  Color{
				r: 55
				g: 70
				b: 105
			}
			text_color:   Color{
				r: 255
				g: 255
				b: 255
			}
			border_color: Color{
				r: 85
				g: 105
				b: 150
			}
		}
		btn_undo:    Button{
			x:            220
			y:            765
			w:            160
			h:            44
			text:         'UNDO [U]'
			bg_color:     Color{
				r: 35
				g: 45
				b: 70
			}
			hover_color:  Color{
				r: 55
				g: 70
				b: 105
			}
			text_color:   Color{
				r: 255
				g: 255
				b: 255
			}
			border_color: Color{
				r: 85
				g: 105
				b: 150
			}
		}
		btn_mode:    Button{
			x:            400
			y:            765
			w:            210
			h:            44
			text:         'MODE: 1P [M]'
			bg_color:     Color{
				r: 35
				g: 45
				b: 70
			}
			hover_color:  Color{
				r: 55
				g: 70
				b: 105
			}
			text_color:   Color{
				r: 255
				g: 255
				b: 255
			}
			border_color: Color{
				r: 85
				g: 105
				b: 150
			}
		}
		btn_diff:    Button{
			x:            630
			y:            765
			w:            240
			h:            44
			text:         'DIFF: HARD [D]'
			bg_color:     Color{
				r: 35
				g: 45
				b: 70
			}
			hover_color:  Color{
				r: 55
				g: 70
				b: 105
			}
			text_color:   Color{
				r: 255
				g: 255
				b: 255
			}
			border_color: Color{
				r: 85
				g: 105
				b: 150
			}
		}
		btn_sound:   Button{
			x:            890
			y:            765
			w:            180
			h:            44
			text:         'SOUND: ON [S]'
			bg_color:     Color{
				r: 35
				g: 45
				b: 70
			}
			hover_color:  Color{
				r: 55
				g: 70
				b: 105
			}
			text_color:   Color{
				r: 80
				g: 240
				b: 140
			}
			border_color: Color{
				r: 85
				g: 105
				b: 150
			}
		}
	}
	return app
}

fn (mut app App) init_sdl() bool {
	if sdl.init(sdl.init_video | sdl.init_audio) < 0 {
		eprintln('Failed to initialize SDL')
		return false
	}

	app.window = sdl.create_window(c'Connect 4 - V & SDL2', sdl.windowpos_centered, sdl.windowpos_centered,
		win_width, win_height, u32(sdl.WindowFlags.shown) | u32(sdl.WindowFlags.fullscreen_desktop) | u32(sdl.WindowFlags.resizable))

	if app.window == unsafe { nil } {
		eprintln('Failed to create SDL Window')
		return false
	}

	app.renderer = sdl.create_renderer(app.window, -1, u32(sdl.RendererFlags.accelerated) | u32(sdl.RendererFlags.presentvsync))
	if app.renderer == unsafe { nil } {
		eprintln('Failed to create SDL Renderer')
		return false
	}

	sdl.render_set_logical_size(app.renderer, win_width, win_height)
	app.tex_mgr.init(app.renderer)

	return true
}

fn (mut app App) trigger_drop(col int) bool {
	if app.anim.active || app.board.state != .in_progress {
		return false
	}
	if app.mode == .pve && app.board.current_turn == 2 {
		return false // Wait for AI turn
	}

	target_row := app.board.get_lowest_empty_row(col)
	if target_row == -1 {
		return false
	}

	app.sound_mgr.play_drop_sound()
	app.anim = AnimPiece{
		active:     true
		col:        col
		target_row: target_row
		player:     app.board.current_turn
		curr_y:     f64(board_start_y - cell_size / 2)
		target_y:   f64(board_start_y + target_row * cell_size + cell_size / 2)
		vy:         2.0
		bounce_cnt: 0
	}
	return true
}

fn (mut app App) spawn_win_particles(pos Pos, player int) {
	cx := f64(board_start_x + pos.col * cell_size + cell_size / 2)
	cy := f64(board_start_y + pos.row * cell_size + cell_size / 2)
	p_color := if player == 1 {
		Color{
			r: 255
			g: 80
			b: 95
		}
	} else {
		Color{
			r: 255
			g: 225
			b: 50
		}
	}

	for _ in 0 .. 18 {
		angle := rand.f64() * math.pi * 2.0
		speed := 2.0 + rand.f64() * 6.5
		app.particles << Particle{
			x:     cx
			y:     cy
			vx:    math.cos(angle) * speed
			vy:    math.sin(angle) * speed
			life:  1.0
			color: p_color
			size:  3 + rand.intn(4) or { 3 }
		}
	}
}

fn (mut app App) update_particles() {
	for i := app.particles.len - 1; i >= 0; i-- {
		app.particles[i].x += app.particles[i].vx
		app.particles[i].y += app.particles[i].vy
		app.particles[i].vy += 0.15
		app.particles[i].life -= 0.025
		if app.particles[i].life <= 0 {
			app.particles.delete(i)
		}
	}
}

fn (mut app App) update_animation() {
	if !app.anim.active {
		return
	}

	app.anim.vy += 1.7 // Gravity acceleration
	app.anim.curr_y += app.anim.vy

	if app.anim.curr_y >= app.anim.target_y {
		app.anim.curr_y = app.anim.target_y
		if app.anim.bounce_cnt == 0 && app.anim.vy > 4.0 {
			app.sound_mgr.play_land_sound()
			app.anim.vy = -app.anim.vy * 0.26
			app.anim.bounce_cnt++
		} else {
			// Animation finished! Finalize drop into board logic
			app.anim.active = false
			app.sound_mgr.play_land_sound()
			app.board.drop_piece(app.anim.col)

			if app.board.state == .won_p1 {
				app.p1_score++
				app.sound_mgr.play_win_sound()
				for pos in app.board.winning_line {
					app.spawn_win_particles(pos, 1)
				}
			} else if app.board.state == .won_p2 {
				app.p2_score++
				if app.mode == .pve {
					app.sound_mgr.play_lose_sound()
				} else {
					app.sound_mgr.play_win_sound()
				}
				for pos in app.board.winning_line {
					app.spawn_win_particles(pos, 2)
				}
			} else if app.board.state == .draw {
				app.draw_score++
				app.sound_mgr.play_draw_sound()
			}

			// If in PvE mode and it's now AI's turn, trigger AI thinking timer
			if app.mode == .pve && app.board.current_turn == 2 && app.board.state == .in_progress {
				app.ai_thinking = true
				app.ai_timer = sdl.get_ticks()
			}
		}
	}
}

fn (mut app App) handle_ai() {
	if !app.ai_thinking || app.anim.active || app.board.state != .in_progress {
		return
	}

	if sdl.get_ticks() - app.ai_timer >= 320 {
		app.ai_thinking = false
		ai_move := get_best_move(app.board, app.diff)

		target_row := app.board.get_lowest_empty_row(ai_move)
		if target_row != -1 {
			app.sound_mgr.play_drop_sound()
			app.anim = AnimPiece{
				active:     true
				col:        ai_move
				target_row: target_row
				player:     2
				curr_y:     f64(board_start_y - cell_size / 2)
				target_y:   f64(board_start_y + target_row * cell_size + cell_size / 2)
				vy:         2.0
				bounce_cnt: 0
			}
		}
	}
}

fn (mut app App) reset_game() {
	app.sound_mgr.play_click_sound()
	app.board = new_board()
	app.anim.active = false
	app.ai_thinking = false
	app.particles.clear()
}

fn (mut app App) toggle_mode() {
	app.sound_mgr.play_click_sound()
	app.mode = if app.mode == .pve { GameMode.pvp } else { GameMode.pve }
	app.btn_mode.text = if app.mode == .pve { 'MODE: 1P [M]' } else { 'MODE: 2P [M]' }
	app.reset_game()
}

fn (mut app App) toggle_difficulty() {
	app.sound_mgr.play_click_sound()
	if app.diff == .easy {
		app.diff = .medium
		app.btn_diff.text = 'DIFF: MEDIUM [D]'
	} else if app.diff == .medium {
		app.diff = .hard
		app.btn_diff.text = 'DIFF: HARD [D]'
	} else {
		app.diff = .easy
		app.btn_diff.text = 'DIFF: EASY [D]'
	}
}

fn (mut app App) toggle_sound() {
	is_on := app.sound_mgr.toggle_sound()
	app.btn_sound.text = if is_on { 'SOUND: ON [S]' } else { 'SOUND: OFF [S]' }
	app.btn_sound.text_color = if is_on {
		Color{
			r: 80
			g: 240
			b: 140
		}
	} else {
		Color{
			r: 240
			g: 90
			b: 90
		}
	}
	if is_on {
		app.sound_mgr.play_click_sound()
	}
}

fn (mut app App) undo_turn() {
	if app.anim.active {
		return
	}
	app.sound_mgr.play_undo_sound()
	if app.mode == .pve {
		app.board.undo_move()
		app.board.undo_move()
	} else {
		app.board.undo_move()
	}
	app.ai_thinking = false
}

fn (mut app App) handle_mouse_click(x int, y int) {
	if app.btn_restart.is_hovered(x, y) {
		app.reset_game()
		return
	}
	if app.btn_undo.is_hovered(x, y) {
		app.undo_turn()
		return
	}
	if app.btn_mode.is_hovered(x, y) {
		app.toggle_mode()
		return
	}
	if app.btn_diff.is_hovered(x, y) {
		app.toggle_difficulty()
		return
	}
	if app.btn_sound.is_hovered(x, y) {
		app.toggle_sound()
		return
	}

	// Board click detection
	if x >= board_start_x && x < board_start_x + board_cols * cell_size {
		if y >= board_start_y && y < board_start_y + board_rows * cell_size {
			col := (x - board_start_x) / cell_size
			app.trigger_drop(col)
		}
	}
}

fn (mut app App) update_hover(x int, y int) {
	app.mouse_x = x
	app.mouse_y = y
	if x >= board_start_x && x < board_start_x + board_cols * cell_size {
		if y >= board_start_y && y < board_start_y + board_rows * cell_size {
			new_hover := (x - board_start_x) / cell_size
			if new_hover != app.hover_col {
				app.hover_col = new_hover
				if app.hover_col != app.prev_hover {
					app.sound_mgr.play_hover_sound()
					app.prev_hover = app.hover_col
				}
			}
			return
		}
	}
	app.hover_col = -1
	app.prev_hover = -1
}

fn (mut app App) render() {
	// Background gradient fill with dark cyberpunk aesthetic
	sdl.set_render_draw_color(app.renderer, 15, 18, 30, 255)
	sdl.render_clear(app.renderer)

	// Top Title Header
	draw_text_centered(app.renderer, win_width / 2, 14, 'CONNECT 4', 3, Color{
		r: 255
		g: 255
		b: 255
	})

	// Glassmorphic Score Cards
	draw_glass_card(app.renderer, 30, 50, 220, 44, Color{ r: 235, g: 45, b: 60 })
	draw_text_centered(app.renderer, 140, 64, 'RED: ${app.p1_score}', 2, Color{
		r: 255
		g: 120
		b: 130
	})

	draw_glass_card(app.renderer, win_width - 250, 50, 220, 44, Color{ r: 255, g: 200, b: 25 })
	draw_text_centered(app.renderer, win_width - 140, 64, 'YELLOW: ${app.p2_score}', 2,
		Color{ r: 255, g: 235, b: 120 })

	// Turn / Status Banner Badge Pill
	mut status_text := ''
	mut status_color := Color{
		r: 255
		g: 255
		b: 255
	}
	mut badge_border := Color{
		r: 90
		g: 110
		b: 160
	}

	if app.board.state == .won_p1 {
		status_text = 'PLAYER 1 (RED) WINS!'
		status_color = Color{
			r: 255
			g: 90
			b: 90
		}
		badge_border = Color{
			r: 235
			g: 45
			b: 60
		}
	} else if app.board.state == .won_p2 {
		status_text = if app.mode == .pve { 'AI (YELLOW) WINS!' } else { 'PLAYER 2 (YELLOW) WINS!' }
		status_color = Color{
			r: 255
			g: 220
			b: 60
		}
		badge_border = Color{
			r: 255
			g: 200
			b: 25
		}
	} else if app.board.state == .draw {
		status_text = 'GAME DRAW!'
		status_color = Color{
			r: 200
			g: 210
			b: 235
		}
		badge_border = Color{
			r: 150
			g: 170
			b: 210
		}
	} else if app.ai_thinking {
		status_text = 'AI IS THINKING...'
		status_color = Color{
			r: 255
			g: 220
			b: 60
		}
		badge_border = Color{
			r: 255
			g: 200
			b: 25
		}
	} else {
		if app.board.current_turn == 1 {
			status_text = 'RED TURN'
			status_color = Color{
				r: 255
				g: 90
				b: 90
			}
			badge_border = Color{
				r: 235
				g: 45
				b: 60
			}
		} else {
			status_text = if app.mode == .pve { 'AI TURN' } else { 'YELLOW TURN' }
			status_color = Color{
				r: 255
				g: 220
				b: 60
			}
			badge_border = Color{
				r: 255
				g: 200
				b: 25
			}
		}
	}

	draw_glass_card(app.renderer, win_width / 2 - 190, 50, 380, 44, badge_border)
	draw_text_centered(app.renderer, win_width / 2, 64, status_text, 2, status_color)

	// Draw Column Hover Target Ghost Disc & Light Column Beam
	if !app.anim.active && app.board.state == .in_progress && app.hover_col >= 0
		&& app.hover_col < board_cols {
		if app.mode == .pvp || app.board.current_turn == 1 {
			cx := board_start_x + app.hover_col * cell_size + cell_size / 2
			cy := board_start_y - cell_size / 2
			draw_ghost_disc(app.renderer, cx, cy, disc_r - 2, app.board.current_turn)

			// Subtle background column glow beam
			beam_rect := sdl.Rect{
				x: board_start_x + app.hover_col * cell_size + 4
				y: board_start_y + 4
				w: cell_size - 8
				h: board_rows * cell_size - 8
			}
			beam_color := if app.board.current_turn == 1 {
				Color{
					r: 235
					g: 45
					b: 60
					a: 35
				}
			} else {
				Color{
					r: 255
					g: 200
					b: 25
					a: 35
				}
			}
			sdl.set_render_draw_color(app.renderer, beam_color.r, beam_color.g, beam_color.b,
				beam_color.a)
			sdl.render_fill_rect(app.renderer, &beam_rect)
		}
	}

	// Draw Main Board Frame
	board_rect := sdl.Rect{
		x: board_start_x
		y: board_start_y
		w: board_cols * cell_size
		h: board_rows * cell_size
	}
	// Blue Metallic Board Fill
	sdl.set_render_draw_color(app.renderer, 22, 60, 155, 255)
	sdl.render_fill_rect(app.renderer, &board_rect)

	// Top edge highlight line
	top_board_highlight := sdl.Rect{
		x: board_start_x
		y: board_start_y
		w: board_cols * cell_size
		h: 3
	}
	sdl.set_render_draw_color(app.renderer, 70, 140, 240, 255)
	sdl.render_fill_rect(app.renderer, &top_board_highlight)

	// Outer Board Shadow / Border
	sdl.set_render_draw_color(app.renderer, 10, 28, 80, 255)
	border_rect := sdl.Rect{
		x: board_start_x - 4
		y: board_start_y - 4
		w: board_cols * cell_size + 8
		h: board_rows * cell_size + 8
	}
	sdl.render_draw_rect(app.renderer, &border_rect)

	// Draw Discs & Empty Cutout Holes
	for r in 0 .. board_rows {
		for c in 0 .. board_cols {
			cx := board_start_x + c * cell_size + cell_size / 2
			cy := board_start_y + r * cell_size + cell_size / 2
			p := app.board.grid[r][c]

			if p == 0 {
				// Empty hole cutout showing background color
				draw_filled_circle(app.renderer, cx, cy, disc_r, Color{ r: 15, g: 18, b: 30 })
				draw_circle_outline(app.renderer, cx, cy, disc_r, 2, Color{ r: 10, g: 32, b: 85 })
			} else {
				is_win := app.board.winning_line.any(it.row == r && it.col == c)
				draw_disc(app.renderer, cx, cy, disc_r, p, is_win, app.tex_mgr.sprite_texture)
			}
		}
	}

	// Draw Dropping Animation Disc
	if app.anim.active {
		cx := board_start_x + app.anim.col * cell_size + cell_size / 2
		cy := int(app.anim.curr_y)
		draw_disc(app.renderer, cx, cy, disc_r, app.anim.player, false, app.tex_mgr.sprite_texture)
	}

	// Highlight Winning Line with Pulsing Gold Rings
	if app.board.winning_line.len >= 4 {
		ticks := sdl.get_ticks()
		pulse := int(math.sin(f64(ticks) * 0.008) * 4.0) + 6
		for pos in app.board.winning_line {
			cx := board_start_x + pos.col * cell_size + cell_size / 2
			cy := board_start_y + pos.row * cell_size + cell_size / 2
			draw_circle_outline(app.renderer, cx, cy, disc_r + 3, pulse, Color{
				r: 255
				g: 255
				b: 255
			})
			draw_circle_outline(app.renderer, cx, cy, disc_r + 1, 2, Color{ r: 255, g: 215, b: 0 })
		}
	}

	// Render Celebration Particles
	for p in app.particles {
		draw_filled_circle(app.renderer, int(p.x), int(p.y), p.size, Color{
			r: p.color.r
			g: p.color.g
			b: p.color.b
			a: u8(p.life * 255.0)
		})
	}

	// Draw UI Buttons
	app.btn_restart.draw(app.renderer, app.mouse_x, app.mouse_y)
	app.btn_undo.draw(app.renderer, app.mouse_x, app.mouse_y)
	app.btn_mode.draw(app.renderer, app.mouse_x, app.mouse_y)
	app.btn_diff.draw(app.renderer, app.mouse_x, app.mouse_y)
	app.btn_sound.draw(app.renderer, app.mouse_x, app.mouse_y)

	prod_fx_render(app.renderer)
	sdl.render_present(app.renderer)
}

fn (mut app App) run() {
	mut should_close := false

	for !should_close {
		evt := sdl.Event{}
		for 0 < sdl.poll_event(&evt) {
			match evt.@type {
				.quit {
					should_close = true
				}
				.mousebuttondown {
					if evt.button.button == u8(sdl.button_left) {
						app.handle_mouse_click(evt.button.x, evt.button.y)
					}
				}
				.mousemotion {
					app.update_hover(evt.motion.x, evt.motion.y)
				}
				.keydown {
					sym := evt.key.keysym.sym
					if sym == int(sdl.KeyCode.f11) {
						toggle_fullscreen(app.window)
					} else if sym == int(sdl.KeyCode.r) {
						app.reset_game()
					} else if sym == int(sdl.KeyCode.u) {
						app.undo_turn()
					} else if sym == int(sdl.KeyCode.m) {
						app.toggle_mode()
					} else if sym == int(sdl.KeyCode.d) {
						app.toggle_difficulty()
					} else if sym == int(sdl.KeyCode.s) {
						app.toggle_sound()
					} else if sym == int(sdl.KeyCode.left) {
						if app.selected_col > 0 {
							app.selected_col--
							app.hover_col = app.selected_col
							app.sound_mgr.play_hover_sound()
						}
					} else if sym == int(sdl.KeyCode.right) {
						if app.selected_col < board_cols - 1 {
							app.selected_col++
							app.hover_col = app.selected_col
							app.sound_mgr.play_hover_sound()
						}
					} else if sym == int(sdl.KeyCode.space) || sym == int(sdl.KeyCode.@return)
						|| sym == int(sdl.KeyCode.down) {
						app.trigger_drop(app.selected_col)
					} else if sym == int(sdl.KeyCode.escape) {
						should_close = true
					}
				}
				else {}
			}
		}

		app.update_animation()
		app.update_particles()
		app.handle_ai()
		app.sound_mgr.update_bgm(app.board.state == .in_progress)
		app.render()
		sdl.delay(16) // ~60 FPS loop
	}
}

fn (mut app App) cleanup() {
	app.sound_mgr.cleanup()
	if app.renderer != unsafe { nil } {
		sdl.destroy_renderer(app.renderer)
	}
	if app.window != unsafe { nil } {
		sdl.destroy_window(app.window)
	}
	sdl.quit()
}

fn main() {
	if os.args.contains('--snapshot') || os.args.contains('--snap') {
		sdl.init(sdl.init_video)
		surface := sdl.create_rgb_surface(0, win_width, win_height, 32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000)
		s_renderer := sdl.create_software_renderer(surface)
		mut app := new_app()
		app.renderer = s_renderer
		// Seed some pieces on board
		app.board.grid[5][3] = 1
		app.board.grid[5][4] = 2
		app.board.grid[5][2] = 1
		app.board.grid[4][3] = 2
		app.board.grid[5][1] = 1
		app.board.grid[4][4] = 2
		app.p1_score = 3
		app.p2_score = 2
		app.render()
		sdl.save_bmp(surface, 'screenshots/connect4.bmp'.str)
		sdl.destroy_renderer(s_renderer)
		sdl.free_surface(surface)
		sdl.quit()
		return
	}

	mut app := new_app()
	if !app.init_sdl() {
		return
	}
	defer {
		app.cleanup()
	}
	app.run()
}

fn toggle_fullscreen(window &sdl.Window) {
	flags := sdl.get_window_flags(window)
	if (flags & u32(sdl.WindowFlags.fullscreen_desktop)) != 0 || (flags & u32(sdl.WindowFlags.fullscreen)) != 0 {
		sdl.set_window_fullscreen(window, 0)
	} else {
		sdl.set_window_fullscreen(window, u32(sdl.WindowFlags.fullscreen_desktop))
	}
}
