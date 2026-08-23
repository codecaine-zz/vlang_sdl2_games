module main

import math
import os
import rand
import sdl

pub struct DownwellTextureManager {
pub mut:
	sprite_texture &sdl.Texture = unsafe { nil }
}

pub fn new_downwell_texture_manager() DownwellTextureManager {
	return DownwellTextureManager{}
}

pub fn (mut tm DownwellTextureManager) init(renderer &sdl.Renderer) {
	paths := [
		'assets/sprites/downwell_sprites.bmp',
		'downwell/assets/sprites/downwell_sprites.bmp',
		'../assets/sprites/downwell_sprites.bmp',
		os.join_path('assets', 'sprites', 'downwell_sprites.bmp'),
		os.join_path('downwell', 'assets', 'sprites', 'downwell_sprites.bmp'),
	]
	for p in paths {
		if os.exists(p) {
			surface := sdl.load_bmp(p.str)
			if !isnil(surface) {
				tm.sprite_texture = sdl.create_texture_from_surface(renderer, surface)
				sdl.free_surface(surface)
				if !isnil(tm.sprite_texture) {
					sdl.set_texture_blend_mode(tm.sprite_texture, .blend)
					return
				}
			}
		}
	}
}

pub fn render_downwell_game(renderer &sdl.Renderer, game &DownwellGame, tex &sdl.Texture) {
	// Deep space / abyss cavern gradient background
	sdl.set_render_draw_color(renderer, 10, 8, 16, 255)
	sdl.render_clear(renderer)

	t := f64(sdl.get_ticks()) / 1000.0

	// Screen shake calculation
	mut shake_x := 0
	mut shake_y := 0
	if game.screen_shake > 0 {
		shake_x = int((rand.f64() - 0.5) * game.screen_shake * 28.0)
		shake_y = int((rand.f64() - 0.5) * game.screen_shake * 28.0)
	}

	screen_w := 800
	screen_h := 600
	well_pixel_w := game.well_width * game.block_size
	offset_x := (screen_w - well_pixel_w) / 2 + shake_x
	cam_y := int(game.camera_y) - shake_y

	// Render Well Backdrop with subtle animated wall pattern
	sdl.set_render_draw_color(renderer, 18, 15, 26, 255)
	bg_rect := sdl.Rect{
		x: offset_x
		y: 0
		w: well_pixel_w
		h: screen_h
	}
	sdl.render_fill_rect(renderer, &bg_rect)

	// Well Grid Line Accents
	sdl.set_render_draw_color(renderer, 28, 22, 40, 255)
	for x in 1 .. game.well_width - 1 {
		gx := offset_x + x * game.block_size
		sdl.render_draw_line(renderer, gx, 0, gx, screen_h)
	}

	// Render Blocks & Lighting Glows
	min_by := math.max(0, int(game.camera_y / f64(game.block_size)) - 1)
	max_by := math.min(game.well_height - 1, int((game.camera_y + f64(screen_h)) / f64(game.block_size)) + 1)

	for by in min_by .. max_by + 1 {
		for bx in 0 .. game.well_width {
			block := game.grid[by][bx]
			if block.kind == .empty {
				continue
			}
			px := offset_x + bx * game.block_size
			py := by * game.block_size - cam_y

			match block.kind {
				.solid {
					// Cavern wall blocks with drop shadow
					sdl.set_render_draw_color(renderer, 12, 10, 18, 255)
					shadow := sdl.Rect{x: px + 3, y: py + 3, w: game.block_size, h: game.block_size}
					sdl.render_fill_rect(renderer, &shadow)

					sdl.set_render_draw_color(renderer, 210, 210, 230, 255)
					rect := sdl.Rect{x: px, y: py, w: game.block_size, h: game.block_size}
					sdl.render_fill_rect(renderer, &rect)
					
					// Bevel highlight
					sdl.set_render_draw_color(renderer, 255, 255, 255, 255)
					sdl.render_draw_line(renderer, px, py, px + game.block_size, py)
					sdl.render_draw_line(renderer, px, py, px, py + game.block_size)

					sdl.set_render_draw_color(renderer, 90, 90, 120, 255)
					sdl.render_draw_rect(renderer, &rect)
				}
				.destructible {
					// Destructible brick with crack texture and red glow
					sdl.set_render_draw_color(renderer, 230, 45, 55, 255)
					rect := sdl.Rect{x: px + 1, y: py + 1, w: game.block_size - 2, h: game.block_size - 2}
					sdl.render_fill_rect(renderer, &rect)
					
					sdl.set_render_draw_color(renderer, 255, 140, 140, 255)
					sdl.render_draw_rect(renderer, &rect)
					
					// Cracks pattern
					sdl.set_render_draw_color(renderer, 120, 20, 30, 255)
					sdl.render_draw_line(renderer, px + 6, py + 6, px + 18, py + 16)
					sdl.render_draw_line(renderer, px + 18, py + 16, px + 26, py + 26)
				}
				.gem_block {
					// Pulsing Gold Gem Vein
					pulse := u8(200 + int(55.0 * math.sin(t * 6.0 + f64(bx + by))))
					sdl.set_render_draw_color(renderer, 255, pulse, 0, 255)
					rect := sdl.Rect{x: px + 1, y: py + 1, w: game.block_size - 2, h: game.block_size - 2}
					sdl.render_fill_rect(renderer, &rect)

					// Inner diamond core
					sdl.set_render_draw_color(renderer, 255, 255, 220, 255)
					diamond := sdl.Rect{x: px + 10, y: py + 10, w: 12, h: 12}
					sdl.render_fill_rect(renderer, &diamond)

					// Additive radial light halo around gem block
					sdl.set_render_draw_blend_mode(renderer, sdl.BlendMode.add)
					sdl.set_render_draw_color(renderer, 255, 200, 40, 40)
					halo := sdl.Rect{x: px - 6, y: py - 6, w: game.block_size + 12, h: game.block_size + 12}
					sdl.render_fill_rect(renderer, &halo)
					sdl.set_render_draw_blend_mode(renderer, sdl.BlendMode.blend)
				}
				.shop_door {
					// Neon Blue Shop Entrance
					sdl.set_render_draw_color(renderer, 40, 160, 255, 255)
					rect := sdl.Rect{x: px, y: py, w: game.block_size, h: game.block_size}
					sdl.render_fill_rect(renderer, &rect)
					draw_text(renderer, px + 2, py + 10, 'SHOP', 1, Color{r: 255, g: 255, b: 255})
				}
				else {}
			}
		}
	}

	// Render Pickups with Additive Light Halos
	for pk in game.pickups {
		if !pk.active {
			continue
		}
		px := offset_x + int(pk.x)
		py := int(pk.y) - cam_y

		// Light halo
		sdl.set_render_draw_blend_mode(renderer, sdl.BlendMode.add)
		sdl.set_render_draw_color(renderer, 255, 220, 100, 60)
		halo := sdl.Rect{x: px - 10, y: py - 10, w: 20, h: 20}
		sdl.render_fill_rect(renderer, &halo)
		sdl.set_render_draw_blend_mode(renderer, sdl.BlendMode.blend)

		match pk.kind {
			.gem {
				sdl.set_render_draw_color(renderer, 255, 215, 0, 255)
				rect := sdl.Rect{x: px - 5, y: py - 5, w: 10, h: 10}
				sdl.render_fill_rect(renderer, &rect)
				sdl.set_render_draw_color(renderer, 255, 255, 255, 255)
				inner := sdl.Rect{x: px - 2, y: py - 2, w: 4, h: 4}
				sdl.render_fill_rect(renderer, &inner)
			}
			.health {
				sdl.set_render_draw_color(renderer, 255, 50, 80, 255)
				rect := sdl.Rect{x: px - 6, y: py - 6, w: 12, h: 12}
				sdl.render_fill_rect(renderer, &rect)
			}
			.max_health {
				sdl.set_render_draw_color(renderer, 255, 100, 255, 255)
				rect := sdl.Rect{x: px - 7, y: py - 7, w: 14, h: 14}
				sdl.render_fill_rect(renderer, &rect)
			}
			.ammo {
				sdl.set_render_draw_color(renderer, 80, 230, 255, 255)
				rect := sdl.Rect{x: px - 6, y: py - 6, w: 12, h: 12}
				sdl.render_fill_rect(renderer, &rect)
			}
		}
	}

	// Render Enemies
	for e in game.enemies {
		if !e.active {
			continue
		}
		px := offset_x + int(e.x)
		py := int(e.y) - cam_y
		w := int(e.w)
		h := int(e.h)

		// Drop Shadow
		sdl.set_render_draw_color(renderer, 0, 0, 0, 140)
		shadow := sdl.Rect{x: px + 3, y: py + 4, w: w, h: h}
		sdl.render_fill_rect(renderer, &shadow)

		if e.is_red {
			sdl.set_render_draw_color(renderer, 240, 30, 40, 255)
		} else {
			sdl.set_render_draw_color(renderer, 245, 245, 255, 255)
		}
		rect := sdl.Rect{x: px, y: py, w: w, h: h}
		sdl.render_fill_rect(renderer, &rect)

		// Outline border
		sdl.set_render_draw_color(renderer, 20, 20, 30, 255)
		sdl.render_draw_rect(renderer, &rect)

		// Enemy eyes
		sdl.set_render_draw_color(renderer, 255, 255, 255, 255)
		eye1 := sdl.Rect{x: px + 4, y: py + 5, w: 5, h: 5}
		eye2 := sdl.Rect{x: px + w - 9, y: py + 5, w: 5, h: 5}
		sdl.render_fill_rect(renderer, &eye1)
		sdl.render_fill_rect(renderer, &eye2)

		sdl.set_render_draw_color(renderer, 0, 0, 0, 255)
		pupil1 := sdl.Rect{x: px + 6, y: py + 6, w: 2, h: 3}
		pupil2 := sdl.Rect{x: px + w - 7, y: py + 6, w: 2, h: 3}
		sdl.render_fill_rect(renderer, &pupil1)
		sdl.render_fill_rect(renderer, &pupil2)
	}

	// Render Bullets with Additive Bloom Core
	for b in game.bullets {
		px := offset_x + int(b.x)
		py := int(b.y) - cam_y

		// Outer Glow (Additive Blend)
		sdl.set_render_draw_blend_mode(renderer, sdl.BlendMode.add)
		sdl.set_render_draw_color(renderer, 255, 180, 40, 100)
		glow := sdl.Rect{x: px - 4, y: py - 4, w: int(b.w) + 8, h: int(b.h) + 8}
		sdl.render_fill_rect(renderer, &glow)

		// Inner Core
		sdl.set_render_draw_blend_mode(renderer, sdl.BlendMode.blend)
		sdl.set_render_draw_color(renderer, 255, 255, 220, 255)
		core := sdl.Rect{x: px, y: py, w: int(b.w), h: int(b.h)}
		sdl.render_fill_rect(renderer, &core)
	}

	// Render Particles (Embers & Dust Sparks)
	sdl.set_render_draw_blend_mode(renderer, sdl.BlendMode.add)
	for pt in game.particles {
		px := offset_x + int(pt.x)
		py := int(pt.y) - cam_y
		alpha := u8(255.0 * (pt.life / pt.max_life))
		sdl.set_render_draw_color(renderer, pt.color.r, pt.color.g, pt.color.b, alpha)
		rect := sdl.Rect{x: px - pt.size / 2, y: py - pt.size / 2, w: pt.size, h: pt.size}
		sdl.render_fill_rect(renderer, &rect)
	}
	sdl.set_render_draw_blend_mode(renderer, sdl.BlendMode.blend)

	// Render Player
	p := game.player
	if p.invuln_timer == 0 || int(p.invuln_timer * 15.0) % 2 == 0 {
		px := offset_x + int(p.x)
		py := int(p.y) - cam_y

		// Gunboot Thrust Aura when falling and shooting
		if p.vy > 50.0 {
			sdl.set_render_draw_blend_mode(renderer, sdl.BlendMode.add)
			sdl.set_render_draw_color(renderer, 255, 100, 30, 120)
			flare := sdl.Rect{x: px - 4, y: py + int(p.h) - 4, w: int(p.w) + 8, h: 16}
			sdl.render_fill_rect(renderer, &flare)
			sdl.set_render_draw_blend_mode(renderer, sdl.BlendMode.blend)
		}

		if !isnil(tex) {
			src_rect := sdl.Rect{x: 0, y: 0, w: 32, h: 32}
			dest_rect := sdl.Rect{x: px, y: py, w: int(p.w), h: int(p.h)}
			sdl.render_copy(renderer, tex, &src_rect, &dest_rect)
		} else {
			// Player Body
			sdl.set_render_draw_color(renderer, 255, 255, 255, 255)
			body_rect := sdl.Rect{x: px, y: py, w: int(p.w), h: int(p.h) - 6}
			sdl.render_fill_rect(renderer, &body_rect)

			// Gunboots (Red boots at bottom)
			sdl.set_render_draw_color(renderer, 240, 30, 40, 255)
			boot_rect := sdl.Rect{x: px, y: py + int(p.h) - 6, w: int(p.w), h: 6}
			sdl.render_fill_rect(renderer, &boot_rect)

			// Eyes
			sdl.set_render_draw_color(renderer, 20, 20, 30, 255)
			eye_x := if p.facing_right { px + 14 } else { px + 4 }
			eye_rect := sdl.Rect{x: eye_x, y: py + 5, w: 4, h: 6}
			sdl.render_fill_rect(renderer, &eye_rect)
		}
	}

	// Render Glassmorphism Modern HUD
	render_modern_hud(renderer, game, offset_x, well_pixel_w)

	// Render CRT Overlay Scanlines
	render_crt_overlay(renderer, screen_w, screen_h)

	// Render Shop Overlay if active
	if game.shop_active {
		render_shop(renderer, game)
	}

	// Render Game Over or Victory overlays
	if game.game_over {
		render_overlay_box(renderer, 'GAME OVER', 'PRESS RESTART OR [R]', Color{r: 240, g: 40, b: 50}, game.score, game.high_score)
	} else if game.victory {
		render_overlay_box(renderer, 'VICTORY!', 'YOU ESCAPED THE WELL!', Color{r: 60, g: 240, b: 100}, game.score, game.high_score)
	}
}

