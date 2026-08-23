import math
import os
import sdl
import sdl.image

pub struct MarioBrosTextureManager {
pub mut:
	sprite_texture &sdl.Texture = unsafe { nil }
}

pub fn (mut tm MarioBrosTextureManager) init(renderer &sdl.Renderer) {
	_ = image.init(int(image.InitFlags.png))
	candidates := [
		'assets/sprites/mariobros.png',
		'./assets/sprites/mariobros.png',
		'../assets/sprites/mariobros.png',
		'mariobros/assets/sprites/mariobros.png',
	]
	for p in candidates {
		if os.exists(p) {
			surface := image.load(p.str)
			if surface != unsafe { nil } {
				tm.sprite_texture = sdl.create_texture_from_surface(renderer, surface)
				sdl.free_surface(surface)
				if tm.sprite_texture != unsafe { nil } {
					println('Mario Bros Texture Loaded Successfully: ' + p)
					return
				}
			}
		}
	}
}

pub fn render_mario_bros_game(renderer &sdl.Renderer, mut g MarioBrosGame, tex &sdl.Texture) {
	// 1. Arcade Deep Sewer Background with Brick Mortar & Steam
	render_sewer_background(renderer)

	ox := int(g.shake_offset_x)
	oy := int(g.shake_offset_y)

	// 1b. Ambient Sewer Wall Torches / Glow Lanterns
	render_ambient_torches(renderer, ox, oy)

	// 1c. Sewer Steam & Mist Clouds
	render_steam_and_mist(renderer, ox, oy)

	// 2. Draw Sewer Pipes (Top and Bottom Left/Right) with metallic collars & steam
	render_pipes(renderer, ox, oy)

	// 3. Draw Water Drips & Sewer Floor Puddle Reflections
	render_water_drips(renderer, mut g, ox, oy)
	render_puddle_reflections(renderer, ox, oy)

	// 4. Draw Multi-Tier Platforms with dynamic Bump Ripples & Brick Texture
	render_platforms(renderer, mut g, ox, oy)

	// 5. Draw Expanding POW Shockwaves
	render_shockwaves(renderer, mut g, ox, oy)

	// 6. Draw POW Block with 3D Bevel, Neon Glow & Fracture Cracks
	render_pow_block(renderer, mut g, ox, oy, tex)

	// 7. Draw Coins with 3D Shimmering & Sparkles
	render_coins(renderer, mut g, ox, oy, tex)

	// 7b. Draw Power-Ups (Starman & Fire Flower)
	render_powerups(renderer, mut g, ox, oy)

	// 7c. Draw Sliding Shells (Bowling Attacks!)
	render_sliding_shells(renderer, mut g, ox, oy)

	// 7d. Draw Player Fireballs
	render_player_fireballs(renderer, mut g, ox, oy)

	// 8. Draw Enemies with Articulated Limbs & Animations
	render_enemies(renderer, mut g, ox, oy, tex)

	// 9. Draw Players (Mario & Luigi) with detailed hats, overalls & dust
	render_players(renderer, mut g, ox, oy, tex)

	// 10. Draw Particles
	render_particles(renderer, mut g, ox, oy)

	// 11. Draw Floating Score Popups
	render_score_popups(renderer, mut g, ox, oy)

	// 12. Draw In-Game Alerts (Phase Ready Banner & Combo Banners)
	render_gameplay_banners(renderer, mut g)

	// 13. Draw Arcade Top HUD & Lives Counters
	render_hud(renderer, mut g)

	// 14. Draw CRT Scanlines & Bezel Vignette
	if g.crt_filter {
		render_crt_overlay(renderer)
	}

	// 15. Draw Game State Overlays (Title, Paused, Phase Clear, Game Over)
	if g.state == .title {
		render_title_screen(renderer, mut g)
	} else if g.state == .paused {
		render_paused_screen(renderer)
	} else if g.state == .phase_clear {
		render_phase_clear_screen(renderer, mut g)
	} else if g.state == .game_over {
		render_game_over_screen(renderer, mut g)
	}
}


fn render_ambient_torches(renderer &sdl.Renderer, ox int, oy int) {
	torches := [
		[130, 95],
		[670, 95],
		[400, 230],
		[220, 360],
		[580, 360],
	]

	ticks := sdl.get_ticks()

	for t in torches {
		tx := t[0] + ox
		ty := t[1] + oy

		flicker := int((math.sin(f64(ticks) / 90.0 + f64(tx)) + 1.0) * 4.0)

		// Multi-layered Soft Radial Warm Torchlight Aura
		sdl.set_render_draw_blend_mode(renderer, .blend)
		for rad := 48; rad >= 12; rad -= 12 {
			alpha := u8(math.max(4, (48 - rad) * 2 + flicker * 2))
			sdl.set_render_draw_color(renderer, 255, 150, 30, alpha)
			glow_rect := sdl.Rect{ x: tx - rad, y: ty - rad, w: rad * 2, h: rad * 2 }
			sdl.render_fill_rect(renderer, &glow_rect)
		}

		sdl.set_render_draw_color(renderer, 255, 220, 80, u8(55 + flicker * 4))
		inner_glow := sdl.Rect{ x: tx - 10, y: ty - 10, w: 20, h: 20 }
		sdl.render_fill_rect(renderer, &inner_glow)

		// Iron Torch Sconce / Wall Bracket
		sdl.set_render_draw_blend_mode(renderer, .none)
		sdl.set_render_draw_color(renderer, 70, 75, 85, 255)
		sconce := sdl.Rect{ x: tx - 4, y: ty + 6, w: 8, h: 10 }
		sdl.render_fill_rect(renderer, &sconce)

		sdl.set_render_draw_color(renderer, 45, 48, 55, 255)
		bracket := sdl.Rect{ x: tx - 6, y: ty + 12, w: 12, h: 3 }
		sdl.render_fill_rect(renderer, &bracket)

		// Dancing Multi-tone Torch Flame
		flame_h := 8 + flicker
		sdl.set_render_draw_color(renderer, 255, 50, 20, 255)
		f1 := sdl.Rect{ x: tx - 4, y: ty - flame_h + 4, w: 8, h: flame_h }
		sdl.render_fill_rect(renderer, &f1)

		sdl.set_render_draw_color(renderer, 255, 230, 60, 255)
		f2 := sdl.Rect{ x: tx - 2, y: ty - flame_h + 6, w: 4, h: flame_h - 4 }
		sdl.render_fill_rect(renderer, &f2)

		sdl.set_render_draw_color(renderer, 255, 255, 220, 255)
		f3 := sdl.Rect{ x: tx - 1, y: ty - flame_h + 8, w: 2, h: 3 }
		sdl.render_fill_rect(renderer, &f3)
	}
}

fn render_steam_and_mist(renderer &sdl.Renderer, ox int, oy int) {
	sdl.set_render_draw_blend_mode(renderer, .blend)
	ticks := sdl.get_ticks()

	// Steam rising from pipe mouths
	pipe_steam_spots := [
		[70, 100],
		[730, 100],
		[70, 510],
		[730, 510],
	]

	for sp in pipe_steam_spots {
		sx := sp[0] + ox
		sy := sp[1] + oy

		for puff := 0; puff < 4; puff++ {
			phase := f64((int(ticks) + puff * 350) % 1800) / 1800.0
			puff_y := sy - int(phase * 50.0)
			puff_x := sx + int(math.sin(phase * 4.5) * 10.0)
			size := int(8.0 + phase * 22.0)
			alpha := u8((1.0 - phase) * 50.0)

			sdl.set_render_draw_color(renderer, 210, 240, 255, alpha)
			rect := sdl.Rect{ x: puff_x - size / 2, y: puff_y - size / 2, w: size, h: size }
			sdl.render_fill_rect(renderer, &rect)
		}
	}
}

fn render_puddle_reflections(renderer &sdl.Renderer, ox int, oy int) {
	sdl.set_render_draw_blend_mode(renderer, .blend)
	ticks := sdl.get_ticks()

	// Shimmering sewer puddle water ripples on bottom floor
	for i := 0; i < 5; i++ {
		px := 120 + i * 140 + ox
		py := 544 + oy
		ripple := int(math.sin(f64(ticks) / 200.0 + f64(i)) * 4.0)

		// Specular blue/cyan floor wet puddle sheen
		sdl.set_render_draw_color(renderer, 40, 150, 230, 60)
		puddle := sdl.Rect{ x: px - 35, y: py, w: 70 + ripple * 2, h: 4 }
		sdl.render_fill_rect(renderer, &puddle)

		sdl.set_render_draw_color(renderer, 180, 235, 255, 90)
		sheen := sdl.Rect{ x: px - 18, y: py + 1, w: 36, h: 2 }
		sdl.render_fill_rect(renderer, &sheen)
	}
}

