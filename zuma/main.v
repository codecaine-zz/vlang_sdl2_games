import math
import os
import rand
import sdl
import sdl.image

pub struct ZumaTextureManager {
pub mut:
	sprite_texture &sdl.Texture = unsafe { nil }
}

pub fn (mut tm ZumaTextureManager) init(renderer &sdl.Renderer) {
	_ = image.init(int(image.InitFlags.png))
	candidates := [
		'assets/sprites/zuma.png',
		'./assets/sprites/zuma.png',
		'../assets/sprites/zuma.png',
		'zuma/assets/sprites/zuma.png',
	]
	for p in candidates {
		if os.exists(p) {
			surface := image.load(p.str)
			if surface != unsafe { nil } {
				tm.sprite_texture = sdl.create_texture_from_surface(renderer, surface)
				sdl.free_surface(surface)
				if tm.sprite_texture != unsafe { nil } {
					println('Zuma Texture Loaded Successfully: ' + p)
					return
				}
			}
		}
	}
}

const win_width = 880
const win_height = 840

const render_ball_r = 16

struct ZumaParticle {
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
	tex_mgr     ZumaTextureManager
	game        ZumaGame
	particles   []ZumaParticle
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
		game:      new_zuma_game()
		btn_reset: Button{
			x: 40, y: btn_y, w: 160, h: 42, text: 'RESET [R]',
			bg_color: Color{r: 45, g: 30, b: 25},
			hover_color: Color{r: 80, g: 48, b: 38},
			text_color: Color{r: 255, g: 255, b: 255},
			border_color: Color{r: 180, g: 90, b: 60},
		}
		btn_sound: Button{
			x: 220, y: btn_y, w: 160, h: 42, text: 'SOUND [M]',
			bg_color: Color{r: 25, g: 42, b: 45},
			hover_color: Color{r: 45, g: 72, b: 78},
			text_color: Color{r: 255, g: 255, b: 255},
			border_color: Color{r: 75, g: 140, b: 155},
		}
		btn_pause: Button{
			x: 400, y: btn_y, w: 160, h: 42, text: 'PAUSE [P]',
			bg_color: Color{r: 45, g: 42, b: 25},
			hover_color: Color{r: 78, g: 72, b: 40},
			text_color: Color{r: 255, g: 255, b: 255},
			border_color: Color{r: 165, g: 155, b: 70},
		}
	}
}

fn get_ball_colors(color_id int) (Color, Color, Color, Color) {
	match color_id {
		1 { // Ruby Red
			return Color{r: 235, g: 35, b: 50}, Color{r: 255, g: 140, b: 155}, Color{r: 130, g: 10, b: 20}, Color{r: 255, g: 230, b: 240}
		}
		2 { // Sapphire Blue
			return Color{r: 30, g: 135, b: 245}, Color{r: 120, g: 200, b: 255}, Color{r: 15, g: 65, b: 160}, Color{r: 215, g: 240, b: 255}
		}
		3 { // Emerald Green
			return Color{r: 35, g: 215, b: 75}, Color{r: 130, g: 255, b: 155}, Color{r: 15, g: 120, b: 35}, Color{r: 220, g: 255, b: 230}
		}
		4 { // Topaz Yellow
			return Color{r: 250, g: 215, b: 30}, Color{r: 255, g: 245, b: 135}, Color{r: 155, g: 130, b: 15}, Color{r: 255, g: 255, b: 220}
		}
		5 { // Amethyst Purple
			return Color{r: 200, g: 45, b: 240}, Color{r: 240, g: 140, b: 255}, Color{r: 120, g: 20, b: 150}, Color{r: 250, g: 220, b: 255}
		}
		else {
			return Color{r: 110, g: 110, b: 120}, Color{r: 165, g: 165, b: 175}, Color{r: 60, g: 60, b: 70}, Color{r: 220, g: 220, b: 230}
		}
	}
}

