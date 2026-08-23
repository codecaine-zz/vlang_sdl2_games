import math
import os
import sdl
import sdl.image

pub struct ContraTextureManager {
pub mut:
	sprite_texture &sdl.Texture = unsafe { nil }
}

pub fn (mut tm ContraTextureManager) init(renderer &sdl.Renderer) {
	_ = image.init(int(image.InitFlags.png))
	candidates := [
		'assets/sprites/contra.png',
		'./assets/sprites/contra.png',
		'../assets/sprites/contra.png',
		'contra/assets/sprites/contra.png',
	]
	for p in candidates {
		if os.exists(p) {
			surface := image.load(p.str)
			if surface != unsafe { nil } {
				tm.sprite_texture = sdl.create_texture_from_surface(renderer, surface)
				sdl.free_surface(surface)
				if tm.sprite_texture != unsafe { nil } {
					println('Contra Texture Loaded Successfully: ' + p)
					return
				}
			}
		}
	}
}

pub fn render_game(renderer &sdl.Renderer, game &ContraGame, win_w int, win_h int, tex &sdl.Texture) {
	// Camera offset with Screen Shake
	cx := game.cam_x + game.shake_x
	cy := game.cam_y + game.shake_y

	// 1. Stage-Specific Multi-Layer Background
	render_stage_background(renderer, game, win_w, win_h, cx)

	// 2. Platforms & Terrain
	render_platforms(renderer, game, cx, cy)

	// 3. Exploding Bridges
	render_bridges(renderer, game, cx, cy)

	// 4. Multi-Part Destructible Boss
	if game.boss.active {
		render_boss(renderer, game, cx, cy)
	}

	// 5. Enemies & Flying Capsules & PowerUps
	render_enemies(renderer, game, cx, cy)
	render_capsules_and_powerups(renderer, game, cx, cy, tex)

	// 6. Glowing Bullets & VFX
	render_bullets(renderer, game, cx, cy)
	render_particles(renderer, game, cx, cy)

	// 7. Commando Players (Bill & Lance)
	render_players(renderer, game, cx, cy, tex)

	// 8. Water Foregrounds
	render_water_foreground(renderer, game, cx, cy)

	// 9. Floating Combat Pop Text
	render_pop_texts(renderer, game, cx, cy)

	// 10. Modern Glassmorphic HUD & Overlays
	render_hud(renderer, game, win_w)
	render_screen_overlays(renderer, game, win_w, win_h)
}