fn render_sewer_background(renderer &sdl.Renderer) {
	// Deep arcade sewer navy-black base
	sdl.set_render_draw_color(renderer, 8, 10, 18, 255)
	sdl.render_clear(renderer)

	ticks := sdl.get_ticks()

	// Subtle masonry brick grid in background
	sdl.set_render_draw_color(renderer, 14, 18, 30, 255)
	for row := 0; row < 15; row++ {
		y := row * 40
		sdl.render_draw_line(renderer, 0, y, 800, y)
		x_off := if row % 2 == 0 { 0 } else { 40 }
		for col := 0; col < 11; col++ {
			x := col * 80 + x_off
			sdl.render_draw_line(renderer, x, y, x, y + 40)
		}
	}

	// Ambient sewer wall drainage trickles running down brick seams
	sdl.set_render_draw_blend_mode(renderer, .blend)
	trickle_xs := [110, 260, 390, 530, 690]
	for idx, tx in trickle_xs {
		t_speed := 90 + idx * 25
		flow_phase := int((ticks / u32(t_speed)) % 540)
		for seg := 0; seg < 4; seg++ {
			sy := (flow_phase + seg * 135) % 530
			sdl.set_render_draw_color(renderer, 45, 110, 160, 40)
			sdl.render_draw_line(renderer, tx, sy, tx, sy + 18)
			sdl.set_render_draw_color(renderer, 120, 200, 255, 60)
			sdl.render_draw_line(renderer, tx, sy + 14, tx, sy + 18)
		}
	}

	// Floating bioluminescent sewer spores / motes
	for m := 0; m < 8; m++ {
		m_phase := f64(ticks + u32(m * 1200)) / 1000.0
		mx := int(60.0 + f64(m * 90) + math.sin(m_phase * 0.7) * 25.0)
		my := int(80.0 + f64((m * 55 + int(m_phase * 15.0)) % 440))
		m_alpha := u8((math.sin(m_phase * 1.5) + 1.0) * 35.0 + 20.0)
		sdl.set_render_draw_color(renderer, 80, 240, 100, m_alpha)
		m_rect := sdl.Rect{ x: mx, y: my, w: 2, h: 2 }
		sdl.render_fill_rect(renderer, &m_rect)
	}
}

fn render_pipes(renderer &sdl.Renderer, ox int, oy int) {
	// Vibrant sewer pipe palette
	dark_green := Color{ r: 16, g: 90, b: 24, a: 255 }
	mid_green := Color{ r: 35, g: 160, b: 45, a: 255 }
	light_green := Color{ r: 90, g: 235, b: 90, a: 255 }
	mouth_black := Color{ r: 4, g: 12, b: 6, a: 255 }
	flange_c := Color{ r: 50, g: 195, b: 65, a: 255 }
	rivet_c := Color{ r: 180, g: 255, b: 180, a: 255 }

	// Top Left Pipe (X: 0..86, Y: 76..134)
	draw_pipe_horizontal(renderer, ox + 0, oy + 76, 86, 56, false, dark_green, mid_green, light_green, mouth_black, flange_c, rivet_c)

	// Top Right Pipe (X: 714..800, Y: 76..134)
	draw_pipe_horizontal(renderer, ox + 714, oy + 76, 86, 56, true, dark_green, mid_green, light_green, mouth_black, flange_c, rivet_c)

	// Bottom Left Pipe (X: 0..86, Y: 484..540)
	draw_pipe_horizontal(renderer, ox + 0, oy + 484, 86, 56, false, dark_green, mid_green, light_green, mouth_black, flange_c, rivet_c)

	// Bottom Right Pipe (X: 714..800, Y: 484..540)
	draw_pipe_horizontal(renderer, ox + 714, oy + 484, 86, 56, true, dark_green, mid_green, light_green, mouth_black, flange_c, rivet_c)

	// Draw Toxic Waste & Sludge Ooze Effects on Pipe Mouths
	render_pipe_waste_and_ooze(renderer, ox, oy)
}

fn render_pipe_waste_and_ooze(renderer &sdl.Renderer, ox int, oy int) {
	sdl.set_render_draw_blend_mode(renderer, .blend)
	ticks := sdl.get_ticks()

	// 1. Toxic Green Glowing Vapor Halos around Pipe Mouths
	pipe_locs := [
		[78, 105],
		[722, 105],
		[78, 512],
		[722, 512],
	]

	for pl in pipe_locs {
		px := pl[0] + ox
		py := pl[1] + oy
		puls := int((math.sin(f64(ticks) / 160.0 + f64(px)) + 1.0) * 5.0)

		sdl.set_render_draw_color(renderer, 40, 220, 60, u8(18 + puls * 2))
		glow := sdl.Rect{ x: px - 22, y: py - 22, w: 44, h: 44 }
		sdl.render_fill_rect(renderer, &glow)

		sdl.set_render_draw_color(renderer, 100, 255, 80, u8(30 + puls * 3))
		inner_glow := sdl.Rect{ x: px - 11, y: py - 11, w: 22, h: 22 }
		sdl.render_fill_rect(renderer, &inner_glow)
	}

	// 2. Top-Left Pipe Ooze & Dripping Slime (x: 78..86, y: 124..136)
	tl_drip_h := int(math.abs(math.sin(f64(ticks) / 220.0)) * 7.0)
	// Slime layer on collar lip
	sdl.set_render_draw_color(renderer, 70, 230, 40, 230)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: ox + 76, y: oy + 128, w: 12, h: 4 })
	// Hanging stretching drip teardrop
	sdl.set_render_draw_color(renderer, 140, 255, 60, 240)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: ox + 82, y: oy + 132, w: 4, h: 4 + tl_drip_h })
	// Specular highlight on slime
	sdl.set_render_draw_color(renderer, 220, 255, 140, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: ox + 83, y: oy + 132 + tl_drip_h, w: 2, h: 2 })

	// Animated bubbles inside top-left pipe mouth
	for b := 0; b < 2; b++ {
		b_phase := f64((ticks + u32(b * 600)) % 1400) / 1400.0
		bx := ox + 76 + int(b_phase * 8.0)
		by := oy + 124 - int(math.sin(b_phase * math.pi) * 6.0)
		b_rad := int(2.0 + b_phase * 2.5)
		sdl.set_render_draw_color(renderer, 90, 255, 50, u8(220 * (1.0 - b_phase)))
		sdl.render_fill_rect(renderer, &sdl.Rect{ x: bx, y: by, w: b_rad, h: b_rad })
	}

	// 3. Top-Right Pipe Ooze & Dripping Slime (x: 714..724, y: 124..136)
	tr_drip_h := int(math.abs(math.sin(f64(ticks) / 240.0 + 1.2)) * 7.0)
	sdl.set_render_draw_color(renderer, 70, 230, 40, 230)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: ox + 712, y: oy + 128, w: 12, h: 4 })
	sdl.set_render_draw_color(renderer, 140, 255, 60, 240)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: ox + 714, y: oy + 132, w: 4, h: 4 + tr_drip_h })
	sdl.set_render_draw_color(renderer, 220, 255, 140, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: ox + 715, y: oy + 132 + tr_drip_h, w: 2, h: 2 })

	// 4. Bottom-Left Pipe Sewage Waste Waterfall & Floor Spill
	// Slime stream cascading down from bottom pipe to floor gutter (y: 532..544)
	flow_w := 6 + int(math.sin(f64(ticks) / 110.0) * 2.0)
	sdl.set_render_draw_color(renderer, 60, 210, 40, 220)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: ox + 78, y: oy + 532, w: flow_w, h: 10 })
	// Waste cascade highlight core
	sdl.set_render_draw_color(renderer, 160, 255, 80, 240)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: ox + 80, y: oy + 534, w: 3, h: 8 })
	// Toxic waste puddle slick on bottom floor curb
	sdl.set_render_draw_color(renderer, 50, 220, 60, 120)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: ox + 60, y: oy + 540, w: 42, h: 5 })
	sdl.set_render_draw_color(renderer, 180, 255, 100, 180)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: ox + 72, y: oy + 541, w: 20, h: 2 })

	// Foam & bubbling froths at bottom-left outfall
	for f := 0; f < 3; f++ {
		f_anim := f64((ticks + u32(f * 450)) % 900) / 900.0
		fx := ox + 70 + f * 7 + int(math.sin(f_anim * 6.0) * 3.0)
		fy := oy + 539 - int(f_anim * 4.0)
		sdl.set_render_draw_color(renderer, 200, 255, 140, u8(240 * (1.0 - f_anim)))
		sdl.render_fill_rect(renderer, &sdl.Rect{ x: fx, y: fy, w: 3, h: 3 })
	}

	// 5. Bottom-Right Pipe Sewage Waste Waterfall & Floor Spill
	r_flow_w := 6 + int(math.sin(f64(ticks) / 120.0 + 1.5) * 2.0)
	sdl.set_render_draw_color(renderer, 60, 210, 40, 220)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: ox + 716, y: oy + 532, w: r_flow_w, h: 10 })
	sdl.set_render_draw_color(renderer, 160, 255, 80, 240)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: ox + 717, y: oy + 534, w: 3, h: 8 })
	// Waste slick on right floor curb
	sdl.set_render_draw_color(renderer, 50, 220, 60, 120)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: ox + 698, y: oy + 540, w: 42, h: 5 })
	sdl.set_render_draw_color(renderer, 180, 255, 100, 180)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: ox + 708, y: oy + 541, w: 20, h: 2 })

	// Foam & bubbling froths at bottom-right outfall
	for f := 0; f < 3; f++ {
		f_anim := f64((ticks + u32(f * 480)) % 900) / 900.0
		fx := ox + 708 + f * 7 + int(math.sin(f_anim * 6.0) * 3.0)
		fy := oy + 539 - int(f_anim * 4.0)
		sdl.set_render_draw_color(renderer, 200, 255, 140, u8(240 * (1.0 - f_anim)))
		sdl.render_fill_rect(renderer, &sdl.Rect{ x: fx, y: fy, w: 3, h: 3 })
	}
}

