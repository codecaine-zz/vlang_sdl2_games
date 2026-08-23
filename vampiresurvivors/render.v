module main

import math
import sdl

// Pixel Font Bitmap Renderer
const font_map = [
	' ', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q',
	'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', '0', '1', '2', '3', '4', '5', '6', '7', '8',
	'9', ':', '-', '!', '?', '+', '/', '.', '(', ')', '%', '\'', '[', ']', '$', '&', '<', '>',
	'*',
]

const font_data = [
	[0, 0, 0, 0, 0], // ' '
	[0x7C, 0x12, 0x11, 0x12, 0x7C], // A
	[0x7F, 0x49, 0x49, 0x49, 0x36], // B
	[0x3E, 0x41, 0x41, 0x41, 0x22], // C
	[0x7F, 0x41, 0x41, 0x22, 0x1C], // D
	[0x7F, 0x49, 0x49, 0x49, 0x41], // E
	[0x7F, 0x09, 0x09, 0x09, 0x01], // F
	[0x3E, 0x41, 0x49, 0x49, 0x7A], // G
	[0x7F, 0x08, 0x08, 0x08, 0x7F], // H
	[0x00, 0x41, 0x7F, 0x41, 0x00], // I
	[0x20, 0x40, 0x41, 0x3F, 0x01], // J
	[0x7F, 0x08, 0x14, 0x22, 0x41], // K
	[0x7F, 0x40, 0x40, 0x40, 0x40], // L
	[0x7F, 0x02, 0x0C, 0x02, 0x7F], // M
	[0x7F, 0x04, 0x08, 0x10, 0x7F], // N
	[0x3E, 0x41, 0x41, 0x41, 0x3E], // O
	[0x7F, 0x09, 0x09, 0x09, 0x06], // P
	[0x3E, 0x41, 0x51, 0x21, 0x5E], // Q
	[0x7F, 0x09, 0x19, 0x29, 0x46], // R
	[0x46, 0x49, 0x49, 0x49, 0x31], // S
	[0x01, 0x01, 0x7F, 0x01, 0x01], // T
	[0x3F, 0x40, 0x40, 0x40, 0x3F], // U
	[0x1F, 0x20, 0x40, 0x20, 0x1F], // V
	[0x7F, 0x20, 0x18, 0x20, 0x7F], // W
	[0x63, 0x14, 0x08, 0x14, 0x63], // X
	[0x07, 0x08, 0x70, 0x08, 0x07], // Y
	[0x61, 0x51, 0x49, 0x45, 0x43], // Z
	[0x3E, 0x51, 0x49, 0x45, 0x3E], // 0
	[0x00, 0x42, 0x7F, 0x40, 0x00], // 1
	[0x42, 0x61, 0x51, 0x49, 0x46], // 2
	[0x21, 0x41, 0x45, 0x4B, 0x31], // 3
	[0x18, 0x14, 0x12, 0x7F, 0x10], // 4
	[0x27, 0x45, 0x45, 0x45, 0x39], // 5
	[0x3C, 0x4A, 0x49, 0x49, 0x30], // 6
	[0x01, 0x71, 0x09, 0x05, 0x03], // 7
	[0x36, 0x49, 0x49, 0x49, 0x36], // 8
	[0x06, 0x49, 0x49, 0x29, 0x1E], // 9
	[0x00, 0x36, 0x36, 0x00, 0x00], // :
	[0x08, 0x08, 0x08, 0x08, 0x08], // -
	[0x00, 0x00, 0x5F, 0x00, 0x00], // !
	[0x02, 0x01, 0x51, 0x09, 0x06], // ?
	[0x08, 0x08, 0x3E, 0x08, 0x08], // +
	[0x20, 0x10, 0x08, 0x04, 0x02], // /
	[0x00, 0x60, 0x60, 0x00, 0x00], // .
	[0x00, 0x1C, 0x22, 0x41, 0x00], // (
	[0x00, 0x41, 0x22, 0x1C, 0x00], // )
	[0x23, 0x13, 0x08, 0x64, 0x62], // %
	[0x00, 0x05, 0x03, 0x00, 0x00], // '
	[0x00, 0x7F, 0x41, 0x41, 0x00], // [
	[0x00, 0x41, 0x41, 0x7F, 0x00], // ]
	[0x12, 0x2A, 0x7F, 0x2A, 0x24], // $
	[0x36, 0x49, 0x55, 0x22, 0x50], // &
	[0x00, 0x08, 0x14, 0x22, 0x41], // <
	[0x41, 0x22, 0x14, 0x08, 0x00], // >
	[0x14, 0x08, 0x3E, 0x08, 0x14], // *
]

fn draw_char(renderer &sdl.Renderer, x int, y int, c u8, scale int, col Color) {
	upper := if c >= `a` && c <= `z` { c - 32 } else { c }
	mut idx := -1
	for i, ch in font_map {
		if u8(ch[0]) == upper {
			idx = i
			break
		}
	}
	if idx < 0 {
		idx = 0
	}
	cols := font_data[idx]
	sdl.set_render_draw_color(renderer, col.r, col.g, col.b, col.a)
	for col_i, col_bits in cols {
		for row_i := 0; row_i < 7; row_i++ {
			if (col_bits & (1 << row_i)) != 0 {
				rect := sdl.Rect{
					x: x + col_i * scale
					y: y + row_i * scale
					w: scale
					h: scale
				}
				sdl.render_fill_rect(renderer, &rect)
			}
		}
	}
}

pub fn draw_text(renderer &sdl.Renderer, x int, y int, text string, scale int, col Color) {
	for i in 0 .. text.len {
		draw_char(renderer, x + i * 6 * scale, y, text[i], scale, col)
	}
}

pub fn draw_text_centered(renderer &sdl.Renderer, cx int, y int, text string, scale int, col Color) {
	w := text.len * 6 * scale
	draw_text(renderer, cx - w / 2, y, text, scale, col)
}

// Main Render Function
pub fn (g &Game) render(renderer &sdl.Renderer) {
	match g.state {
		.character_select {
			g.render_character_select(renderer)
		}
		.playing, .level_up, .chest_opened, .paused, .game_over, .victory {
			g.render_world(renderer)
			g.render_hud(renderer)

			if g.state == .level_up {
				g.render_level_up_modal(renderer)
			} else if g.state == .chest_opened {
				g.render_chest_modal(renderer)
			} else if g.state == .paused {
				g.render_pause_grimoire(renderer)
			} else if g.state == .game_over {
				g.render_game_over_banner(renderer)
			}
		}
	}
}