fn render_stage_background(renderer &sdl.Renderer, game &ContraGame, win_w int, win_h int, cx f32) {
	def := game.stage_data.def

	match def.stage_type {
		.side_scroll {
			// Stage 1 Jungle: Night Sky, Moon, Parallax Mountains, Palm Foliage
			sdl.set_render_draw_color(renderer, 8, 16, 32, 255)
			sdl.render_clear(renderer)

			// Glowing Moon
			draw_filled_circle(renderer, win_w - 140, 85, 28, 240, 245, 255)
			draw_filled_circle(renderer, win_w - 140, 85, 34, 180, 200, 240)

			// Distant Mountains (Parallax 0.2)
			para_mountains := cx * 0.2
			sdl.set_render_draw_color(renderer, 18, 36, 62, 255)
			for i := -1; i < 7; i++ {
				mx := int(f32(i * 300) - f32(math.fmod(f64(para_mountains), 300.0)))
				fill_triangle(renderer, mx, 380, mx + 150, 180, mx + 300, 380)
			}

			// Midground Palm Trees & Jungle Canopies (Parallax 0.55)
			para_palms := cx * 0.55
			sdl.set_render_draw_color(renderer, 12, 65, 35, 255)
			for i := -1; i < 9; i++ {
				tx := int(f32(i * 190) - f32(math.fmod(f64(para_palms), 190.0)))
				sway := int(f32(math.sin(f64(game.global_time * 2.0 + f32(i)))) * 6.0)
				sdl.render_draw_line(renderer, tx, 420, tx + sway, 270)
				draw_filled_circle(renderer, tx + sway, 260, 32, 16, 85, 45)
				draw_filled_circle(renderer, tx + sway - 18, 270, 22, 14, 75, 40)
				draw_filled_circle(renderer, tx + sway + 18, 270, 22, 14, 75, 40)
			}
		}
		.base_3d {
			// Stage 2 3D Base: High-Tech Cyber Corridor with Illuminated Conduits
			sdl.set_render_draw_color(renderer, 5, 8, 18, 255)
			sdl.render_clear(renderer)

			mid_x := win_w / 2
			mid_y := win_h / 2

			// Vanishing Perspective Lines
			sdl.set_render_draw_color(renderer, 20, 80, 160, 255)
			sdl.render_draw_line(renderer, 40, 40, mid_x, mid_y)
			sdl.render_draw_line(renderer, win_w - 40, 40, mid_x, mid_y)
			sdl.render_draw_line(renderer, 40, win_h - 40, mid_x, mid_y)
			sdl.render_draw_line(renderer, win_w - 40, win_h - 40, mid_x, mid_y)

			// Animated Depth Laser Rings
			for d := 1; d <= 5; d++ {
				depth_scale := f32(d) / 5.0
				w := int(f32(win_w - 80) * depth_scale)
				h := int(f32(win_h - 80) * depth_scale)
				rect := sdl.Rect{x: mid_x - w / 2, y: mid_y - h / 2, w: w, h: h}

				pulse := u8(120 + 90 * math.sin(f64(game.global_time * 6.0 + f32(d))))
				sdl.set_render_draw_color(renderer, 30, pulse, 240, 255)
				sdl.render_draw_rect(renderer, &rect)
			}
		}
		.vertical_scroll {
			// Stage 3 Waterfall: Vertical Rock Cliffs with White Water Torrent
			sdl.set_render_draw_color(renderer, 25, 30, 42, 255)
			sdl.render_clear(renderer)

			// Massive Cascading Waterfall Column
			wf_rect := sdl.Rect{x: 290, y: 0, w: 260, h: win_h}
			sdl.set_render_draw_color(renderer, 30, 110, 210, 255)
			sdl.render_fill_rect(renderer, &wf_rect)

			// Water Torrent Strands
			sdl.set_render_draw_color(renderer, 180, 230, 255, 255)
			foam_y := int(game.global_time * 450.0) % 35
			for y := -35 + foam_y; y < win_h + 35; y += 35 {
				for x := 305; x < 535; x += 30 {
					sdl.render_draw_line(renderer, x, y, x + 10, y + 25)
				}
			}
		}
		.alien_lair {
			// Stage 4 Alien Lair: Dark Crimson Biomechanical Veins & Alien Ribs
			sdl.set_render_draw_color(renderer, 28, 6, 12, 255)
			sdl.render_clear(renderer)

			for i := -1; i < 8; i++ {
				rx := int(f32(i * 220) - f32(math.fmod(f64(cx * 0.4), 220.0)))
				pulse := u8(80 + 40 * math.sin(f64(game.global_time * 5.0 + f32(i))))
				draw_filled_circle(renderer, rx + 110, 190, 52, pulse, 15, 25)
			}
		}
	}
}

fn render_platforms(renderer &sdl.Renderer, game &ContraGame, cx f32, cy f32) {
	for plat in game.stage_data.platforms {
		if plat.is_water { continue }
		sx := int(plat.x - cx)
		sy := int(plat.y - cy)
		sw := int(plat.w)
		sh := int(plat.h)

		if sx + sw < -20 || sx > 860 || sy + sh < -20 || sy > 500 { continue }

		rect := sdl.Rect{x: sx, y: sy, w: sw, h: sh}

		match game.current_stage {
			1 {
				// Stage 1 Jungle: Soil & Grass Edge
				sdl.set_render_draw_color(renderer, 85, 48, 22, 255)
				sdl.render_fill_rect(renderer, &rect)
				top_rect := sdl.Rect{x: sx, y: sy, w: sw, h: 5}
				sdl.set_render_draw_color(renderer, 35, 190, 55, 255)
				sdl.render_fill_rect(renderer, &top_rect)
			}
			2 {
				// Stage 2 Base: Tech Grid Ledges
				sdl.set_render_draw_color(renderer, 45, 55, 75, 255)
				sdl.render_fill_rect(renderer, &rect)
				top_rect := sdl.Rect{x: sx, y: sy, w: sw, h: 4}
				sdl.set_render_draw_color(renderer, 80, 180, 255, 255)
				sdl.render_fill_rect(renderer, &top_rect)
			}
			3 {
				// Stage 3 Waterfall: Mountain Stone
				sdl.set_render_draw_color(renderer, 75, 80, 95, 255)
				sdl.render_fill_rect(renderer, &rect)
				top_rect := sdl.Rect{x: sx, y: sy, w: sw, h: 5}
				sdl.set_render_draw_color(renderer, 150, 160, 180, 255)
				sdl.render_fill_rect(renderer, &top_rect)
			}
			else {
				// Stage 4 Alien Lair: Organic Bone Ledges
				sdl.set_render_draw_color(renderer, 130, 35, 55, 255)
				sdl.render_fill_rect(renderer, &rect)
				top_rect := sdl.Rect{x: sx, y: sy, w: sw, h: 6}
				sdl.set_render_draw_color(renderer, 230, 205, 185, 255)
				sdl.render_fill_rect(renderer, &top_rect)
			}
		}
	}
}