// Draw a 3D Sphere with Specular Highlight and Power-Up Glyphs
fn draw_marble(renderer &sdl.Renderer, cx int, cy int, color_id int, power PowerupType, tex &sdl.Texture) {
	if color_id == 0 {
		return
	}
	r := render_ball_r

	if tex != unsafe { nil } {
		col_idx := match power {
			.bomb { 5 }
			.reverse { 6 }
			.slow { 7 }
			else { color_id - 1 }
		}
		src := sdl.Rect{x: col_idx * 64, y: 0, w: 64, h: 64}
		dst := sdl.Rect{x: cx - r, y: cy - r, w: r * 2, h: r * 2}
		sdl.render_copy(renderer, tex, &src, &dst)
		return
	}

	main_c, high_c, shadow_c, glint_c := get_ball_colors(color_id)

	// Outer Shadow Disc
	for dy := -r; dy <= r; dy++ {
		dx_max := int(math.sqrt(f64(r * r - dy * dy)))
		s_rect := sdl.Rect{x: cx - dx_max, y: cy + dy, w: dx_max * 2, h: 1}
		dist_norm := f64(dy + r) / f64(2 * r)
		red := u8(f64(shadow_c.r) * (1.0 - dist_norm) + f64(main_c.r) * dist_norm)
		green := u8(f64(shadow_c.g) * (1.0 - dist_norm) + f64(main_c.g) * dist_norm)
		blue := u8(f64(shadow_c.b) * (1.0 - dist_norm) + f64(main_c.b) * dist_norm)

		sdl.set_render_draw_color(renderer, red, green, blue, 255)
		sdl.render_fill_rect(renderer, &s_rect)
	}

	// Inner Top Highlight Glow
	hl_r := r / 2
	hl_cx := cx - r / 3
	hl_cy := cy - r / 3
	for dy := -hl_r; dy <= hl_r; dy++ {
		dx_max := int(math.sqrt(f64(hl_r * hl_r - dy * dy)))
		h_rect := sdl.Rect{x: hl_cx - dx_max, y: hl_cy + dy, w: dx_max * 2, h: 1}
		sdl.set_render_draw_color(renderer, high_c.r, high_c.g, high_c.b, 180)
		sdl.render_fill_rect(renderer, &h_rect)
	}

	// Specular Glint Point
	sdl.set_render_draw_color(renderer, glint_c.r, glint_c.g, glint_c.b, 255)
	sdl.render_draw_point(renderer, cx - r / 3, cy - r / 3)
	sdl.render_draw_point(renderer, cx - r / 3 + 1, cy - r / 3)
	sdl.render_draw_point(renderer, cx - r / 3, cy - r / 3 + 1)

	// Powerup Symbols
	match power {
		.slow {
			sdl.set_render_draw_color(renderer, 255, 255, 255, 240)
			sdl.render_draw_line(renderer, cx - 4, cy, cx + 4, cy)
			sdl.render_draw_line(renderer, cx, cy - 4, cx, cy + 4)
			sdl.render_draw_line(renderer, cx - 3, cy - 3, cx + 3, cy + 3)
			sdl.render_draw_line(renderer, cx - 3, cy + 3, cx + 3, cy - 3)
		}
		.reverse {
			sdl.set_render_draw_color(renderer, 255, 255, 255, 240)
			sdl.render_draw_line(renderer, cx + 2, cy - 3, cx - 2, cy)
			sdl.render_draw_line(renderer, cx - 2, cy, cx + 2, cy + 3)
			sdl.render_draw_line(renderer, cx + 5, cy - 3, cx + 1, cy)
			sdl.render_draw_line(renderer, cx + 1, cy, cx + 5, cy + 3)
		}
		.bomb {
			sdl.set_render_draw_color(renderer, 255, 255, 255, 255)
			sdl.render_draw_line(renderer, cx - 5, cy, cx + 5, cy)
			sdl.render_draw_line(renderer, cx, cy - 5, cx, cy + 5)
		}
		.none {}
	}
}

