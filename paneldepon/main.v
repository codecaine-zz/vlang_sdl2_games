import math
import os
import rand
import sdl
import sdl.image

pub struct PanelDePonTextureManager {
pub mut:
	sprite_texture &sdl.Texture = unsafe { nil }
}

pub fn (mut tm PanelDePonTextureManager) init(renderer &sdl.Renderer) {
	_ = image.init(int(image.InitFlags.png))
	candidates := [
		'assets/sprites/paneldepon.png',
		'./assets/sprites/paneldepon.png',
		'../assets/sprites/paneldepon.png',
		'paneldepon/assets/sprites/paneldepon.png',
	]
	for p in candidates {
		if os.exists(p) {
			surface := image.load(p.str)
			if surface != unsafe { nil } {
				tm.sprite_texture = sdl.create_texture_from_surface(renderer, surface)
				sdl.free_surface(surface)
				if tm.sprite_texture != unsafe { nil } {
					println('Panel de Pon Texture Loaded Successfully: ' + p)
					return
				}
			}
		}
	}
}

const win_width = 860
const win_height = 840

const cell_size = 46
const grid_w = pdp_cols * cell_size
const grid_h = pdp_rows * cell_size

const board_x = 240
const board_y = 110

struct PdpParticle {
mut:
	x     f64
	y     f64
	vx    f64
	vy    f64
	life  f64
	max_l f64
	color Color
	size  int
}

struct FloatText {
mut:
	x     f64
	y     f64
	text  string
	life  f64
	max_l f64
	scale int
	color Color
}

struct App {
mut:
	window      &sdl.Window   = unsafe { nil }
	renderer    &sdl.Renderer = unsafe { nil }
	sound_mgr   SoundManager
	tex_mgr     PanelDePonTextureManager
	game        PanelGame
	particles   []PdpParticle
	float_texts []FloatText
	shake_timer f64
	paused      bool
	btn_reset   Button
	btn_sound   Button
	btn_pause   Button
}

fn new_app() App {
	btn_y := 770
	return App{
		sound_mgr: new_sound_manager()
		game:      new_panel_game()
		btn_reset: Button{
			x: 40, y: btn_y, w: 160, h: 42, text: 'RESET [R]',
			bg_color: Color{r: 45, g: 30, b: 55},
			hover_color: Color{r: 75, g: 45, b: 90},
			text_color: Color{r: 255, g: 255, b: 255},
			border_color: Color{r: 160, g: 80, b: 180},
		}
		btn_sound: Button{
			x: 220, y: btn_y, w: 160, h: 42, text: 'SOUND [M]',
			bg_color: Color{r: 30, g: 45, b: 50},
			hover_color: Color{r: 50, g: 75, b: 85},
			text_color: Color{r: 255, g: 255, b: 255},
			border_color: Color{r: 80, g: 140, b: 160},
		}
		btn_pause: Button{
			x: 400, y: btn_y, w: 160, h: 42, text: 'PAUSE [P]',
			bg_color: Color{r: 45, g: 45, b: 30},
			hover_color: Color{r: 75, g: 75, b: 45},
			text_color: Color{r: 255, g: 255, b: 255},
			border_color: Color{r: 160, g: 160, b: 70},
		}
	}
}

fn get_panel_colors(panel_type int) (Color, Color, Color) {
	match panel_type {
		1 { // Red Heart
			return Color{r: 240, g: 40, b: 65}, Color{r: 255, g: 140, b: 160}, Color{r: 145, g: 15, b: 30}
		}
		2 { // Yellow Star
			return Color{r: 250, g: 215, b: 35}, Color{r: 255, g: 245, b: 145}, Color{r: 160, g: 135, b: 15}
		}
		3 { // Cyan Diamond
			return Color{r: 35, g: 195, b: 245}, Color{r: 130, g: 235, b: 255}, Color{r: 15, g: 110, b: 165}
		}
		4 { // Green Triangle
			return Color{r: 40, g: 215, b: 75}, Color{r: 140, g: 255, b: 160}, Color{r: 15, g: 130, b: 40}
		}
		5 { // Purple Moon
			return Color{r: 195, g: 45, b: 240}, Color{r: 235, g: 140, b: 255}, Color{r: 115, g: 20, b: 150}
		}
		else {
			return Color{r: 90, g: 90, b: 90}, Color{r: 140, g: 140, b: 140}, Color{r: 50, g: 50, b: 50}
		}
	}
}