fn render_bridges(renderer &sdl.Renderer, game &ContraGame, cx f32, cy f32) {
	for seg in game.bridge_segments {
		if seg.exploded { continue }
		sx := int(seg.x - cx)
		sy := int(seg.y - cy)
		sw := int(seg.w)
		sh := int(seg.h)

		rect := sdl.Rect{x: sx, y: sy, w: sw, h: sh}
		sdl.set_render_draw_color(renderer, 165, 95, 35, 255)
		sdl.render_fill_rect(renderer, &rect)
		sdl.set_render_draw_color(renderer, 80, 40, 15, 255)
		for px := sx; px < sx + sw; px += 10 {
			sdl.render_draw_line(renderer, px, sy, px, sy + sh)
		}
	}
}

fn render_boss(renderer &sdl.Renderer, game &ContraGame, cx f32, cy f32) {
	boss := &game.boss
	sx := int(boss.x - cx)
	sy := int(boss.y - cy)

	for part in boss.parts {
		if part.destroyed { continue }
		px := sx + int(part.rel_x)
		py := sy + int(part.rel_y)
		pw := int(part.w)
		ph := int(part.h)

		rect := sdl.Rect{x: px - pw / 2, y: py - ph / 2, w: pw, h: ph}

		if boss.flash_timer > 0 {
			sdl.set_render_draw_color(renderer, 255, 255, 255, 255)
		} else if part.is_core {
			// Pulsing Core
			pulse := u8(180 + 75 * math.sin(f64(game.global_time * 10.0)))
			sdl.set_render_draw_color(renderer, pulse, 20, 40, 255)
		} else {
			sdl.set_render_draw_color(renderer, 175, 45, 45, 255)
		}
		sdl.render_fill_rect(renderer, &rect)
		sdl.set_render_draw_color(renderer, 255, 215, 0, 255)
		sdl.render_draw_rect(renderer, &rect)
	}
}

fn render_enemies(renderer &sdl.Renderer, game &ContraGame, cx f32, cy f32) {
	for e in game.enemies {
		if !e.active { continue }
		sx := int(e.x - cx)
		sy := int(e.y - cy)

		match e.enemy_type {
			.runner {
				rect := sdl.Rect{x: sx - 8, y: sy - 34, w: 16, h: 34}
				sdl.set_render_draw_color(renderer, 225, 40, 40, 255)
				sdl.render_fill_rect(renderer, &rect)
				draw_filled_circle(renderer, sx, sy - 38, 6, 255, 200, 160)
				gun_x := if e.facing_right { sx + 12 } else { sx - 12 }
				sdl.set_render_draw_color(renderer, 20, 20, 20, 255)
				sdl.render_draw_line(renderer, sx, sy - 24, gun_x, sy - 24)
			}
			.sniper {
				rect := sdl.Rect{x: sx - 9, y: sy - 32, w: 18, h: 32}
				sdl.set_render_draw_color(renderer, 40, 150, 60, 255)
				sdl.render_fill_rect(renderer, &rect)
				draw_filled_circle(renderer, sx, sy - 36, 6, 255, 200, 160)
				sdl.set_render_draw_color(renderer, 30, 30, 30, 255)
				sdl.render_draw_line(renderer, sx, sy - 22, sx - 16, sy - 22)
			}
			.turret {
				draw_filled_circle(renderer, sx, sy - 14, 16, 120, 130, 145)
				draw_filled_circle(renderer, sx, sy - 14, 9, 60, 70, 80)
				sdl.set_render_draw_color(renderer, 220, 40, 40, 255)
				sdl.render_draw_line(renderer, sx, sy - 14, sx - 22, sy - 14)
			}
			.scuba {
				draw_filled_circle(renderer, sx, sy - 10, 8, 45, 140, 195)
				sdl.set_render_draw_color(renderer, 255, 220, 0, 255)
				sdl.render_draw_line(renderer, sx - 4, sy - 10, sx + 4, sy - 10)
			}
			.barrel {
				draw_filled_circle(renderer, sx, sy - 12, 12, 185, 85, 25)
				draw_filled_circle(renderer, sx, sy - 12, 6, 255, 220, 50)
			}
			.facehugger {
				draw_filled_circle(renderer, sx, sy - 8, 8, 220, 175, 135)
				sdl.set_render_draw_color(renderer, 190, 60, 80, 255)
				sdl.render_draw_line(renderer, sx - 12, sy, sx + 12, sy)
			}
		}
	}
}

