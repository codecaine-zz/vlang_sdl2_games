module main

import os
import sdl

const win_width = 860
const win_height = 680

struct Button {
	x            int
	y            int
	w            int
	h            int
	bg_color     Color
	hover_color  Color
	text_color   Color
	border_color Color
mut:
	text string
}

fn (b Button) contains(x int, y int) bool {
	return x >= b.x && x <= b.x + b.w && y >= b.y && y <= b.y + b.h
}

fn (b Button) render(renderer &sdl.Renderer, mouse_x int, mouse_y int) {
	is_hover := b.contains(mouse_x, mouse_y)
	color := if is_hover { b.hover_color } else { b.bg_color }

	rect := sdl.Rect{
		x: b.x
		y: b.y
		w: b.w
		h: b.h
	}
	sdl.set_render_draw_color(renderer, color.r, color.g, color.b, color.a)
	sdl.render_fill_rect(renderer, &rect)

	sdl.set_render_draw_color(renderer, b.border_color.r, b.border_color.g, b.border_color.b, b.border_color.a)
	sdl.render_draw_rect(renderer, &rect)

	scale := if b.text.len * 8 * 2 > b.w - 8 { 1 } else { 2 }
	text_x := b.x + (b.w - b.text.len * 8 * scale) / 2
	text_y := b.y + (b.h - 8 * scale) / 2
	draw_text(renderer, text_x, text_y, b.text, scale, b.text_color)
}

struct App {
mut:
	window       &sdl.Window   = unsafe { nil }
	renderer     &sdl.Renderer = unsafe { nil }
	game         Minesweeper
	sound_mgr    SoundManager
	tex_mgr      MinesweeperTextureManager
	particles    []Particle
	mouse_x      int
	mouse_y      int
	mouse_down   bool
	mouse_rdown  bool
	curs_r       int
	curs_c       int
	btn_beg      Button
	btn_int      Button
	btn_exp      Button
	btn_sound    Button
	btn_theme    Button
	btn_reset    Button
	face_rect    sdl.Rect
	cell_size    int = 28
	board_x      int
	board_y      int
}

fn new_app() App {
	mut app := App{
		game:      new_minesweeper(.beginner)
		sound_mgr: new_sound_manager()
		btn_beg:   Button{
			x:            20
			y:            620
			w:            125
			h:            38
			text:         '1: BEG'
			bg_color:     Color{r: 30, g: 40, b: 60}
			hover_color:  Color{r: 50, g: 70, b: 100}
			text_color:   Color{r: 255, g: 255, b: 255}
			border_color: Color{r: 80, g: 110, b: 160}
		}
		btn_int:   Button{
			x:            155
			y:            620
			w:            125
			h:            38
			text:         '2: INT'
			bg_color:     Color{r: 30, g: 40, b: 60}
			hover_color:  Color{r: 50, g: 70, b: 100}
			text_color:   Color{r: 255, g: 255, b: 255}
			border_color: Color{r: 80, g: 110, b: 160}
		}
		btn_exp:   Button{
			x:            290
			y:            620
			w:            125
			h:            38
			text:         '3: EXP'
			bg_color:     Color{r: 30, g: 40, b: 60}
			hover_color:  Color{r: 50, g: 70, b: 100}
			text_color:   Color{r: 255, g: 255, b: 255}
			border_color: Color{r: 80, g: 110, b: 160}
		}
		btn_theme: Button{
			x:            425
			y:            620
			w:            135
			h:            38
			text:         'THEME [T]'
			bg_color:     Color{r: 30, g: 40, b: 60}
			hover_color:  Color{r: 50, g: 70, b: 100}
			text_color:   Color{r: 255, g: 255, b: 255}
			border_color: Color{r: 80, g: 110, b: 160}
		}
		btn_sound: Button{
			x:            570
			y:            620
			w:            135
			h:            38
			text:         'SOUND [S]'
			bg_color:     Color{r: 30, g: 40, b: 60}
			hover_color:  Color{r: 50, g: 70, b: 100}
			text_color:   Color{r: 255, g: 255, b: 255}
			border_color: Color{r: 80, g: 110, b: 160}
		}
		btn_reset: Button{
			x:            715
			y:            620
			w:            125
			h:            38
			text:         'RESET [R]'
			bg_color:     Color{r: 80, g: 30, b: 40}
			hover_color:  Color{r: 120, g: 40, b: 50}
			text_color:   Color{r: 255, g: 255, b: 255}
			border_color: Color{r: 180, g: 60, b: 80}
		}
	}
	app.recalc_layout()
	return app
}

