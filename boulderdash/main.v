import math
import os
import sdl
import sdl.image

const win_width = 1000
const win_height = 840

const cell_size = 38
const board_cols = 20
const board_rows = 15
const board_w = board_cols * cell_size
const board_h = board_rows * cell_size
const board_x = (win_width - board_w) / 2
const board_y = 140

pub struct BoulderDashTextureManager {
pub mut:
	sprite_texture &sdl.Texture = unsafe { nil }
}

pub fn (mut tm BoulderDashTextureManager) init(renderer &sdl.Renderer) {
	_ = image.init(int(image.InitFlags.png))
	candidates := [
		'assets/sprites/boulderdash.png',
		'./assets/sprites/boulderdash.png',
		'../assets/sprites/boulderdash.png',
		'boulderdash/assets/sprites/boulderdash.png',
	]
	for p in candidates {
		if os.exists(p) {
			surface := image.load(p.str)
			if surface != unsafe { nil } {
				tm.sprite_texture = sdl.create_texture_from_surface(renderer, surface)
				sdl.free_surface(surface)
				if tm.sprite_texture != unsafe { nil } {
					println('BoulderDash Texture Loaded Successfully: ' + p)
					return
				}
			}
		}
	}
}

struct App {
pub mut:
	window      &sdl.Window   = unsafe { nil }
	renderer    &sdl.Renderer = unsafe { nil }
	sound_mgr   SoundManager
	tex_mgr     BoulderDashTextureManager
	caves       []Cave
	current_idx int
	btn_prev    Button
	btn_next    Button
	btn_reset   Button
	btn_sound   Button
	anim_tick   f64
}

fn new_app() App {
	levels := get_cave_levels()
	btn_y := 765

	return App{
		sound_mgr:   new_sound_manager()
		caves:       levels
		current_idx: 0
		btn_prev:    Button{
			x: 100, y: btn_y, w: 180, h: 42, text: 'PREV CAVE [P]',
			bg_color: Color{r: 35, g: 45, b: 65},
			hover_color: Color{r: 55, g: 70, b: 100},
			text_color: Color{r: 255, g: 255, b: 255},
			border_color: Color{r: 80, g: 105, b: 145},
		}
		btn_next:    Button{
			x: 300, y: btn_y, w: 180, h: 42, text: 'NEXT CAVE [N]',
			bg_color: Color{r: 35, g: 45, b: 65},
			hover_color: Color{r: 55, g: 70, b: 100},
			text_color: Color{r: 255, g: 255, b: 255},
			border_color: Color{r: 80, g: 105, b: 145},
		}
		btn_reset:   Button{
			x: 500, y: btn_y, w: 180, h: 42, text: 'RESET [R]',
			bg_color: Color{r: 50, g: 40, b: 40},
			hover_color: Color{r: 80, g: 55, b: 55},
			text_color: Color{r: 255, g: 255, b: 255},
			border_color: Color{r: 130, g: 80, b: 80},
		}
		btn_sound:   Button{
			x: 700, y: btn_y, w: 180, h: 42, text: 'SOUND: ON [S]',
			bg_color: Color{r: 35, g: 50, b: 70},
			hover_color: Color{r: 55, g: 80, b: 110},
			text_color: Color{r: 255, g: 255, b: 255},
			border_color: Color{r: 80, g: 115, b: 160},
		}
	}
}

fn (mut app App) change_level(offset int) {
	new_idx := app.current_idx + offset
	if new_idx >= 0 && new_idx < app.caves.len {
		app.current_idx = new_idx
		app.sound_mgr.play_diamond_sound()
	}
}

fn (mut app App) reset_current_level() {
	fresh_levels := get_cave_levels()
	app.caves[app.current_idx] = fresh_levels[app.current_idx]
	app.sound_mgr.play_dig_sound()
}