pub fn (g &Game) render_world(renderer &sdl.Renderer) {
	mut shake_x := 0
	mut shake_y := 0
	if g.shake_timer > 0 {
		shake_mag := g.shake_timer * 22.0
		shake_x = int((math.sin(g.game_time * 50.0)) * shake_mag)
		shake_y = int((math.cos(g.game_time * 45.0)) * shake_mag)
	}

	cam_x := int(g.cam_x) - shake_x
	cam_y := int(g.cam_y) - shake_y
	ticks := sdl.get_ticks()

	tile_s := 64
	start_col := cam_x / tile_s
	end_col := (cam_x + win_width) / tile_s + 1
	start_row := cam_y / tile_s
	end_row := (cam_y + win_height) / tile_s + 1

	// 1. Gothic Cobblestone Ground with Moss Variations
	for r := start_row; r <= end_row; r++ {
		for c := start_col; c <= end_col; c++ {
			sx := c * tile_s - cam_x
			sy := r * tile_s - cam_y

			tile_type := if (r * 11 + c * 7) % 7 == 0 {
				2 // Mossy
			} else if (r * 13 + c * 5) % 11 == 0 {
				3 // Cracked
			} else {
				1 // Normal
			}

			if g.sprite_texture != unsafe { nil } {
				src_x := match tile_type {
					2 { 576 }
					3 { 640 }
					else { 512 }
				}
				src := sdl.Rect{x: src_x, y: 384, w: 64, h: 64}
				dst := sdl.Rect{x: sx, y: sy, w: tile_s, h: tile_s}
				sdl.render_copy(renderer, g.sprite_texture, &src, &dst)
			} else {
				is_dark := (r + c) % 2 == 0
				if is_dark {
					sdl.set_render_draw_color(renderer, 20, 24, 34, 255)
				} else {
					sdl.set_render_draw_color(renderer, 16, 19, 28, 255)
				}
				tile_r := sdl.Rect{x: sx, y: sy, w: tile_s, h: tile_s}
				sdl.render_fill_rect(renderer, &tile_r)
				sdl.set_render_draw_color(renderer, 28, 33, 46, 255)
				sdl.render_draw_rect(renderer, &tile_r)
			}

			if (r * 13 + c * 7) % 19 == 0 {
				draw_tombstone(renderer, sx + 32, sy + 32, g.sprite_texture)
			}
		}
	}

	// 2. Persistent Blood Splatters
	sdl.set_render_draw_blend_mode(renderer, .blend)
	for bs in g.blood_stains {
		bx := int(bs.x) - cam_x
		by := int(bs.y) - cam_y
		if bx < -40 || bx > win_width + 40 || by < -40 || by > win_height + 40 {
			continue
		}
		alpha := u8(math.min(180.0, bs.life * 6.0))
		sdl.set_render_draw_color(renderer, 120, 15, 20, alpha)
		b_rect := sdl.Rect{x: bx - int(bs.rad), y: by - int(bs.rad / 2.0), w: int(bs.rad * 2.0), h: int(bs.rad)}
		sdl.render_fill_rect(renderer, &b_rect)
	}

	// 3. Breakable Props (Candelabras & Urns)
	for br in g.breakables {
		bx := int(br.x) - cam_x
		by := int(br.y) - cam_y
		if bx < -40 || bx > win_width + 40 || by < -40 || by > win_height + 40 {
			continue
		}
		if br.is_urn {
			draw_urn(renderer, bx, by, g.sprite_texture)
		} else {
			draw_candelabra(renderer, bx, by, ticks, g.sprite_texture)
		}
	}

	// 4. Floor Pickups
	for item in g.floor_pickups {
		ix := int(item.x) - cam_x
		iy := int(item.y) - cam_y
		if ix < -40 || ix > win_width + 40 || iy < -40 || iy > win_height + 40 {
			continue
		}
		draw_floor_pickup(renderer, ix, iy, item.kind, ticks, g.sprite_texture)
	}

	// 5. Exp Gems
	for gem in g.gems {
		gx := int(gem.x) - cam_x
		gy := int(gem.y) - cam_y
		if gx < -30 || gx > win_width + 30 || gy < -30 || gy > win_height + 30 {
			continue
		}
		draw_exp_gem(renderer, gx, gy, gem.kind, g.sprite_texture)
	}

	// 6. Enemies
	for e in g.enemies {
		ex := int(e.x) - cam_x
		ey := int(e.y) - cam_y
		if ex < -80 || ex > win_width + 80 || ey < -80 || ey > win_height + 80 {
			continue
		}
		draw_enemy_sprite(renderer, ex, ey, e, g.frozen_timer > 0, ticks, g.sprite_texture)
	}

	// 7. Player Projectiles & Weapons
	for pr in g.projectiles {
		px := int(pr.x) - cam_x
		py := int(pr.y) - cam_y
		draw_projectile(renderer, px, py, pr, ticks, g.sprite_texture)
	}

	// 7b. Enemy Projectiles (Red skull fireballs & Shadow bolts)
	for ep in g.enemy_projectiles {
		epx := int(ep.x) - cam_x
		epy := int(ep.y) - cam_y
		if epx < -30 || epx > win_width + 30 || epy < -30 || epy > win_height + 30 {
			continue
		}
		if g.sprite_texture != unsafe { nil } {
			src := sdl.Rect{x: 832, y: 256, w: 32, h: 32}
			dst := sdl.Rect{x: epx - 16, y: epy - 16, w: 32, h: 32}
			sdl.render_copy(renderer, g.sprite_texture, &src, &dst)
		} else {
			rad := int(ep.radius)
			sdl.set_render_draw_color(renderer, 255, 60, 40, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{x: epx - rad, y: epy - rad, w: rad * 2, h: rad * 2})
			sdl.set_render_draw_color(renderer, 255, 220, 100, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{x: epx - rad / 2, y: epy - rad / 2, w: rad, h: rad})
		}
	}

	// 8. Players
	for p in g.players {
		if p.hp <= 0 {
			continue
		}
		px := int(p.x) - cam_x
		py := int(p.y) - cam_y
		draw_player_sprite(renderer, px, py, p, g.sprite_texture)
	}

	// 9. Ambient Glowing Fireflies
	sdl.set_render_draw_blend_mode(renderer, .blend)
	for ff in g.fireflies {
		fx := int(ff.x) - cam_x
		fy := int(ff.y) - cam_y
		if fx < 0 || fx > win_width || fy < 0 || fy > win_height {
			continue
		}
		f_alpha := u8((math.sin(ff.phase) * 0.5 + 0.5) * 200.0 + 55.0)
		sdl.set_render_draw_color(renderer, 180, 255, 100, f_alpha)
		sdl.render_fill_rect(renderer, &sdl.Rect{x: fx - 1, y: fy - 1, w: 3, h: 3})
	}

	// 10. Particles
	for pt in g.particles {
		px := int(pt.x) - cam_x
		py := int(pt.y) - cam_y
		rect := sdl.Rect{x: px, y: py, w: int(pt.size), h: int(pt.size)}
		alpha := u8(pt.life / pt.max_l * 255.0)
		sdl.set_render_draw_color(renderer, pt.r, pt.g, pt.b, alpha)
		sdl.render_fill_rect(renderer, &rect)
	}

	// 11. Floating Damage Numbers
	for dn in g.dmg_nums {
		dx := int(dn.x) - cam_x
		dy := int(dn.y) - cam_y
		col := if dn.is_heal {
			Color{r: 80, g: 255, b: 120}
		} else if dn.is_crit {
			Color{r: 255, g: 50, b: 50}
		} else {
			Color{r: 255, g: 235, b: 80}
		}
		scale := if dn.is_crit || dn.is_heal { 2 } else { 1 }
		prefix := if dn.is_heal { '+' } else { '' }
		draw_text(renderer, dx, dy, '${prefix}${dn.val}', scale, col)
	}

	// 12. Holy Nuke Screen Flash
	if g.flash_nuke > 0 {
		alpha := u8(math.min(255.0, g.flash_nuke * 500.0))
		sdl.set_render_draw_blend_mode(renderer, .blend)
		sdl.set_render_draw_color(renderer, 255, 255, 230, alpha)
		full_rect := sdl.Rect{x: 0, y: 0, w: win_width, h: win_height}
		sdl.render_fill_rect(renderer, &full_rect)
	}

	// 13. Time Freeze Tint
	if g.frozen_timer > 0 {
		f_alpha := u8(math.min(100.0, g.frozen_timer * 20.0 + 30.0))
		sdl.set_render_draw_blend_mode(renderer, .blend)
		sdl.set_render_draw_color(renderer, 60, 180, 255, f_alpha)
		f_rect := sdl.Rect{x: 0, y: 0, w: win_width, h: win_height}
		sdl.render_fill_rect(renderer, &f_rect)
		draw_text_centered(renderer, win_width / 2, 80, 'TIME STOPPED: ${int(g.frozen_timer + 0.9)}s', 2, Color{r: 160, g: 235, b: 255})
	}

	// 14. Kill Streak Multiplier Banner (RAMPAGE! / GODLIKE!)
	if g.combo_title_t > 0 && g.combo_title.len > 0 {
		draw_text_centered(renderer, win_width / 2, 120, g.combo_title, 3, Color{r: 255, g: 60, b: 60})
	}
}

fn draw_tombstone(renderer &sdl.Renderer, x int, y int, tex &sdl.Texture) {
	if tex != unsafe { nil } {
		src := sdl.Rect{x: 476, y: 384, w: 32, h: 40}
		dst := sdl.Rect{x: x - 16, y: y - 20, w: 32, h: 40}
		sdl.render_copy(renderer, tex, &src, &dst)
		return
	}
	sdl.set_render_draw_color(renderer, 50, 58, 75, 255)
	t_rect := sdl.Rect{x: x - 8, y: y - 10, w: 16, h: 20}
	sdl.render_fill_rect(renderer, &t_rect)
	sdl.set_render_draw_color(renderer, 80, 92, 115, 255)
	sdl.render_draw_rect(renderer, &t_rect)
	sdl.set_render_draw_color(renderer, 25, 30, 40, 255)
	sdl.render_draw_line(renderer, x, y - 7, x, y + 4)
	sdl.render_draw_line(renderer, x - 4, y - 3, x + 4, y - 3)
}

fn draw_candelabra(renderer &sdl.Renderer, x int, y int, ticks u32, tex &sdl.Texture) {
	if tex != unsafe { nil } {
		frame_idx := int(ticks / 200) % 2
		src_x := if frame_idx == 0 { 372 } else { 408 }
		src := sdl.Rect{x: src_x, y: 384, w: 36, h: 48}
		dst := sdl.Rect{x: x - 18, y: y - 24, w: 36, h: 48}
		sdl.render_copy(renderer, tex, &src, &dst)
		return
	}
	sdl.set_render_draw_color(renderer, 180, 150, 60, 255)
	sdl.render_draw_line(renderer, x, y - 8, x, y + 14)
	sdl.render_draw_line(renderer, x - 8, y - 2, x + 8, y - 2)
	sdl.render_draw_line(renderer, x - 8, y - 8, x - 8, y - 2)
	sdl.render_draw_line(renderer, x + 8, y - 8, x + 8, y - 2)
	flicker := int(math.sin(f64(ticks) * 0.02) * 2.0)
	sdl.set_render_draw_color(renderer, 255, 120, 30, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{x: x - 2, y: y - 14 + flicker, w: 4, h: 5})
	sdl.render_fill_rect(renderer, &sdl.Rect{x: x - 10, y: y - 13 + flicker, w: 4, h: 5})
	sdl.render_fill_rect(renderer, &sdl.Rect{x: x + 6, y: y - 13 + flicker, w: 4, h: 5})
}