fn draw_pipe_horizontal(renderer &sdl.Renderer, x int, y int, w int, h int, is_right bool,
	dark Color, mid Color, light Color, mouth Color, flange Color, rivet Color) {
	// Pipe stem
	stem_x := if is_right { x + 26 } else { x }
	stem_w := w - 26
	stem_rect := sdl.Rect{ x: stem_x, y: y + 6, w: stem_w, h: h - 12 }
	sdl.set_render_draw_color(renderer, mid.r, mid.g, mid.b, 255)
	sdl.render_fill_rect(renderer, &stem_rect)

	// Highlight stripe along top edge
	hl_rect := sdl.Rect{ x: stem_x, y: y + 10, w: stem_w, h: 7 }
	sdl.set_render_draw_color(renderer, light.r, light.g, light.b, 255)
	sdl.render_fill_rect(renderer, &hl_rect)

	// Shadow stripe along bottom edge
	sd_rect := sdl.Rect{ x: stem_x, y: y + h - 16, w: stem_w, h: 9 }
	sdl.set_render_draw_color(renderer, dark.r, dark.g, dark.b, 255)
	sdl.render_fill_rect(renderer, &sd_rect)

	// Outer pipe collar / flange
	flange_x := if is_right { x } else { x + w - 26 }
	flange_rect := sdl.Rect{ x: flange_x, y: y, w: 26, h: h }
	sdl.set_render_draw_color(renderer, flange.r, flange.g, flange.b, 255)
	sdl.render_fill_rect(renderer, &flange_rect)

	flange_hl := sdl.Rect{ x: flange_x + 3, y: y + 4, w: 20, h: 7 }
	sdl.set_render_draw_color(renderer, light.r, light.g, light.b, 255)
	sdl.render_fill_rect(renderer, &flange_hl)

	flange_sd := sdl.Rect{ x: flange_x + 3, y: y + h - 12, w: 20, h: 8 }
	sdl.set_render_draw_color(renderer, dark.r, dark.g, dark.b, 255)
	sdl.render_fill_rect(renderer, &flange_sd)

	// Metallic Rivets on flange
	sdl.set_render_draw_color(renderer, rivet.r, rivet.g, rivet.b, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: flange_x + 11, y: y + 6, w: 4, h: 4 })
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: flange_x + 11, y: y + h / 2 - 2, w: 4, h: 4 })
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: flange_x + 11, y: y + h - 10, w: 4, h: 4 })

	// Inner dark pipe mouth
	mouth_x := if is_right { x } else { x + w - 8 }
	mouth_rect := sdl.Rect{ x: mouth_x, y: y + 4, w: 8, h: h - 8 }
	sdl.set_render_draw_color(renderer, mouth.r, mouth.g, mouth.b, 255)
	sdl.render_fill_rect(renderer, &mouth_rect)
}

fn render_water_drips(renderer &sdl.Renderer, mut g MarioBrosGame, ox int, oy int) {
	for d in g.water_drips {
		if !d.active {
			continue
		}
		dx := int(d.x) + ox
		dy := int(d.y) + oy
		// Teardrop length scales with falling velocity
		d_len := int(math.min(12.0, math.max(6.0, f64(d.vy * 0.035))))

		// Translucent trailing tail
		sdl.set_render_draw_blend_mode(renderer, .blend)
		sdl.set_render_draw_color(renderer, d.color.r, d.color.g, d.color.b, u8(math.max(80, int(d.color.a) - 60)))
		sdl.render_draw_line(renderer, dx + 1, dy, dx + 1, dy + d_len - 2)

		// Bright teardrop body
		sdl.set_render_draw_color(renderer, d.color.r, d.color.g, d.color.b, d.color.a)
		drip_rect := sdl.Rect{ x: dx, y: dy + d_len - 4, w: 3, h: 4 }
		sdl.render_fill_rect(renderer, &drip_rect)

		// Specular gleam head
		match d.drip_type {
			.toxic_waste {
				sdl.set_render_draw_color(renderer, 210, 255, 140, 255)
			}
			.sludge {
				sdl.set_render_draw_color(renderer, 255, 230, 110, 255)
			}
			else {
				sdl.set_render_draw_color(renderer, 220, 245, 255, 255)
			}
		}
		sdl.render_fill_rect(renderer, &sdl.Rect{ x: dx + 1, y: dy + d_len - 2, w: 1, h: 2 })
	}
}

fn render_platforms(renderer &sdl.Renderer, mut g MarioBrosGame, ox int, oy int) {
	for plat in g.platforms {
		px := int(plat.x) + ox
		py := int(plat.y) + oy
		pw := int(plat.w)
		ph := int(plat.h)

		// Ground Floor (Sewer drain curb with iron grating & bottom water flow)
		if ph > 30 {
			// Sewer base curb
			sdl.set_render_draw_color(renderer, 20, 65, 110, 255)
			base_rect := sdl.Rect{ x: px, y: py, w: pw, h: ph }
			sdl.render_fill_rect(renderer, &base_rect)

			// Top curb bright cyan highlight strip
			sdl.set_render_draw_color(renderer, 60, 160, 245, 255)
			top_line := sdl.Rect{ x: px, y: py, w: pw, h: 6 }
			sdl.render_fill_rect(renderer, &top_line)

			// Iron drainage grating lines
			sdl.set_render_draw_color(renderer, 12, 40, 75, 255)
			for gx := px; gx < px + pw; gx += 20 {
				sdl.render_draw_line(renderer, gx, py + 6, gx, py + ph)
			}

			// Subtle flowing bottom sewer water stream
			water_glow := int((math.sin(f64(sdl.get_ticks()) / 250.0) + 1.0) * 20.0)
			sdl.set_render_draw_color(renderer, 15, u8(70 + water_glow), u8(130 + water_glow), 255)
			water_rect := sdl.Rect{ x: px, y: py + ph - 8, w: pw, h: 8 }
			sdl.render_fill_rect(renderer, &water_rect)
			continue
		}

		// Floating Multi-Tier Platforms with dynamic Sinusoidal Bumping & Brick Lattice
		for step_x := px; step_x < px + pw; step_x += 16 {
			bw := int(math.min(16, (px + pw) - step_x))

			// Calculate bump wave upward offset for this segment
			mut bump_disp := f32(0.0)
			for wave in g.bump_waves {
				if wave.active {
					dist := math.abs(f32(step_x + bw / 2) - wave.x)
					if dist < wave.radius {
						progress := wave.timer / wave.duration
						bump_amount := f32(math.sin(f64((1.0 - progress) * f32(math.pi))) * 16.0)
						falloff := 1.0 - (dist / wave.radius)
						bump_val := bump_amount * falloff
						if bump_val > bump_disp {
							bump_disp = bump_val
						}
					}
				}
			}

			disp_y := py - int(bump_disp)

			// Platform body (Vibrant arcade Cyan-Blue)
			plat_rect := sdl.Rect{ x: step_x, y: disp_y, w: bw, h: ph }
			sdl.set_render_draw_color(renderer, 28, 92, 160, 255)
			sdl.render_fill_rect(renderer, &plat_rect)

			// Top neon highlight ridge
			top_rect := sdl.Rect{ x: step_x, y: disp_y, w: bw, h: 4 }
			sdl.set_render_draw_color(renderer, 100, 200, 255, 255)
			sdl.render_fill_rect(renderer, &top_rect)

			// Brick bevel & mortar division lines
			sdl.set_render_draw_color(renderer, 14, 48, 90, 255)
			sdl.render_draw_line(renderer, step_x, disp_y, step_x, disp_y + ph)
			sdl.render_draw_line(renderer, step_x, disp_y + ph / 2, step_x + bw, disp_y + ph / 2)

			// Under-rail dark support shadow
			sdl.set_render_draw_color(renderer, 8, 22, 45, 255)
			sdl.render_draw_line(renderer, step_x, disp_y + ph, step_x + bw, disp_y + ph)
		}
	}
}

fn render_shockwaves(renderer &sdl.Renderer, mut g MarioBrosGame, ox int, oy int) {
	for sw in g.shockwaves {
		if !sw.active {
			continue
		}
		cx := int(sw.x) + ox
		cy := int(sw.y) + oy
		r := int(sw.radius)

		alpha := u8(math.max(0.0, f64(sw.timer / sw.duration) * 255.0))
		sdl.set_render_draw_blend_mode(renderer, .blend)

		// Outer Neon Cyan Chromatic Halo
		sdl.set_render_draw_color(renderer, 60, 220, 255, alpha / 2)
		draw_circle_wire(renderer, cx, cy, r + 2)

		// Main Shockwave Ring
		sdl.set_render_draw_color(renderer, sw.color.r, sw.color.g, sw.color.b, alpha)
		for ring_off in -1 .. 2 {
			draw_circle_wire(renderer, cx, cy, r + ring_off)
		}

		// Inner Fiery White Edge
		sdl.set_render_draw_color(renderer, 255, 255, 255, alpha)
		draw_circle_wire(renderer, cx, cy, r - 2)
	}
}

fn draw_circle_wire(renderer &sdl.Renderer, cx int, cy int, radius int) {
	if radius <= 0 {
		return
	}
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

		if err <= 0 {
			y += 1
			err += 2 * y + 1
		}
		if err > 0 {
			x -= 1
			err -= 2 * x + 1
		}
	}
}