fn draw_tile(renderer &sdl.Renderer, x int, y int, tile int, anim_tick f64, tex &sdl.Texture) {
	rect := sdl.Rect{x: x, y: y, w: cell_size, h: cell_size}

	if tex != unsafe { nil } {
		match tile {
			tile_wall {
				src := sdl.Rect{x: 0, y: 64, w: 64, h: 64}
				sdl.render_copy(renderer, tex, &src, &rect)
				return
			}
			tile_brick {
				src := sdl.Rect{x: 64, y: 64, w: 64, h: 64}
				sdl.render_copy(renderer, tex, &src, &rect)
				return
			}
			tile_dirt {
				src := sdl.Rect{x: 128, y: 64, w: 64, h: 64}
				sdl.render_copy(renderer, tex, &src, &rect)
				return
			}
			tile_boulder {
				src := sdl.Rect{x: 0, y: 128, w: 64, h: 64}
				sdl.render_copy(renderer, tex, &src, &rect)
				return
			}
			tile_diamond {
				sparkle := (int(anim_tick * 4.0) % 2 == 1)
				col_x := if sparkle { 128 } else { 64 }
				src := sdl.Rect{x: col_x, y: 128, w: 64, h: 64}
				sdl.render_copy(renderer, tex, &src, &rect)
				return
			}
			tile_exit_closed {
				src := sdl.Rect{x: 192, y: 128, w: 64, h: 64}
				sdl.render_copy(renderer, tex, &src, &rect)
				return
			}
			tile_exit_open {
				src := sdl.Rect{x: 256, y: 128, w: 64, h: 64}
				sdl.render_copy(renderer, tex, &src, &rect)
				return
			}
			tile_player {
				col_x := (int(anim_tick * 5.0) % 3) * 64
				src := sdl.Rect{x: col_x, y: 0, w: 64, h: 64}
				sdl.render_copy(renderer, tex, &src, &rect)
				return
			}
			tile_firefly {
				f := int(anim_tick * 8.0) % 2
				src := sdl.Rect{x: f * 64, y: 192, w: 64, h: 64}
				sdl.render_copy(renderer, tex, &src, &rect)
				return
			}
			tile_butterfly {
				f := int(anim_tick * 8.0) % 2
				src := sdl.Rect{x: (2 + f) * 64, y: 192, w: 64, h: 64}
				sdl.render_copy(renderer, tex, &src, &rect)
				return
			}
			tile_amoeba {
				src := sdl.Rect{x: 256, y: 192, w: 64, h: 64}
				sdl.render_copy(renderer, tex, &src, &rect)
				return
			}
			else {
				sdl.set_render_draw_color(renderer, 15, 18, 26, 255)
				sdl.render_fill_rect(renderer, &rect)
				return
			}
		}
	}

	match tile {
		tile_wall { // Steel Wall
			sdl.set_render_draw_color(renderer, 90, 95, 110, 255)
			sdl.render_fill_rect(renderer, &rect)
			sdl.set_render_draw_color(renderer, 140, 150, 175, 255)
			sdl.render_draw_rect(renderer, &rect)
			// Rivets
			sdl.set_render_draw_color(renderer, 200, 210, 230, 255)
			r1 := sdl.Rect{x: x + 4, y: y + 4, w: 3, h: 3}
			r2 := sdl.Rect{x: x + cell_size - 7, y: y + 4, w: 3, h: 3}
			r3 := sdl.Rect{x: x + 4, y: y + cell_size - 7, w: 3, h: 3}
			r4 := sdl.Rect{x: x + cell_size - 7, y: y + cell_size - 7, w: 3, h: 3}
			sdl.render_fill_rect(renderer, &r1)
			sdl.render_fill_rect(renderer, &r2)
			sdl.render_fill_rect(renderer, &r3)
			sdl.render_fill_rect(renderer, &r4)
		}
		tile_brick { // Rounded Brick Wall
			sdl.set_render_draw_color(renderer, 170, 65, 50, 255)
			sdl.render_fill_rect(renderer, &rect)
			sdl.set_render_draw_color(renderer, 220, 110, 90, 255)
			sdl.render_draw_line(renderer, x + 2, y + 2, x + cell_size - 3, y + 2)
			sdl.render_draw_line(renderer, x + 2, y + cell_size / 2, x + cell_size - 3, y + cell_size / 2)
			sdl.set_render_draw_color(renderer, 90, 30, 20, 255)
			sdl.render_draw_rect(renderer, &rect)
		}
		tile_dirt { // Organic speckled brown soil
			sdl.set_render_draw_color(renderer, 100, 65, 40, 255)
			sdl.render_fill_rect(renderer, &rect)
			sdl.set_render_draw_color(renderer, 140, 90, 55, 255)
			p1 := sdl.Rect{x: x + 6, y: y + 8, w: 4, h: 4}
			p2 := sdl.Rect{x: x + 22, y: y + 14, w: 4, h: 4}
			p3 := sdl.Rect{x: x + 12, y: y + 24, w: 4, h: 4}
			sdl.render_fill_rect(renderer, &p1)
			sdl.render_fill_rect(renderer, &p2)
			sdl.render_fill_rect(renderer, &p3)
		}
		tile_boulder { // Grey Stone Sphere
			cx := x + cell_size / 2
			cy := y + cell_size / 2
			r := cell_size / 2 - 2
			sdl.set_render_draw_color(renderer, 130, 135, 145, 255)
			for dy := -r; dy <= r; dy++ {
				w := int(f64(r) * math.sqrt(math.max(0.0, 1.0 - (f64(dy) / f64(r)) * (f64(dy) / f64(r)))))
				line := sdl.Rect{x: cx - w, y: cy + dy, w: w * 2, h: 1}
				sdl.render_fill_rect(renderer, &line)
			}
			// Highlight
			sdl.set_render_draw_color(renderer, 210, 215, 225, 255)
			hl := sdl.Rect{x: cx - r / 2, y: cy - r / 2, w: r / 2, h: r / 3}
			sdl.render_fill_rect(renderer, &hl)
		}
		tile_diamond { // Brilliant Cyan Diamond Crystal
			cx := x + cell_size / 2
			cy := y + cell_size / 2
			r := cell_size / 2 - 3
			sdl.set_render_draw_color(renderer, 60, 220, 255, 255)
			for dy := -r; dy <= r; dy++ {
				w := int(f64(r) * (1.0 - math.abs(f64(dy)) / f64(r)))
				line := sdl.Rect{x: cx - w, y: cy + dy, w: w * 2, h: 1}
				sdl.render_fill_rect(renderer, &line)
			}
			// Crystal Facet
			sdl.set_render_draw_color(renderer, 255, 255, 255, 255)
			facet := sdl.Rect{x: cx - 2, y: cy - r / 2, w: 4, h: 4}
			sdl.render_fill_rect(renderer, &facet)
		}
		tile_player { // Rockford Player
			cx := x + cell_size / 2
			cy := y + cell_size / 2
			// Body (Red)
			body := sdl.Rect{x: cx - 10, y: cy - 6, w: 20, h: 18}
			sdl.set_render_draw_color(renderer, 230, 40, 50, 255)
			sdl.render_fill_rect(renderer, &body)
			// Head / Helmet (Yellow/Orange)
			head := sdl.Rect{x: cx - 8, y: cy - 14, w: 16, h: 10}
			sdl.set_render_draw_color(renderer, 255, 210, 40, 255)
			sdl.render_fill_rect(renderer, &head)
			// Eyes
			sdl.set_render_draw_color(renderer, 20, 20, 30, 255)
			eye1 := sdl.Rect{x: cx - 5, y: cy - 10, w: 3, h: 3}
			eye2 := sdl.Rect{x: cx + 2, y: cy - 10, w: 3, h: 3}
			sdl.render_fill_rect(renderer, &eye1)
			sdl.render_fill_rect(renderer, &eye2)
		}
		tile_firefly { // Firefly Enemy (Orange/Red)
			cx := x + cell_size / 2
			cy := y + cell_size / 2
			sdl.set_render_draw_color(renderer, 255, 120, 20, 255)
			body := sdl.Rect{x: cx - 8, y: cy - 8, w: 16, h: 16}
			sdl.render_fill_rect(renderer, &body)
			// Wings
			wing_offset := int(math.sin(anim_tick * 15.0) * 4.0)
			sdl.set_render_draw_color(renderer, 255, 220, 100, 255)
			w1 := sdl.Rect{x: cx - 12, y: cy - 6 + wing_offset, w: 5, h: 8}
			w2 := sdl.Rect{x: cx + 7, y: cy - 6 - wing_offset, w: 5, h: 8}
			sdl.render_fill_rect(renderer, &w1)
			sdl.render_fill_rect(renderer, &w2)
		}
		tile_butterfly { // Butterfly Enemy (Magenta/Yellow)
			cx := x + cell_size / 2
			cy := y + cell_size / 2
			sdl.set_render_draw_color(renderer, 235, 50, 180, 255)
			body := sdl.Rect{x: cx - 6, y: cy - 8, w: 12, h: 16}
			sdl.render_fill_rect(renderer, &body)
			// Fluttering wings
			flutter := int(math.cos(anim_tick * 18.0) * 5.0)
			sdl.set_render_draw_color(renderer, 255, 240, 60, 255)
			w1 := sdl.Rect{x: cx - 13, y: cy - 8 + flutter, w: 7, h: 12}
			w2 := sdl.Rect{x: cx + 6, y: cy - 8 - flutter, w: 7, h: 12}
			sdl.render_fill_rect(renderer, &w1)
			sdl.render_fill_rect(renderer, &w2)
		}
		tile_amoeba { // Amoeba Slime
			pulse := u8((math.sin(anim_tick * 8.0) * 0.5 + 0.5) * 60.0 + 160.0)
			sdl.set_render_draw_color(renderer, 40, pulse, 70, 255)
			sdl.render_fill_rect(renderer, &rect)
			sdl.set_render_draw_color(renderer, 80, 255, 120, 255)
			b1 := sdl.Rect{x: x + 8, y: y + 8, w: 8, h: 8}
			b2 := sdl.Rect{x: x + 20, y: y + 18, w: 8, h: 8}
			sdl.render_fill_rect(renderer, &b1)
			sdl.render_fill_rect(renderer, &b2)
		}
		tile_exit_closed { // Closed Steel Door
			sdl.set_render_draw_color(renderer, 60, 65, 80, 255)
			sdl.render_fill_rect(renderer, &rect)
			sdl.set_render_draw_color(renderer, 200, 50, 50, 255) // Red Lock
			lock_rect := sdl.Rect{x: x + cell_size / 2 - 4, y: y + cell_size / 2 - 4, w: 8, h: 8}
			sdl.render_fill_rect(renderer, &lock_rect)
		}
		tile_exit_open { // Open Flashing Portal
			ticks := sdl.get_ticks()
			pr := u8((math.sin(f64(ticks) * 0.01) * 0.5 + 0.5) * 255.0)
			pg := u8((math.sin(f64(ticks) * 0.01 + 2.0) * 0.5 + 0.5) * 255.0)
			pb := u8((math.sin(f64(ticks) * 0.01 + 4.0) * 0.5 + 0.5) * 255.0)
			sdl.set_render_draw_color(renderer, pr, pg, pb, 255)
			sdl.render_fill_rect(renderer, &rect)
			sdl.set_render_draw_color(renderer, 255, 255, 255, 255)
			inner := sdl.Rect{x: x + 6, y: y + 6, w: cell_size - 12, h: cell_size - 12}
			sdl.render_draw_rect(renderer, &inner)
		}
		else { // Empty
			sdl.set_render_draw_color(renderer, 15, 18, 26, 255)
			sdl.render_fill_rect(renderer, &rect)
		}
	}
}