fn render_capsules_and_powerups(renderer &sdl.Renderer, game &ContraGame, cx f32, cy f32, tex &sdl.Texture) {
	// 1. Flying Falcon Blimp Capsules
	for cap in game.capsules {
		if !cap.active { continue }
		sx := int(cap.x - cx)
		sy := int(cap.y - cy)

		draw_filled_circle(renderer, sx, sy, 14, 225, 35, 35)
		draw_filled_circle(renderer, sx, sy, 8, 255, 255, 255)
		sdl.set_render_draw_color(renderer, 255, 215, 0, 255)
		sdl.render_draw_line(renderer, sx - 20, sy, sx + 20, sy)
	}

	// 2. Power-Up Letter Badges
	for item in game.powerups {
		if !item.active { continue }
		sx := int(item.x - cx)
		sy := int(item.y - cy)

		if tex != unsafe { nil } {
			col_x := match item.w_type {
				.machine_gun { 0 }
				.spread_gun { 64 }
				.laser { 128 }
				.fire_gun { 192 }
				.barrier { 256 }
				else { 0 }
			}
			src := sdl.Rect{x: col_x, y: 192, w: 64, h: 64}
			dst := sdl.Rect{x: sx - 12, y: sy - 12, w: 24, h: 24}
			sdl.render_copy(renderer, tex, &src, &dst)
			continue
		}

		// Metallic badge box
		rect := sdl.Rect{x: sx - 10, y: sy - 10, w: 20, h: 20}
		sdl.set_render_draw_color(renderer, 255, 50, 50, 255)
		sdl.render_fill_rect(renderer, &rect)
		sdl.set_render_draw_color(renderer, 255, 255, 255, 255)
		sdl.render_draw_rect(renderer, &rect)

		letter := match item.w_type {
			.machine_gun { 'M' }
			.spread_gun { 'S' }
			.laser { 'L' }
			.fire_gun { 'F' }
			.rapid { 'R' }
			.barrier { 'B' }
			else { 'M' }
		}
		draw_text(renderer, letter, sx - 4, sy - 4, 1, Color{r: 255, g: 255, b: 255})
	}
}

// Glowing Plasma Bullets and VFX
fn render_bullets(renderer &sdl.Renderer, game &ContraGame, cx f32, cy f32) {
	for b in game.bullets {
		sx := int(b.x - cx)
		sy := int(b.y - cy)

		if b.is_player {
			match b.w_type {
				.spread_gun {
					// Glowing red plasma orb with core
					draw_filled_circle(renderer, sx, sy, 6, 255, 45, 45)
					draw_filled_circle(renderer, sx, sy, 3, 255, 235, 200)
				}
				.laser {
					// Continuous high energy blue beam
					sdl.set_render_draw_color(renderer, 60, 210, 255, 255)
					sdl.render_draw_line(renderer, sx, sy, sx - int(b.vx * 0.04), sy - int(b.vy * 0.04))
					draw_filled_circle(renderer, sx, sy, 5, 255, 255, 255)
				}
				.fire_gun {
					// Whirling fireball cluster
					draw_filled_circle(renderer, sx, sy, 9, 255, 120, 10)
					draw_filled_circle(renderer, sx, sy, 5, 255, 240, 50)
				}
				else {
					// Machine gun / Normal bullet
					draw_filled_circle(renderer, sx, sy, 4, 255, 240, 120)
				}
			}
		} else {
			// Enemy red plasma pellet
			draw_filled_circle(renderer, sx, sy, 5, 255, 40, 40)
			draw_filled_circle(renderer, sx, sy, 2, 255, 220, 220)
		}
	}
}

fn render_particles(renderer &sdl.Renderer, game &ContraGame, cx f32, cy f32) {
	for p in game.particles {
		sx := int(p.x - cx)
		sy := int(p.y - cy)
		sz := int(p.size)
		rect := sdl.Rect{x: sx - sz / 2, y: sy - sz / 2, w: sz, h: sz}
		sdl.set_render_draw_color(renderer, p.r, p.g, p.b, 255)
		sdl.render_fill_rect(renderer, &rect)
	}
}