// Draw a Panel with its unique embossed glyph (Heart, Star, Diamond, Triangle, Moon)
fn draw_panel(renderer &sdl.Renderer, cx int, cy int, size int, panel_type int, tex &sdl.Texture) {
	if panel_type == 0 {
		return
	}
	r := size / 2 - 2

	if tex != unsafe { nil } {
		col_x := (panel_type - 1) * 64
		src := sdl.Rect{x: col_x, y: 0, w: 64, h: 64}
		dst := sdl.Rect{x: cx - r + 1, y: cy - r + 1, w: (r - 1) * 2, h: (r - 1) * 2}
		sdl.render_copy(renderer, tex, &src, &dst)
		return
	}

	main_c, high_c, shadow_c := get_panel_colors(panel_type)

	rect := sdl.Rect{x: cx - r + 1, y: cy - r + 1, w: (r - 1) * 2, h: (r - 1) * 2}
	sdl.set_render_draw_color(renderer, main_c.r, main_c.g, main_c.b, 255)
	sdl.render_fill_rect(renderer, &rect)

	// Top & Left bevel
	sdl.set_render_draw_color(renderer, high_c.r, high_c.g, high_c.b, 255)
	for i in 0 .. 3 {
		sdl.render_draw_line(renderer, cx - r + 1 + i, cy - r + 1 + i, cx + r - 1 - i, cy - r + 1 + i)
		sdl.render_draw_line(renderer, cx - r + 1 + i, cy - r + 1 + i, cx - r + 1 + i, cy + r - 1 - i)
	}

	// Bottom & Right shadow
	sdl.set_render_draw_color(renderer, shadow_c.r, shadow_c.g, shadow_c.b, 255)
	for i in 0 .. 3 {
		sdl.render_draw_line(renderer, cx - r + 1 + i, cy + r - 1 - i, cx + r - 1 - i, cy + r - 1 - i)
		sdl.render_draw_line(renderer, cx + r - 1 - i, cy - r + 1 + i, cx + r - 1 - i, cy + r - 1 - i)
	}

	// Inner Symbol Glyph (Embossed White)
	sdl.set_render_draw_color(renderer, 255, 255, 255, 240)
	match panel_type {
		1 { // Heart
			sdl.render_draw_line(renderer, cx - 5, cy - 2, cx, cy - 7)
			sdl.render_draw_line(renderer, cx, cy - 7, cx + 5, cy - 2)
			sdl.render_draw_line(renderer, cx - 5, cy - 2, cx, cy + 6)
			sdl.render_draw_line(renderer, cx + 5, cy - 2, cx, cy + 6)
		}
		2 { // Star
			sdl.render_draw_line(renderer, cx - 6, cy, cx + 6, cy)
			sdl.render_draw_line(renderer, cx, cy - 6, cx, cy + 6)
			sdl.render_draw_line(renderer, cx - 4, cy - 4, cx + 4, cy + 4)
			sdl.render_draw_line(renderer, cx - 4, cy + 4, cx + 4, cy - 4)
		}
		3 { // Diamond
			sdl.render_draw_line(renderer, cx - 6, cy, cx, cy - 6)
			sdl.render_draw_line(renderer, cx, cy - 6, cx + 6, cy)
			sdl.render_draw_line(renderer, cx + 6, cy, cx, cy + 6)
			sdl.render_draw_line(renderer, cx, cy + 6, cx - 6, cy)
		}
		4 { // Triangle
			sdl.render_draw_line(renderer, cx, cy - 6, cx - 6, cy + 5)
			sdl.render_draw_line(renderer, cx, cy - 6, cx + 6, cy + 5)
			sdl.render_draw_line(renderer, cx - 6, cy + 5, cx + 6, cy + 5)
		}
		5 { // Moon
			sdl.render_draw_line(renderer, cx + 3, cy - 6, cx - 5, cy)
			sdl.render_draw_line(renderer, cx - 5, cy, cx + 3, cy + 6)
			sdl.render_draw_line(renderer, cx + 3, cy - 6, cx - 1, cy)
			sdl.render_draw_line(renderer, cx - 1, cy, cx + 3, cy + 6)
		}
		else {}
	}

	// Border
	sdl.set_render_draw_color(renderer, 20, 20, 30, 255)
	sdl.render_draw_rect(renderer, &rect)
}