fn draw_urn(renderer &sdl.Renderer, x int, y int, tex &sdl.Texture) {
	if tex != unsafe { nil } {
		src := sdl.Rect{x: 444, y: 384, w: 32, h: 36}
		dst := sdl.Rect{x: x - 16, y: y - 18, w: 32, h: 36}
		sdl.render_copy(renderer, tex, &src, &dst)
		return
	}
	sdl.set_render_draw_color(renderer, 140, 95, 60, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{x: x - 7, y: y - 8, w: 14, h: 16})
	sdl.set_render_draw_color(renderer, 190, 145, 100, 255)
	sdl.render_draw_rect(renderer, &sdl.Rect{x: x - 7, y: y - 8, w: 14, h: 16})
}

fn draw_floor_pickup(renderer &sdl.Renderer, x int, y int, kind FloorPickupType, ticks u32, tex &sdl.Texture) {
	bob := int(math.sin(f64(ticks) * 0.008) * 3.0)
	cy := y + bob

	if tex != unsafe { nil } {
		src_x := match kind {
			.vacuum_orb { 192 }
			.rosary_bomb { 228 }
			.freeze_watch { 264 }
			.floor_chicken { 300 }
			.coin_bag { 336 }
		}
		src := sdl.Rect{x: src_x, y: 384, w: 36, h: 36}
		dst := sdl.Rect{x: x - 18, y: cy - 18, w: 36, h: 36}
		sdl.render_copy(renderer, tex, &src, &dst)
		return
	}

	match kind {
		.vacuum_orb {
			sdl.set_render_draw_color(renderer, 60, 180, 255, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{x: x - 8, y: cy - 8, w: 16, h: 16})
			sdl.set_render_draw_color(renderer, 255, 255, 255, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{x: x - 4, y: cy - 4, w: 8, h: 8})
		}
		.rosary_bomb {
			sdl.set_render_draw_color(renderer, 255, 220, 70, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{x: x - 3, y: cy - 10, w: 6, h: 20})
			sdl.render_fill_rect(renderer, &sdl.Rect{x: x - 8, y: cy - 6, w: 16, h: 6})
			sdl.set_render_draw_color(renderer, 255, 255, 255, 255)
			sdl.render_draw_rect(renderer, &sdl.Rect{x: x - 3, y: cy - 10, w: 6, h: 20})
		}
		.freeze_watch {
			sdl.set_render_draw_color(renderer, 200, 225, 245, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{x: x - 8, y: cy - 8, w: 16, h: 16})
			sdl.set_render_draw_color(renderer, 40, 90, 160, 255)
			sdl.render_draw_rect(renderer, &sdl.Rect{x: x - 8, y: cy - 8, w: 16, h: 16})
			sdl.render_draw_line(renderer, x, cy, x, cy - 5)
			sdl.render_draw_line(renderer, x, cy, x + 4, cy)
		}
		.floor_chicken {
			sdl.set_render_draw_color(renderer, 190, 110, 45, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{x: x - 9, y: cy - 6, w: 18, h: 12})
			sdl.set_render_draw_color(renderer, 245, 245, 245, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{x: x + 6, y: cy - 2, w: 6, h: 4})
		}
		.coin_bag {
			sdl.set_render_draw_color(renderer, 220, 175, 45, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{x: x - 7, y: cy - 6, w: 14, h: 14})
			sdl.set_render_draw_color(renderer, 140, 40, 30, 255)
			sdl.render_draw_line(renderer, x - 5, cy - 4, x + 5, cy - 4)
		}
	}
}

fn draw_exp_gem(renderer &sdl.Renderer, x int, y int, kind GemType, tex &sdl.Texture) {
	if tex != unsafe { nil } {
		match kind {
			.blue {
				src := sdl.Rect{x: 0, y: 384, w: 32, h: 32}
				dst := sdl.Rect{x: x - 16, y: y - 16, w: 32, h: 32}
				sdl.render_copy(renderer, tex, &src, &dst)
			}
			.green {
				src := sdl.Rect{x: 32, y: 384, w: 32, h: 32}
				dst := sdl.Rect{x: x - 16, y: y - 16, w: 32, h: 32}
				sdl.render_copy(renderer, tex, &src, &dst)
			}
			.red {
				src := sdl.Rect{x: 64, y: 384, w: 32, h: 32}
				dst := sdl.Rect{x: x - 18, y: y - 18, w: 36, h: 36}
				sdl.render_copy(renderer, tex, &src, &dst)
			}
			.chest {
				src := sdl.Rect{x: 96, y: 384, w: 48, h: 40}
				dst := sdl.Rect{x: x - 24, y: y - 20, w: 48, h: 40}
				sdl.render_copy(renderer, tex, &src, &dst)
			}
		}
		return
	}

	match kind {
		.blue {
			sdl.set_render_draw_color(renderer, 80, 200, 255, 255)
			for i in 0 .. 5 {
				sdl.render_draw_line(renderer, x - i, y - 4 + i * 2, x + i, y - 4 + i * 2)
			}
		}
		.green {
			sdl.set_render_draw_color(renderer, 60, 255, 120, 255)
			for i in 0 .. 6 {
				sdl.render_draw_line(renderer, x - i, y - 5 + i * 2, x + i, y - 5 + i * 2)
			}
		}
		.red {
			sdl.set_render_draw_color(renderer, 255, 60, 70, 255)
			for i in 0 .. 7 {
				sdl.render_draw_line(renderer, x - i, y - 6 + i * 2, x + i, y - 6 + i * 2)
			}
		}
		.chest {
			sdl.set_render_draw_color(renderer, 150, 90, 30, 255)
			c_rect := sdl.Rect{x: x - 12, y: y - 10, w: 24, h: 20}
			sdl.render_fill_rect(renderer, &c_rect)
			sdl.set_render_draw_color(renderer, 255, 215, 60, 255)
			sdl.render_draw_rect(renderer, &c_rect)
			sdl.render_draw_line(renderer, x - 12, y, x + 12, y)
			sdl.render_fill_rect(renderer, &sdl.Rect{x: x - 3, y: y - 2, w: 6, h: 6})
		}
	}
}

fn draw_player_sprite(renderer &sdl.Renderer, x int, y int, p Player, tex &sdl.Texture) {
	if p.invuln_time > 0 && int(p.invuln_time * 25.0) % 2 == 0 {
		return
	}

	if tex != unsafe { nil } {
		base_x := match p.char_class {
			.antonio { 0 }
			.imelda { 128 }
			.pasqualina { 256 }
			.gennaro { 384 }
		}
		frame_idx := if p.moving && int(p.walk_frame * 4.0) % 2 == 1 { 64 } else { 0 }
		src := sdl.Rect{x: base_x + frame_idx, y: 0, w: 64, h: 64}
		dst := sdl.Rect{x: x - 32, y: y - 34, w: 64, h: 64}
		flip := if p.facing_right { sdl.RendererFlip.none } else { sdl.RendererFlip.horizontal }
		sdl.render_copy_ex(renderer, tex, &src, &dst, 0.0, unsafe { nil }, flip)

		// Health Bar
		bar_w := 36
		bar_h := 4
		bar_x := x - bar_w / 2
		bar_y := y - 36
		sdl.set_render_draw_color(renderer, 20, 20, 20, 255)
		sdl.render_fill_rect(renderer, &sdl.Rect{x: bar_x, y: bar_y, w: bar_w, h: bar_h})
		hp_pct := math.clamp(p.hp / p.max_hp, 0.0, 1.0)
		sdl.set_render_draw_color(renderer, 70, 220, 90, 255)
		sdl.render_fill_rect(renderer, &sdl.Rect{x: bar_x, y: bar_y, w: int(f64(bar_w) * hp_pct), h: bar_h})
		sdl.set_render_draw_color(renderer, 0, 0, 0, 255)
		sdl.render_draw_rect(renderer, &sdl.Rect{x: bar_x, y: bar_y, w: bar_w, h: bar_h})
		return
	}

	// Procedural fallback
	sdl.set_render_draw_color(renderer, 10, 10, 15, 180)
	sh_rect := sdl.Rect{x: x - 14, y: y + 14, w: 28, h: 8}
	sdl.render_fill_rect(renderer, &sh_rect)

	body_col, cape_col, hair_col := match p.char_class {
		.antonio { Color{r: 60, g: 100, b: 180}, Color{r: 160, g: 30, b: 30}, Color{r: 80, g: 45, b: 20} }
		.imelda { Color{r: 150, g: 50, b: 180}, Color{r: 220, g: 190, b: 80}, Color{r: 230, g: 210, b: 140} }
		.pasqualina { Color{r: 40, g: 140, b: 90}, Color{r: 180, g: 120, b: 40}, Color{r: 200, g: 70, b: 40} }
		.gennaro { Color{r: 140, g: 40, b: 40}, Color{r: 40, g: 40, b: 50}, Color{r: 30, g: 30, b: 35} }
	}

	walk_offset := if p.moving { int(math.sin(p.walk_frame) * 3.0) } else { 0 }
	cape_x := if p.facing_right { x - 10 } else { x + 6 }
	sdl.set_render_draw_color(renderer, cape_col.r, cape_col.g, cape_col.b, 255)
	c_rect := sdl.Rect{x: cape_x, y: y - 6 + walk_offset, w: 8, h: 18}
	sdl.render_fill_rect(renderer, &c_rect)

	sdl.set_render_draw_color(renderer, body_col.r, body_col.g, body_col.b, 255)
	b_rect := sdl.Rect{x: x - 8, y: y - 6 + walk_offset, w: 16, h: 16}
	sdl.render_fill_rect(renderer, &b_rect)

	sdl.set_render_draw_color(renderer, 255, 205, 160, 255)
	h_rect := sdl.Rect{x: x - 6, y: y - 18 + walk_offset, w: 12, h: 12}
	sdl.render_fill_rect(renderer, &h_rect)

	sdl.set_render_draw_color(renderer, hair_col.r, hair_col.g, hair_col.b, 255)
	hair_rect := sdl.Rect{x: x - 7, y: y - 21 + walk_offset, w: 14, h: 6}
	sdl.render_fill_rect(renderer, &hair_rect)

	eye_x := if p.facing_right { x + 1 } else { x - 4 }
	sdl.set_render_draw_color(renderer, 20, 20, 30, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{x: eye_x, y: y - 14 + walk_offset, w: 3, h: 3})

	sdl.set_render_draw_color(renderer, 40, 45, 60, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{x: x - 6, y: y + 10, w: 4, h: 8 + walk_offset})
	sdl.render_fill_rect(renderer, &sdl.Rect{x: x + 2, y: y + 10, w: 4, h: 8 - walk_offset})

	bar_w := 32
	bar_h := 4
	bar_x := x - bar_w / 2
	bar_y := y - 28
	sdl.set_render_draw_color(renderer, 20, 20, 20, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{x: bar_x, y: bar_y, w: bar_w, h: bar_h})
	hp_pct := math.clamp(p.hp / p.max_hp, 0.0, 1.0)
	sdl.set_render_draw_color(renderer, 70, 220, 90, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{x: bar_x, y: bar_y, w: int(f64(bar_w) * hp_pct), h: bar_h})
	sdl.set_render_draw_color(renderer, 0, 0, 0, 255)
	sdl.render_draw_rect(renderer, &sdl.Rect{x: bar_x, y: bar_y, w: bar_w, h: bar_h})
}