// Commando Sprites (Bill & Lance)
fn render_players(renderer &sdl.Renderer, game &ContraGame, cx f32, cy f32, tex &sdl.Texture) {
	for p in game.players {
		if p.state == .dead && p.lives <= 0 { continue }
		if p.invuln_timer > 0 && int(p.invuln_timer * 15.0) % 2 == 0 { continue }

		sx := int(p.x - cx)
		sy := int(p.y - cy)

		bandanna_color := if p.id == 1 { Color{r: 40, g: 130, b: 250} } else { Color{r: 250, g: 50, b: 50} }
		pants_color := if p.id == 1 { Color{r: 30, g: 75, b: 170} } else { Color{r: 170, g: 30, b: 30} }
		skin_color := Color{r: 255, g: 200, b: 155}

		// Barrier rainbow aura
		if p.barrier_timer > 0 {
			shield_col := u8(180 + 75 * math.sin(f64(game.global_time * 14.0)))
			draw_filled_circle(renderer, sx, sy - 18, 28, shield_col, 255, 110)
		}

		if tex != unsafe { nil } {
			row_y := if p.id == 1 { 0 } else { 64 }
			col_x := match p.state {
				.running { (1 + (int(game.global_time * 8.0) % 2)) * 64 }
				.prone, .crouching { 256 }
				.jumping {
					if p.aim_y < -0.3 { 192 } // Aim up in air
					else if p.aim_y > 0.3 { 384 } // Aim down in air
					else { 320 } // Somersault ball
				}
				.dead { 448 }
				else {
					if p.aim_y < -0.3 { 192 }
					else { 0 }
				}
			}
			src := sdl.Rect{x: col_x, y: row_y, w: 64, h: 64}
			dst := sdl.Rect{x: sx - 16, y: sy - 38, w: 32, h: 38}
			flip := if p.facing_right { sdl.RendererFlip.none } else { sdl.RendererFlip.horizontal }
			sdl.render_copy_ex(renderer, tex, &src, &dst, 0.0, unsafe { nil }, flip)
			continue
		}

		match p.state {
			.jumping {
				// Somersault spinning ball
				rot := p.jump_anim_rot
				draw_filled_circle(renderer, sx, sy - 16, 12, pants_color.r, pants_color.g, pants_color.b)
				draw_filled_circle(renderer, sx + int(math.cos(f64(rot)) * 4.0), sy - 16 + int(math.sin(f64(rot)) * 4.0), 6, bandanna_color.r, bandanna_color.g, bandanna_color.b)
			}
			.prone {
				// Prone crawling on ground
				rect := sdl.Rect{x: sx - 16, y: sy - 12, w: 32, h: 12}
				sdl.set_render_draw_color(renderer, pants_color.r, pants_color.g, pants_color.b, 255)
				sdl.render_fill_rect(renderer, &rect)
				head_x := if p.facing_right { sx + 10 } else { sx - 10 }
				draw_filled_circle(renderer, head_x, sy - 10, 6, skin_color.r, skin_color.g, skin_color.b)
				gun_x := if p.facing_right { sx + 24 } else { sx - 24 }
				sdl.set_render_draw_color(renderer, 20, 20, 20, 255)
				sdl.render_draw_line(renderer, head_x, sy - 6, gun_x, sy - 6)
			}
			.standing, .running, .crouching, .spawning, .in_water {
				// Shirtless Muscular Torso
				torso := sdl.Rect{x: sx - 7, y: sy - 30, w: 14, h: 14}
				sdl.set_render_draw_color(renderer, skin_color.r, skin_color.g, skin_color.b, 255)
				sdl.render_fill_rect(renderer, &torso)

				// Pants & Tactical Boots
				if p.state != .in_water {
					legs := sdl.Rect{x: sx - 7, y: sy - 16, w: 14, h: 16}
					sdl.set_render_draw_color(renderer, pants_color.r, pants_color.g, pants_color.b, 255)
					sdl.render_fill_rect(renderer, &legs)
				}

				// Head & Fluttering Bandanna
				draw_filled_circle(renderer, sx, sy - 34, 7, skin_color.r, skin_color.g, skin_color.b)
				bandanna_rect := sdl.Rect{x: sx - 7, y: sy - 38, w: 14, h: 5}
				sdl.set_render_draw_color(renderer, bandanna_color.r, bandanna_color.g, bandanna_color.b, 255)
				sdl.render_fill_rect(renderer, &bandanna_rect)

				// Bandanna tail flapping
				band_tail_x := if p.facing_right { sx - 11 } else { sx + 11 }
				sdl.render_draw_line(renderer, sx, sy - 36, band_tail_x, sy - 34)

				// 8-Way Aimed Rifle
				gun_len := f32(18.0)
				gx := sx + int(p.aim_x * gun_len)
				gy := (sy - 22) + int(p.aim_y * gun_len)
				sdl.set_render_draw_color(renderer, 20, 20, 20, 255)
				sdl.render_draw_line(renderer, sx, sy - 22, gx, gy)
				sdl.render_draw_line(renderer, sx, sy - 21, gx, gy + 1)
			}
			else {}
		}
	}
}