fn (mut app App) render() {
	renderer := app.renderer
	mut cave := unsafe { &app.caves[app.current_idx] }

	// Background Dark Slate
	sdl.set_render_draw_color(renderer, 12, 15, 24, 255)
	sdl.render_clear(renderer)

	// Top Title
	draw_text_centered(renderer, win_width / 2, 20, 'BOULDER DASH // RETRO CAVE DIGGER', 3, Color{r: 255, g: 190, b: 60})

	// Top HUD Stats Bar
	name_str := 'CAVE ${app.current_idx + 1}/${app.caves.len}: ${cave.name.to_upper()}'
	draw_text(renderer, board_x, 62, name_str, 2, Color{r: 255, g: 255, b: 255})

	score_str := 'SCORE: ${cave.score:05d}'
	draw_text_right(renderer, board_x + board_w, 62, score_str, 2, Color{r: 200, g: 220, b: 255})

	// Row 2: Diamond Quota, Time Left, Lives
	quota_color := if cave.diamonds_got >= cave.diamonds_needed { Color{r: 80, g: 255, b: 120} } else { Color{r: 90, g: 220, b: 255} }
	quota_str := 'DIAMONDS: ${cave.diamonds_got:02d} / ${cave.diamonds_needed:02d}'
	draw_text(renderer, board_x, 96, quota_str, 2, quota_color)

	time_color := if cave.time_left < 25.0 { Color{r: 255, g: 80, b: 80} } else { Color{r: 255, g: 220, b: 100} }
	time_str := 'TIME: ${int(cave.time_left):03d}s'
	draw_text(renderer, board_x + 320, 96, time_str, 2, time_color)

	mut lives_str := 'LIVES: '
	for i in 0 .. 3 {
		lives_str += if i < cave.lives { '<3 ' } else { '   ' }
	}
	draw_text(renderer, board_x + 550, 96, lives_str, 2, Color{r: 255, g: 100, b: 120})

	// Outer Playfield Border
	pad := 8
	field_rect := sdl.Rect{
		x: board_x - pad
		y: board_y - pad
		w: board_w + pad * 2
		h: board_h + pad * 2
	}
	sdl.set_render_draw_color(renderer, 40, 48, 70, 255)
	sdl.render_fill_rect(renderer, &field_rect)
	sdl.set_render_draw_color(renderer, 80, 95, 140, 255)
	sdl.render_draw_rect(renderer, &field_rect)

	// Render Grid Cells
	for r in 0 .. cave.height {
		for c in 0 .. cave.width {
			draw_tile(renderer, board_x + c * cell_size, board_y + r * cell_size, cave.grid[r][c], app.anim_tick, app.tex_mgr.sprite_texture)
		}
	}

	// Status Banners
	if cave.level_completed {
		banner := sdl.Rect{x: 0, y: 690, w: win_width, h: 55}
		sdl.set_render_draw_color(renderer, 20, 75, 45, 230)
		sdl.render_fill_rect(renderer, &banner)
		draw_text_centered(renderer, win_width / 2, 708, '*** CAVE COMPLETE! EXCELLENT DIGGING! PRESS [N] FOR NEXT CAVE ***', 2, Color{r: 120, g: 255, b: 160})
	} else if cave.game_over {
		banner := sdl.Rect{x: 0, y: 690, w: win_width, h: 55}
		sdl.set_render_draw_color(renderer, 75, 20, 25, 230)
		sdl.render_fill_rect(renderer, &banner)
		draw_text_centered(renderer, win_width / 2, 708, 'GAME OVER - OUT OF LIVES! PRESS [R] TO RESTART  [F11] Fullscreen', 2, Color{r: 255, g: 100, b: 100})
	} else if cave.player_dead {
		banner := sdl.Rect{x: 0, y: 690, w: win_width, h: 55}
		sdl.set_render_draw_color(renderer, 75, 50, 20, 230)
		sdl.render_fill_rect(renderer, &banner)
		draw_text_centered(renderer, win_width / 2, 708, 'CRUSHED! RESPAWNING...', 2, Color{r: 255, g: 200, b: 80})
	}

	// Render Buttons
	mut mx, mut my := 0, 0
	sdl.get_mouse_state(&mx, &my)

	app.btn_prev.render(renderer, mx, my)
	app.btn_next.render(renderer, mx, my)
	app.btn_reset.render(renderer, mx, my)

	app.btn_sound.text = if app.sound_mgr.sound_enabled { 'SOUND: ON' } else { 'SOUND: OFF' }
	app.btn_sound.render(renderer, mx, my)

	prod_fx_render(renderer)
	sdl.render_present(renderer)
}