fn draw_enemy_sprite(renderer &sdl.Renderer, x int, y int, e Enemy, is_frozen bool, ticks u32, tex &sdl.Texture) {
	if e.is_champion {
		sdl.set_render_draw_color(renderer, 255, 215, 60, 255)
		rad := int(e.radius) + 3
		sdl.render_draw_rect(renderer, &sdl.Rect{x: x - rad, y: y - rad, w: rad * 2, h: rad * 2})
		draw_text(renderer, x - 6, y - rad - 12, '*', 1, Color{r: 255, g: 215, b: 60})
	}

	if e.flash_time > 0 {
		sdl.set_render_draw_color(renderer, 255, 255, 255, 255)
		sdl.render_fill_rect(renderer, &sdl.Rect{x: x - int(e.radius), y: y - int(e.radius), w: int(e.radius * 2), h: int(e.radius * 2)})
		return
	}

	if tex != unsafe { nil } {
		anim_frame := if int(ticks / 180) % 2 == 1 { 1 } else { 0 }
		src, dst := match e.kind {
			.bat {
				sx := if anim_frame == 0 { 0 } else { 48 }
				sdl.Rect{x: sx, y: 128, w: 48, h: 48}, sdl.Rect{x: x - 24, y: y - 24, w: 48, h: 48}
			}
			.skeleton {
				sx := if anim_frame == 0 { 96 } else { 144 }
				sdl.Rect{x: sx, y: 128, w: 48, h: 48}, sdl.Rect{x: x - 24, y: y - 24, w: 48, h: 48}
			}
			.zombie {
				sx := if anim_frame == 0 { 192 } else { 240 }
				sdl.Rect{x: sx, y: 128, w: 48, h: 48}, sdl.Rect{x: x - 24, y: y - 24, w: 48, h: 48}
			}
			.ghost {
				sx := if anim_frame == 0 { 288 } else { 336 }
				sdl.Rect{x: sx, y: 128, w: 48, h: 48}, sdl.Rect{x: x - 24, y: y - 24, w: 48, h: 48}
			}
			.mudman {
				sx := if anim_frame == 0 { 384 } else { 448 }
				sdl.Rect{x: sx, y: 128, w: 64, h: 64}, sdl.Rect{x: x - 32, y: y - 32, w: 64, h: 64}
			}
			.werewolf {
				sx := if anim_frame == 0 { 512 } else { 576 }
				sdl.Rect{x: sx, y: 128, w: 64, h: 64}, sdl.Rect{x: x - 32, y: y - 32, w: 64, h: 64}
			}
			.red_skull {
				sx := if anim_frame == 0 { 640 } else { 704 }
				sdl.Rect{x: sx, y: 128, w: 64, h: 64}, sdl.Rect{x: x - 32, y: y - 32, w: 64, h: 64}
			}
			.reaper_boss {
				sx := if anim_frame == 0 { 768 } else { 864 }
				sdl.Rect{x: sx, y: 128, w: 96, h: 96}, sdl.Rect{x: x - 48, y: y - 48, w: 96, h: 96}
			}
		}
		flip := if e.vx < 0 { sdl.RendererFlip.horizontal } else { sdl.RendererFlip.none }
		sdl.render_copy_ex(renderer, tex, &src, &dst, 0.0, unsafe { nil }, flip)

		if is_frozen {
			sdl.set_render_draw_blend_mode(renderer, .blend)
			sdl.set_render_draw_color(renderer, 100, 200, 255, 120)
			sdl.render_fill_rect(renderer, &dst)
		}
		return
	}

	// Procedural fallback
	if is_frozen {
		sdl.set_render_draw_color(renderer, 100, 200, 255, 255)
	}
	match e.kind {
		.bat {
			wing := int(math.sin(f64(ticks) * 0.02) * 5.0)
			if !is_frozen {
				sdl.set_render_draw_color(renderer, 130, 60, 180, 255)
			}
			sdl.render_fill_rect(renderer, &sdl.Rect{x: x - 4, y: y - 4, w: 8, h: 8})
			sdl.render_draw_line(renderer, x - 4, y, x - 12, y - wing)
			sdl.render_draw_line(renderer, x + 4, y, x + 12, y - wing)
			sdl.set_render_draw_color(renderer, 255, 40, 40, 255)
			sdl.render_draw_point(renderer, x - 2, y - 2)
			sdl.render_draw_point(renderer, x + 2, y - 2)
		}
		.skeleton {
			if !is_frozen {
				sdl.set_render_draw_color(renderer, 225, 225, 225, 255)
			}
			sdl.render_fill_rect(renderer, &sdl.Rect{x: x - 6, y: y - 14, w: 12, h: 10})
			sdl.render_fill_rect(renderer, &sdl.Rect{x: x - 4, y: y - 4, w: 8, h: 10})
			sdl.set_render_draw_color(renderer, 20, 20, 20, 255)
			sdl.render_draw_point(renderer, x - 3, y - 10)
			sdl.render_draw_point(renderer, x + 3, y - 10)
		}
		.zombie {
			if !is_frozen {
				sdl.set_render_draw_color(renderer, 75, 140, 85, 255)
			}
			sdl.render_fill_rect(renderer, &sdl.Rect{x: x - 8, y: y - 14, w: 16, h: 22})
			sdl.set_render_draw_color(renderer, 140, 40, 40, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{x: x - 8, y: y - 4, w: 16, h: 8})
		}
		.ghost {
			if !is_frozen {
				sdl.set_render_draw_color(renderer, 160, 220, 255, 200)
			}
			sdl.render_fill_rect(renderer, &sdl.Rect{x: x - 8, y: y - 12, w: 16, h: 18})
			sdl.set_render_draw_color(renderer, 40, 40, 70, 255)
			sdl.render_draw_point(renderer, x - 3, y - 6)
			sdl.render_draw_point(renderer, x + 3, y - 6)
		}
		.mudman {
			if !is_frozen {
				sdl.set_render_draw_color(renderer, 120, 80, 50, 255)
			}
			sdl.render_fill_rect(renderer, &sdl.Rect{x: x - 12, y: y - 14, w: 24, h: 24})
			sdl.set_render_draw_color(renderer, 240, 200, 80, 255)
			sdl.render_draw_point(renderer, x - 5, y - 6)
			sdl.render_draw_point(renderer, x + 5, y - 6)
		}
		.werewolf {
			if !is_frozen {
				sdl.set_render_draw_color(renderer, 140, 50, 40, 255)
			}
			sdl.render_fill_rect(renderer, &sdl.Rect{x: x - 10, y: y - 16, w: 20, h: 26})
			sdl.set_render_draw_color(renderer, 255, 230, 40, 255)
			sdl.render_draw_point(renderer, x - 4, y - 10)
			sdl.render_draw_point(renderer, x + 4, y - 10)
		}
		.red_skull {
			if !is_frozen {
				sdl.set_render_draw_color(renderer, 255, 40, 40, 255)
			}
			sdl.render_fill_rect(renderer, &sdl.Rect{x: x - 14, y: y - 16, w: 28, h: 26})
			sdl.set_render_draw_color(renderer, 255, 220, 40, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{x: x - 8, y: y - 8, w: 4, h: 6})
			sdl.render_fill_rect(renderer, &sdl.Rect{x: x + 4, y: y - 8, w: 4, h: 6})
		}
		.reaper_boss {
			sdl.set_render_draw_color(renderer, 20, 20, 25, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{x: x - 22, y: y - 30, w: 44, h: 54})
			sdl.set_render_draw_color(renderer, 255, 30, 30, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{x: x - 8, y: y - 14, w: 5, h: 4})
			sdl.render_fill_rect(renderer, &sdl.Rect{x: x + 3, y: y - 14, w: 5, h: 4})
			sdl.set_render_draw_color(renderer, 200, 215, 235, 255)
			sdl.render_draw_line(renderer, x + 16, y - 36, x + 32, y - 20)
			sdl.render_draw_line(renderer, x + 32, y - 20, x + 24, y + 24)
		}
	}
}