fn render_pow_block(renderer &sdl.Renderer, mut g MarioBrosGame, ox int, oy int, tex &sdl.Texture) {
	if !g.pow_block.active || g.pow_block.hits_left <= 0 {
		return
	}

	bx := int(g.pow_block.x) + ox
	by := int(g.pow_block.y) + oy
	bw := int(g.pow_block.w)
	bh := int(g.pow_block.h)

	shake_y := if g.pow_block.shake_timer > 0.0 {
		int(math.sin(f64(g.pow_block.shake_timer * 35.0)) * 5.0)
	} else {
		0
	}

	if tex != unsafe { nil } {
		src := sdl.Rect{x: 0, y: 128, w: 32, h: 32}
		dst := sdl.Rect{x: bx, y: by + shake_y, w: bw, h: bh}
		sdl.render_copy(renderer, tex, &src, &dst)
		return
	}

	// Dynamic block color based on remaining hits (Electric Blue -> Bright Orange -> Fiery Red)
	base_color := match g.pow_block.hits_left {
		3 { Color{ r: 35, g: 125, b: 245, a: 255 } }
		2 { Color{ r: 240, g: 140, b: 25, a: 255 } }
		else { Color{ r: 245, g: 45, b: 35, a: 255 } }
	}

	top_color := match g.pow_block.hits_left {
		3 { Color{ r: 130, g: 200, b: 255, a: 255 } }
		2 { Color{ r: 255, g: 210, b: 110, a: 255 } }
		else { Color{ r: 255, g: 140, b: 130, a: 255 } }
	}

	// Outer ambient neon glow halo
	sdl.set_render_draw_blend_mode(renderer, .blend)
	sdl.set_render_draw_color(renderer, top_color.r, top_color.g, top_color.b, 60)
	glow_rect := sdl.Rect{ x: bx - 4, y: by + shake_y - 4, w: bw + 8, h: bh + 8 }
	sdl.render_fill_rect(renderer, &glow_rect)

	// 3D Block Base
	sdl.set_render_draw_blend_mode(renderer, .none)
	block_rect := sdl.Rect{ x: bx, y: by + shake_y, w: bw, h: bh }
	sdl.set_render_draw_color(renderer, base_color.r, base_color.g, base_color.b, 255)
	sdl.render_fill_rect(renderer, &block_rect)

	// Top beveled highlight strip
	top_rect := sdl.Rect{ x: bx, y: by + shake_y, w: bw, h: 6 }
	sdl.set_render_draw_color(renderer, top_color.r, top_color.g, top_color.b, 255)
	sdl.render_fill_rect(renderer, &top_rect)

	// Outer crisp white border
	sdl.set_render_draw_color(renderer, 255, 255, 255, 255)
	border := sdl.Rect{ x: bx, y: by + shake_y, w: bw, h: bh }
	sdl.render_draw_rect(renderer, &border)

	// Fracture Cracks for damaged hits
	if g.pow_block.hits_left <= 2 {
		sdl.set_render_draw_color(renderer, 15, 15, 20, 255)
		sdl.render_draw_line(renderer, bx + 12, by + shake_y + 2, bx + 18, by + shake_y + 16)
		sdl.render_draw_line(renderer, bx + 18, by + shake_y + 16, bx + 14, by + shake_y + bh - 4)
	}
	if g.pow_block.hits_left == 1 {
		sdl.set_render_draw_color(renderer, 15, 15, 20, 255)
		sdl.render_draw_line(renderer, bx + bw - 14, by + shake_y + 2, bx + bw - 20, by + shake_y + 18)
		sdl.render_draw_line(renderer, bx + bw - 20, by + shake_y + 18, bx + bw - 12, by + shake_y + bh - 4)
	}

	// "POW" text in bold center
	draw_text_centered_shadow(renderer, bx + bw / 2, by + shake_y + 8, 'POW', 2,
		Color{ r: 255, g: 255, b: 255, a: 255 }, Color{ r: 10, g: 10, b: 25, a: 255 })
}

fn render_coins(renderer &sdl.Renderer, mut g MarioBrosGame, ox int, oy int, tex &sdl.Texture) {
	for c in g.coins {
		if !c.active {
			continue
		}
		cx := int(c.x) + ox
		cy := int(c.y) + oy

		if tex != unsafe { nil } {
			f := int(c.anim_timer * 8.0) % 4
			src := sdl.Rect{x: (1 + f) * 32, y: 128, w: 32, h: 32}
			dst := sdl.Rect{x: cx, y: cy, w: int(c.width), h: int(c.height)}
			sdl.render_copy(renderer, tex, &src, &dst)
			continue
		}

		// Animated coin spin width
		spin := math.abs(math.cos(f64(c.anim_timer)))
		cw := int(math.max(4.0, f64(c.width) * spin))
		ch := int(c.height)
		coin_x := cx + (int(c.width) - cw) / 2

		// Gold outer rim
		sdl.set_render_draw_color(renderer, 255, 215, 0, 255)
		coin_rect := sdl.Rect{ x: coin_x, y: cy, w: cw, h: ch }
		sdl.render_fill_rect(renderer, &coin_rect)

		// Inner sparkle
		if cw > 8 {
			sdl.set_render_draw_color(renderer, 255, 250, 180, 255)
			inner := sdl.Rect{ x: coin_x + 3, y: cy + 3, w: cw - 6, h: ch - 6 }
			sdl.render_fill_rect(renderer, &inner)

			// Coin vertical slot
			sdl.set_render_draw_color(renderer, 190, 140, 10, 255)
			slot := sdl.Rect{ x: coin_x + cw / 2 - 1, y: cy + 5, w: 2, h: ch - 10 }
			sdl.render_fill_rect(renderer, &slot)
		}
	}
}

fn render_powerups(renderer &sdl.Renderer, mut g MarioBrosGame, ox int, oy int) {
	for pu in g.powerups {
		if !pu.active {
			continue
		}
		px := int(pu.x) + ox
		py := int(pu.y) + oy
		pw := int(pu.width)
		ph := int(pu.height)

		match pu.power_type {
			.star {
				// Shimmering 5-point Starman
				ticks := sdl.get_ticks()
				star_col := if (ticks / 100) % 2 == 0 { Color{ r: 255, g: 235, b: 60, a: 255 } } else { Color{ r: 255, g: 140, b: 40, a: 255 } }
				sdl.set_render_draw_color(renderer, star_col.r, star_col.g, star_col.b, 255)
				core := sdl.Rect{ x: px + 4, y: py + 4, w: pw - 8, h: ph - 8 }
				sdl.render_fill_rect(renderer, &core)

				top_p := sdl.Rect{ x: px + pw / 2 - 3, y: py, w: 6, h: 6 }
				l_p := sdl.Rect{ x: px, y: py + 6, w: 6, h: 6 }
				r_p := sdl.Rect{ x: px + pw - 6, y: py + 6, w: 6, h: 6 }
				sdl.render_fill_rect(renderer, &top_p)
				sdl.render_fill_rect(renderer, &l_p)
				sdl.render_fill_rect(renderer, &r_p)

				// Cute Arcade Eyes
				sdl.set_render_draw_color(renderer, 0, 0, 0, 255)
				eye1 := sdl.Rect{ x: px + 7, y: py + 8, w: 2, h: 5 }
				eye2 := sdl.Rect{ x: px + pw - 9, y: py + 8, w: 2, h: 5 }
				sdl.render_fill_rect(renderer, &eye1)
				sdl.render_fill_rect(renderer, &eye2)
			}
			.fire_flower {
				// Fire Flower Petals (Red/Orange)
				sdl.set_render_draw_color(renderer, 255, 60, 40, 255)
				petals := sdl.Rect{ x: px + 3, y: py + 2, w: pw - 6, h: 14 }
				sdl.render_fill_rect(renderer, &petals)

				// Flower Center (White)
				sdl.set_render_draw_color(renderer, 255, 255, 255, 255)
				center := sdl.Rect{ x: px + 7, y: py + 5, w: pw - 14, h: 8 }
				sdl.render_fill_rect(renderer, &center)

				// Stem & Green Leaves
				sdl.set_render_draw_color(renderer, 40, 190, 50, 255)
				stem := sdl.Rect{ x: px + pw / 2 - 2, y: py + 14, w: 4, h: 8 }
				leaf_l := sdl.Rect{ x: px + 2, y: py + 18, w: 6, h: 4 }
				leaf_r := sdl.Rect{ x: px + pw - 8, y: py + 18, w: 6, h: 4 }
				sdl.render_fill_rect(renderer, &stem)
				sdl.render_fill_rect(renderer, &leaf_l)
				sdl.render_fill_rect(renderer, &leaf_r)
			}
		}
	}
}

fn render_sliding_shells(renderer &sdl.Renderer, mut g MarioBrosGame, ox int, oy int) {
	for sh in g.sliding_shells {
		if !sh.active {
			continue
		}
		sx := int(sh.x) + ox
		sy := int(sh.y) + oy
		sw := int(sh.width)
		sh_h := int(sh.height)

		// Green Sliding Turtle Shell Body
		sdl.set_render_draw_color(renderer, 40, 200, 60, 255)
		body := sdl.Rect{ x: sx + 2, y: sy + 2, w: sw - 4, h: sh_h - 4 }
		sdl.render_fill_rect(renderer, &body)

		// Shell Rim (Yellow / White)
		sdl.set_render_draw_color(renderer, 255, 255, 200, 255)
		rim := sdl.Rect{ x: sx, y: sy + sh_h - 6, w: sw, h: 5 }
		sdl.render_fill_rect(renderer, &rim)

		// Spinning Shell Lines
		spin_offset := int(sh.anim_timer) % 8
		sdl.set_render_draw_color(renderer, 20, 140, 30, 255)
		l1 := sdl.Rect{ x: sx + 4 + spin_offset, y: sy + 4, w: 3, h: sh_h - 10 }
		l2 := sdl.Rect{ x: sx + 14 + spin_offset, y: sy + 4, w: 3, h: sh_h - 10 }
		sdl.render_fill_rect(renderer, &l1)
		sdl.render_fill_rect(renderer, &l2)
	}
}