fn render_water_foreground(renderer &sdl.Renderer, game &ContraGame, cx f32, cy f32) {
	for plat in game.stage_data.platforms {
		if !plat.is_water { continue }
		sx := int(plat.x - cx)
		sy := int(plat.y - cy)
		sw := int(plat.w)
		sh := int(plat.h)

		rect := sdl.Rect{x: sx, y: sy, w: sw, h: sh}
		sdl.set_render_draw_color(renderer, 25, 95, 185, 200)
		sdl.render_fill_rect(renderer, &rect)
		sdl.set_render_draw_color(renderer, 160, 225, 255, 255)
		for x := sx; x < sx + sw; x += 16 {
			sdl.render_draw_line(renderer, x, sy, x + 8, sy)
		}
	}
}

fn render_pop_texts(renderer &sdl.Renderer, game &ContraGame, cx f32, cy f32) {
	for pt in game.pop_texts {
		sx := int(pt.x - cx)
		sy := int(pt.y - cy)
		draw_text_shadow(renderer, pt.text, sx, sy, 1, Color{r: pt.r, g: pt.g, b: pt.b}, Color{r: 0, g: 0, b: 0})
	}
}

// Glassmorphic Arcade HUD
fn render_hud(renderer &sdl.Renderer, game &ContraGame, win_w int) {
	hud_h := 40
	rect := sdl.Rect{x: 0, y: 0, w: win_w, h: hud_h}
	sdl.set_render_draw_color(renderer, 10, 15, 25, 230)
	sdl.render_fill_rect(renderer, &rect)
	sdl.set_render_draw_color(renderer, 255, 215, 0, 255)
	sdl.render_draw_line(renderer, 0, hud_h - 1, win_w, hud_h - 1)

	// 1P Score & Lives
	if game.players.len > 0 {
		p1 := game.players[0]
		draw_text_shadow(renderer, '1P', 20, 8, 2, Color{r: 80, g: 180, b: 255}, Color{r: 0, g: 0, b: 0})
		draw_text_shadow(renderer, '${p1.score:06d}', 55, 8, 2, Color{r: 255, g: 255, b: 255}, Color{r: 0, g: 0, b: 0})

		// Weapon Badge
		w_letter := match p1.weapon {
			.machine_gun { 'M' }
			.spread_gun { 'S' }
			.laser { 'L' }
			.fire_gun { 'F' }
			else { 'R' }
		}
		draw_text_shadow(renderer, 'LIVES: ${p1.lives:02d} [${w_letter}]', 165, 8, 2, Color{r: 255, g: 220, b: 0}, Color{r: 0, g: 0, b: 0})
	}

	// HIGH SCORE
	draw_text_shadow(renderer, 'HIGH', 390, 8, 2, Color{r: 255, g: 150, b: 50}, Color{r: 0, g: 0, b: 0})
	draw_text_shadow(renderer, '${game.high_score:06d}', 460, 8, 2, Color{r: 255, g: 255, b: 255}, Color{r: 0, g: 0, b: 0})

	// STAGE TITLE
	stg_x := win_w - (game.stage_data.def.name.len * 16 + 20)
	draw_text_shadow(renderer, game.stage_data.def.name, stg_x, 8, 2, Color{r: 200, g: 240, b: 255}, Color{r: 0, g: 0, b: 0})
}