fn draw_projectile(renderer &sdl.Renderer, x int, y int, pr Projectile, ticks u32, tex &sdl.Texture) {
	if tex != unsafe { nil } {
		match pr.kind {
			.whip {
				src := sdl.Rect{x: 0, y: 256, w: 96, h: 48}
				dst := sdl.Rect{x: x - 48, y: y - 24, w: 96, h: 48}
				sdl.render_copy(renderer, tex, &src, &dst)
			}
			.bloody_tear {
				src := sdl.Rect{x: 96, y: 256, w: 96, h: 48}
				dst := sdl.Rect{x: x - 48, y: y - 24, w: 96, h: 48}
				sdl.render_copy(renderer, tex, &src, &dst)
			}
			.magic_wand {
				src := sdl.Rect{x: 192, y: 256, w: 32, h: 32}
				dst := sdl.Rect{x: x - 16, y: y - 16, w: 32, h: 32}
				sdl.render_copy(renderer, tex, &src, &dst)
			}
			.holy_wand {
				src := sdl.Rect{x: 224, y: 256, w: 32, h: 32}
				dst := sdl.Rect{x: x - 16, y: y - 16, w: 32, h: 32}
				sdl.render_copy(renderer, tex, &src, &dst)
			}
			.knife {
				src := sdl.Rect{x: 256, y: 256, w: 32, h: 32}
				dst := sdl.Rect{x: x - 16, y: y - 16, w: 32, h: 32}
				deg := pr.angle * (180.0 / math.pi)
				sdl.render_copy_ex(renderer, tex, &src, &dst, deg, unsafe { nil }, sdl.RendererFlip.none)
			}
			.thousand_edge {
				src := sdl.Rect{x: 288, y: 256, w: 32, h: 32}
				dst := sdl.Rect{x: x - 16, y: y - 16, w: 32, h: 32}
				deg := pr.angle * (180.0 / math.pi)
				sdl.render_copy_ex(renderer, tex, &src, &dst, deg, unsafe { nil }, sdl.RendererFlip.none)
			}
			.axe {
				src := sdl.Rect{x: 320, y: 256, w: 48, h: 48}
				dst := sdl.Rect{x: x - 24, y: y - 24, w: 48, h: 48}
				deg := f64((ticks * 2) % 360)
				sdl.render_copy_ex(renderer, tex, &src, &dst, deg, unsafe { nil }, sdl.RendererFlip.none)
			}
			.death_spiral {
				src := sdl.Rect{x: 368, y: 256, w: 48, h: 48}
				dst := sdl.Rect{x: x - 24, y: y - 24, w: 48, h: 48}
				deg := f64((ticks * 3) % 360)
				sdl.render_copy_ex(renderer, tex, &src, &dst, deg, unsafe { nil }, sdl.RendererFlip.none)
			}
			.holy_bible {
				src := sdl.Rect{x: 416, y: 256, w: 36, h: 44}
				dst := sdl.Rect{x: x - 18, y: y - 22, w: 36, h: 44}
				deg := pr.angle * (180.0 / math.pi)
				sdl.render_copy_ex(renderer, tex, &src, &dst, deg, unsafe { nil }, sdl.RendererFlip.none)
			}
			.unholy_vespers {
				src := sdl.Rect{x: 452, y: 256, w: 36, h: 44}
				dst := sdl.Rect{x: x - 18, y: y - 22, w: 36, h: 44}
				deg := pr.angle * (180.0 / math.pi)
				sdl.render_copy_ex(renderer, tex, &src, &dst, deg, unsafe { nil }, sdl.RendererFlip.none)
			}
			.garlic {
				src := sdl.Rect{x: 488, y: 256, w: 64, h: 64}
				rad := int(pr.radius * 1.5)
				dst := sdl.Rect{x: x - rad, y: y - rad, w: rad * 2, h: rad * 2}
				sdl.render_copy(renderer, tex, &src, &dst)
			}
			.soul_eater {
				src := sdl.Rect{x: 552, y: 256, w: 64, h: 64}
				rad := int(pr.radius * 1.6)
				dst := sdl.Rect{x: x - rad, y: y - rad, w: rad * 2, h: rad * 2}
				sdl.render_copy(renderer, tex, &src, &dst)
			}
			.lightning_ring {
				src := sdl.Rect{x: 616, y: 256, w: 48, h: 80}
				dst := sdl.Rect{x: x - 24, y: y - 60, w: 48, h: 80}
				sdl.render_copy(renderer, tex, &src, &dst)
			}
			.fire_wand {
				src := sdl.Rect{x: 664, y: 256, w: 40, h: 40}
				dst := sdl.Rect{x: x - 20, y: y - 20, w: 40, h: 40}
				sdl.render_copy(renderer, tex, &src, &dst)
			}
			.cataclysm_nuke {
				src := sdl.Rect{x: 704, y: 256, w: 64, h: 64}
				rad := int(pr.radius)
				dst := sdl.Rect{x: x - rad, y: y - rad, w: rad * 2, h: rad * 2}
				sdl.render_copy(renderer, tex, &src, &dst)
			}
			.prismatic_laser {
				src := sdl.Rect{x: 768, y: 256, w: 64, h: 64}
				dst := sdl.Rect{x: x - 32, y: y - 32, w: 64, h: 64}
				deg := pr.angle * (180.0 / math.pi)
				sdl.render_copy_ex(renderer, tex, &src, &dst, deg, unsafe { nil }, sdl.RendererFlip.none)
			}
		}
		return
	}

	// Procedural Fallback
	match pr.kind {
		.whip {
			sdl.set_render_draw_color(renderer, 255, 220, 80, 255)
			sdl.render_draw_line(renderer, x - 35, y, x + 35, y)
			sdl.set_render_draw_color(renderer, 255, 255, 255, 255)
			sdl.render_draw_line(renderer, x - 30, y - 2, x + 30, y + 2)
		}
		.bloody_tear {
			sdl.set_render_draw_color(renderer, 255, 40, 60, 255)
			sdl.render_draw_line(renderer, x - 50, y, x + 50, y)
			sdl.set_render_draw_color(renderer, 255, 180, 200, 255)
			sdl.render_draw_line(renderer, x - 45, y - 3, x + 45, y + 3)
		}
		.magic_wand, .holy_wand {
			sdl.set_render_draw_color(renderer, 80, 230, 255, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{x: x - 4, y: y - 4, w: 8, h: 8})
			sdl.set_render_draw_color(renderer, 255, 255, 255, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{x: x - 2, y: y - 2, w: 4, h: 4})
		}
		.knife, .thousand_edge {
			sdl.set_render_draw_color(renderer, 210, 220, 235, 255)
			vx := math.cos(pr.angle) * 12.0
			vy := math.sin(pr.angle) * 12.0
			sdl.render_draw_line(renderer, x - int(vx), y - int(vy), x + int(vx), y + int(vy))
		}
		.axe {
			sdl.set_render_draw_color(renderer, 170, 180, 195, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{x: x - 6, y: y - 6, w: 12, h: 12})
			sdl.set_render_draw_color(renderer, 120, 75, 30, 255)
			sdl.render_draw_line(renderer, x, y - 10, x, y + 10)
		}
		.death_spiral {
			sdl.set_render_draw_color(renderer, 30, 30, 40, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{x: x - 8, y: y - 8, w: 16, h: 16})
			sdl.set_render_draw_color(renderer, 220, 220, 235, 255)
			sdl.render_draw_line(renderer, x - 10, y - 10, x + 10, y + 10)
		}
		.holy_bible, .unholy_vespers {
			col := if pr.kind == .unholy_vespers { Color{r: 255, g: 60, b: 60} } else { Color{r: 255, g: 220, b: 80} }
			sdl.set_render_draw_color(renderer, 70, 30, 15, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{x: x - 7, y: y - 9, w: 14, h: 18})
			sdl.set_render_draw_color(renderer, col.r, col.g, col.b, 255)
			sdl.render_draw_rect(renderer, &sdl.Rect{x: x - 7, y: y - 9, w: 14, h: 18})
			sdl.render_draw_line(renderer, x, y - 6, x, y + 6)
			sdl.render_draw_line(renderer, x - 4, y - 2, x + 4, y - 2)
		}
		.garlic, .soul_eater {
			col := if pr.kind == .soul_eater { Color{r: 160, g: 40, b: 180, a: 160} } else { Color{r: 160, g: 255, b: 180, a: 120} }
			sdl.set_render_draw_blend_mode(renderer, .blend)
			sdl.set_render_draw_color(renderer, col.r, col.g, col.b, col.a)
			rad := int(pr.radius)
			for ang_i in 0 .. 16 {
				ang1 := f64(ang_i) * math.pi / 8.0
				ang2 := f64(ang_i + 1) * math.pi / 8.0
				x1 := x + int(math.cos(ang1) * f64(rad))
				y1 := y + int(math.sin(ang1) * f64(rad))
				x2 := x + int(math.cos(ang2) * f64(rad))
				y2 := y + int(math.sin(ang2) * f64(rad))
				sdl.render_draw_line(renderer, x1, y1, x2, y2)
			}
		}
		.lightning_ring {
			sdl.set_render_draw_color(renderer, 200, 140, 255, 255)
			sdl.render_draw_line(renderer, x, y - 80, x - 10, y - 30)
			sdl.render_draw_line(renderer, x - 10, y - 30, x + 8, y - 10)
			sdl.render_draw_line(renderer, x + 8, y - 10, x, y)
		}
		.fire_wand {
			sdl.set_render_draw_color(renderer, 255, 100, 30, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{x: x - 6, y: y - 6, w: 12, h: 12})
			sdl.set_render_draw_color(renderer, 255, 220, 60, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{x: x - 3, y: y - 3, w: 6, h: 6})
		}
		.cataclysm_nuke {
			rad := int(pr.radius)
			sdl.set_render_draw_blend_mode(renderer, .blend)
			sdl.set_render_draw_color(renderer, 255, 140, 20, 160)
			sdl.render_fill_rect(renderer, &sdl.Rect{x: x - rad, y: y - rad, w: rad * 2, h: rad * 2})
			sdl.set_render_draw_color(renderer, 255, 255, 100, 220)
			sdl.render_fill_rect(renderer, &sdl.Rect{x: x - rad / 2, y: y - rad / 2, w: rad, h: rad})
			sdl.set_render_draw_color(renderer, 255, 255, 255, 255)
			sdl.render_draw_rect(renderer, &sdl.Rect{x: x - rad, y: y - rad, w: rad * 2, h: rad * 2})
		}
		.prismatic_laser {
			vx := math.cos(pr.angle) * 140.0
			vy := math.sin(pr.angle) * 140.0
			sdl.set_render_draw_color(renderer, 80, 240, 255, 255)
			sdl.render_draw_line(renderer, x - int(vx), y - int(vy), x + int(vx), y + int(vy))
			sdl.set_render_draw_color(renderer, 255, 255, 255, 255)
			sdl.render_draw_line(renderer, x - int(vx) / 2, y - int(vy) / 2, x + int(vx) / 2, y + int(vy) / 2)
		}
	}
}