fn render_player_fireballs(renderer &sdl.Renderer, mut g MarioBrosGame, ox int, oy int) {
	for fb in g.player_fireballs {
		if !fb.active {
			continue
		}
		fx := int(fb.x) + ox
		fy := int(fb.y) + oy
		fw := int(fb.width)
		fh := int(fb.height)

		sdl.set_render_draw_color(renderer, 255, 100, 20, 255)
		outer := sdl.Rect{ x: fx, y: fy, w: fw, h: fh }
		sdl.render_fill_rect(renderer, &outer)

		sdl.set_render_draw_color(renderer, 255, 240, 60, 255)
		inner := sdl.Rect{ x: fx + 2, y: fy + 2, w: fw - 4, h: fh - 4 }
		sdl.render_fill_rect(renderer, &inner)

		sdl.set_render_draw_color(renderer, 255, 255, 255, 255)
		center := sdl.Rect{ x: fx + 4, y: fy + 4, w: fw - 8, h: fh - 8 }
		sdl.render_fill_rect(renderer, &center)
	}
}

fn render_enemies(renderer &sdl.Renderer, mut g MarioBrosGame, ox int, oy int, tex &sdl.Texture) {
	for e in g.enemies {
		if !e.active || e.state == .in_pipe {
			continue
		}
		ex := int(e.x) + ox
		ey := int(e.y) + oy
		ew := int(e.width)
		eh := int(e.height)

		match e.enemy_type {
			.shellcreeper {
				render_shellcreeper(renderer, ex, ey, ew, eh, e.state, e.facing_right, e.stun_timer, tex)
			}
			.sidestepper {
				render_sidestepper(renderer, ex, ey, ew, eh, e.state, e.stun_timer, e.angry_level, tex)
			}
			.fighterfly {
				render_fighterfly(renderer, ex, ey, ew, eh, e.state, e.stun_timer, e.hop_timer, tex)
			}
			.slipice {
				render_slipice(renderer, ex, ey, ew, eh)
			}
			.fireball {
				render_fireball(renderer, ex, ey, ew, eh)
			}
		}

		// Orbiting Dizzy Stun Stars over flipped enemies
		if e.state == .stunned || e.state == .recovering {
			ticks := f64(sdl.get_ticks())
			for st := 0; st < 3; st++ {
				star_ang := (ticks * 0.008) + f64(st) * (2.0 * math.pi / 3.0)
				sx := ex + ew / 2 + int(math.cos(star_ang) * 14.0)
				sy := ey - 6 + int(math.sin(star_ang) * 5.0)
				sdl.set_render_draw_color(renderer, 255, 235, 40, 255)
				sdl.render_fill_rect(renderer, &sdl.Rect{x: sx - 2, y: sy - 2, w: 4, h: 4})
				sdl.set_render_draw_color(renderer, 255, 255, 255, 255)
				sdl.render_draw_point(renderer, sx, sy)
			}
		}
	}
}

fn render_shellcreeper(renderer &sdl.Renderer, x int, y int, w int, h int, state EnemyState, facing_right bool, stun_timer f32, tex &sdl.Texture) {
	is_flipped := state == .stunned || state == .recovering || state == .kicked
	is_recovering := state == .recovering
	flash := is_recovering && (int(stun_timer * 15.0) % 2 == 0)

	if tex != unsafe { nil } {
		col_x := if is_flipped {
			2 * 32
		} else {
			0
		}
		src := sdl.Rect{x: col_x, y: 64, w: 32, h: 32}
		dst := sdl.Rect{x: x, y: y, w: w, h: h}
		flip := if facing_right { sdl.RendererFlip.none } else { sdl.RendererFlip.horizontal }
		sdl.render_copy_ex(renderer, tex, &src, &dst, 0.0, unsafe { nil }, flip)
		return
	}

	if is_flipped {
		// Flipped shell with dynamic rocking physics and legs wiggling on top
		rock_x := int(math.sin(f64(stun_timer * 16.0)) * 3.0)
		rock_y := int(math.abs(math.cos(f64(stun_timer * 16.0))) * 2.0)

		shell_color := if flash { Color{ r: 255, g: 50, b: 50, a: 255 } } else { Color{ r: 220, g: 190, b: 60, a: 255 } }
		sdl.set_render_draw_color(renderer, shell_color.r, shell_color.g, shell_color.b, 255)
		shell := sdl.Rect{ x: x + 2 + rock_x, y: y + 10 - rock_y, w: w - 4, h: h - 10 }
		sdl.render_fill_rect(renderer, &shell)

		// Shell underbelly rim
		sdl.set_render_draw_color(renderer, 160, 120, 20, 255)
		rim := sdl.Rect{ x: x + rock_x, y: y + 10 - rock_y, w: w, h: 4 }
		sdl.render_fill_rect(renderer, &rim)

		// 4 Animated wiggling legs pointing UP with wobble
		leg_c := if flash { Color{ r: 255, g: 255, b: 255, a: 255 } } else { Color{ r: 70, g: 190, b: 40, a: 255 } }
		sdl.set_render_draw_color(renderer, leg_c.r, leg_c.g, leg_c.b, 255)
		wiggle := int(math.sin(f64(stun_timer * 22.0)) * 4.0)

		l1 := sdl.Rect{ x: x + 4 + rock_x, y: y + 2 - rock_y + wiggle, w: 4, h: 8 }
		l2 := sdl.Rect{ x: x + 10 + rock_x, y: y + 2 - rock_y - wiggle, w: 4, h: 8 }
		l3 := sdl.Rect{ x: x + 16 + rock_x, y: y + 2 - rock_y + wiggle, w: 4, h: 8 }
		l4 := sdl.Rect{ x: x + 22 + rock_x, y: y + 2 - rock_y - wiggle, w: 4, h: 8 }
		sdl.render_fill_rect(renderer, &l1)
		sdl.render_fill_rect(renderer, &l2)
		sdl.render_fill_rect(renderer, &l3)
		sdl.render_fill_rect(renderer, &l4)
		return
	}

	// Upright walking turtle
	// Green Shell dome
	sdl.set_render_draw_color(renderer, 50, 180, 50, 255)
	shell := sdl.Rect{ x: x + 4, y: y + 4, w: w - 8, h: h - 10 }
	sdl.render_fill_rect(renderer, &shell)

	// Shell highlights
	sdl.set_render_draw_color(renderer, 120, 230, 90, 255)
	sh_top := sdl.Rect{ x: x + 8, y: y + 6, w: w - 16, h: 4 }
	sdl.render_fill_rect(renderer, &sh_top)

	// Head
	hx := if facing_right { x + w - 8 } else { x }
	sdl.set_render_draw_color(renderer, 220, 170, 70, 255)
	head := sdl.Rect{ x: hx, y: y + 8, w: 8, h: 10 }
	sdl.render_fill_rect(renderer, &head)

	// Turtle Eye
	eye_x := if facing_right { hx + 5 } else { hx + 1 }
	sdl.set_render_draw_color(renderer, 10, 10, 10, 255)
	eye := sdl.Rect{ x: eye_x, y: y + 10, w: 2, h: 3 }
	sdl.render_fill_rect(renderer, &eye)

	// Walking Feet
	sdl.set_render_draw_color(renderer, 220, 170, 70, 255)
	foot1 := sdl.Rect{ x: x + 4, y: y + h - 6, w: 7, h: 6 }
	foot2 := sdl.Rect{ x: x + w - 11, y: y + h - 6, w: 7, h: 6 }
	sdl.render_fill_rect(renderer, &foot1)
	sdl.render_fill_rect(renderer, &foot2)
}