fn render_screen_overlays(renderer &sdl.Renderer, game &ContraGame, win_w int, win_h int) {
	cx := win_w / 2

	match game.state {
		.title {
			rect := sdl.Rect{x: 60, y: 55, w: win_w - 120, h: win_h - 110}
			sdl.set_render_draw_color(renderer, 10, 15, 30, 240)
			sdl.render_fill_rect(renderer, &rect)
			sdl.set_render_draw_color(renderer, 240, 40, 40, 255)
			sdl.render_draw_rect(renderer, &rect)

			draw_text_centered_shadow(renderer, 'CONTRA', cx, 80, 5, Color{r: 255, g: 50, b: 50}, Color{r: 120, g: 10, b: 10})
			draw_text_centered_shadow(renderer, 'MODERN 1988 KONAMI MASTERPIECE', cx, 135, 2, Color{r: 255, g: 215, b: 0}, Color{r: 0, g: 0, b: 0})

			draw_text_centered_shadow(renderer, 'PRESS SPACE OR ENTER TO START', cx, 190, 2, Color{r: 255, g: 255, b: 255}, Color{r: 0, g: 0, b: 0})
			draw_text_centered_shadow(renderer, '[ 1 - 4 ] STAGE SELECT | [ C ] 2-PLAYER CO-OP', cx, 225, 2, Color{r: 255, g: 200, b: 80}, Color{r: 0, g: 0, b: 0})

			if game.konami_activated {
				draw_text_centered_shadow(renderer, '*** 30 LIVES CODE ACTIVATED! ***', cx, 265, 2, Color{r: 40, g: 255, b: 120}, Color{r: 0, g: 0, b: 0})
			} else {
				draw_text_centered_shadow(renderer, 'KONAMI CODE: UP UP DOWN DOWN LEFT RIGHT LEFT RIGHT B A', cx, 265, 1, Color{r: 160, g: 190, b: 230}, Color{r: 0, g: 0, b: 0})
			}

			// Controls Info
			draw_text_centered_shadow(renderer, '--- CONTROLS ---', cx, 305, 2, Color{r: 180, g: 200, b: 240}, Color{r: 0, g: 0, b: 0})
			draw_text_centered_shadow(renderer, 'WASD / ARROWS : MOVE & 8-WAY AIM', cx, 335, 2, Color{r: 220, g: 230, b: 255}, Color{r: 0, g: 0, b: 0})
			draw_text_centered_shadow(renderer, 'J / Z / L-CLICK : FIRE WEAPON (HOLD AUTO-FIRE)', cx, 360, 2, Color{r: 220, g: 230, b: 255}, Color{r: 0, g: 0, b: 0})
			draw_text_centered_shadow(renderer, 'K / X / SPACE : SOMERSAULT JUMP', cx, 385, 2, Color{r: 220, g: 230, b: 255}, Color{r: 0, g: 0, b: 0})
			draw_text_centered_shadow(renderer, 'S + K / DOWN + JUMP : DROP THROUGH PLATFORMS', cx, 410, 2, Color{r: 220, g: 230, b: 255}, Color{r: 0, g: 0, b: 0})
			draw_text_centered_shadow(renderer, 'F11 : FULLSCREEN | M : AUDIO | P : PAUSE | R : RESTART', cx, 435, 2, Color{r: 220, g: 230, b: 255}, Color{r: 0, g: 0, b: 0})
		}
		.stage_intro {
			draw_text_centered_shadow(renderer, game.stage_data.def.name, cx, win_h / 2 - 30, 4, Color{r: 255, g: 215, b: 0}, Color{r: 0, g: 0, b: 0})
			draw_text_centered_shadow(renderer, 'DESTROY THE ALIEN DEFENSE CORPS!', cx, win_h / 2 + 20, 2, Color{r: 255, g: 255, b: 255}, Color{r: 0, g: 0, b: 0})
		}
		.stage_clear {
			box := sdl.Rect{x: cx - 220, y: win_h / 2 - 80, w: 440, h: 160}
			sdl.set_render_draw_color(renderer, 10, 20, 50, 240)
			sdl.render_fill_rect(renderer, &box)
			sdl.set_render_draw_color(renderer, 255, 215, 0, 255)
			sdl.render_draw_rect(renderer, &box)

			draw_text_centered_shadow(renderer, 'STAGE CLEARED!', cx, win_h / 2 - 60, 4, Color{r: 40, g: 255, b: 120}, Color{r: 0, g: 0, b: 0})
			draw_text_centered_shadow(renderer, 'BOSS DEFENSE SYSTEM DESTROYED', cx, win_h / 2 - 10, 2, Color{r: 255, g: 220, b: 0}, Color{r: 0, g: 0, b: 0})
			draw_text_centered_shadow(renderer, 'PROCEEDING TO NEXT MISSION...', cx, win_h / 2 + 25, 2, Color{r: 255, g: 255, b: 255}, Color{r: 0, g: 0, b: 0})
		}
		.game_over {
			draw_text_centered_shadow(renderer, 'GAME OVER', cx, win_h / 2 - 40, 5, Color{r: 255, g: 50, b: 50}, Color{r: 0, g: 0, b: 0})
			draw_text_centered_shadow(renderer, 'PRESS SPACE TO CONTINUE', cx, win_h / 2 + 30, 2, Color{r: 255, g: 255, b: 255}, Color{r: 0, g: 0, b: 0})
		}
		.victory {
			box := sdl.Rect{x: cx - 260, y: win_h / 2 - 110, w: 520, h: 220}
			sdl.set_render_draw_color(renderer, 10, 20, 40, 245)
			sdl.render_fill_rect(renderer, &box)
			sdl.set_render_draw_color(renderer, 255, 215, 0, 255)
			sdl.render_draw_rect(renderer, &box)

			draw_text_centered_shadow(renderer, 'MISSION ACCOMPLISHED!', cx, win_h / 2 - 90, 4, Color{r: 255, g: 215, b: 0}, Color{r: 180, g: 80, b: 0})
			draw_text_centered_shadow(renderer, 'THE ALIEN HEART HAS BEEN OBLITERATED', cx, win_h / 2 - 40, 2, Color{r: 255, g: 255, b: 255}, Color{r: 0, g: 0, b: 0})
			draw_text_centered_shadow(renderer, 'EARTH IS SAFE ONCE MORE', cx, win_h / 2 - 10, 2, Color{r: 100, g: 220, b: 255}, Color{r: 0, g: 0, b: 0})
			draw_text_centered_shadow(renderer, 'YOU ARE A TRUE CONTRA HERO', cx, win_h / 2 + 25, 2, Color{r: 40, g: 255, b: 120}, Color{r: 0, g: 0, b: 0})
			draw_text_centered_shadow(renderer, 'PRESS SPACE TO RETURN TO TITLE', cx, win_h / 2 + 65, 2, Color{r: 255, g: 200, b: 80}, Color{r: 0, g: 0, b: 0})
		}
		.paused {
			draw_text_centered_shadow(renderer, 'PAUSED', cx, win_h / 2 - 20, 4, Color{r: 255, g: 255, b: 255}, Color{r: 0, g: 0, b: 0})
		}
		else {}
	}
}