fn (mut app App) update(dt f64) {
	app.anim_tick += dt
	mut cave := unsafe { &app.caves[app.current_idx] }
	if cave.toast_timer > 0 {
		cave.toast_timer -= dt
	}
	cave.update(dt, &app.sound_mgr)
	app.sound_mgr.update_bgm(!cave.game_over && !cave.level_completed)
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
		mut cave := unsafe { &app.caves[app.current_idx] }
		cave.move_player(0, 1, &app.sound_mgr)
		cave.move_player(0, 1, &app.sound_mgr)
		app.render()
		sdl.save_bmp(surface, 'screenshots/boulderdash.bmp'.str)
		sdl.destroy_renderer(s_renderer)
		sdl.free_surface(surface)
		return
	}

	window := sdl.create_window(
		'Boulder Dash // Retro Cave Digger'.str,
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
	app.tex_mgr.init(renderer)

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
				.mousebuttondown {
					mx := event.button.x
					my := event.button.y
					if app.btn_prev.is_hovered(mx, my) {
						app.change_level(-1)
					} else if app.btn_next.is_hovered(mx, my) {
						app.change_level(1)
					} else if app.btn_reset.is_hovered(mx, my) {
						app.reset_current_level()
					} else if app.btn_sound.is_hovered(mx, my) {
						app.sound_mgr.toggle_sound()
					}
				}
				.keydown {
					sym := int(event.key.keysym.sym)
					mut cave := unsafe { &app.caves[app.current_idx] }

					if sym == int(sdl.KeyCode.f11) {
						toggle_fullscreen(window)
					} else if sym == int(sdl.KeyCode.escape) {
						return
					} else if sym == int(sdl.KeyCode.f5) {
						cave.save_state()
					} else if sym == int(sdl.KeyCode.f9) {
						cave.load_state()
					} else if sym == int(sdl.KeyCode.r) {
						app.reset_current_level()
					} else if sym == int(sdl.KeyCode.p) || sym == int(sdl.KeyCode.leftbracket) {
						app.change_level(-1)
						cave.save_progress()
					} else if sym == int(sdl.KeyCode.n) || sym == int(sdl.KeyCode.rightbracket) {
						app.change_level(1)
						cave.save_progress()
					} else if sym == int(sdl.KeyCode.s) {
						app.sound_mgr.toggle_sound()
					} else if sym == int(sdl.KeyCode.up) || sym == int(sdl.KeyCode.w) {
						cave.move_player(-1, 0, &app.sound_mgr)
					} else if sym == int(sdl.KeyCode.down) {
						cave.move_player(1, 0, &app.sound_mgr)
					} else if sym == int(sdl.KeyCode.left) || sym == int(sdl.KeyCode.a) {
						cave.move_player(0, -1, &app.sound_mgr)
					} else if sym == int(sdl.KeyCode.right) || sym == int(sdl.KeyCode.d) {
						cave.move_player(0, 1, &app.sound_mgr)
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