fn render_sidestepper(renderer &sdl.Renderer, x int, y int, w int, h int, state EnemyState, stun_timer f32, angry int, tex &sdl.Texture) {
	is_flipped := state == .stunned || state == .recovering || state == .kicked
	is_angry := state == .angry || angry > 0
	is_recovering := state == .recovering
	flash := is_recovering && (int(stun_timer * 15.0) % 2 == 0)

	if tex != unsafe { nil } {
		col_x := if is_flipped {
			5 * 32
		} else if is_angry {
			4 * 32
		} else {
			3 * 32
		}
		src := sdl.Rect{x: col_x, y: 64, w: 32, h: 32}
		dst := sdl.Rect{x: x, y: y, w: w, h: h}
		sdl.render_copy(renderer, tex, &src, &dst)
		return
	}

	crab_color := if is_angry {
		Color{ r: 240, g: 30, b: 30, a: 255 }
	} else if flash {
		Color{ r: 255, g: 255, b: 255, a: 255 }
	} else {
		Color{ r: 240, g: 120, b: 20, a: 255 }
	}

	if is_flipped {
		// Flipped crab shell
		sdl.set_render_draw_color(renderer, 230, 200, 120, 255)
		belly := sdl.Rect{ x: x + 2, y: y + 10, w: w - 4, h: h - 10 }
		sdl.render_fill_rect(renderer, &belly)

		// Twitching claws pointing UP
		sdl.set_render_draw_color(renderer, crab_color.r, crab_color.g, crab_color.b, 255)
		c1 := sdl.Rect{ x: x + 2, y: y + 2, w: 6, h: 8 }
		c2 := sdl.Rect{ x: x + w - 8, y: y + 2, w: 6, h: 8 }
		sdl.render_fill_rect(renderer, &c1)
		sdl.render_fill_rect(renderer, &c2)
		return
	}

	// Crab Main Body
	sdl.set_render_draw_color(renderer, crab_color.r, crab_color.g, crab_color.b, 255)
	body := sdl.Rect{ x: x + 4, y: y + 8, w: w - 8, h: h - 14 }
	sdl.render_fill_rect(renderer, &body)

	// Crab Large Snapping Claws (Left & Right)
	claw_l := sdl.Rect{ x: x, y: y + 2, w: 7, h: 10 }
	claw_r := sdl.Rect{ x: x + w - 7, y: y + 2, w: 7, h: 10 }
	sdl.render_fill_rect(renderer, &claw_l)
	sdl.render_fill_rect(renderer, &claw_r)

	// Eyestalks
	sdl.set_render_draw_color(renderer, 255, 255, 255, 255)
	eye1 := sdl.Rect{ x: x + 8, y: y + 4, w: 4, h: 5 }
	eye2 := sdl.Rect{ x: x + w - 12, y: y + 4, w: 4, h: 5 }
	sdl.render_fill_rect(renderer, &eye1)
	sdl.render_fill_rect(renderer, &eye2)

	// Pupils
	sdl.set_render_draw_color(renderer, 10, 10, 10, 255)
	pup1 := sdl.Rect{ x: x + 9, y: y + 5, w: 2, h: 3 }
	pup2 := sdl.Rect{ x: x + w - 11, y: y + 5, w: 2, h: 3 }
	sdl.render_fill_rect(renderer, &pup1)
	sdl.render_fill_rect(renderer, &pup2)

	// Skittering Legs
	sdl.set_render_draw_color(renderer, crab_color.r, crab_color.g, crab_color.b, 255)
	for lx := 0; lx < 4; lx++ {
		leg := sdl.Rect{ x: x + 3 + lx * 6, y: y + h - 6, w: 3, h: 6 }
		sdl.render_fill_rect(renderer, &leg)
	}
}

fn render_fighterfly(renderer &sdl.Renderer, x int, y int, w int, h int, state EnemyState, stun_timer f32, hop_timer f32, tex &sdl.Texture) {
	is_flipped := state == .stunned || state == .recovering || state == .kicked
	is_recovering := state == .recovering
	flash := is_recovering && (int(stun_timer * 15.0) % 2 == 0)

	if tex != unsafe { nil } {
		col_x := if is_flipped {
			0
		} else if int(hop_timer * 10.0) % 2 == 0 {
			0
		} else {
			32
		}
		src := sdl.Rect{x: col_x, y: 96, w: 32, h: 32}
		dst := sdl.Rect{x: x, y: y, w: w, h: h}
		sdl.render_copy(renderer, tex, &src, &dst)
		return
	}

	if is_flipped {
		sdl.set_render_draw_color(renderer, 150, 100, 220, 255)
		body := sdl.Rect{ x: x + 4, y: y + 10, w: w - 8, h: h - 10 }
		sdl.render_fill_rect(renderer, &body)

		// Twitching legs UP
		leg_c := if flash { Color{ r: 255, g: 255, b: 255, a: 255 } } else { Color{ r: 230, g: 180, b: 40, a: 255 } }
		sdl.set_render_draw_color(renderer, leg_c.r, leg_c.g, leg_c.b, 255)
		l1 := sdl.Rect{ x: x + 6, y: y + 2, w: 4, h: 8 }
		l2 := sdl.Rect{ x: x + w - 10, y: y + 2, w: 4, h: 8 }
		sdl.render_fill_rect(renderer, &l1)
		sdl.render_fill_rect(renderer, &l2)
		return
	}

	// Fighter Fly Body (Purple / Blue)
	sdl.set_render_draw_color(renderer, 80, 70, 200, 255)
	body := sdl.Rect{ x: x + 6, y: y + 8, w: w - 12, h: h - 14 }
	sdl.render_fill_rect(renderer, &body)

	// Flapping Translucent Wings
	sdl.set_render_draw_color(renderer, 200, 220, 255, 220)
	wing_y := if int(hop_timer * 20.0) % 2 == 0 { y + 2 } else { y + 6 }
	w_left := sdl.Rect{ x: x, y: wing_y, w: 7, h: 6 }
	w_right := sdl.Rect{ x: x + w - 7, y: wing_y, w: 7, h: 6 }
	sdl.render_fill_rect(renderer, &w_left)
	sdl.render_fill_rect(renderer, &w_right)

	// Large Red Bug Eyes
	sdl.set_render_draw_color(renderer, 240, 40, 40, 255)
	e1 := sdl.Rect{ x: x + 7, y: y + 7, w: 4, h: 5 }
	e2 := sdl.Rect{ x: x + w - 11, y: y + 7, w: 4, h: 5 }
	sdl.render_fill_rect(renderer, &e1)
	sdl.render_fill_rect(renderer, &e2)

	// Hopping Yellow Feet
	sdl.set_render_draw_color(renderer, 240, 210, 40, 255)
	f1 := sdl.Rect{ x: x + 6, y: y + h - 6, w: 5, h: 6 }
	f2 := sdl.Rect{ x: x + w - 11, y: y + h - 6, w: 5, h: 6 }
	sdl.render_fill_rect(renderer, &f1)
	sdl.render_fill_rect(renderer, &f2)
}

fn render_slipice(renderer &sdl.Renderer, x int, y int, w int, h int) {
	// Crystal diamond shape
	sdl.set_render_draw_color(renderer, 140, 230, 255, 255)
	core := sdl.Rect{ x: x + 4, y: y + 4, w: w - 8, h: h - 8 }
	sdl.render_fill_rect(renderer, &core)

	// Bright frosted center
	sdl.set_render_draw_color(renderer, 255, 255, 255, 255)
	frost := sdl.Rect{ x: x + 8, y: y + 8, w: w - 16, h: h - 16 }
	sdl.render_fill_rect(renderer, &frost)
}

fn render_fireball(renderer &sdl.Renderer, x int, y int, w int, h int) {
	// Outer fiery orange corona
	sdl.set_render_draw_color(renderer, 255, 100, 20, 255)
	corona := sdl.Rect{ x: x + 2, y: y + 2, w: w - 4, h: h - 4 }
	sdl.render_fill_rect(renderer, &corona)

	// Inner yellow hot core
	sdl.set_render_draw_color(renderer, 255, 240, 40, 255)
	core := sdl.Rect{ x: x + 6, y: y + 6, w: w - 12, h: h - 12 }
	sdl.render_fill_rect(renderer, &core)

	// Center white flame
	sdl.set_render_draw_color(renderer, 255, 255, 255, 255)
	center := sdl.Rect{ x: x + 10, y: y + 10, w: w - 20, h: h - 20 }
	sdl.render_fill_rect(renderer, &center)
}