fn (mut app App) spawn_burst(cx int, cy int, panel_type int) {
	main_c, _, _ := get_panel_colors(panel_type)
	for _ in 0 .. 16 {
		ang := rand.f64_in_range(0.0, 2.0 * math.pi) or { 0.0 }
		spd := rand.f64_in_range(90.0, 300.0) or { 160.0 }
		life := rand.f64_in_range(0.35, 0.7) or { 0.5 }
		app.particles << PdpParticle{
			x:     f64(cx)
			y:     f64(cy)
			vx:    math.cos(ang) * spd
			vy:    math.sin(ang) * spd
			life:  life
			max_l: life
			color: main_c
			size:  rand.int_in_range(3, 6) or { 4 }
		}
	}
}

fn (mut app App) update(dt f64) {
	if app.paused {
		return
	}

	if app.shake_timer > 0 {
		app.shake_timer -= dt
	}

	prev_clearing := app.game.clearing_cells.len
	app.game.update(dt)

	if prev_clearing == 0 && app.game.clearing_cells.len > 0 {
		app.sound_mgr.play_match_sound(app.game.chain_count)
		if app.game.chain_count > 1 {
			app.sound_mgr.play_freeze_sound()
			app.shake_timer = 0.2
			app.float_texts << FloatText{
				x:     f64(board_x + grid_w / 2)
				y:     f64(board_y + grid_h / 2 - 30)
				text:  'CHAIN x${app.game.chain_count}!'
				life:  1.1
				max_l: 1.1
				scale: 3
				color: Color{r: 255, g: 230, b: 80}
			}
		}

		for p in app.game.clearing_cells {
			cx := board_x + p.c * cell_size + cell_size / 2
			cy := board_y + p.r * cell_size + cell_size / 2
			val := app.game.grid[p.r][p.c]
			app.spawn_burst(cx, cy, val)
		}
	}

	// Update Particles
	mut active_particles := []PdpParticle{}
	for mut p in app.particles {
		p.x += p.vx * dt
		p.y += p.vy * dt
		p.vy += 380.0 * dt
		p.vx *= 0.985
		p.life -= dt
		if p.life > 0 {
			active_particles << p
		}
	}
	app.particles = active_particles

	// Update Floating Texts
	mut active_texts := []FloatText{}
	for mut ft in app.float_texts {
		ft.y -= 35.0 * dt
		ft.life -= dt
		if ft.life > 0 {
			active_texts << ft
		}
	}
	app.float_texts = active_texts
}