// HUD Overlay & Radar
pub fn (g &Game) render_hud(renderer &sdl.Renderer) {
	if g.players.len == 0 {
		return
	}
	p1 := g.players[0]

	// 1. Top EXP Bar
	exp_bar_bg := sdl.Rect{x: 0, y: 0, w: win_width, h: 18}
	sdl.set_render_draw_color(renderer, 15, 20, 32, 240)
	sdl.render_fill_rect(renderer, &exp_bar_bg)

	exp_pct := math.clamp(f64(p1.exp) / f64(p1.exp_next), 0.0, 1.0)
	exp_fill := sdl.Rect{x: 0, y: 0, w: int(f64(win_width) * exp_pct), h: 18}
	sdl.set_render_draw_color(renderer, 40, 160, 255, 255)
	sdl.render_fill_rect(renderer, &exp_fill)
	sdl.set_render_draw_color(renderer, 80, 220, 255, 255)
	sdl.render_draw_line(renderer, 0, 17, win_width, 17)

	draw_text(renderer, 12, 4, 'LV ${p1.level}  EXP ${p1.exp} / ${p1.exp_next}', 1, Color{r: 255, g: 255, b: 255})

	// 2. Top Status Bar (Timer, Kills, Gold)
	mins := int(g.game_time) / 60
	secs := int(g.game_time) % 60
	time_str := if secs < 10 { '${mins}:0${secs}' } else { '${mins}:${secs}' }

	time_box := sdl.Rect{x: win_width / 2 - 70, y: 24, w: 140, h: 32}
	sdl.set_render_draw_color(renderer, 20, 24, 38, 220)
	sdl.render_fill_rect(renderer, &time_box)
	sdl.set_render_draw_color(renderer, 60, 75, 115, 255)
	sdl.render_draw_rect(renderer, &time_box)
	draw_text_centered(renderer, win_width / 2, 32, time_str, 2, Color{r: 255, g: 255, b: 255})

	// Kills & Gold
	draw_text(renderer, win_width - 240, 32, 'KILLS: ${g.total_kills}', 2, Color{r: 255, g: 100, b: 100})
	draw_text(renderer, win_width - 100, 32, '$ ${p1.gold}', 2, Color{r: 255, g: 215, b: 60})

	// 3. Left Inventory Trays
	mut icon_x := 20
	for w in p1.weapons {
		w_box := sdl.Rect{x: icon_x, y: 28, w: 32, h: 32}
		sdl.set_render_draw_color(renderer, 30, 35, 55, 230)
		sdl.render_fill_rect(renderer, &w_box)
		border_col := if w.is_evolved { Color{r: 255, g: 215, b: 60} } else { Color{r: 70, g: 90, b: 140} }
		sdl.set_render_draw_color(renderer, border_col.r, border_col.g, border_col.b, 255)
		sdl.render_draw_rect(renderer, &w_box)

		if g.sprite_texture != unsafe { nil } {
			w_idx := match w.kind {
				.whip { 0 }
				.magic_wand { 1 }
				.knife { 2 }
				.axe { 3 }
				.holy_bible { 4 }
				.garlic { 5 }
				.lightning_ring { 6 }
				.fire_wand { 7 }
				.cataclysm_nuke { 8 }
				.prismatic_laser { 9 }
				.bloody_tear { 10 }
				.holy_wand { 11 }
				.thousand_edge { 12 }
				.death_spiral { 13 }
				.unholy_vespers { 14 }
				.soul_eater { 15 }
			}
			src := sdl.Rect{x: w_idx * 32, y: 512, w: 32, h: 32}
			sdl.render_copy(renderer, g.sprite_texture, &src, &w_box)
		} else {
			let := match w.kind {
				.whip, .bloody_tear { 'W' }
				.magic_wand, .holy_wand { 'M' }
				.knife, .thousand_edge { 'K' }
				.axe, .death_spiral { 'A' }
				.holy_bible, .unholy_vespers { 'B' }
				.garlic, .soul_eater { 'G' }
				.lightning_ring { 'L' }
				.fire_wand { 'F' }
				.cataclysm_nuke { 'N' }
				.prismatic_laser { 'P' }
			}
			txt_col := if w.is_evolved { Color{r: 255, g: 80, b: 80} } else { Color{r: 255, g: 220, b: 80} }
			draw_text(renderer, icon_x + 8, 34, let, 2, txt_col)
		}
		draw_text(renderer, icon_x + 20, 46, '${w.level}', 1, Color{r: 100, g: 240, b: 255})
		icon_x += 38
	}

	mut p_icon_x := 20
	for pass in p1.passives {
		p_box := sdl.Rect{x: p_icon_x, y: 66, w: 26, h: 26}
		sdl.set_render_draw_color(renderer, 24, 30, 48, 230)
		sdl.render_fill_rect(renderer, &p_box)
		sdl.set_render_draw_color(renderer, 50, 70, 110, 255)
		sdl.render_draw_rect(renderer, &p_box)

		if g.sprite_texture != unsafe { nil } {
			p_idx := match pass.kind {
				.spinach { 0 }
				.armor { 1 }
				.empty_tome { 2 }
				.wings { 3 }
				.crown { 4 }
				.duplicator { 5 }
			}
			src := sdl.Rect{x: p_idx * 32, y: 544, w: 32, h: 32}
			sdl.render_copy(renderer, g.sprite_texture, &src, &p_box)
		} else {
			let := match pass.kind {
				.spinach { 'S' }
				.armor { 'R' }
				.empty_tome { 'T' }
				.wings { 'W' }
				.crown { 'C' }
				.duplicator { 'D' }
			}
			draw_text(renderer, p_icon_x + 6, 71, let, 1, Color{r: 120, g: 255, b: 150})
		}
		draw_text(renderer, p_icon_x + 16, 78, '${pass.level}', 1, Color{r: 255, g: 255, b: 255})
		p_icon_x += 30
	}

	// 4. Ultimate Ability Meter Bar (Bottom Center)
	ult_w := 240
	ult_h := 14
	ult_x := win_width / 2 - ult_w / 2
	ult_y := win_height - 48

	sdl.set_render_draw_color(renderer, 15, 20, 32, 220)
	sdl.render_fill_rect(renderer, &sdl.Rect{x: ult_x, y: ult_y, w: ult_w, h: ult_h})
	ult_pct := math.clamp(p1.ultimate_meter / p1.ultimate_max, 0.0, 1.0)
	is_ult_ready := p1.ultimate_meter >= p1.ultimate_max

	ult_fill_col := if is_ult_ready { Color{r: 255, g: 215, b: 60} } else { Color{r: 180, g: 50, b: 220} }
	sdl.set_render_draw_color(renderer, ult_fill_col.r, ult_fill_col.g, ult_fill_col.b, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{x: ult_x, y: ult_y, w: int(f64(ult_w) * ult_pct), h: ult_h})
	sdl.set_render_draw_color(renderer, 255, 255, 255, 255)
	sdl.render_draw_rect(renderer, &sdl.Rect{x: ult_x, y: ult_y, w: ult_w, h: ult_h})

	ult_label := if is_ult_ready { '[SPACE] ULTIMATE READY!' } else { 'ULTIMATE: ${int(p1.ultimate_meter)}%' }
	draw_text_centered(renderer, win_width / 2, ult_y - 18, ult_label, 1, if is_ult_ready { Color{r: 255, g: 225, b: 60} } else { Color{r: 200, g: 170, b: 240} })

	// 5. Minimap Radar (Top-Right)
	if g.show_radar {
		r_size := 80
		r_x := win_width - r_size - 16
		r_y := 70
		sdl.set_render_draw_blend_mode(renderer, .blend)
		sdl.set_render_draw_color(renderer, 15, 20, 30, 200)
		r_rect := sdl.Rect{x: r_x, y: r_y, w: r_size, h: r_size}
		sdl.render_fill_rect(renderer, &r_rect)
		sdl.set_render_draw_color(renderer, 50, 70, 110, 255)
		sdl.render_draw_rect(renderer, &r_rect)

		scale_x := f64(r_size) / world_width
		scale_y := f64(r_size) / world_height
		px := r_x + int(p1.x * scale_x)
		py := r_y + int(p1.y * scale_y)
		sdl.set_render_draw_color(renderer, 60, 255, 120, 255)
		sdl.render_fill_rect(renderer, &sdl.Rect{x: px - 1, y: py - 1, w: 3, h: 3})

		for e in g.enemies {
			if e.is_boss {
				bx := r_x + int(e.x * scale_x)
				by := r_y + int(e.y * scale_y)
				sdl.set_render_draw_color(renderer, 255, 40, 40, 255)
				sdl.render_fill_rect(renderer, &sdl.Rect{x: bx - 2, y: by - 2, w: 4, h: 4})
			}
		}
	}

	// 6. Bottom Controls Helper
	bgm_name := match g.sound_mgr.bgm_track {
		.gothic_rondo { 'GOTHIC RONDO' }
		.vampires_eclipse { 'VAMPIRE ECLIPSE' }
		.bloodlust_symphony { 'BLOODLUST SYMPHONY' }
		.off { 'OFF' }
	}
	spd_str := if g.game_speed == 1.0 { '1.0X' } else if g.game_speed == 1.5 { '1.5X FAST' } else if g.game_speed == 2.0 { '2.0X HYPER' } else { '3.0X TURBO' }
	diff_str := match g.difficulty {
		.normal { 'NORMAL' }
		.hard { 'HARD' }
		.inferno { 'INFERNO' }
	}
	draw_text(renderer, 20, win_height - 24, 'WASD: MOVE  [SPACE] ULT  [H] SPEED: ${spd_str}  [D] DIFF: ${diff_str}  [T/B] ${bgm_name}  [F11] Fullscreen', 1, Color{r: 170, g: 190, b: 230})
}