fn render_players(renderer &sdl.Renderer, mut g MarioBrosGame, ox int, oy int, tex &sdl.Texture) {
	for p in g.players {
		px := int(p.x) + ox
		py := int(p.y) + oy
		pw := int(p.width)
		ph := int(p.height)

		// Invulnerability flashing
		if p.invuln_timer > 0.0 && (int(p.invuln_timer * 18.0) % 2 == 0) {
			continue
		}

		is_mario := p.id == 1

		if tex != unsafe { nil } {
			// Super Star Sparkle Aura
			if p.star_timer > 0.0 {
				ticks := sdl.get_ticks()
				for s := 0; s < 4; s++ {
					ang := f64(ticks) * 0.01 + f64(s) * (math.pi / 2.0)
					sx := px + pw / 2 + int(math.cos(ang) * 20.0)
					sy := py + ph / 2 + int(math.sin(ang) * 20.0)
					sdl.set_render_draw_color(renderer, 255, 235, 60, 255)
					sdl.render_fill_rect(renderer, &sdl.Rect{x: sx - 2, y: sy - 2, w: 4, h: 4})
				}
			}

			// Super Jump Charging Electric Aura
			if p.is_charged {
				sdl.set_render_draw_color(renderer, 255, 235, 40, 200)
				aura := sdl.Rect{x: px - 4, y: py - 4, w: pw + 8, h: ph + 8}
				sdl.render_draw_rect(renderer, &aura)
			}

			row_y := if is_mario { 0 } else { 32 }
			anim_col := if p.is_dead {
				0
			} else if p.is_jumping || !p.is_grounded {
				3
			} else if p.is_skidding {
				0
			} else if math.abs(p.vx) > 10.0 {
				int(sdl.get_ticks() / 120) % 2 + 1
			} else {
				0
			}
			src := sdl.Rect{x: anim_col * 32, y: row_y, w: 32, h: 32}
			dst := sdl.Rect{x: px, y: py, w: pw, h: ph}
			flip := if p.facing_right { sdl.RendererFlip.none } else { sdl.RendererFlip.horizontal }
			sdl.render_copy_ex(renderer, tex, &src, &dst, 0.0, unsafe { nil }, flip)
			continue
		}

		mut shirt_c := if is_mario { Color{ r: 240, g: 30, b: 30, a: 255 } } else { Color{ r: 40, g: 200, b: 40, a: 255 } }
		mut cap_c := if is_mario { Color{ r: 240, g: 30, b: 30, a: 255 } } else { Color{ r: 40, g: 200, b: 40, a: 255 } }
		mut overalls_c := if is_mario { Color{ r: 30, g: 90, b: 230, a: 255 } } else { Color{ r: 240, g: 240, b: 240, a: 255 } }
		skin_c := Color{ r: 255, g: 195, b: 140, a: 255 }
		brown_c := Color{ r: 120, g: 60, b: 20, a: 255 }

		// Fire Flower Costume (White Cap/Shirt, Red/Green Overalls)
		if p.has_fire {
			cap_c = Color{ r: 255, g: 255, b: 255, a: 255 }
			shirt_c = Color{ r: 255, g: 255, b: 255, a: 255 }
			overalls_c = if is_mario { Color{ r: 240, g: 30, b: 30, a: 255 } } else { Color{ r: 40, g: 200, b: 40, a: 255 } }
		}

		// Super Star Rainbow Palette cycling
		if p.star_timer > 0.0 {
			ticks := sdl.get_ticks()
			hue_phase := int((ticks / 70) % 6)
			rainbow := [
				Color{ r: 255, g: 60, b: 60, a: 255 },
				Color{ r: 255, g: 180, b: 40, a: 255 },
				Color{ r: 255, g: 240, b: 40, a: 255 },
				Color{ r: 60, g: 240, b: 60, a: 255 },
				Color{ r: 60, g: 180, b: 255, a: 255 },
				Color{ r: 220, g: 60, b: 255, a: 255 },
			]
			cap_c = rainbow[hue_phase]
			shirt_c = rainbow[(hue_phase + 2) % 6]
			overalls_c = rainbow[(hue_phase + 4) % 6]
		}

		// Super Jump Charging Aura
		if p.is_charged {
			sdl.set_render_draw_color(renderer, 255, 240, 60, 180)
			aura := sdl.Rect{ x: px - 3, y: py - 3, w: pw + 6, h: ph + 6 }
			sdl.render_fill_rect(renderer, &aura)
		}

		// Dead spinning pose
		if p.is_dead {
			// Cap
			sdl.set_render_draw_color(renderer, cap_c.r, cap_c.g, cap_c.b, 255)
			c_rect := sdl.Rect{ x: px + 4, y: py + 22, w: pw - 8, h: 8 }
			sdl.render_fill_rect(renderer, &c_rect)
			// Face
			sdl.set_render_draw_color(renderer, skin_c.r, skin_c.g, skin_c.b, 255)
			f_rect := sdl.Rect{ x: px + 6, y: py + 14, w: pw - 12, h: 8 }
			sdl.render_fill_rect(renderer, &f_rect)
			// Overalls
			sdl.set_render_draw_color(renderer, overalls_c.r, overalls_c.g, overalls_c.b, 255)
			o_rect := sdl.Rect{ x: px + 4, y: py + 4, w: pw - 8, h: 10 }
			sdl.render_fill_rect(renderer, &o_rect)
			continue
		}

		// 1. Cap & Visor
		sdl.set_render_draw_color(renderer, cap_c.r, cap_c.g, cap_c.b, 255)
		cap_main := sdl.Rect{ x: px + 4, y: py, w: pw - 8, h: 7 }
		sdl.render_fill_rect(renderer, &cap_main)

		visor_x := if p.facing_right { px + pw - 8 } else { px }
		visor := sdl.Rect{ x: visor_x, y: py + 4, w: 8, h: 4 }
		sdl.render_fill_rect(renderer, &visor)

		// 2. Head / Face
		sdl.set_render_draw_color(renderer, skin_c.r, skin_c.g, skin_c.b, 255)
		face := sdl.Rect{ x: px + 6, y: py + 7, w: pw - 12, h: 9 }
		sdl.render_fill_rect(renderer, &face)

		// Nose
		nose_x := if p.facing_right { px + pw - 6 } else { px + 2 }
		nose := sdl.Rect{ x: nose_x, y: py + 9, w: 5, h: 4 }
		sdl.render_fill_rect(renderer, &nose)

		// Mustache & Eye
		sdl.set_render_draw_color(renderer, brown_c.r, brown_c.g, brown_c.b, 255)
		mustache_x := if p.facing_right { px + pw - 9 } else { px + 3 }
		mustache := sdl.Rect{ x: mustache_x, y: py + 12, w: 7, h: 4 }
		sdl.render_fill_rect(renderer, &mustache)

		eye_x := if p.facing_right { px + pw - 9 } else { px + 7 }
		eye := sdl.Rect{ x: eye_x, y: py + 8, w: 2, h: 3 }
		sdl.render_fill_rect(renderer, &eye)

		// 3. Shirt & Torso
		sdl.set_render_draw_color(renderer, shirt_c.r, shirt_c.g, shirt_c.b, 255)
		shirt := sdl.Rect{ x: px + 4, y: py + 16, w: pw - 8, h: 8 }
		sdl.render_fill_rect(renderer, &shirt)

		// Raised arm in jumping pose
		if p.is_jumping {
			arm_x := if p.facing_right { px + pw - 5 } else { px }
			arm := sdl.Rect{ x: arm_x, y: py + 8, w: 5, h: 10 }
			sdl.render_fill_rect(renderer, &arm)
			// White Glove
			sdl.set_render_draw_color(renderer, 255, 255, 255, 255)
			glove := sdl.Rect{ x: arm_x, y: py + 4, w: 5, h: 5 }
			sdl.render_fill_rect(renderer, &glove)
		}

		// 4. Overalls
		sdl.set_render_draw_color(renderer, overalls_c.r, overalls_c.g, overalls_c.b, 255)
		overalls := sdl.Rect{ x: px + 5, y: py + 20, w: pw - 10, h: 10 }
		sdl.render_fill_rect(renderer, &overalls)

		// Yellow overall buttons
		sdl.set_render_draw_color(renderer, 255, 230, 40, 255)
		btn1 := sdl.Rect{ x: px + 7, y: py + 21, w: 2, h: 2 }
		btn2 := sdl.Rect{ x: px + pw - 9, y: py + 21, w: 2, h: 2 }
		sdl.render_fill_rect(renderer, &btn1)
		sdl.render_fill_rect(renderer, &btn2)

		// 5. Shoes (Animated running / jumping / skidding)
		sdl.set_render_draw_color(renderer, brown_c.r, brown_c.g, brown_c.b, 255)
		if p.is_jumping {
			shoe1 := sdl.Rect{ x: px + 3, y: py + ph - 8, w: 8, h: 6 }
			shoe2 := sdl.Rect{ x: px + pw - 11, y: py + ph - 6, w: 8, h: 6 }
			sdl.render_fill_rect(renderer, &shoe1)
			sdl.render_fill_rect(renderer, &shoe2)
		} else if p.walk_frame % 2 == 1 {
			shoe1 := sdl.Rect{ x: px + 2, y: py + ph - 6, w: 9, h: 6 }
			shoe2 := sdl.Rect{ x: px + pw - 9, y: py + ph - 8, w: 8, h: 6 }
			sdl.render_fill_rect(renderer, &shoe1)
			sdl.render_fill_rect(renderer, &shoe2)
		} else {
			shoe1 := sdl.Rect{ x: px + 4, y: py + ph - 6, w: 8, h: 6 }
			shoe2 := sdl.Rect{ x: px + pw - 12, y: py + ph - 6, w: 8, h: 6 }
			sdl.render_fill_rect(renderer, &shoe1)
			sdl.render_fill_rect(renderer, &shoe2)
		}
	}
}

fn render_particles(renderer &sdl.Renderer, mut g MarioBrosGame, ox int, oy int) {
	for pt in g.particles {
		if !pt.active {
			continue
		}
		sdl.set_render_draw_color(renderer, pt.color.r, pt.color.g, pt.color.b, pt.color.a)
		rect := sdl.Rect{
			x: int(pt.x) + ox
			y: int(pt.y) + oy
			w: int(pt.size)
			h: int(pt.size)
		}
		sdl.render_fill_rect(renderer, &rect)
	}
}

fn render_score_popups(renderer &sdl.Renderer, mut g MarioBrosGame, ox int, oy int) {
	for sp in g.score_popups {
		if !sp.active {
			continue
		}
		draw_text_centered_shadow(renderer, int(sp.x) + ox, int(sp.y) + oy, sp.text, 2,
			sp.color, Color{ r: 0, g: 0, b: 0, a: 255 })
	}
}

fn render_gameplay_banners(renderer &sdl.Renderer, mut g MarioBrosGame) {
	// Phase Ready Banner
	if g.phase_banner_timer > 0.0 && g.state == .playing {
		banner_text := 'PHASE ${g.phase} - READY!'
		draw_text_centered_shadow(renderer, 400, 240, banner_text, 3,
			Color{ r: 255, g: 235, b: 60, a: 255 }, Color{ r: 20, g: 20, b: 20, a: 255 })
	}

	// Dynamic Combo Banner
	if g.combo_banner_timer > 0.0 && g.combo_banner != '' {
		draw_text_centered_shadow(renderer, 400, 200, g.combo_banner, 2,
			Color{ r: 255, g: 140, b: 40, a: 255 }, Color{ r: 10, g: 10, b: 10, a: 255 })
	}
}