fn (mut app App) recalc_layout() {
	match app.game.difficulty {
		.beginner {
			app.cell_size = 40
		}
		.intermediate {
			app.cell_size = 28
		}
		.expert {
			app.cell_size = 24
		}
		.custom {
			app.cell_size = 24
		}
	}

	board_w := app.game.cols * app.cell_size
	app.board_x = (win_width - board_w) / 2
	app.board_y = 138

	app.face_rect = sdl.Rect{
		x: win_width / 2 - 20
		y: 85
		w: 40
		h: 40
	}
}

fn (mut app App) handle_cell_click(r int, c int, is_right bool) {
	if !app.game.is_valid(r, c) {
		return
	}

	if is_right {
		old_state := app.game.cells[r][c].state
		new_state := app.game.toggle_flag(r, c)
		if new_state == .flagged {
			app.sound_mgr.play_flag_sound()
		} else if old_state == .flagged {
			app.sound_mgr.play_unflag_sound()
		}
		if app.game.state == .won {
			app.sound_mgr.play_win_sound()
			app.particles << create_confetti_particles(win_width, win_height)
		}
		return
	}

	// Left click
	cell := app.game.cells[r][c]
	if cell.state == .revealed {
		// Attempt chord
		hit_mine, opened := app.game.chord_cell(r, c)
		if hit_mine {
			app.sound_mgr.play_explode_sound()
			cx := f64(app.board_x + c * app.cell_size + app.cell_size / 2)
			cy := f64(app.board_y + r * app.cell_size + app.cell_size / 2)
			app.particles << create_explosion_particles(cx, cy)
		} else if opened > 0 {
			if opened > 2 {
				app.sound_mgr.play_cascade_sound()
			} else {
				app.sound_mgr.play_click_sound()
			}
			if app.game.state == .won {
				app.sound_mgr.play_win_sound()
				app.particles << create_confetti_particles(win_width, win_height)
			}
		}
		return
	}

	hit_mine, opened := app.game.reveal_cell(r, c)
	if hit_mine {
		app.sound_mgr.play_explode_sound()
		cx := f64(app.board_x + c * app.cell_size + app.cell_size / 2)
		cy := f64(app.board_y + r * app.cell_size + app.cell_size / 2)
		app.particles << create_explosion_particles(cx, cy)
	} else if opened > 0 {
		if opened > 3 {
			app.sound_mgr.play_cascade_sound()
		} else {
			app.sound_mgr.play_click_sound()
		}
		if app.game.state == .won {
			app.sound_mgr.play_win_sound()
			app.particles << create_confetti_particles(win_width, win_height)
		}
	}
}

fn (mut app App) restart_game() {
	app.game.reset()
	app.particles.clear()
	app.recalc_layout()
}

fn (mut app App) change_diff(diff Difficulty) {
	app.game.set_difficulty(diff)
	app.restart_game()
}