fn (mut app App) spawn_burst(cx int, cy int, color_id int) {
	main_c, _, _, _ := get_ball_colors(color_id)
	for _ in 0 .. 18 {
		ang := rand.f64_in_range(0.0, 2.0 * math.pi) or { 0.0 }
		spd := rand.f64_in_range(90.0, 310.0) or { 160.0 }
		life := rand.f64_in_range(0.35, 0.7) or { 0.5 }
		app.particles << ZumaParticle{
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

	prev_combo := app.game.combo_count
	app.game.update(dt)

	if app.game.combo_count > prev_combo && app.game.combo_count > 0 {
		app.sound_mgr.play_match_sound(app.game.combo_count)
		if app.game.combo_count > 1 {
			app.shake_timer = 0.2
			app.float_texts << FloatText{
				x:     f64(app.game.shooter_x)
				y:     f64(app.game.shooter_y - 45)
				text:  'COMBO x${app.game.combo_count}!'
				life:  1.1
				max_l: 1.1
				scale: 3
				color: Color{r: 255, g: 230, b: 60}
			}
		}
	}

	// Update Particles
	mut active_particles := []ZumaParticle{}
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

	// Ancient Aztec Jungle Midnight Background
	sdl.set_render_draw_color(renderer, 15, 20, 18, 255)
	sdl.render_clear(renderer)

	// Screen Shake Offset
	mut sx := 0
	mut sy := 0
	if app.shake_timer > 0 {
		mag := app.shake_timer * 16.0
		sx = int((rand.f64() * 2.0 - 1.0) * mag)
		sy = int((rand.f64() * 2.0 - 1.0) * mag)
	}

	// Header Banner
	draw_text_centered_fitted(renderer, win_width / 2 + sx, 20 + sy, 'ZUMA // TEMPLE OF THE STONE IDOL', 3, win_width - 60, Color{r: 255, g: 195, b: 50})
	draw_text_centered_fitted(renderer, win_width / 2 + sx, 56 + sy, 'AIM 360 STONE FROG & PREVENT SPHERES FROM REACHING THE SKULL!', 2, win_width - 60, Color{r: 170, g: 235, b: 215})

	// Render Carved Spiral Path Trench
	for i := 0; i < app.game.track.len - 1; i++ {
		p1 := app.game.track[i]
		p2 := app.game.track[i + 1]

		// Trench Shadow
		sdl.set_render_draw_color(renderer, 8, 12, 10, 255)
		for w := -render_ball_r - 4; w <= render_ball_r + 4; w++ {
			sdl.render_draw_line(renderer, int(p1.x) + w + sx, int(p1.y) + w + sy, int(p2.x) + w + sx, int(p2.y) + w + sy)
		}
		// Trench Inner Stone Bed
		sdl.set_render_draw_color(renderer, 32, 42, 38, 255)
		for w := -render_ball_r; w <= render_ball_r; w++ {
			sdl.render_draw_line(renderer, int(p1.x) + w + sx, int(p1.y) + sy, int(p2.x) + w + sx, int(p2.y) + sy)
		}
	}

	// Golden Skull Danger Pit (at end of track)
	if app.game.track.len > 0 {
		skull_pt := app.game.track[app.game.track.len - 1]
		sk_x := int(skull_pt.x) + sx
		sk_y := int(skull_pt.y) + sy

		// Golden Skull Frame
		sk_rect := sdl.Rect{x: sk_x - 30, y: sk_y - 30, w: 60, h: 60}
		if app.tex_mgr.sprite_texture != unsafe { nil } {
			sk_src := sdl.Rect{x: 0, y: 128, w: 64, h: 64}
			sdl.render_copy(renderer, app.tex_mgr.sprite_texture, &sk_src, &sk_rect)
		} else {
			sdl.set_render_draw_color(renderer, 45, 35, 15, 255)
			sdl.render_fill_rect(renderer, &sk_rect)
			sdl.set_render_draw_color(renderer, 240, 195, 50, 255)
			sdl.render_draw_rect(renderer, &sk_rect)

			// Glowing Red Eyes
			eye_pulse := u8((math.sin(f64(ticks) * 0.008) * 0.5 + 0.5) * 155.0 + 100.0)
			sdl.set_render_draw_color(renderer, eye_pulse, 20, 20, 255)
			eye1 := sdl.Rect{x: sk_x - 14, y: sk_y - 12, w: 8, h: 12}
			eye2 := sdl.Rect{x: sk_x + 6, y: sk_y - 12, w: 8, h: 12}
			sdl.render_fill_rect(renderer, &eye1)
			sdl.render_fill_rect(renderer, &eye2)
		}
	}

	// Render Rolling Balls Train
	for ball in app.game.balls {
		pos_x, pos_y := app.game.get_track_pos(ball.dist)
		draw_marble(renderer, int(pos_x) + sx, int(pos_y) + sy, ball.color, ball.powerup, app.tex_mgr.sprite_texture)
	}

	// Render Flying Projectile
	if app.game.projectile.active {
		draw_marble(renderer, int(app.game.projectile.x) + sx, int(app.game.projectile.y) + sy, app.game.projectile.color, .none, app.tex_mgr.sprite_texture)
	}

	// Stone Frog Turret in Center
	turret_cx := int(app.game.shooter_x) + sx
	turret_cy := int(app.game.shooter_y) + sy

	// Laser Aiming Guide Line
	mut mx := 0
	mut my := 0
	sdl.get_mouse_state(&mx, &my)
	aim_dx := f64(mx - turret_cx)
	aim_dy := f64(my - turret_cy)
	aim_len := math.sqrt(aim_dx * aim_dx + aim_dy * aim_dy)
	if aim_len > 0.1 {
		ux := aim_dx / aim_len
		uy := aim_dy / aim_len
		sdl.set_render_draw_color(renderer, 255, 255, 255, 120)
		for d := 45; d < 300; d += 15 {
			gx := turret_cx + int(ux * f64(d))
			gy := turret_cy + int(uy * f64(d))
			g_dot := sdl.Rect{x: gx - 1, y: gy - 1, w: 3, h: 3}
			sdl.render_fill_rect(renderer, &g_dot)
		}
	}

	// Stone Frog Base
	frog_r := 34
	f_rect := sdl.Rect{x: turret_cx - frog_r, y: turret_cy - frog_r, w: frog_r * 2, h: frog_r * 2}
	if app.tex_mgr.sprite_texture != unsafe { nil } {
		frog_src := sdl.Rect{x: 0, y: 64, w: 64, h: 64}
		frog_deg := app.game.turret_angle * 180.0 / math.pi + 90.0
		sdl.render_copy_ex(renderer, app.tex_mgr.sprite_texture, &frog_src, &f_rect, frog_deg, unsafe { nil }, sdl.RendererFlip.none)
	} else {
		sdl.set_render_draw_color(renderer, 42, 54, 48, 255)
		sdl.render_fill_rect(renderer, &f_rect)
		sdl.set_render_draw_color(renderer, 95, 135, 115, 255)
		sdl.render_draw_rect(renderer, &f_rect)
	}

	// Loaded Ball inside Frog Mouth
	draw_marble(renderer, turret_cx, turret_cy, app.game.current_ball, .none, app.tex_mgr.sprite_texture)

	// Next Ball on Frog's Back
	back_bx := turret_cx - int(math.cos(app.game.turret_angle) * 22.0)
	back_by := turret_cy - int(math.sin(app.game.turret_angle) * 22.0)
	draw_marble(renderer, back_bx, back_by, app.game.next_ball, .none, app.tex_mgr.sprite_texture)

	// Left HUD Card: Score & Level
	card_x := 32
	card_y := 120
	card_w := 180
	card_h := 320
	card_rect := sdl.Rect{x: card_x, y: card_y, w: card_w, h: card_h}
	sdl.set_render_draw_color(renderer, 22, 32, 28, 240)
	sdl.render_fill_rect(renderer, &card_rect)
	sdl.set_render_draw_color(renderer, 75, 115, 95, 255)
	sdl.render_draw_rect(renderer, &card_rect)

	info_x := card_x + 14
	draw_text(renderer, info_x, card_y + 16, 'SCORE', 2, Color{r: 180, g: 220, b: 200})
	draw_text(renderer, info_x, card_y + 40, '${app.game.score}', 3, Color{r: 255, g: 230, b: 70})

	draw_text(renderer, info_x, card_y + 90, 'HIGH SCORE', 2, Color{r: 180, g: 220, b: 200})
	draw_text(renderer, info_x, card_y + 114, '${app.game.high_score}', 3, Color{r: 255, g: 160, b: 60})

	draw_text(renderer, info_x, card_y + 165, 'LEVEL', 2, Color{r: 180, g: 220, b: 200})
	draw_text(renderer, info_x, card_y + 188, '${app.game.level}', 3, Color{r: 90, g: 240, b: 215})

	draw_text(renderer, info_x, card_y + 240, 'BALLS LEFT', 2, Color{r: 180, g: 220, b: 200})
	draw_text(renderer, info_x, card_y + 264, '${app.game.balls.len}', 3, Color{r: 255, g: 255, b: 255})

	// Right HUD Card: Controls & Powerups
	rcard_x := 668
	rcard_y := 120
	rcard_w := 180
	rcard_h := 320
	rcard_rect := sdl.Rect{x: rcard_x, y: rcard_y, w: rcard_w, h: rcard_h}
	sdl.set_render_draw_color(renderer, 22, 32, 28, 240)
	sdl.render_fill_rect(renderer, &rcard_rect)
	sdl.set_render_draw_color(renderer, 75, 115, 95, 255)
	sdl.render_draw_rect(renderer, &rcard_rect)

	rhud_x := rcard_x + 14
	draw_text(renderer, rhud_x, rcard_y + 16, 'CONTROLS', 2, Color{r: 255, g: 255, b: 255})
	draw_text(renderer, rhud_x, rcard_y + 42, 'MOUSE: AIM 360', 1, Color{r: 190, g: 225, b: 210})
	draw_text(renderer, rhud_x, rcard_y + 64, 'CLICK/SPACE: SHOOT', 1, Color{r: 190, g: 225, b: 210})
	draw_text(renderer, rhud_x, rcard_y + 86, 'RCLICK/TAB: SWAP', 1, Color{r: 190, g: 225, b: 210})

	draw_text(renderer, rhud_x, rcard_y + 130, 'POWERUPS', 2, Color{r: 255, g: 215, b: 90})
	draw_text(renderer, rhud_x, rcard_y + 154, '* SLOWDOWN', 1, Color{r: 120, g: 235, b: 255})
	draw_text(renderer, rhud_x, rcard_y + 174, '<< REVERSE ROLL', 1, Color{r: 255, g: 220, b: 80})
	draw_text(renderer, rhud_x, rcard_y + 194, '+ BOMB EXPLOSION', 1, Color{r: 255, g: 100, b: 110})

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
	app.btn_reset.render(renderer, mx, my)
	app.btn_sound.render(renderer, mx, my)
	app.btn_pause.render(renderer, mx, my)

	// Overlays
	if app.game.state == .level_won {
		box := sdl.Rect{x: win_width / 2 - 200, y: win_height / 2 - 60, w: 400, h: 120}
		sdl.set_render_draw_color(renderer, 20, 35, 25, 245)
		sdl.render_fill_rect(renderer, &box)
		sdl.set_render_draw_color(renderer, 60, 240, 100, 255)
		sdl.render_draw_rect(renderer, &box)
		draw_text_centered(renderer, win_width / 2, win_height / 2 - 35, 'STAGE CLEARED!', 3, Color{r: 80, g: 255, b: 120})
		draw_text_centered(renderer, win_width / 2, win_height / 2 + 15, 'PRESS [SPACE] FOR NEXT STAGE', 2, Color{r: 255, g: 255, b: 255})
	} else if app.game.state == .game_over {
		box := sdl.Rect{x: win_width / 2 - 200, y: win_height / 2 - 60, w: 400, h: 120}
		sdl.set_render_draw_color(renderer, 35, 15, 20, 245)
		sdl.render_fill_rect(renderer, &box)
		sdl.set_render_draw_color(renderer, 255, 60, 70, 255)
		sdl.render_draw_rect(renderer, &box)
		draw_text_centered(renderer, win_width / 2, win_height / 2 - 35, 'SKULL BREACH! GAME OVER', 2, Color{r: 255, g: 70, b: 90})
		draw_text_centered(renderer, win_width / 2, win_height / 2 + 15, 'PRESS [R] TO RESTART  [F11] Fullscreen', 2, Color{r: 255, g: 255, b: 255})
	} else if app.paused {
		box := sdl.Rect{x: win_width / 2 - 160, y: win_height / 2 - 50, w: 320, h: 100}
		sdl.set_render_draw_color(renderer, 20, 25, 40, 245)
		sdl.render_fill_rect(renderer, &box)
		draw_text_centered(renderer, win_width / 2, win_height / 2 - 25, 'PAUSED', 3, Color{r: 255, g: 220, b: 80})
		draw_text_centered(renderer, win_width / 2, win_height / 2 + 15, 'PRESS [P] TO RESUME', 2, Color{r: 200, g: 220, b: 255})
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
		app.game.score = 9850
		app.game.level = 2
		app.render()
		sdl.save_bmp(surface, 'screenshots/zuma.bmp'.str)
		sdl.destroy_renderer(s_renderer)
		sdl.free_surface(surface)
		return
	}

	window := sdl.create_window(
		'ZUMA // PopCap Stone Idol Classic'.str,
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
				.mousemotion {
					turret_cx := app.game.shooter_x
					turret_cy := app.game.shooter_y
					dx := f64(event.motion.x) - turret_cx
					dy := f64(event.motion.y) - turret_cy
					app.game.turret_angle = math.atan2(dy, dx)
				}
				.mousebuttondown {
					mx := event.button.x
					my := event.button.y
					if app.btn_reset.is_hovered(mx, my) {
						app.game = new_zuma_game()
					} else if app.btn_sound.is_hovered(mx, my) {
						app.sound_mgr.toggle_sound()
					} else if app.btn_pause.is_hovered(mx, my) {
						app.paused = !app.paused
					} else if event.button.button == 1 {
						if app.game.state == .level_won {
							app.game.init_level(app.game.level + 1)
						} else {
							if app.game.shoot_ball() {
								app.sound_mgr.play_shoot_sound()
							}
						}
					} else if event.button.button == 3 {
						app.game.swap_current_ball()
						app.sound_mgr.play_swap_sound()
					}
				}
				.keydown {
					sym := int(event.key.keysym.sym)
					if sym == int(sdl.KeyCode.f11) {
						toggle_fullscreen(window)
					} else if sym == int(sdl.KeyCode.escape) {
						return
					} else if sym == int(sdl.KeyCode.r) {
						app.game = new_zuma_game()
					} else if sym == int(sdl.KeyCode.p) {
						app.paused = !app.paused
					} else if sym == int(sdl.KeyCode.m) {
						app.sound_mgr.toggle_sound()
					} else if sym == int(sdl.KeyCode.tab) {
						app.game.swap_current_ball()
						app.sound_mgr.play_swap_sound()
					} else if sym == int(sdl.KeyCode.space) {
						if app.game.state == .level_won {
							app.game.init_level(app.game.level + 1)
						} else {
							if app.game.shoot_ball() {
								app.sound_mgr.play_shoot_sound()
							}
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