fn (mut app App) render() {
	renderer := app.renderer
	ticks := sdl.get_ticks()

	// Dreamy pastel arcade midnight purple background
	sdl.set_render_draw_color(renderer, 20, 14, 32, 255)
	sdl.render_clear(renderer)

	// Screen Shake Offset
	mut bx := board_x
	mut by := board_y
	if app.shake_timer > 0 {
		mag := app.shake_timer * 15.0
		bx += int((rand.f64() * 2.0 - 1.0) * mag)
		by += int((rand.f64() * 2.0 - 1.0) * mag)
	}

	// Header Banner
	draw_text_centered_fitted(renderer, win_width / 2, 20, 'PANEL DE PON // PUZZLE LEAGUE', 3, win_width - 60, Color{r: 255, g: 120, b: 180})
	draw_text_centered_fitted(renderer, win_width / 2, 55, 'SWAP HORIZONTAL PANELS & TRIGGER CASCADE COMBOS!', 2, win_width - 60, Color{r: 160, g: 210, b: 255})

	// Outer Board Frame
	frame := sdl.Rect{x: bx - 8, y: by - 8, w: grid_w + 16, h: grid_h + 16}
	sdl.set_render_draw_color(renderer, 45, 35, 65, 255)
	sdl.render_fill_rect(renderer, &frame)
	sdl.set_render_draw_color(renderer, 130, 90, 190, 255)
	sdl.render_draw_rect(renderer, &frame)

	// Inner Grid Area
	grid_bg := sdl.Rect{x: bx, y: by, w: grid_w, h: grid_h}
	sdl.set_render_draw_color(renderer, 12, 8, 22, 255)
	sdl.render_fill_rect(renderer, &grid_bg)

	// Vertical rise shift
	rise_px := int(app.game.rise_offset * f64(cell_size))

	// Render Panels
	for r in 0 .. pdp_rows {
		for c in 0 .. pdp_cols {
			p_val := app.game.grid[r][c]
			if p_val != 0 {
				cx := bx + c * cell_size + cell_size / 2
				cy := by + r * cell_size - rise_px + cell_size / 2
				if cy >= by {
					draw_panel(renderer, cx, cy, cell_size, p_val, app.tex_mgr.sprite_texture)
				}
			}
		}
	}

	// Bottom Rising Preview Row
	for c in 0 .. pdp_cols {
		cx := bx + c * cell_size + cell_size / 2
		cy := by + pdp_rows * cell_size - rise_px + cell_size / 2
		draw_panel(renderer, cx, cy, cell_size, app.game.next_row[c], app.tex_mgr.sprite_texture)
	}

	// Render Animated 2-Tile Cursor (Brackets)
	cur_px := bx + app.game.cur_c * cell_size
	cur_py := by + app.game.cur_r * cell_size - rise_px
	cur_w := cell_size * 2
	cur_h := cell_size

	t_cur := f64(ticks) * 0.008
	pulse := int(math.sin(t_cur * 4.0) * 2.0)

	if app.tex_mgr.sprite_texture != unsafe { nil } {
		l_src := sdl.Rect{x: 0, y: 64, w: 64, h: 64}
		l_dst := sdl.Rect{x: cur_px - 4 - pulse, y: cur_py - 4 - pulse, w: cell_size + 8 + pulse * 2, h: cell_size + 8 + pulse * 2}
		r_src := sdl.Rect{x: 64, y: 64, w: 64, h: 64}
		r_dst := sdl.Rect{x: cur_px + cell_size - 4 - pulse, y: cur_py - 4 - pulse, w: cell_size + 8 + pulse * 2, h: cell_size + 8 + pulse * 2}
		sdl.render_copy(renderer, app.tex_mgr.sprite_texture, &l_src, &l_dst)
		sdl.render_copy(renderer, app.tex_mgr.sprite_texture, &r_src, &r_dst)
	} else {
		c_rect := sdl.Rect{x: cur_px - 2 - pulse, y: cur_py - 2 - pulse, w: cur_w + 4 + pulse * 2, h: cur_h + 4 + pulse * 2}
		sdl.set_render_draw_color(renderer, 255, 255, 255, 255)
		sdl.render_draw_rect(renderer, &c_rect)

		// Inner Cursor Corners
		sdl.set_render_draw_color(renderer, 255, 220, 60, 255)
		corner_len := 10
		// Top-left
		sdl.render_draw_line(renderer, c_rect.x, c_rect.y, c_rect.x + corner_len, c_rect.y)
		sdl.render_draw_line(renderer, c_rect.x, c_rect.y, c_rect.x, c_rect.y + corner_len)
		// Top-right
		sdl.render_draw_line(renderer, c_rect.x + c_rect.w, c_rect.y, c_rect.x + c_rect.w - corner_len, c_rect.y)
		sdl.render_draw_line(renderer, c_rect.x + c_rect.w, c_rect.y, c_rect.x + c_rect.w, c_rect.y + corner_len)
		// Bottom-left
		sdl.render_draw_line(renderer, c_rect.x, c_rect.y + c_rect.h, c_rect.x + corner_len, c_rect.y + c_rect.h)
		sdl.render_draw_line(renderer, c_rect.x, c_rect.y + c_rect.h, c_rect.x, c_rect.y + c_rect.h - corner_len)
		// Bottom-right
		sdl.render_draw_line(renderer, c_rect.x + c_rect.w, c_rect.y + c_rect.h, c_rect.x + c_rect.w - corner_len, c_rect.y + c_rect.h)
		sdl.render_draw_line(renderer, c_rect.x + c_rect.w, c_rect.y + c_rect.h, c_rect.x + c_rect.w, c_rect.y + corner_len)
	}

	// Left HUD Card: Score, Level & Stop-Time Freeze Bar
	card_x := 32
	card_y := 120
	card_w := 180
	card_h := 340
	card_rect := sdl.Rect{x: card_x, y: card_y, w: card_w, h: card_h}
	sdl.set_render_draw_color(renderer, 24, 18, 38, 240)
	sdl.render_fill_rect(renderer, &card_rect)
	sdl.set_render_draw_color(renderer, 95, 75, 140, 255)
	sdl.render_draw_rect(renderer, &card_rect)

	info_x := card_x + 14
	draw_text(renderer, info_x, card_y + 16, 'SCORE', 2, Color{r: 180, g: 190, b: 230})
	draw_text(renderer, info_x, card_y + 38, '${app.game.score}', 3, Color{r: 255, g: 230, b: 70})

	draw_text(renderer, info_x, card_y + 88, 'HIGH SCORE', 2, Color{r: 180, g: 190, b: 230})
	draw_text(renderer, info_x, card_y + 110, '${app.game.high_score}', 3, Color{r: 255, g: 160, b: 60})

	draw_text(renderer, info_x, card_y + 160, 'LEVEL', 2, Color{r: 180, g: 190, b: 230})
	draw_text(renderer, info_x, card_y + 182, '${app.game.level}', 3, Color{r: 90, g: 230, b: 255})

	// Freeze Bar Gauge
	draw_text(renderer, info_x, card_y + 235, 'FREEZE GAUGE', 2, Color{r: 120, g: 240, b: 255})
	f_box := sdl.Rect{x: info_x, y: card_y + 260, w: 152, h: 22}
	sdl.set_render_draw_color(renderer, 30, 40, 60, 255)
	sdl.render_fill_rect(renderer, &f_box)
	if app.game.stop_timer > 0 {
		fill_w := int(math.min(1.0, app.game.stop_timer / 4.0) * 148.0)
		fill_rect := sdl.Rect{x: info_x + 2, y: card_y + 262, w: fill_w, h: 18}
		sdl.set_render_draw_color(renderer, 80, 220, 255, 255)
		sdl.render_fill_rect(renderer, &fill_rect)
	}
	sdl.set_render_draw_color(renderer, 80, 160, 220, 255)
	sdl.render_draw_rect(renderer, &f_box)

	// Right HUD Card: Controls
	rcard_x := 648
	rcard_y := 120
	rcard_w := 195
	rcard_h := 320
	rcard_rect := sdl.Rect{x: rcard_x, y: rcard_y, w: rcard_w, h: rcard_h}
	sdl.set_render_draw_color(renderer, 24, 18, 38, 240)
	sdl.render_fill_rect(renderer, &rcard_rect)
	sdl.set_render_draw_color(renderer, 95, 75, 140, 255)
	sdl.render_draw_rect(renderer, &rcard_rect)

	ctrl_x := rcard_x + 14
	draw_text(renderer, ctrl_x, rcard_y + 16, 'CONTROLS', 2, Color{r: 255, g: 255, b: 255})
	draw_text(renderer, ctrl_x, rcard_y + 44, 'WASD/ARROWS: MOVE', 1, Color{r: 190, g: 200, b: 230})
	draw_text(renderer, ctrl_x, rcard_y + 68, 'SPACE / J: SWAP', 1, Color{r: 190, g: 200, b: 230})
	draw_text(renderer, ctrl_x, rcard_y + 92, 'LSHIFT / K: RAISE', 1, Color{r: 190, g: 200, b: 230})

	// Render Particles
	for p in app.particles {
		prect := sdl.Rect{x: int(p.x), y: int(p.y), w: p.size, h: p.size}
		alpha := u8((p.life / p.max_l) * 255.0)
		sdl.set_render_draw_color(renderer, p.color.r, p.color.g, p.color.b, alpha)
		sdl.render_fill_rect(renderer, &prect)
	}

	// Render Floating Texts
	for ft in app.float_texts {
		draw_text_centered(renderer, int(ft.x), int(ft.y), ft.text, ft.scale, ft.color)
	}

	// Buttons
	mut mx := 0
	mut my := 0
	sdl.get_mouse_state(&mx, &my)
	app.btn_reset.render(renderer, mx, my)
	app.btn_sound.render(renderer, mx, my)
	app.btn_pause.render(renderer, mx, my)

	// Overlays
	if app.game.state == .game_over {
		box := sdl.Rect{x: bx + 10, y: by + grid_h / 2 - 60, w: grid_w - 20, h: 120}
		sdl.set_render_draw_color(renderer, 35, 15, 20, 245)
		sdl.render_fill_rect(renderer, &box)
		sdl.set_render_draw_color(renderer, 255, 60, 70, 255)
		sdl.render_draw_rect(renderer, &box)
		draw_text_centered(renderer, bx + grid_w / 2, by + grid_h / 2 - 35, 'GAME OVER', 3, Color{r: 255, g: 70, b: 90})
		draw_text_centered(renderer, bx + grid_w / 2, by + grid_h / 2 + 15, 'PRESS [R] TO RESTART  [F11] Fullscreen', 2, Color{r: 255, g: 255, b: 255})
	} else if app.paused {
		box := sdl.Rect{x: bx + 10, y: by + grid_h / 2 - 50, w: grid_w - 20, h: 100}
		sdl.set_render_draw_color(renderer, 20, 25, 40, 245)
		sdl.render_fill_rect(renderer, &box)
		draw_text_centered(renderer, bx + grid_w / 2, by + grid_h / 2 - 25, 'PAUSED', 3, Color{r: 255, g: 220, b: 80})
		draw_text_centered(renderer, bx + grid_w / 2, by + grid_h / 2 + 15, 'PRESS [P] TO RESUME', 2, Color{r: 200, g: 220, b: 255})
	}

	prod_fx_render(renderer)
	sdl.render_present(renderer)
}