fn draw_filled_circle(renderer &sdl.Renderer, cx int, cy int, radius int, r u8, g u8, b u8) {
	sdl.set_render_draw_color(renderer, r, g, b, 255)
	for dy := -radius; dy <= radius; dy++ {
		dx_limit := int(math.sqrt(math.max(0.0, f64(radius * radius - dy * dy))))
		sdl.render_draw_line(renderer, cx - dx_limit, cy + dy, cx + dx_limit, cy + dy)
	}
}

fn fill_triangle(renderer &sdl.Renderer, x0 int, y0 int, x1 int, y1 int, x2 int, y2 int) {
	mut ax := x0; mut ay := y0; mut bx := x1; mut by := y1; mut cx := x2; mut cy := y2

	if ay > by {
		tmp_x := ax; tmp_y := ay; ax = bx; ay = by; bx = tmp_x; by = tmp_y
	}
	if ay > cy {
		tmp_x := ax; tmp_y := ay; ax = cx; ay = cy; cx = tmp_x; cy = tmp_y
	}
	if by > cy {
		tmp_x := bx; tmp_y := by; bx = cx; by = cy; cx = tmp_x; cy = tmp_y
	}

	if cy == ay { return }

	for y := ay; y <= cy; y++ {
		mut x_start := 0
		mut x_end := 0

		if y < by {
			if by == ay { continue }
			t1 := f32(y - ay) / f32(by - ay)
			t2 := f32(y - ay) / f32(cy - ay)
			x_start = int(f32(ax) + t1 * f32(bx - ax))
			x_end = int(f32(ax) + t2 * f32(cx - ax))
		} else {
			if cy == by { continue }
			t1 := f32(y - by) / f32(cy - by)
			t2 := f32(y - ay) / f32(cy - ay)
			x_start = int(f32(bx) + t1 * f32(cx - bx))
			x_end = int(f32(ax) + t2 * f32(cx - ax))
		}

		if x_start > x_end {
			tmp := x_start
			x_start = x_end
			x_end = tmp
		}

		sdl.render_draw_line(renderer, x_start, y, x_end, y)
	}
}