fn render_modern_hud(renderer &sdl.Renderer, game &DownwellGame, offset_x int, well_w int) {
	p := game.player

	// Glassmorphism Card Container (Left Panel)
	sdl.set_render_draw_blend_mode(renderer, sdl.BlendMode.blend)
	sdl.set_render_draw_color(renderer, 20, 16, 28, 200)
	hud_l_bg := sdl.Rect{x: 20, y: 20, w: 220, h: 200}
	sdl.render_fill_rect(renderer, &hud_l_bg)
	sdl.set_render_draw_color(renderer, 255, 80, 100, 150)
	sdl.render_draw_rect(renderer, &hud_l_bg)

	hud_l_x := 30
	draw_text(renderer, hud_l_x, 32, 'DOWNWELL', 2, Color{r: 255, g: 80, b: 100})
	draw_text(renderer, hud_l_x, 65, 'STAGE ${game.stage}-1', 2, Color{r: 255, g: 255, b: 255})

	// Health Hearts
	draw_text(renderer, hud_l_x, 100, 'HP:', 2, Color{r: 200, g: 200, b: 220})
	for i in 0 .. p.max_hp {
		color := if i < p.hp { Color{r: 240, g: 40, b: 50} } else { Color{r: 60, g: 50, b: 70} }
		rect := sdl.Rect{x: hud_l_x + 55 + i * 22, y: 100, w: 16, h: 16}
		sdl.set_render_draw_color(renderer, color.r, color.g, color.b, 255)
		sdl.render_fill_rect(renderer, &rect)
	}

	// Weapon & Ammo meter
	mut w_name := 'STANDARD'
	match p.weapon {
		.machinegun { w_name = 'MACHINEGUN' }
		.shotgun { w_name = 'SHOTGUN' }
		.laser { w_name = 'LASER' }
		.burst { w_name = 'BURST' }
		else {}
	}
	draw_text(renderer, hud_l_x, 135, 'BOOTS: ${w_name}', 1, Color{r: 80, g: 220, b: 255})

	// Ammo bar
	draw_text(renderer, hud_l_x, 155, 'AMMO:', 1, Color{r: 200, g: 200, b: 220})
	for i in 0 .. p.max_ammo {
		color := if i < p.ammo { Color{r: 255, g: 220, b: 60} } else { Color{r: 60, g: 60, b: 80} }
		rect := sdl.Rect{x: hud_l_x + 50 + i * 10, y: 155, w: 7, h: 14}
		sdl.set_render_draw_color(renderer, color.r, color.g, color.b, 255)
		sdl.render_fill_rect(renderer, &rect)
	}

	// Glassmorphism Card Container (Right Panel)
	hud_r_x := offset_x + well_w + 30
	hud_r_bg := sdl.Rect{x: hud_r_x - 10, y: 20, w: 220, h: 220}
	sdl.set_render_draw_color(renderer, 20, 16, 28, 200)
	sdl.render_fill_rect(renderer, &hud_r_bg)
	sdl.set_render_draw_color(renderer, 255, 215, 0, 150)
	sdl.render_draw_rect(renderer, &hud_r_bg)

	draw_text(renderer, hud_r_x, 32, 'SCORE', 1, Color{r: 180, g: 180, b: 200})
	draw_text(renderer, hud_r_x, 48, '${game.score}', 3, Color{r: 255, g: 255, b: 255})

	draw_text(renderer, hud_r_x, 92, 'HIGH SCORE', 1, Color{r: 180, g: 180, b: 200})
	draw_text(renderer, hud_r_x, 108, '${game.high_score}', 2, Color{r: 255, g: 215, b: 0})

	draw_text(renderer, hud_r_x, 142, 'GEMS: ${p.gems}', 2, Color{r: 255, g: 215, b: 0})

	if p.combo > 1 {
		draw_text(renderer, hud_r_x, 175, 'COMBO x${p.combo}!', 2, Color{r: 255, g: 80, b: 100})
	}

	depth_m := int(game.depth)
	draw_text(renderer, hud_r_x, 205, 'DEPTH: ${depth_m}m', 2, Color{r: 140, g: 220, b: 255})
}