fn main() {
	if sdl.init(sdl.init_video | sdl.init_audio) != 0 {
		eprintln('Failed to init SDL')
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
		app.game.score = 7200
		app.game.level = 2
		app.render()
		sdl.save_bmp(surface, 'screenshots/paneldepon.bmp'.str)
		sdl.destroy_renderer(s_renderer)
		sdl.free_surface(surface)
		return
	}

	window := sdl.create_window(
		'PANEL DE PON // Puzzle League Classic'.str,
		sdl.windowpos_centered,
		sdl.windowpos_centered,
		win_width,
		win_height,
		u32(sdl.WindowFlags.shown) | u32(sdl.WindowFlags.fullscreen_desktop) | u32(sdl.WindowFlags.resizable),
	)
	if window == unsafe { nil } {
		eprintln('Failed to create window')
		return
	}
	defer {
		sdl.destroy_window(window)
	}

	renderer := sdl.create_renderer(window, -1, u32(u32(sdl.RendererFlags.accelerated) | u32(sdl.RendererFlags.presentvsync)))
	if renderer == unsafe { nil } {
		eprintln('Failed to create renderer')
		return
	}
	defer {
		sdl.destroy_renderer(renderer)
	}
	sdl.render_set_logical_size(renderer, win_width, win_height)

	app.window = window
	app.renderer = renderer
	app.tex_mgr.init(renderer)

	mut last_ticks := sdl.get_ticks()

	for {
		current_ticks := sdl.get_ticks()
		dt := f64(current_ticks - last_ticks) / 1000.0
		last_ticks = current_ticks
		app.sound_mgr.update_bgm(app.game.state == .playing && !app.paused)

		mut event := sdl.Event{}
		for sdl.poll_event(&event) != 0 {
			match event.@type {
				.quit {
					return
				}
				.mousebuttondown {
					mx := event.button.x
					my := event.button.y
					if app.btn_reset.is_hovered(mx, my) {
						app.game = new_panel_game()
					} else if app.btn_sound.is_hovered(mx, my) {
						app.sound_mgr.toggle_sound()
					} else if app.btn_pause.is_hovered(mx, my) {
						app.paused = !app.paused
					}
				}
				.keydown {
					sym := int(event.key.keysym.sym)
					if sym == int(sdl.KeyCode.f11) {
						toggle_fullscreen(window)
					} else if sym == int(sdl.KeyCode.escape) {
						return
					} else if sym == int(sdl.KeyCode.r) {
						app.game = new_panel_game()
					} else if sym == int(sdl.KeyCode.p) {
						app.paused = !app.paused
					} else if sym == int(sdl.KeyCode.m) {
						app.sound_mgr.toggle_sound()
					} else if sym == int(sdl.KeyCode.left) || sym == int(sdl.KeyCode.a) {
						app.game.move_cursor(0, -1)
						app.sound_mgr.play_move_sound()
					} else if sym == int(sdl.KeyCode.right) || sym == int(sdl.KeyCode.d) {
						app.game.move_cursor(0, 1)
						app.sound_mgr.play_move_sound()
					} else if sym == int(sdl.KeyCode.up) || sym == int(sdl.KeyCode.w) {
						app.game.move_cursor(-1, 0)
						app.sound_mgr.play_move_sound()
					} else if sym == int(sdl.KeyCode.down) || sym == int(sdl.KeyCode.s) {
						app.game.move_cursor(1, 0)
						app.sound_mgr.play_move_sound()
					} else if sym == int(sdl.KeyCode.space) || sym == int(sdl.KeyCode.j) {
						if app.game.swap_panels() {
							app.sound_mgr.play_swap_sound()
						}
					} else if sym == int(sdl.KeyCode.lshift) || sym == int(sdl.KeyCode.k) {
						if app.game.push_stack_up() {
							app.sound_mgr.play_push_sound()
						}
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