// Level Up Card Selection Modal
pub fn (g &Game) render_level_up_modal(renderer &sdl.Renderer) {
	sdl.set_render_draw_color(renderer, 8, 10, 18, 220)
	overlay := sdl.Rect{x: 0, y: 0, w: win_width, h: win_height}
	sdl.render_fill_rect(renderer, &overlay)

	modal_w := 660
	modal_h := 470
	modal_x := win_width / 2 - modal_w / 2
	modal_y := win_height / 2 - modal_h / 2

	sdl.set_render_draw_color(renderer, 24, 28, 44, 255)
	m_rect := sdl.Rect{x: modal_x, y: modal_y, w: modal_w, h: modal_h}
	sdl.render_fill_rect(renderer, &m_rect)
	sdl.set_render_draw_color(renderer, 215, 175, 60, 255)
	sdl.render_draw_rect(renderer, &m_rect)

	draw_text_centered(renderer, win_width / 2, modal_y + 24, 'LEVEL UP!', 3, Color{r: 255, g: 225, b: 60})
	draw_text_centered(renderer, win_width / 2, modal_y + 60, 'CHOOSE YOUR POWER UPGRADE [1-3] OR [ENTER]', 2, Color{r: 180, g: 200, b: 240})

	for i, card in g.upgrade_cards {
		card_y := modal_y + 105 + i * 105
		card_w := modal_w - 60
		card_h := 88
		card_x := modal_x + 30

		is_sel := i == g.selected_card
		bg_col := if is_sel { Color{r: 45, g: 55, b: 85} } else { Color{r: 16, g: 20, b: 32} }
		border_col := if card.is_evolution { Color{r: 255, g: 60, b: 60} } else if is_sel { Color{r: 255, g: 220, b: 80} } else { Color{r: 60, g: 75, b: 110} }

		sdl.set_render_draw_color(renderer, bg_col.r, bg_col.g, bg_col.b, 255)
		c_rect := sdl.Rect{x: card_x, y: card_y, w: card_w, h: card_h}
		sdl.render_fill_rect(renderer, &c_rect)
		sdl.set_render_draw_color(renderer, border_col.r, border_col.g, border_col.b, 255)
		sdl.render_draw_rect(renderer, &c_rect)

		if g.sprite_texture != unsafe { nil } {
			if card.is_weapon {
				w_idx := match card.w_kind {
					.whip { 0 }
					.magic_wand { 1 }
					.knife { 2 }
					.axe { 3 }
					.holy_bible { 4 }
					.garlic { 5 }
					.lightning_ring { 6 }
					.fire_wand { 7 }
					.cataclysm_nuke { 8 }
					.prismatic_laser { 9 }
					.bloody_tear { 10 }
					.holy_wand { 11 }
					.thousand_edge { 12 }
					.death_spiral { 13 }
					.unholy_vespers { 14 }
					.soul_eater { 15 }
				}
				src := sdl.Rect{x: w_idx * 32, y: 512, w: 32, h: 32}
				dst := sdl.Rect{x: card_x + 14, y: card_y + 14, w: 36, h: 36}
				sdl.render_copy(renderer, g.sprite_texture, &src, &dst)
			} else {
				p_idx := match card.p_kind {
					.spinach { 0 }
					.armor { 1 }
					.empty_tome { 2 }
					.wings { 3 }
					.crown { 4 }
					.duplicator { 5 }
				}
				src := sdl.Rect{x: p_idx * 32, y: 544, w: 32, h: 32}
				dst := sdl.Rect{x: card_x + 14, y: card_y + 14, w: 36, h: 36}
				sdl.render_copy(renderer, g.sprite_texture, &src, &dst)
			}
		}

		tag_txt := if card.is_evolution { 'SUPER EVOLUTION' } else if card.is_weapon { 'WEAPON' } else { 'PASSIVE' }
		tag_col := if card.is_evolution { Color{r: 255, g: 60, b: 60} } else if card.is_weapon { Color{r: 255, g: 140, b: 60} } else { Color{r: 100, g: 230, b: 255} }

		draw_text(renderer, card_x + 60, card_y + 14, '[${i + 1}] ${card.name} (LV ${card.level})', 2, Color{r: 255, g: 255, b: 255})
		draw_text(renderer, card_x + card_w - 140, card_y + 14, tag_txt, 1, tag_col)
		draw_text(renderer, card_x + 60, card_y + 44, card.desc, 1, Color{r: 190, g: 205, b: 235})
	}
}

// Chest Opened Modal
pub fn (g &Game) render_chest_modal(renderer &sdl.Renderer) {
	sdl.set_render_draw_color(renderer, 10, 12, 22, 230)
	sdl.render_fill_rect(renderer, &sdl.Rect{x: 0, y: 0, w: win_width, h: win_height})

	title_col := if g.chest_tier == 5 { Color{r: 255, g: 220, b: 60} } else if g.chest_tier == 3 { Color{r: 100, g: 240, b: 255} } else { Color{r: 255, g: 255, b: 255} }
	header := if g.chest_tier == 5 { '⭐️ MEGA JACKPOT CHEST! ⭐️' } else if g.chest_tier == 3 { '⭐️ TRIPLE SUPER CHEST! ⭐️' } else { 'TREASURE CHEST OPENED!' }

	draw_text_centered(renderer, win_width / 2, win_height / 2 - 130, header, 3, title_col)

	if g.sprite_texture != unsafe { nil } {
		src := sdl.Rect{x: 144, y: 384, w: 48, h: 40}
		dst := sdl.Rect{x: win_width / 2 - 36, y: win_height / 2 - 70, w: 72, h: 60}
		sdl.render_copy(renderer, g.sprite_texture, &src, &dst)
	} else {
		draw_exp_gem(renderer, win_width / 2, win_height / 2 - 50, .chest, g.sprite_texture)
	}

	for i, item in g.chest_items {
		draw_text_centered(renderer, win_width / 2, win_height / 2 + 10 + i * 30, item, 2, Color{r: 255, g: 255, b: 255})
	}
	draw_text_centered(renderer, win_width / 2, win_height / 2 + 140, 'PRESS [SPACE] OR [ENTER] TO CLAIM', 2, Color{r: 100, g: 230, b: 255})
}