fn (app &App) render() {
	r := app.renderer

	// Background Theme Colors
	is_neon := app.game.theme_neon
	bg_color := if is_neon { Color{r: 12, g: 15, b: 24} } else { Color{r: 192, g: 192, b: 192} }
	panel_bg := if is_neon { Color{r: 20, g: 26, b: 40} } else { Color{r: 192, g: 192, b: 192} }
	light_bev := if is_neon { Color{r: 60, g: 80, b: 130} } else { Color{r: 255, g: 255, b: 255} }
	dark_bev := if is_neon { Color{r: 10, g: 12, b: 20} } else { Color{r: 128, g: 128, b: 128} }
	title_col := if is_neon { Color{r: 80, g: 220, b: 255} } else { Color{r: 20, g: 30, b: 60} }

	sdl.set_render_draw_color(r, bg_color.r, bg_color.g, bg_color.b, 255)
	sdl.render_clear(r)

	// Title
	draw_text_centered(r, win_width / 2, 18, 'MINESWEEPER PRO', 3, title_col)
	draw_text_centered(r, win_width / 2, 48, 'RETRO ARCADE PUZZLE', 1, if is_neon { Color{r: 160, g: 180, b: 210} } else { Color{r: 80, g: 80, b: 90} })

	// Main Frame Inset / Bevel
	frame_w := app.game.cols * app.cell_size + 24
	frame_h := app.game.rows * app.cell_size + 80
	frame_x := (win_width - frame_w) / 2
	frame_y := 70

	draw_bevel_rect(r, frame_x, frame_y, frame_w, frame_h, true, panel_bg, light_bev, dark_bev, 4)

	// Top Status Bar (Mines Counter, Face, Timer)
	status_x := frame_x + 10
	status_y := frame_y + 10
	status_w := frame_w - 20
	status_h := 50
	draw_bevel_rect(r, status_x, status_y, status_w, status_h, false, panel_bg, light_bev, dark_bev, 3)

	led_on := Color{r: 255, g: 25, b: 25}
	led_off := Color{r: 45, g: 10, b: 10}
	led_box_w := 74
	led_box_h := 40
	led_y := status_y + 5

	// Left LED Counter: Remaining Mines
	led_left_x := status_x + 8
	draw_bevel_rect(r, led_left_x, led_y, led_box_w, led_box_h, false, Color{r: 0, g: 0, b: 0}, dark_bev, light_bev, 2)
	draw_number_7seg(r, led_left_x + 6, led_y + 4, app.game.get_remaining_mines(), 3, 18, 32, 4, led_on, led_off)

	// Right LED Counter: Timer
	led_right_x := status_x + status_w - led_box_w - 8
	draw_bevel_rect(r, led_right_x, led_y, led_box_w, led_box_h, false, Color{r: 0, g: 0, b: 0}, dark_bev, light_bev, 2)
	draw_number_7seg(r, led_right_x + 6, led_y + 4, app.game.timer_ticks, 3, 18, 32, 4, led_on, led_off)

	// Middle Smiley Face Button
	face_pressed := app.face_rect.x <= app.mouse_x && app.mouse_x <= app.face_rect.x + app.face_rect.w &&
		app.face_rect.y <= app.mouse_y && app.mouse_y <= app.face_rect.y + app.face_rect.h && app.mouse_down
	draw_bevel_rect(r, app.face_rect.x, app.face_rect.y, app.face_rect.w, app.face_rect.h, !face_pressed, panel_bg, light_bev, dark_bev, 3)

	mut face_state := app.game.face_state
	if app.mouse_down && app.game.state == .playing {
		face_state = .shock
	}
	draw_smiley_face(r, app.face_rect.x + 20, app.face_rect.y + 20, 14, face_state, face_pressed, app.tex_mgr.sprite_texture)

	// Board Grid Inset
	grid_x := frame_x + 10
	grid_y := frame_y + 66
	grid_w := app.game.cols * app.cell_size + 4
	grid_h := app.game.rows * app.cell_size + 4
	draw_bevel_rect(r, grid_x, grid_y, grid_w, grid_h, false, panel_bg, light_bev, dark_bev, 3)

	// Render Cells
	number_colors := [
		Color{r: 0, g: 0, b: 0},       // 0 (unused)
		Color{r: 25, g: 50, b: 230},   // 1: Blue
		Color{r: 20, g: 140, b: 30},   // 2: Green
		Color{r: 220, g: 30, b: 30},   // 3: Red
		Color{r: 10, g: 20, b: 130},   // 4: Dark Blue
		Color{r: 130, g: 15, b: 15},   // 5: Dark Red
		Color{r: 15, g: 150, b: 150},  // 6: Teal
		Color{r: 20, g: 20, b: 20},    // 7: Black
		Color{r: 120, g: 120, b: 120}, // 8: Gray
	]

	cell_bg_hidden := if is_neon { Color{r: 28, g: 36, b: 56} } else { Color{r: 192, g: 192, b: 192} }
	cell_bg_revealed := if is_neon { Color{r: 18, g: 22, b: 34} } else { Color{r: 192, g: 192, b: 192} }

	for row in 0 .. app.game.rows {
		for col in 0 .. app.game.cols {
			cx := app.board_x + col * app.cell_size
			cy := app.board_y + row * app.cell_size
			cell := app.game.cells[row][col]

			if cell.state == .revealed {
				// Revealed sunken cell
				draw_bevel_rect(r, cx, cy, app.cell_size, app.cell_size, false, cell_bg_revealed, light_bev, dark_bev, 1)

				if cell.is_mine {
					draw_mine_icon(r, cx + app.cell_size / 2, cy + app.cell_size / 2, app.cell_size - 4, cell.exploded, app.tex_mgr.sprite_texture)
				} else if cell.neighbor_mines > 0 {
					num_str := '${cell.neighbor_mines}'
					scale := if app.cell_size >= 32 { 2 } else { 1 }
					num_col := number_colors[cell.neighbor_mines]
					tx := cx + (app.cell_size - 8 * scale) / 2
					ty := cy + (app.cell_size - 8 * scale) / 2
					draw_text(r, tx, ty, num_str, scale, num_col)
				}
			} else {
				// Hidden raised tile
				draw_bevel_rect(r, cx, cy, app.cell_size, app.cell_size, true, cell_bg_hidden, light_bev, dark_bev, 2)

				if cell.state == .flagged {
					if cell.wrong_flag {
						draw_wrong_flag_icon(r, cx + app.cell_size / 2, cy + app.cell_size / 2, app.cell_size - 6, app.tex_mgr.sprite_texture)
					} else {
						draw_flag_icon(r, cx + app.cell_size / 2, cy + app.cell_size / 2, app.cell_size - 6, app.tex_mgr.sprite_texture)
					}
				} else if cell.state == .question {
					scale := if app.cell_size >= 32 { 2 } else { 1 }
					tx := cx + (app.cell_size - 8 * scale) / 2
					ty := cy + (app.cell_size - 8 * scale) / 2
					draw_text(r, tx, ty, '?', scale, Color{r: 20, g: 20, b: 30})
				}
			}

			// Highlight keyboard cursor if hovering
			if row == app.curs_r && col == app.curs_c {
				sdl.set_render_draw_color(r, 255, 220, 50, 200)
				curs_box := sdl.Rect{x: cx + 1, y: cy + 1, w: app.cell_size - 2, h: app.cell_size - 2}
				sdl.render_draw_rect(r, &curs_box)
			}
		}
	}

	// Render Particles
	render_particles(r, app.particles)

	// Render Bottom Buttons
	app.btn_beg.render(r, app.mouse_x, app.mouse_y)
	app.btn_int.render(r, app.mouse_x, app.mouse_y)
	app.btn_exp.render(r, app.mouse_x, app.mouse_y)
	app.btn_theme.render(r, app.mouse_x, app.mouse_y)
	app.btn_sound.render(r, app.mouse_x, app.mouse_y)
	app.btn_reset.render(r, app.mouse_x, app.mouse_y)

	// Game Over / Win Banner Overlay
	if app.game.state == .won {
		draw_text_centered(r, win_width / 2, frame_y + frame_h + 8, 'VICTORY! ALL MINES CLEARED!', 2, Color{r: 40, g: 220, b: 80})
	} else if app.game.state == .lost {
		draw_text_centered(r, win_width / 2, frame_y + frame_h + 8, 'GAME OVER - MINE DETONATED', 2, Color{r: 240, g: 50, b: 50})
	}

	prod_fx_render(r)
	sdl.render_present(r)
}