fn render_crt_overlay(renderer &sdl.Renderer, w int, h int) {
	sdl.set_render_draw_blend_mode(renderer, sdl.BlendMode.blend)
	sdl.set_render_draw_color(renderer, 0, 0, 0, 15)
	for y := 0; y < h; y += 4 {
		line := sdl.Rect{x: 0, y: y, w: w, h: 2}
		sdl.render_fill_rect(renderer, &line)
	}
}

fn render_shop(renderer &sdl.Renderer, game &DownwellGame) {
	sdl.set_render_draw_blend_mode(renderer, sdl.BlendMode.blend)
	sdl.set_render_draw_color(renderer, 10, 8, 16, 230)
	bg := sdl.Rect{x: 150, y: 100, w: 500, h: 400}
	sdl.render_fill_rect(renderer, &bg)

	sdl.set_render_draw_color(renderer, 60, 180, 255, 255)
	sdl.render_draw_rect(renderer, &bg)

	draw_text_centered(renderer, 400, 125, 'WELL SIDE SHOP', 3, Color{r: 80, g: 220, b: 255})
	draw_text_centered(renderer, 400, 160, 'GEMS AVAILABLE: ${game.player.gems}', 2, Color{r: 255, g: 215, b: 0})

	for i, item in game.shop_items {
		iy := 200 + i * 55
		color := if item.bought { Color{r: 100, g: 100, b: 100} } else if game.player.gems >= item.cost { Color{r: 255, g: 255, b: 255} } else { Color{r: 220, g: 80, b: 80} }
		txt := if item.bought { '[BOUGHT] ${item.name}' } else { '[${i + 1}] ${item.name} - ${item.cost} GEMS' }
		
		// Item card frame
		card := sdl.Rect{x: 170, y: iy - 5, w: 460, h: 45}
		sdl.set_render_draw_color(renderer, 25, 20, 35, 200)
		sdl.render_fill_rect(renderer, &card)
		sdl.set_render_draw_color(renderer, 50, 40, 70, 255)
		sdl.render_draw_rect(renderer, &card)

		draw_text(renderer, 185, iy + 8, txt, 2, color)
	}

	draw_text_centered(renderer, 400, 450, 'PRESS [1-4] OR CLICK TO BUY, [C] TO CLOSE', 1, Color{r: 180, g: 180, b: 180})
}

fn render_overlay_box(renderer &sdl.Renderer, title string, subtitle string, color Color, score int, high int) {
	sdl.set_render_draw_blend_mode(renderer, sdl.BlendMode.blend)
	sdl.set_render_draw_color(renderer, 10, 8, 16, 235)
	box := sdl.Rect{x: 180, y: 180, w: 440, h: 240}
	sdl.render_fill_rect(renderer, &box)

	sdl.set_render_draw_color(renderer, color.r, color.g, color.b, 255)
	sdl.render_draw_rect(renderer, &box)

	draw_text_centered(renderer, 400, 210, title, 4, color)
	draw_text_centered(renderer, 400, 260, subtitle, 2, Color{r: 255, g: 255, b: 255})
	draw_text_centered(renderer, 400, 300, 'FINAL SCORE: ${score}', 2, Color{r: 255, g: 215, b: 0})
	draw_text_centered(renderer, 400, 330, 'HIGH SCORE: ${high}', 2, Color{r: 200, g: 200, b: 200})
}