fn render_hud(renderer &sdl.Renderer, mut g MarioBrosGame) {
	// Top Arcade Score Bar
	// P1 Score (Mario)
	p1_score := if g.players.len > 0 { g.players[0].score } else { 0 }
	draw_text_shadow(renderer, 40, 20, 'MARIO', 2, Color{ r: 240, g: 60, b: 60, a: 255 }, Color{ r: 20, g: 20, b: 20, a: 255 })
	draw_text_shadow(renderer, 40, 42, '${p1_score:06d}', 2, Color{ r: 255, g: 255, b: 255, a: 255 }, Color{ r: 20, g: 20, b: 20, a: 255 })

	// Top High Score
	draw_text_centered_shadow(renderer, 400, 20, 'TOP', 2, Color{ r: 240, g: 220, b: 40, a: 255 }, Color{ r: 20, g: 20, b: 20, a: 255 })
	draw_text_centered_shadow(renderer, 400, 42, '${g.high_score:06d}', 2, Color{ r: 255, g: 255, b: 255, a: 255 }, Color{ r: 20, g: 20, b: 20, a: 255 })

	// P2 Score (Luigi)
	p2_score := if g.players.len > 1 { g.players[1].score } else { 0 }
	draw_text_shadow(renderer, 660, 20, 'LUIGI', 2, Color{ r: 60, g: 220, b: 60, a: 255 }, Color{ r: 20, g: 20, b: 20, a: 255 })
	draw_text_shadow(renderer, 660, 42, '${p2_score:06d}', 2, Color{ r: 255, g: 255, b: 255, a: 255 }, Color{ r: 20, g: 20, b: 20, a: 255 })

	// Phase number indicator
	if g.state == .bonus_phase {
		timer_color := if g.bonus_timer < 5.0 { Color{ r: 255, g: 40, b: 40, a: 255 } } else { Color{ r: 255, g: 140, b: 40, a: 255 } }
		draw_text_centered_shadow(renderer, 400, 68, 'BONUS PHASE  TIME: ${int(g.bonus_timer)}', 2,
			timer_color, Color{ r: 0, g: 0, b: 0, a: 255 })
	} else {
		draw_text_centered_shadow(renderer, 400, 68, 'PHASE ${g.phase:02d}', 2,
			Color{ r: 120, g: 200, b: 255, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	}

	// Lives Counter Icons at Bottom
	if g.players.len > 0 {
		p1_lives := g.players[0].lives
		draw_text(renderer, 30, 568, 'M:', 2, Color{ r: 240, g: 60, b: 60, a: 255 })
		for i in 0 .. p1_lives {
			draw_mini_mario_cap(renderer, 70 + i * 22, 566, Color{ r: 240, g: 40, b: 40, a: 255 })
		}
	}

	if g.players.len > 1 {
		p2_lives := g.players[1].lives
		draw_text(renderer, 670, 568, 'L:', 2, Color{ r: 40, g: 220, b: 40, a: 255 })
		for i in 0 .. p2_lives {
			draw_mini_mario_cap(renderer, 710 + i * 22, 566, Color{ r: 40, g: 220, b: 40, a: 255 })
		}
	}
}

fn draw_mini_mario_cap(renderer &sdl.Renderer, x int, y int, color Color) {
	sdl.set_render_draw_color(renderer, color.r, color.g, color.b, 255)
	c_rect := sdl.Rect{ x: x, y: y, w: 14, h: 6 }
	sdl.render_fill_rect(renderer, &c_rect)
	v_rect := sdl.Rect{ x: x + 4, y: y + 6, w: 12, h: 4 }
	sdl.render_fill_rect(renderer, &v_rect)
}

fn render_crt_overlay(renderer &sdl.Renderer) {
	sdl.set_render_draw_blend_mode(renderer, .blend)
	// Subtle CRT horizontal scanlines
	sdl.set_render_draw_color(renderer, 0, 0, 0, 28)
	for y := 0; y < 600; y += 3 {
		line := sdl.Rect{ x: 0, y: y, w: 800, h: 1 }
		sdl.render_fill_rect(renderer, &line)
	}

	// CRT Vignette corner borders
	sdl.set_render_draw_color(renderer, 0, 0, 0, 80)
	top_bar := sdl.Rect{ x: 0, y: 0, w: 800, h: 2 }
	bot_bar := sdl.Rect{ x: 0, y: 598, w: 800, h: 2 }
	left_bar := sdl.Rect{ x: 0, y: 0, w: 2, h: 600 }
	right_bar := sdl.Rect{ x: 798, y: 0, w: 2, h: 600 }
	sdl.render_fill_rect(renderer, &top_bar)
	sdl.render_fill_rect(renderer, &bot_bar)
	sdl.render_fill_rect(renderer, &left_bar)
	sdl.render_fill_rect(renderer, &right_bar)
}

fn render_title_screen(renderer &sdl.Renderer, mut g MarioBrosGame) {
	// Dark semi-transparent backdrop
	sdl.set_render_draw_blend_mode(renderer, .blend)
	sdl.set_render_draw_color(renderer, 5, 8, 16, 220)
	scrim := sdl.Rect{ x: 0, y: 0, w: 800, h: 600 }
	sdl.render_fill_rect(renderer, &scrim)

	// Giant Arcade Marquee Title with Golden Trim
	draw_text_centered_shadow(renderer, 400, 75, 'MARIO BROS.', 5,
		Color{ r: 255, g: 45, b: 45, a: 255 }, Color{ r: 245, g: 220, b: 30, a: 255 })

	draw_text_centered_shadow(renderer, 400, 135, 'ARCADE 1983 RECREATION', 2,
		Color{ r: 60, g: 210, b: 255, a: 255 }, Color{ r: 10, g: 20, b: 40, a: 255 })

	// Mode Selector
	p1_c := if g.mode == .single_player { Color{ r: 255, g: 240, b: 40, a: 255 } } else { Color{ r: 160, g: 160, b: 160, a: 255 } }
	p2_c := if g.mode == .two_players { Color{ r: 255, g: 240, b: 40, a: 255 } } else { Color{ r: 160, g: 160, b: 160, a: 255 } }

	cursor_y := if g.mode == .single_player { 210 } else { 250 }
	draw_text_shadow(renderer, 240, cursor_y, '>', 2, Color{ r: 255, g: 50, b: 50, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })

	draw_text_shadow(renderer, 280, 210, '1 PLAYER GAME   (1)', 2, p1_c, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_shadow(renderer, 280, 250, '2 PLAYERS GAME  (2)', 2, p2_c, Color{ r: 0, g: 0, b: 0, a: 255 })

	draw_text_centered_shadow(renderer, 400, 305, 'PRESS SPACE OR ENTER TO START', 2,
		Color{ r: 255, g: 255, b: 255, a: 255 }, Color{ r: 20, g: 20, b: 20, a: 255 })

	// Controls Summary Box
	draw_text_centered_shadow(renderer, 400, 365, 'CONTROLS & SHORTCUTS', 2,
		Color{ r: 255, g: 185, b: 45, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 395, 'PLAYER 1 (MARIO): A / D MOVE | SPACE / W JUMP', 1,
		Color{ r: 230, g: 230, b: 230, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 420, 'PLAYER 2 (LUIGI): J / L MOVE | I / UP JUMP', 1,
		Color{ r: 230, g: 230, b: 230, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 445, 'HIT PLATFORMS UNDERNEATH PESTS TO FLIP THEM!', 1,
		Color{ r: 110, g: 255, b: 130, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 470, 'HIT THE POW BLOCK IN EMERGENCIES (3 USES)', 1,
		Color{ r: 100, g: 210, b: 255, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 495, '[P] PAUSE  [M] MUTE  [C] CRT SCANLINES  [R] RESET  [F11] Fullscreen', 1,
		Color{ r: 255, g: 215, b: 110, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })

	draw_text_centered_shadow(renderer, 400, 560, '(C) 1983 NINTENDO ARCADE CLASSIC', 1,
		Color{ r: 150, g: 150, b: 160, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
}

fn render_paused_screen(renderer &sdl.Renderer) {
	sdl.set_render_draw_blend_mode(renderer, .blend)
	sdl.set_render_draw_color(renderer, 0, 0, 0, 190)
	scrim := sdl.Rect{ x: 0, y: 0, w: 800, h: 600 }
	sdl.render_fill_rect(renderer, &scrim)

	draw_text_centered_shadow(renderer, 400, 270, 'PAUSED', 4,
		Color{ r: 255, g: 230, b: 40, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 320, 'PRESS P TO RESUME', 2,
		Color{ r: 255, g: 255, b: 255, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
}

fn render_phase_clear_screen(renderer &sdl.Renderer, mut g MarioBrosGame) {
	sdl.set_render_draw_blend_mode(renderer, .blend)
	sdl.set_render_draw_color(renderer, 0, 0, 0, 180)
	scrim := sdl.Rect{ x: 0, y: 0, w: 800, h: 600 }
	sdl.render_fill_rect(renderer, &scrim)

	draw_text_centered_shadow(renderer, 400, 240, 'PHASE ${g.phase} CLEAR!', 4,
		Color{ r: 80, g: 255, b: 100, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 300, 'BONUS +1000 PTS', 2,
		Color{ r: 255, g: 230, b: 60, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 350, 'PRESS SPACE TO CONTINUE', 2,
		Color{ r: 255, g: 255, b: 255, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
}

fn render_game_over_screen(renderer &sdl.Renderer, mut g MarioBrosGame) {
	sdl.set_render_draw_blend_mode(renderer, .blend)
	sdl.set_render_draw_color(renderer, 0, 0, 0, 210)
	scrim := sdl.Rect{ x: 0, y: 0, w: 800, h: 600 }
	sdl.render_fill_rect(renderer, &scrim)

	p1_s := if g.players.len > 0 { g.players[0].score } else { 0 }
	draw_text_centered_shadow(renderer, 400, 230, 'GAME OVER', 5,
		Color{ r: 255, g: 40, b: 40, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 300, 'FINAL SCORE: ${p1_s}', 2,
		Color{ r: 255, g: 255, b: 255, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 360, 'PRESS SPACE TO RETRY', 2,
		Color{ r: 255, g: 230, b: 40, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
}