fn main() {
	if sdl.init(sdl.init_video | sdl.init_audio | sdl.init_events | sdl.init_timer) < 0 {
		eprintln('Failed to initialize SDL2')
		return
	}
	defer { sdl.quit() }

	if os.args.contains('--snap') {
		surface := sdl.create_rgb_surface(0, win_width, win_height, 32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000)
		if unsafe { surface == nil } { return }
		defer { sdl.free_surface(surface) }

		renderer := sdl.create_software_renderer(surface)
		if unsafe { renderer == nil } { return }
		defer { sdl.destroy_renderer(renderer) }
	sdl.render_set_logical_size(renderer, win_width, win_height)

		mut snap_app := new_app()
		snap_app.renderer = renderer
		snap_app.game.set_difficulty(.intermediate)
		snap_app.recalc_layout()

		// Playful partially revealed board state
		snap_app.game.reveal_cell(7, 7)
		snap_app.game.reveal_cell(2, 2)
		snap_app.game.toggle_flag(3, 4)
		snap_app.game.toggle_flag(5, 11)
		snap_app.game.timer_ticks = 28
		snap_app.game.state = .playing
		snap_app.game.face_state = .normal

		snap_app.render()
		bmp_path := 'screenshots/minesweeper.bmp'
		sdl.save_bmp(surface, bmp_path.str)
		return
	}

	mut app := new_app()

	window := sdl.create_window(
		'Minesweeper Pro - Classic & Modern Arcade Puzzle'.str,
		sdl.windowpos_centered,
		sdl.windowpos_centered,
		win_width,
		win_height,
		u32(sdl.WindowFlags.shown) | u32(sdl.WindowFlags.fullscreen_desktop) | u32(sdl.WindowFlags.resizable)
	)
	if unsafe { window == nil } {
		eprintln('Failed to create SDL window')
		return
	}
	defer { sdl.destroy_window(window) }

	renderer := sdl.create_renderer(window, -1, u32(sdl.RendererFlags.accelerated) | u32(sdl.RendererFlags.presentvsync))
	if unsafe { renderer == nil } {
		eprintln('Failed to create SDL renderer')
		return
	}
	defer { sdl.destroy_renderer(renderer) }
	sdl.render_set_logical_size(renderer, win_width, win_height)

	app.window = window
	app.renderer = renderer
	app.tex_mgr.init(renderer)

	mut event := sdl.Event{}
	mut running := true
	mut last_ticks := sdl.get_ticks()

	for running {
		now := sdl.get_ticks()
		dt := f64(now - last_ticks) / 1000.0
		last_ticks = now

		app.game.update_timer(now)
		update_particles(mut app.particles, dt)

		for sdl.poll_event(&event) != 0 {
			match event.@type {
				.quit {
					running = false
				}
				.mousemotion {
					app.mouse_x = event.motion.x
					app.mouse_y = event.motion.y
				}
				.mousebuttondown {
					mx := event.button.x
					my := event.button.y
					if event.button.button == sdl.button_left {
						app.mouse_down = true

						// Smiley face check
						if app.face_rect.x <= mx && mx <= app.face_rect.x + app.face_rect.w &&
							app.face_rect.y <= my && my <= app.face_rect.y + app.face_rect.h {
							app.restart_game()
						}

						// Bottom buttons check
						if app.btn_beg.contains(mx, my) {
							app.change_diff(.beginner)
						} else if app.btn_int.contains(mx, my) {
							app.change_diff(.intermediate)
						} else if app.btn_exp.contains(mx, my) {
							app.change_diff(.expert)
						} else if app.btn_theme.contains(mx, my) {
							app.game.theme_neon = !app.game.theme_neon
						} else if app.btn_sound.contains(mx, my) {
							enabled := app.sound_mgr.toggle_sound()
							app.btn_sound.text = if enabled { 'SOUND: ON' } else { 'SOUND: OFF' }
						} else if app.btn_reset.contains(mx, my) {
							app.restart_game()
						}

						// Board cell click
						if mx >= app.board_x && mx < app.board_x + app.game.cols * app.cell_size &&
							my >= app.board_y && my < app.board_y + app.game.rows * app.cell_size {
							c := (mx - app.board_x) / app.cell_size
							r_idx := (my - app.board_y) / app.cell_size
							app.curs_r = r_idx
							app.curs_c = c
							app.handle_cell_click(r_idx, c, false)
						}
					} else if event.button.button == sdl.button_right {
						app.mouse_rdown = true
						if mx >= app.board_x && mx < app.board_x + app.game.cols * app.cell_size &&
							my >= app.board_y && my < app.board_y + app.game.rows * app.cell_size {
							c := (mx - app.board_x) / app.cell_size
							r_idx := (my - app.board_y) / app.cell_size
							app.curs_r = r_idx
							app.curs_c = c
							app.handle_cell_click(r_idx, c, true)
						}
					} else if event.button.button == sdl.button_middle {
						if mx >= app.board_x && mx < app.board_x + app.game.cols * app.cell_size &&
							my >= app.board_y && my < app.board_y + app.game.rows * app.cell_size {
							c := (mx - app.board_x) / app.cell_size
							r_idx := (my - app.board_y) / app.cell_size
							app.handle_cell_click(r_idx, c, false)
						}
					}
				}
				.mousebuttonup {
					if event.button.button == sdl.button_left {
						app.mouse_down = false
					} else if event.button.button == sdl.button_right {
						app.mouse_rdown = false
					}
				}
				.keydown {
					sym := int(event.key.keysym.sym)
					if sym == int(sdl.KeyCode.f11) {
						toggle_fullscreen(window)
					} else if sym == int(sdl.KeyCode.escape) {
						running = false
					} else if sym == int(sdl.KeyCode.r) {
						app.restart_game()
					} else if sym == int(sdl.KeyCode._1) {
						app.change_diff(.beginner)
					} else if sym == int(sdl.KeyCode._2) {
						app.change_diff(.intermediate)
					} else if sym == int(sdl.KeyCode._3) {
						app.change_diff(.expert)
					} else if sym == int(sdl.KeyCode.s) {
						enabled := app.sound_mgr.toggle_sound()
						app.btn_sound.text = if enabled { 'SOUND: ON' } else { 'SOUND: OFF' }
					} else if sym == int(sdl.KeyCode.t) {
						app.game.theme_neon = !app.game.theme_neon
					} else if sym == int(sdl.KeyCode.up) || sym == int(sdl.KeyCode.w) {
						if app.curs_r > 0 { app.curs_r-- }
					} else if sym == int(sdl.KeyCode.down) {
						if app.curs_r < app.game.rows - 1 { app.curs_r++ }
					} else if sym == int(sdl.KeyCode.left) || sym == int(sdl.KeyCode.a) {
						if app.curs_c > 0 { app.curs_c-- }
					} else if sym == int(sdl.KeyCode.right) || sym == int(sdl.KeyCode.d) {
						if app.curs_c < app.game.cols - 1 { app.curs_c++ }
					} else if sym == int(sdl.KeyCode.space) || sym == int(sdl.KeyCode.@return) {
						app.handle_cell_click(app.curs_r, app.curs_c, false)
					} else if sym == int(sdl.KeyCode.f) {
						app.handle_cell_click(app.curs_r, app.curs_c, true)
					}
				}
				else {}
			}
		}

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