// Pause Menu: DPS Stats & Evolution Grimoire
pub fn (g &Game) render_pause_grimoire(renderer &sdl.Renderer) {
	sdl.set_render_draw_color(renderer, 8, 12, 20, 235)
	sdl.render_fill_rect(renderer, &sdl.Rect{x: 0, y: 0, w: win_width, h: win_height})

	draw_text_centered(renderer, win_width / 2, 40, 'PAUSED // STATS & EVOLUTION RECIPES', 3, Color{r: 255, g: 220, b: 80})

	// Weapon DPS Stats Table
	p1 := g.players[0]
	card_x := 60
	card_w := 420
	card_y := 100

	sdl.set_render_draw_color(renderer, 20, 25, 40, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{x: card_x, y: card_y, w: card_w, h: 520})
	sdl.set_render_draw_color(renderer, 60, 80, 130, 255)
	sdl.render_draw_rect(renderer, &sdl.Rect{x: card_x, y: card_y, w: card_w, h: 520})

	draw_text(renderer, card_x + 20, card_y + 20, 'EQUIPPED WEAPON DPS', 2, Color{r: 100, g: 220, b: 255})
	for i, w in p1.weapons {
		wy := card_y + 60 + i * 50
		dps := if g.game_time > 0.1 { w.total_damage / g.game_time } else { 0.0 }
		w_name := get_weapon_name(w.kind)
		draw_text(renderer, card_x + 20, wy, '${w_name} (LV ${w.level})', 1, Color{r: 255, g: 255, b: 255})
		draw_text(renderer, card_x + 20, wy + 16, 'TOTAL DMG: ${int(w.total_damage)}  DPS: ${int(dps)}', 1, Color{r: 170, g: 200, b: 240})
	}

	// Evolution Grimoire
	g_x := 510
	g_w := 430
	sdl.set_render_draw_color(renderer, 20, 25, 40, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{x: g_x, y: card_y, w: g_w, h: 520})
	sdl.set_render_draw_color(renderer, 60, 80, 130, 255)
	sdl.render_draw_rect(renderer, &sdl.Rect{x: g_x, y: card_y, w: g_w, h: 520})

	draw_text(renderer, g_x + 20, card_y + 20, 'WEAPON EVOLUTION RECIPES', 2, Color{r: 255, g: 140, b: 60})
	recipes := [
		['WHIP (LV8) + SPINACH', '-> BLOODY TEAR (Lifesteal)'],
		['MAGIC WAND (LV8) + TOME', '-> HOLY WAND (No Cooldown)'],
		['KNIFE (LV8) + DUPLICATOR', '-> THOUSAND EDGE (Stream)'],
		['AXE (LV8) + WINGS', '-> DEATH SPIRAL (Scythes)'],
		['KING BIBLE (LV8) + CROWN', '-> UNHOLY VESPERS (Never fades)'],
		['GARLIC (LV8) + ARMOR', '-> SOUL EATER (Dark Aura)'],
	]
	for r_i, rec in recipes {
		ry := card_y + 60 + r_i * 65
		draw_text(renderer, g_x + 20, ry, rec[0], 1, Color{r: 255, g: 220, b: 80})
		draw_text(renderer, g_x + 20, ry + 18, rec[1], 1, Color{r: 120, g: 255, b: 150})
	}

	draw_text_centered(renderer, win_width / 2, win_height - 60, 'PRESS [P] OR [ESC] TO RESUME SURVIVING', 2, Color{r: 255, g: 255, b: 255})
}

// Character Select Screen
pub fn (g &Game) render_character_select(renderer &sdl.Renderer) {
	sdl.set_render_draw_color(renderer, 12, 15, 24, 255)
	sdl.render_clear(renderer)

	draw_text_centered(renderer, win_width / 2, 40, 'VAMPIRE SURVIVORS', 4, Color{r: 255, g: 50, b: 50})
	draw_text_centered(renderer, win_width / 2, 85, 'AAA GOTHIC BULLET-HELL SURVIVAL HORDE', 2, Color{r: 200, g: 215, b: 245})

	chars := [
		['ANTONIO BELPAESE', 'WEAPON: WHIP Master', '+10% MELEE DAMAGE', 'ULT: BLOOD TEMPEST'],
		['IMELDA BELPAESE', 'WEAPON: MAGIC WAND', '+10% EXP GROWTH', 'ULT: ASTRAL NOVA'],
		['PASQUALINA BELPAESE', 'WEAPON: KING BIBLE', '+10% SPEED', 'ULT: RUNIC JUDGEMENT'],
		['GENNARO BELPAESE', 'WEAPON: KNIFE Master', '+1 EXTRA PROJECTILE', 'ULT: BLADE HURRICANE'],
	]

	for i, c_info in chars {
		card_x := 60 + i * 225
		card_y := 140
		card_w := 205
		card_h := 400

		sdl.set_render_draw_color(renderer, 24, 30, 48, 255)
		c_rect := sdl.Rect{x: card_x, y: card_y, w: card_w, h: card_h}
		sdl.render_fill_rect(renderer, &c_rect)
		sdl.set_render_draw_color(renderer, 60, 80, 130, 255)
		sdl.render_draw_rect(renderer, &c_rect)

		if g.sprite_texture != unsafe { nil } {
			src := sdl.Rect{x: 512 + i * 64, y: 0, w: 64, h: 64}
			dst := sdl.Rect{x: card_x + card_w / 2 - 32, y: card_y + 20, w: 64, h: 64}
			sdl.render_copy(renderer, g.sprite_texture, &src, &dst)
		} else {
			dummy_p := Player{char_class: match i {
				0 { CharacterClass.antonio }
				1 { CharacterClass.imelda }
				2 { CharacterClass.pasqualina }
				else { CharacterClass.gennaro }
			}, hp: 100.0, max_hp: 100.0}
			draw_player_sprite(renderer, card_x + card_w / 2, card_y + 65, dummy_p, g.sprite_texture)
		}

		draw_text_centered(renderer, card_x + card_w / 2, card_y + 95, '[${i + 1}]', 2, Color{r: 255, g: 215, b: 60})
		draw_text_centered(renderer, card_x + card_w / 2, card_y + 130, c_info[0], 1, Color{r: 255, g: 255, b: 255})
		draw_text_centered(renderer, card_x + card_w / 2, card_y + 160, c_info[1], 1, Color{r: 100, g: 220, b: 255})
		draw_text_centered(renderer, card_x + card_w / 2, card_y + 190, c_info[2], 1, Color{r: 120, g: 255, b: 150})
		draw_text_centered(renderer, card_x + card_w / 2, card_y + 220, c_info[3], 1, Color{r: 255, g: 140, b: 220})
	}

	coop_str := if g.is_coop { 'MODE: 2-PLAYER CO-OP [C]' } else { 'MODE: 1-PLAYER SOLO [C]' }
	diff_str := match g.difficulty {
		.normal { 'DIFFICULTY: NORMAL [D]' }
		.hard { 'DIFFICULTY: HARD (CHALLENGE) [D]' }
		.inferno { 'DIFFICULTY: INFERNO (BULLET-HELL) [D]' }
	}
	diff_col := match g.difficulty {
		.normal { Color{r: 100, g: 240, b: 255} }
		.hard { Color{r: 255, g: 180, b: 60} }
		.inferno { Color{r: 255, g: 50, b: 50} }
	}
	draw_text_centered(renderer, win_width / 2, 555, coop_str, 2, Color{r: 255, g: 220, b: 80})
	draw_text_centered(renderer, win_width / 2, 595, diff_str, 2, diff_col)
	draw_text_centered(renderer, win_width / 2, 635, 'PRESS [1-4] TO SELECT HERO & START SURVIVING', 2, Color{r: 255, g: 255, b: 255})
	draw_text_centered(renderer, win_width / 2, 675, 'WASD/ARROWS: MOVE  [SPACE] ULTIMATE  [H] SPEED  [D] DIFF  [F11] Fullscreen', 1, Color{r: 180, g: 195, b: 230})
}

// Game Over Banner
pub fn (g &Game) render_game_over_banner(renderer &sdl.Renderer) {
	banner := sdl.Rect{x: 0, y: win_height / 2 - 70, w: win_width, h: 140}
	sdl.set_render_draw_color(renderer, 60, 15, 20, 240)
	sdl.render_fill_rect(renderer, &banner)
	sdl.set_render_draw_color(renderer, 220, 50, 50, 255)
	sdl.render_draw_rect(renderer, &banner)

	mins := int(g.game_time) / 60
	secs := int(g.game_time) % 60
	time_str := if secs < 10 { '${mins}:0${secs}' } else { '${mins}:${secs}' }

	draw_text_centered(renderer, win_width / 2, win_height / 2 - 45, 'YOU DIED // SURVIVED: ${time_str}', 3, Color{r: 255, g: 215, b: 70})
	draw_text_centered(renderer, win_width / 2, win_height / 2 + 5, 'TOTAL KILLS: ${g.total_kills}', 2, Color{r: 255, g: 255, b: 255})
	draw_text_centered(renderer, win_width / 2, win_height / 2 + 35, 'PRESS [R] OR [ENTER] TO TRY AGAIN', 2, Color{r: 100, g: 230, b: 255})
}
