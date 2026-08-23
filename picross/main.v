module main

import math
import os
import rand
import sdl
import time

const win_width = 1000
const win_height = 840

enum PlayMode {
	strikes
	zen
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

struct App {
mut:
	window        &sdl.Window   = unsafe { nil }
	renderer      &sdl.Renderer = unsafe { nil }
	sound_mgr     SoundManager
	puzzles       []Puzzle
	current_idx   int
	cursor_r      int
	cursor_c      int
	mouse_down    bool
	mouse_button  u8
	drag_fill_mode CellState = .empty
	hover_r       int       = -1
	hover_c       int       = -1
	mode          PlayMode  = .zen
	strikes_count int
	max_strikes   int = 3
	game_over     bool
	start_time    time.Time
	elapsed_sec   int
	particles     []Particle
	btn_prev      Button
	btn_next      Button
	btn_reset     Button
	btn_hint      Button
	btn_mode      Button
	btn_sound     Button
}

fn new_app() App {
	catalog := get_puzzle_catalog()
	btn_y := 770

	return App{
		sound_mgr:   new_sound_manager()
		puzzles:     catalog
		current_idx: 0
		start_time:  time.now()
		btn_prev:    Button{
			x: 50, y: 70, w: 160, h: 36, text: 'PREV [P]',
			bg_color: Color{r: 30, g: 45, b: 70},
			hover_color: Color{r: 50, g: 75, b: 110},
			text_color: Color{r: 255, g: 255, b: 255},
			border_color: Color{r: 70, g: 100, b: 150},
		}
		btn_next:    Button{
			x: win_width - 210, y: 70, w: 160, h: 36, text: 'NEXT [N]',
			bg_color: Color{r: 30, g: 45, b: 70},
			hover_color: Color{r: 50, g: 75, b: 110},
			text_color: Color{r: 255, g: 255, b: 255},
			border_color: Color{r: 70, g: 100, b: 150},
		}
		btn_reset:   Button{
			x: 60, y: btn_y, w: 180, h: 42, text: 'RESET [R]',
			bg_color: Color{r: 40, g: 40, b: 60},
			hover_color: Color{r: 65, g: 65, b: 90},
			text_color: Color{r: 255, g: 255, b: 255},
			border_color: Color{r: 90, g: 90, b: 130},
		}
		btn_hint:    Button{
			x: 270, y: btn_y, w: 180, h: 42, text: 'HINT [H]',
			bg_color: Color{r: 40, g: 60, b: 40},
			hover_color: Color{r: 60, g: 90, b: 60},
			text_color: Color{r: 255, g: 255, b: 255},
			border_color: Color{r: 80, g: 140, b: 80},
		}
		btn_mode:    Button{
			x: 480, y: btn_y, w: 230, h: 42, text: 'MODE: ZEN [M]',
			bg_color: Color{r: 45, g: 40, b: 70},
			hover_color: Color{r: 70, g: 60, b: 110},
			text_color: Color{r: 255, g: 255, b: 255},
			border_color: Color{r: 100, g: 85, b: 150},
		}
		btn_sound:   Button{
			x: 740, y: btn_y, w: 200, h: 42, text: 'SOUND: ON [S]',
			bg_color: Color{r: 35, g: 50, b: 70},
			hover_color: Color{r: 55, g: 80, b: 110},
			text_color: Color{r: 255, g: 255, b: 255},
			border_color: Color{r: 80, g: 115, b: 160},
		}
	}
}

fn (mut app App) change_puzzle(offset int) {
	new_idx := app.current_idx + offset
	if new_idx >= 0 && new_idx < app.puzzles.len {
		app.current_idx = new_idx
		app.cursor_r = 0
		app.cursor_c = 0
		app.strikes_count = 0
		app.game_over = false
		app.start_time = time.now()
		app.sound_mgr.play_fill_sound()
	}
}

fn (mut app App) spawn_win_particles() {
	p := app.puzzles[app.current_idx]
	for _ in 0 .. 60 {
		angle := rand.f64() * 2.0 * math.pi
		speed := 80.0 + rand.f64() * 240.0
		app.particles << Particle{
			x: f64(win_width / 2)
			y: f64(win_height / 2)
			vx: math.cos(angle) * speed
			vy: math.sin(angle) * speed
			life: 1.0
			color: p.art_color
			size: 3 + rand.int_in_range(1, 4) or { 2 }
		}
	}
}

fn (mut app App) apply_cell_action(r int, c int, action CellState) {
	mut p := unsafe { &app.puzzles[app.current_idx] }
	if p.completed || app.game_over {
		return
	}
	if r < 0 || r >= p.height || c < 0 || c >= p.width {
		return
	}

	curr := p.grid[r][c]
	mut target := action

	if curr == action {
		target = .empty
	}

	if app.mode == .strikes && target == .filled && !p.solution[r][c] {
		// Mistake in challenge mode!
		p.grid[r][c] = .crossed
		app.strikes_count++
		app.sound_mgr.play_error_sound()
		if app.strikes_count >= app.max_strikes {
			app.game_over = true
		}
		p.update_status()
		return
	}

	p.grid[r][c] = target

	match target {
		.filled { app.sound_mgr.play_fill_sound() }
		.crossed { app.sound_mgr.play_cross_sound() }
		.empty { app.sound_mgr.play_erase_sound() }
	}

	was_completed := p.completed
	if p.update_status() && !was_completed {
		app.sound_mgr.play_win_sound()
		app.spawn_win_particles()
	}
}

fn (mut app App) calculate_grid_metrics() (int, int, int, int, int) {
	p := app.puzzles[app.current_idx]
	
	// Max clue lengths
	mut max_row_clues := 1
	for row in p.row_clues {
		if row.len > max_row_clues {
			max_row_clues = row.len
		}
	}
	mut max_col_clues := 1
	for col in p.col_clues {
		if col.len > max_col_clues {
			max_col_clues = col.len
		}
	}

	clue_col_w := max_row_clues * 22 + 16
	clue_row_h := max_col_clues * 20 + 16

	mut cell_size := 38
	if p.width == 5 {
		cell_size = 64
	} else if p.width == 10 {
		cell_size = 40
	} else if p.width == 15 {
		cell_size = 28
	}

	total_grid_w := p.width * cell_size
	total_grid_h := p.height * cell_size

	start_x := (win_width - total_grid_w + clue_col_w) / 2
	start_y := 130 + clue_row_h + (560 - clue_row_h - total_grid_h) / 2

	return cell_size, start_x, start_y, clue_col_w, clue_row_h
}

fn (mut app App) get_cell_under_mouse(mx int, my int) (int, int) {
	cell_size, start_x, start_y, _, _ := app.calculate_grid_metrics()
	p := app.puzzles[app.current_idx]

	if mx >= start_x && mx < start_x + p.width * cell_size &&
	   my >= start_y && my < start_y + p.height * cell_size {
		c := (mx - start_x) / cell_size
		r := (my - start_y) / cell_size
		return r, c
	}
	return -1, -1
}

fn (mut app App) render() {
	renderer := app.renderer
	p := app.puzzles[app.current_idx]

	// Background gradient / dark slate
	sdl.set_render_draw_color(renderer, 15, 18, 28, 255)
	sdl.render_clear(renderer)

	// Top Title
	draw_text_centered(renderer, win_width / 2, 20, 'PICROSS PRO // NONOGRAM LOGIC', 3, Color{r: 90, g: 180, b: 255})

	// Puzzle Name & Progress
	diff_str := 'PUZZLE ${app.current_idx + 1}/${app.puzzles.len}: ${p.name.to_upper()}'
	draw_text_centered(renderer, win_width / 2, 76, diff_str, 2, Color{r: 255, g: 255, b: 255})

	// Timer / Strikes
	if !p.completed && !app.game_over {
		app.elapsed_sec = int(time.since(app.start_time).seconds())
	}
	time_str := 'TIME: ${app.elapsed_sec / 60:02d}:${app.elapsed_sec % 60:02d}'
	draw_text(renderer, 40, 115, time_str, 2, Color{r: 160, g: 210, b: 255})

	if app.mode == .strikes {
		mut strike_str := 'STRIKES: '
		for i in 0 .. app.max_strikes {
			strike_str += if i < app.strikes_count { 'X ' } else { '- ' }
		}
		draw_text_right(renderer, win_width - 40, 115, strike_str, 2, Color{r: 255, g: 90, b: 90})
	} else {
		draw_text_right(renderer, win_width - 40, 115, 'ZEN LOGIC MODE', 2, Color{r: 100, g: 230, b: 150})
	}

	cell_size, start_x, start_y, _, clue_row_h := app.calculate_grid_metrics()

	// Hover highlight background bars
	if app.hover_r >= 0 && app.hover_c >= 0 && !p.completed {
		// Row highlight
		row_rect := sdl.Rect{
			x: start_x
			y: start_y + app.hover_r * cell_size
			w: p.width * cell_size
			h: cell_size
		}
		sdl.set_render_draw_color(renderer, 30, 42, 65, 120)
		sdl.render_fill_rect(renderer, &row_rect)

		// Column highlight
		col_rect := sdl.Rect{
			x: start_x + app.hover_c * cell_size
			y: start_y
			w: cell_size
			h: p.height * cell_size
		}
		sdl.render_fill_rect(renderer, &col_rect)
	}

	// Draw Column Clues (Above grid)
	for c in 0 .. p.width {
		clues := p.col_clues[c]
		col_solved := p.col_solved[c]
		clue_color := if col_solved { Color{r: 80, g: 100, b: 120} } else { Color{r: 230, g: 235, b: 245} }

		// Box behind clues
		col_bg := sdl.Rect{
			x: start_x + c * cell_size
			y: start_y - clue_row_h
			w: cell_size
			h: clue_row_h
		}
		sdl.set_render_draw_color(renderer, 22, 27, 40, 255)
		sdl.render_fill_rect(renderer, &col_bg)
		sdl.set_render_draw_color(renderer, 45, 55, 80, 255)
		sdl.render_draw_rect(renderer, &col_bg)

		for i in 0 .. clues.len {
			clue_val := clues[clues.len - 1 - i]
			num_str := '${clue_val}'
			cx := start_x + c * cell_size + cell_size / 2
			cy := start_y - 20 - i * 18
			draw_text_centered(renderer, cx, cy, num_str, 2, clue_color)
		}
	}

	// Draw Row Clues (Left of grid)
	for r in 0 .. p.height {
		clues := p.row_clues[r]
		row_solved := p.row_solved[r]
		clue_color := if row_solved { Color{r: 80, g: 100, b: 120} } else { Color{r: 230, g: 235, b: 245} }

		// Box behind clues
		row_bg := sdl.Rect{
			x: start_x - clues.len * 22 - 12
			y: start_y + r * cell_size
			w: clues.len * 22 + 12
			h: cell_size
		}
		sdl.set_render_draw_color(renderer, 22, 27, 40, 255)
		sdl.render_fill_rect(renderer, &row_bg)
		sdl.set_render_draw_color(renderer, 45, 55, 80, 255)
		sdl.render_draw_rect(renderer, &row_bg)

		for i in 0 .. clues.len {
			clue_val := clues[clues.len - 1 - i]
			num_str := '${clue_val}'
			cx := start_x - 14 - i * 22
			cy := start_y + r * cell_size + (cell_size - 16) / 2
			draw_text_centered(renderer, cx, cy, num_str, 2, clue_color)
		}
	}

	// Draw Cells
	for r in 0 .. p.height {
		for c in 0 .. p.width {
			cell_rect := sdl.Rect{
				x: start_x + c * cell_size
				y: start_y + r * cell_size
				w: cell_size
				h: cell_size
			}

			// Cell Background
			state := p.grid[r][c]
			match state {
				.filled {
					fill_color := if p.completed { p.art_color } else { Color{r: 70, g: 140, b: 245} }
					sdl.set_render_draw_color(renderer, fill_color.r, fill_color.g, fill_color.b, 255)
					sdl.render_fill_rect(renderer, &cell_rect)
				}
				.crossed {
					sdl.set_render_draw_color(renderer, 25, 30, 45, 255)
					sdl.render_fill_rect(renderer, &cell_rect)
					// Draw X cross
					sdl.set_render_draw_color(renderer, 220, 80, 80, 255)
					pad := cell_size / 4
					x1 := cell_rect.x + pad
					y1 := cell_rect.y + pad
					x2 := cell_rect.x + cell_size - pad
					y2 := cell_rect.y + cell_size - pad
					sdl.render_draw_line(renderer, x1, y1, x2, y2)
					sdl.render_draw_line(renderer, x1 + 1, y1, x2 + 1, y2)
					sdl.render_draw_line(renderer, x1, y2, x2, y1)
					sdl.render_draw_line(renderer, x1 + 1, y2, x2 + 1, y1)
				}
				.empty {
					sdl.set_render_draw_color(renderer, 32, 38, 55, 255)
					sdl.render_fill_rect(renderer, &cell_rect)
				}
			}

			// Minor grid border
			sdl.set_render_draw_color(renderer, 50, 60, 85, 255)
			sdl.render_draw_rect(renderer, &cell_rect)
		}
	}

	// Draw 5x5 Major Grid Lines
	for r in 0 .. p.height + 1 {
		if r % 5 == 0 {
			y := start_y + r * cell_size
			sdl.set_render_draw_color(renderer, 120, 160, 220, 255)
			sdl.render_draw_line(renderer, start_x, y, start_x + p.width * cell_size, y)
			sdl.render_draw_line(renderer, start_x, y - 1, start_x + p.width * cell_size, y - 1)
		}
	}
	for c in 0 .. p.width + 1 {
		if c % 5 == 0 {
			x := start_x + c * cell_size
			sdl.set_render_draw_color(renderer, 120, 160, 220, 255)
			sdl.render_draw_line(renderer, x, start_y, x, start_y + p.height * cell_size)
			sdl.render_draw_line(renderer, x - 1, start_y, x - 1, start_y + p.height * cell_size)
		}
	}

	// Keyboard cursor highlight
	if !p.completed && !app.game_over {
		cur_rect := sdl.Rect{
			x: start_x + app.cursor_c * cell_size
			y: start_y + app.cursor_r * cell_size
			w: cell_size
			h: cell_size
		}
		sdl.set_render_draw_color(renderer, 255, 220, 60, 255)
		sdl.render_draw_rect(renderer, &cur_rect)
		inner := sdl.Rect{x: cur_rect.x + 1, y: cur_rect.y + 1, w: cur_rect.w - 2, h: cur_rect.h - 2}
		sdl.render_draw_rect(renderer, &inner)
	}

	// Completion Banner
	if p.completed {
		banner := sdl.Rect{
			x: 0
			y: 690
			w: win_width
			h: 60
		}
		sdl.set_render_draw_color(renderer, 15, 65, 40, 230)
		sdl.render_fill_rect(renderer, &banner)
		draw_text_centered(renderer, win_width / 2, 708, '*** PUZZLE SOLVED! EXCELLENT WORK! ***', 2, Color{r: 100, g: 255, b: 150})
	} else if app.game_over {
		banner := sdl.Rect{
			x: 0
			y: 690
			w: win_width
			h: 60
		}
		sdl.set_render_draw_color(renderer, 75, 20, 20, 230)
		sdl.render_fill_rect(renderer, &banner)
		draw_text_centered(renderer, win_width / 2, 708, '3 STRIKES! GAME OVER - PRESS [R] TO RETRY', 2, Color{r: 255, g: 100, b: 100})
	}

	// Render UI Buttons
	mut mx, mut my := 0, 0
	sdl.get_mouse_state(&mx, &my)

	app.btn_prev.render(renderer, mx, my)
	app.btn_next.render(renderer, mx, my)
	app.btn_reset.render(renderer, mx, my)
	app.btn_hint.render(renderer, mx, my)

	app.btn_mode.text = if app.mode == .zen { 'MODE: ZEN [M]' } else { 'MODE: STRIKES [M]' }
	app.btn_mode.render(renderer, mx, my)

	app.btn_sound.text = if app.sound_mgr.sound_enabled { 'SOUND: ON [S]' } else { 'SOUND: OFF [S]' }
	app.btn_sound.render(renderer, mx, my)

	// Render Particles
	for p_idx in 0 .. app.particles.len {
		part := app.particles[p_idx]
		rect := sdl.Rect{
			x: int(part.x)
			y: int(part.y)
			w: part.size
			h: part.size
		}
		sdl.set_render_draw_color(renderer, part.color.r, part.color.g, part.color.b, u8(part.life * 255.0))
		sdl.render_fill_rect(renderer, &rect)
	}

	prod_fx_render(renderer)
	sdl.render_present(renderer)
}

fn (mut app App) update(dt f64) {
	// Update particles
	for i := app.particles.len - 1; i >= 0; i-- {
		mut part := unsafe { &app.particles[i] }
		part.x += part.vx * dt
		part.y += part.vy * dt
		part.life -= dt * 1.2
		if part.life <= 0 {
			app.particles.delete(i)
		}
	}
}

fn main() {
	if sdl.init(sdl.init_video | sdl.init_audio) != 0 {
		println('Failed to init SDL')
		return
	}
	defer {
		sdl.quit()
	}

	mut app := new_app()

	if os.args.contains('--snap') || os.args.contains('--snapshot') || os.getenv('SNAPSHOT') == '1' {
		surface := sdl.create_rgb_surface(0, win_width, win_height, 32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000)
		s_renderer := sdl.create_software_renderer(surface)
		app.renderer = s_renderer
		mut p := unsafe { &app.puzzles[app.current_idx] }
		p.grid[0][1] = .filled
		p.grid[0][2] = .filled
		p.grid[1][0] = .filled
		p.grid[1][1] = .filled
		p.grid[3][0] = .crossed
		p.update_status()
		app.render()
		sdl.save_bmp(surface, 'screenshots/picross.bmp'.str)
		sdl.destroy_renderer(s_renderer)
		sdl.free_surface(surface)
		return
	}

	window := sdl.create_window(
		'Picross Pro // Nonogram Logic Grid'.str,
		sdl.windowpos_centered,
		sdl.windowpos_centered,
		win_width,
		win_height,
		u32(sdl.WindowFlags.shown) | u32(sdl.WindowFlags.fullscreen_desktop) | u32(sdl.WindowFlags.resizable)
	)
	if window == unsafe { nil } {
		return
	}
	defer {
		sdl.destroy_window(window)
	}

	renderer := sdl.create_renderer(window, -1, u32(u32(sdl.RendererFlags.accelerated) | u32(sdl.RendererFlags.presentvsync)))
	if renderer == unsafe { nil } {
		return
	}
	defer {
		sdl.destroy_renderer(renderer)
	}
	sdl.render_set_logical_size(renderer, win_width, win_height)

	app.window = window
	app.renderer = renderer

	mut last_ticks := sdl.get_ticks()

	for {
		ticks := sdl.get_ticks()
		dt := f64(ticks - last_ticks) / 1000.0
		last_ticks = ticks

		mut event := sdl.Event{}
		for sdl.poll_event(&event) != 0 {
			match event.@type {
				.quit {
					return
				}
				.mousemotion {
					app.hover_r, app.hover_c = app.get_cell_under_mouse(event.motion.x, event.motion.y)
					if app.mouse_down && app.hover_r >= 0 && app.hover_c >= 0 {
						app.apply_cell_action(app.hover_r, app.hover_c, app.drag_fill_mode)
					}
				}
				.mousebuttondown {
					mx := event.button.x
					my := event.button.y
					if app.btn_prev.is_hovered(mx, my) {
						app.change_puzzle(-1)
					} else if app.btn_next.is_hovered(mx, my) {
						app.change_puzzle(1)
					} else if app.btn_reset.is_hovered(mx, my) {
						mut p := unsafe { &app.puzzles[app.current_idx] }
						p.reset()
						app.strikes_count = 0
						app.game_over = false
						app.start_time = time.now()
						app.sound_mgr.play_erase_sound()
					} else if app.btn_hint.is_hovered(mx, my) {
						mut p := unsafe { &app.puzzles[app.current_idx] }
						_, _, ok := p.use_hint()
						if ok {
							app.sound_mgr.play_fill_sound()
						}
					} else if app.btn_mode.is_hovered(mx, my) {
						app.mode = if app.mode == .zen { .strikes } else { .zen }
						app.strikes_count = 0
						app.game_over = false
						app.sound_mgr.play_fill_sound()
					} else if app.btn_sound.is_hovered(mx, my) {
						app.sound_mgr.toggle_sound()
					} else {
						r, c := app.get_cell_under_mouse(mx, my)
						if r >= 0 && c >= 0 {
							app.mouse_down = true
							app.mouse_button = event.button.button
							app.drag_fill_mode = if event.button.button == 1 { .filled } else { .crossed }
							app.apply_cell_action(r, c, app.drag_fill_mode)
						}
					}
				}
				.mousebuttonup {
					app.mouse_down = false
				}
				.keydown {
					sym := int(event.key.keysym.sym)
					if sym == int(sdl.KeyCode.f11) {
						toggle_fullscreen(window)
					} else if sym == int(sdl.KeyCode.escape) {
						return
					} else if sym == int(sdl.KeyCode.f5) {
						mut p := unsafe { &app.puzzles[app.current_idx] }
						p.save_state(app.current_idx)
					} else if sym == int(sdl.KeyCode.f9) {
						mut p := unsafe { &app.puzzles[app.current_idx] }
						p.load_state(app.current_idx)
					} else if sym == int(sdl.KeyCode.r) {
						mut p := unsafe { &app.puzzles[app.current_idx] }
						p.reset()
						app.strikes_count = 0
						app.game_over = false
						app.start_time = time.now()
						app.sound_mgr.play_erase_sound()
					} else if sym == int(sdl.KeyCode.h) {
						mut p := unsafe { &app.puzzles[app.current_idx] }
						_, _, ok := p.use_hint()
						if ok {
							app.sound_mgr.play_fill_sound()
						}
					} else if sym == int(sdl.KeyCode.m) {
						app.mode = if app.mode == .zen { .strikes } else { .zen }
						app.strikes_count = 0
						app.game_over = false
						app.sound_mgr.play_fill_sound()
					} else if sym == int(sdl.KeyCode.s) {
						app.sound_mgr.toggle_sound()
					} else if sym == int(sdl.KeyCode.p) || sym == int(sdl.KeyCode.leftbracket) {
						app.change_puzzle(-1)
					} else if sym == int(sdl.KeyCode.n) || sym == int(sdl.KeyCode.rightbracket) {
						app.change_puzzle(1)
					} else if sym == int(sdl.KeyCode.up) || sym == int(sdl.KeyCode.w) {
						p := app.puzzles[app.current_idx]
						if app.cursor_r > 0 { app.cursor_r-- } else { app.cursor_r = p.height - 1 }
					} else if sym == int(sdl.KeyCode.down) {
						p := app.puzzles[app.current_idx]
						if app.cursor_r < p.height - 1 { app.cursor_r++ } else { app.cursor_r = 0 }
					} else if sym == int(sdl.KeyCode.left) || sym == int(sdl.KeyCode.a) {
						p := app.puzzles[app.current_idx]
						if app.cursor_c > 0 { app.cursor_c-- } else { app.cursor_c = p.width - 1 }
					} else if sym == int(sdl.KeyCode.right) || sym == int(sdl.KeyCode.d) {
						p := app.puzzles[app.current_idx]
						if app.cursor_c < p.width - 1 { app.cursor_c++ } else { app.cursor_c = 0 }
					} else if sym == int(sdl.KeyCode.space) || sym == int(sdl.KeyCode.z) || sym == int(sdl.KeyCode.@return) {
						app.apply_cell_action(app.cursor_r, app.cursor_c, .filled)
					} else if sym == int(sdl.KeyCode.x) || sym == int(sdl.KeyCode.f) {
						app.apply_cell_action(app.cursor_r, app.cursor_c, .crossed)
					} else if sym == int(sdl.KeyCode.c) {
						app.apply_cell_action(app.cursor_r, app.cursor_c, .empty)
					}
				}
				else {}
			}
		}

		app.update(dt)
		app.render()
		sdl.delay(16)
	}
}

fn toggle_fullscreen(window &sdl.Window) {
	flags := sdl.get_window_flags(window)
	if (flags & u32(sdl.WindowFlags.fullscreen_desktop)) != 0 || (flags & u32(sdl.WindowFlags.fullscreen)) != 0 {
		sdl.set_window_fullscreen(window, 0)
	} else {
		sdl.set_window_fullscreen(window, u32(sdl.WindowFlags.fullscreen_desktop))
	}
}
