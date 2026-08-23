module main

import math
import sdl

struct Button {
pub mut:
	x            int
	y            int
	w            int
	h            int
	text         string
	bg_color     Color
	hover_color  Color
	text_color   Color
	border_color Color
}

pub fn (b Button) contains(mx int, my int) bool {
	return mx >= b.x && mx <= b.x + b.w && my >= b.y && my <= b.y + b.h
}

pub fn (b Button) draw(renderer &sdl.Renderer, mx int, my int) {
	is_hover := b.contains(mx, my)
	bg := if is_hover { b.hover_color } else { b.bg_color }

	rect := sdl.Rect{
		x: b.x
		y: b.y
		w: b.w
		h: b.h
	}
	sdl.set_render_draw_color(renderer, bg.r, bg.g, bg.b, bg.a)
	sdl.render_fill_rect(renderer, &rect)

	// Cyber Top/Left Neon Bevel
	br := if is_hover { b.border_color } else { Color{ r: u8(math_min(int(bg.r) + 60, 255)), g: u8(math_min(int(bg.g) + 60, 255)), b: u8(math_min(int(bg.b) + 60, 255)) } }
	sdl.set_render_draw_color(renderer, br.r, br.g, br.b, 255)
	sdl.render_draw_line(renderer, b.x, b.y, b.x + b.w, b.y)
	sdl.render_draw_line(renderer, b.x, b.y, b.x, b.y + b.h)

	// Cyber Cut-Corner Accents
	sdl.set_render_draw_color(renderer, b.border_color.r, b.border_color.g, b.border_color.b, b.border_color.a)
	sdl.render_draw_rect(renderer, &rect)

	sdl.render_draw_line(renderer, b.x + 2, b.y + 2, b.x + 6, b.y + 2)
	sdl.render_draw_line(renderer, b.x + b.w - 7, b.y + b.h - 3, b.x + b.w - 3, b.y + b.h - 3)

	text_scale := if b.text.len * 16 > b.w - 10 { 1 } else { 2 }
	text_h := 8 * text_scale
	draw_text_centered(renderer, b.x + b.w / 2, b.y + (b.h - text_h) / 2, b.text, text_scale, b.text_color)
}

fn math_min(a int, b int) int {
	return if a < b { a } else { b }
}

pub fn draw_game(renderer &sdl.Renderer, game Game, mx int, my int, btn_editor Button, btn_restart Button, btn_sound Button, btn_prev Button, btn_next Button, btn_test Button, btn_clear Button, btn_undo Button, btn_level_select Button) {
	ticks := sdl.get_ticks()
	current_theme := if game.mode == .editor { game.editor_level.theme } else { game.current_level.theme }

	// 1. Draw Masterpiece Themed Cyber Ambient World
	draw_futuristic_background(renderer, current_theme)
	draw_ambient_world_effects(renderer, current_theme, ticks)

	// 2. Draw Holographic Header Bar
	draw_futuristic_header(renderer, game, ticks)

	// 3. Draw Main Cyber Playfield
	draw_futuristic_playfield(renderer, game, ticks, current_theme, mx, my)

	// 3b. Flashlight Fog-of-War Dark Dungeon Mask
	if game.mode == .play && game.current_level.is_dark_dungeon {
		draw_dark_dungeon_mask(renderer, game)
	}

	// 4. Draw Sci-Fi Sidebar Panel
	if game.mode == .editor {
		draw_mario_maker_editor(renderer, game, mx, my, btn_test, btn_clear)
	} else {
		draw_hud_panel(renderer, game, mx, my, btn_prev, btn_next, btn_restart, btn_undo, btn_level_select)
	}

	// 5. Draw Top UI Buttons
	btn_editor.draw(renderer, mx, my)
	btn_sound.draw(renderer, mx, my)

	// 6. Draw Achievement Toasts & Hologram Dialogues
	if game.is_dialogue_open {
		draw_dialogue_modal(renderer, game.active_dialogue, ticks)
	} else if game.badge_toast != '' {
		draw_achievement_toast(renderer, game.badge_toast, ticks)
	}

	// 7. Modals & Overlays
	if game.is_replaying {
		draw_replay_overlay(renderer, ticks)
	} else if game.status == .won {
		draw_victory_ending(renderer, game, ticks)
	} else if game.status == .lost || game.status == .level_clear {
		draw_status_overlay(renderer, game)
	}

	if game.is_share_modal_open {
		draw_share_and_community_modal(renderer, game, mx, my)
	} else if game.is_level_select_open {
		draw_level_select_modal(renderer, game, mx, my)
	}

	// 8. Subtle Arcade CRT Scanlines
	draw_subtle_crt_scanlines(renderer)
}

fn draw_futuristic_background(renderer &sdl.Renderer, theme LevelTheme) {
	match theme {
		.castle {
			sdl.set_render_draw_color(renderer, 6, 10, 20, 255)
			sdl.render_clear(renderer)
			for r in 0 .. 15 {
				y := r * 48
				for c in 0 .. 20 {
					x := c * 48
					sdl.set_render_draw_color(renderer, 12, 22, 42, 255)
					sdl.render_draw_rect(renderer, &sdl.Rect{ x: x, y: y, w: 48, h: 48 })
				}
			}
		}
		.forest {
			sdl.set_render_draw_color(renderer, 4, 16, 12, 255)
			sdl.render_clear(renderer)
			for r in 0 .. 15 {
				y := r * 48
				for c in 0 .. 20 {
					x := c * 48
					sdl.set_render_draw_color(renderer, 10, 32, 22, 255)
					sdl.render_draw_rect(renderer, &sdl.Rect{ x: x, y: y, w: 48, h: 48 })
				}
			}
		}
		.desert {
			sdl.set_render_draw_color(renderer, 24, 14, 6, 255)
			sdl.render_clear(renderer)
			for r in 0 .. 15 {
				y := r * 48
				for c in 0 .. 20 {
					x := c * 48
					sdl.set_render_draw_color(renderer, 46, 26, 12, 255)
					sdl.render_draw_rect(renderer, &sdl.Rect{ x: x, y: y, w: 48, h: 48 })
				}
			}
		}
		.ice {
			sdl.set_render_draw_color(renderer, 6, 16, 28, 255)
			sdl.render_clear(renderer)
			for r in 0 .. 15 {
				y := r * 48
				for c in 0 .. 20 {
					x := c * 48
					sdl.set_render_draw_color(renderer, 14, 35, 60, 255)
					sdl.render_draw_rect(renderer, &sdl.Rect{ x: x, y: y, w: 48, h: 48 })
				}
			}
		}
		.volcanic {
			sdl.set_render_draw_color(renderer, 20, 6, 8, 255)
			sdl.render_clear(renderer)
			for r in 0 .. 15 {
				y := r * 48
				for c in 0 .. 20 {
					x := c * 48
					sdl.set_render_draw_color(renderer, 45, 14, 16, 255)
					sdl.render_draw_rect(renderer, &sdl.Rect{ x: x, y: y, w: 48, h: 48 })
				}
			}
		}
		.haunted {
			sdl.set_render_draw_color(renderer, 12, 6, 22, 255)
			sdl.render_clear(renderer)
			for r in 0 .. 15 {
				y := r * 48
				for c in 0 .. 20 {
					x := c * 48
					sdl.set_render_draw_color(renderer, 26, 14, 45, 255)
					sdl.render_draw_rect(renderer, &sdl.Rect{ x: x, y: y, w: 48, h: 48 })
				}
			}
		}
	}
}

fn draw_ambient_world_effects(renderer &sdl.Renderer, theme LevelTheme, ticks u32) {
	sdl.set_render_draw_blend_mode(renderer, .blend)

	match theme {
		.castle {
			// Cyan Data Packets streaming along conduits
			for i in 0 .. 14 {
				cx := (i * 75 + int(ticks / 15)) % win_w
				cy := (i * 49) % win_h
				sdl.set_render_draw_color(renderer, 0, 240, 255, 180)
				sdl.render_fill_rect(renderer, &sdl.Rect{ x: cx, y: cy, w: 10, h: 3 })
			}
		}
		.forest {
			// Rising bioluminescent quantum energy spores
			for i in 0 .. 24 {
				fx := (i * 43 + int(ticks / 24)) % win_w
				fy := win_h - ((i * 31 + int(ticks / 16)) % win_h)
				glow := int((math.sin(f64(ticks) / 120.0 + f64(i)) + 1.0) * 40.0)
				sdl.set_render_draw_color(renderer, 50, u8(210 + glow), 140, 200)
				sdl.render_fill_rect(renderer, &sdl.Rect{ x: fx, y: fy, w: 3, h: 3 })
			}
		}
		.desert {
			// Solar amber atmospheric radiation motes
			for i in 0 .. 18 {
				sx := (i * 55 + int(ticks / 20)) % win_w
				sy := (i * 37 + int(ticks / 28)) % win_h
				sdl.set_render_draw_color(renderer, 255, 190, 40, 180)
				sdl.render_fill_rect(renderer, &sdl.Rect{ x: sx, y: sy, w: 4, h: 2 })
			}
		}
		.ice {
			// Drifting cryo snow crystals & floor sheen puddles (Mario Bros style)
			for i in 0 .. 30 {
				cx := (i * 35 + int(ticks / 22)) % win_w
				cy := (i * 41 + int(ticks / 12)) % win_h
				sdl.set_render_draw_color(renderer, 180, 240, 255, 220)
				sdl.render_fill_rect(renderer, &sdl.Rect{ x: cx, y: cy, w: 2, h: 4 })
			}
			for p in 0 .. 3 {
				px := 100 + p * 280
				py := win_h - 40
				ripple := int(math.sin(f64(ticks) / 200.0 + f64(p)) * 2.0)
				sdl.set_render_draw_color(renderer, 40, 140, 220, 60)
				sdl.render_fill_rect(renderer, &sdl.Rect{ x: px, y: py, w: 90, h: 6 + ripple })
				sdl.set_render_draw_color(renderer, 200, 240, 255, 120)
				sdl.render_fill_rect(renderer, &sdl.Rect{ x: px + 20, y: py + 1, w: 50, h: 2 })
			}
		}
		.volcanic {
			// Molten plasma embers rising from below
			for i in 0 .. 28 {
				px := (i * 37 + int(ticks / 18)) % win_w
				py := win_h - ((i * 27 + int(ticks / 10)) % win_h)
				col := if i % 2 == 0 { Color{ r: 255, g: 140, b: 20 } } else { Color{ r: 255, g: 40, b: 50 } }
				sdl.set_render_draw_color(renderer, col.r, col.g, col.b, 230)
				sdl.render_fill_rect(renderer, &sdl.Rect{ x: px, y: py, w: 3, h: 4 })
			}
		}
		.haunted {
			// Floating spectral phantom wisps & cosmic stars
			for i in 0 .. 16 {
				wx := (i * 67 + int(ticks / 26)) % win_w
				wy := (i * 43 + int(math.sin(f64(ticks) / 90.0 + f64(i)) * 20.0) + 180) % win_h
				sdl.set_render_draw_color(renderer, 210, 120, 255, 190)
				sdl.render_fill_rect(renderer, &sdl.Rect{ x: wx, y: wy, w: 4, h: 4 })
			}
		}
	}
	sdl.set_render_draw_blend_mode(renderer, .none)
}

fn draw_subtle_crt_scanlines(renderer &sdl.Renderer) {
	sdl.set_render_draw_blend_mode(renderer, .blend)
	sdl.set_render_draw_color(renderer, 0, 0, 0, 18)
	for y := 0; y < win_h; y += 4 {
		sdl.render_draw_line(renderer, 0, y, win_w, y)
	}
	sdl.set_render_draw_blend_mode(renderer, .none)
}

fn draw_futuristic_header(renderer &sdl.Renderer, game Game, ticks u32) {
	hdr_rect := sdl.Rect{ x: 0, y: 0, w: win_w, h: 64 }
	sdl.set_render_draw_color(renderer, 14, 18, 30, 255)
	sdl.render_fill_rect(renderer, &hdr_rect)

	pulse := int((math.sin(f64(ticks) / 120.0) + 1.0) * 30.0)
	sdl.set_render_draw_color(renderer, 0, u8(190 + pulse), 255, 255)
	sdl.render_draw_line(renderer, 0, 62, win_w, 62)
	sdl.render_draw_line(renderer, 0, 63, win_w, 63)
	sdl.set_render_draw_color(renderer, 0, 100, 180, 255)
	sdl.render_draw_line(renderer, 0, 64, win_w, 64)

	draw_text(renderer, 20, 12, 'ADVENTURES OF LOLO', 2, Color{ r: 255, g: 215, b: 0 })

	if game.mode == .editor {
		draw_text(renderer, 20, 36, 'CYBER MAKER DESIGNER', 2, Color{ r: 0, g: 230, b: 255 })

		theme_name := match game.editor_level.theme {
			.castle { 'CYBER-CORE' }
			.forest { 'QUANTUM BIO' }
			.desert { 'SOLAR OUTPOST' }
			.ice { 'CRYO-STASIS' }
			.volcanic { 'PLASMA CORE' }
			.haunted { 'VOID NETHER' }
		}
		draw_text(renderer, 480, 16, 'BIOME: ${theme_name}', 1, Color{ r: 255, g: 215, b: 0 })

		tool_name := match game.editor_tool {
			.pencil { 'PENCIL' }
			.line { 'LINE' }
			.rect { 'RECT' }
			.fill { 'FILL' }
			.eraser { 'ERASER' }
			.prefab { 'PREFAB' }
		}
		draw_text(renderer, 480, 38, 'TOOL: ${tool_name}', 1, Color{ r: 0, g: 240, b: 255 })

		tab_name := match game.editor_tab {
			.tiles { 'TILES' }
			.items { 'ITEMS' }
			.enemies { 'ENEMIES' }
			.themes { 'SETTINGS' }
			.gizmos { 'GIZMOS' }
		}
		draw_text(renderer, 620, 38, 'TAB: ${tab_name}', 1, Color{ r: 255, g: 160, b: 100 })
	} else {
		lvl_name := 'SECTOR ${game.current_level.floor} - ${game.current_level.name}'
		l_scale := if lvl_name.len > 20 { 1 } else { 2 }
		l_y := if l_scale == 1 { 38 } else { 36 }
		draw_text(renderer, 20, l_y, lvl_name, l_scale, Color{ r: 0, g: 230, b: 255 })

		// Speedrun Timer Telemetry
		sec := int(game.level_time_ms / 1000)
		ms := int((game.level_time_ms % 1000) / 10)
		time_str := 'TIME: ${sec:02d}.${ms:02d}s'
		draw_text(renderer, 480, 16, time_str, 1, Color{ r: 255, g: 255, b: 255 })

		dim_str := if game.active_dimension == .alpha { 'DIM: ALPHA [Q]' } else { 'DIM: BETA [Q]' }
		dim_col := if game.active_dimension == .alpha { Color{ r: 0, g: 240, b: 255 } } else { Color{ r: 255, g: 100, b: 255 } }
		draw_text(renderer, 480, 38, dim_str, 1, dim_col)

		skin_name := match game.skin {
			.neon_blue { 'BLUE' }
			.cyber_magenta { 'MAGENTA' }
			.obsidian_gold { 'GOLD' }
			.toxic_lime { 'LIME' }
			.dark_matter { 'VOID' }
		}
		draw_text(renderer, 620, 38, 'SKIN: ${skin_name} [C]', 1, Color{ r: 255, g: 200, b: 80 })
	}
}

fn draw_futuristic_playfield(renderer &sdl.Renderer, game Game, ticks u32, theme LevelTheme, mx int, my int) {
	frame_rect := sdl.Rect{
		x: grid_offset_x - 12
		y: grid_offset_y - 12
		w: (grid_cols * cell_size) + 24
		h: (grid_rows * cell_size) + 24
	}

	frame_col := match theme {
		.castle { Color{ r: 18, g: 38, b: 72 } }
		.forest { Color{ r: 14, g: 50, b: 30 } }
		.desert { Color{ r: 70, g: 42, b: 18 } }
		.ice { Color{ r: 20, g: 65, b: 105 } }
		.volcanic { Color{ r: 75, g: 22, b: 22 } }
		.haunted { Color{ r: 42, g: 20, b: 68 } }
	}
	sdl.set_render_draw_color(renderer, frame_col.r, frame_col.g, frame_col.b, 255)
	sdl.render_fill_rect(renderer, &frame_rect)

	neon_glow := match theme {
		.castle { Color{ r: 0, g: 230, b: 255 } }
		.forest { Color{ r: 50, g: 255, b: 120 } }
		.desert { Color{ r: 255, g: 190, b: 30 } }
		.ice { Color{ r: 120, g: 220, b: 255 } }
		.volcanic { Color{ r: 255, g: 80, b: 40 } }
		.haunted { Color{ r: 210, g: 90, b: 255 } }
	}
	sdl.set_render_draw_color(renderer, neon_glow.r, neon_glow.g, neon_glow.b, 255)
	sdl.render_draw_rect(renderer, &sdl.Rect{ x: grid_offset_x - 4, y: grid_offset_y - 4, w: (grid_cols * cell_size) + 8, h: (grid_rows * cell_size) + 8 })

	// 1. Draw Floor Tiles & Modern Gizmos
	for r in 0 .. grid_rows {
		for c in 0 .. grid_cols {
			tile := if game.mode == .editor { game.editor_level.grid[r][c] } else { game.grid[r][c] }
			tx := grid_offset_x + c * cell_size
			ty := grid_offset_y + r * cell_size
			draw_futuristic_tile(renderer, tx, ty, tile, r, c, ticks, theme, game.active_dimension, game.gate_open, game.sprite_texture)
		}
	}

	// 2. Draw AI Hint Path
	if game.show_hint && game.hint_path.len > 0 {
		for pt in game.hint_path {
			hx := grid_offset_x + pt.x * cell_size + cell_size / 2
			hy := grid_offset_y + pt.y * cell_size + cell_size / 2
			pulse := int(math.sin(f64(ticks) / 80.0) * 3.0)
			sdl.set_render_draw_color(renderer, 0, 255, 180, 200)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: hx - 4 - pulse, y: hy - 4 - pulse, w: 8 + pulse * 2, h: 8 + pulse * 2 })
		}
	}

	// 3. Draw Entities & Blocks
	for r in 0 .. grid_rows {
		for c in 0 .. grid_cols {
			ent := if game.mode == .editor { game.editor_level.entities[r][c] } else { game.entities[r][c] }
			if ent != .none {
				tx := grid_offset_x + c * cell_size
				ty := grid_offset_y + r * cell_size
				// Soft entity shadow
				draw_soft_shadow(renderer, tx, ty, cell_size - 8)
				draw_futuristic_entity(renderer, tx, ty, ent, game.chest_open, game.door_open, ticks, game.sprite_texture)
			}
		}
	}

	// 4. Draw Dynamic Enemies
	if game.mode == .play {
		for enemy in game.enemies {
			if enemy.x >= 0 && enemy.x < grid_cols && enemy.y >= 0 && enemy.y < grid_rows {
				ex := grid_offset_x + enemy.x * cell_size
				ey := grid_offset_y + enemy.y * cell_size
				draw_soft_shadow(renderer, ex, ey, cell_size - 8)
				draw_futuristic_enemy(renderer, ex, ey, enemy, ticks, game.sprite_texture)
			}
		}
	}

	// 5. Draw Cyber-Lolo with Selected Skin
	if game.mode == .play && !game.lolo.is_dead {
		lx := grid_offset_x + game.lolo.x * cell_size
		ly := grid_offset_y + game.lolo.y * cell_size
		draw_soft_shadow(renderer, lx, ly, cell_size - 8)
		draw_cyber_lolo(renderer, lx, ly, game.lolo.dir, ticks, game.lolo.speed_boost > 0, game.skin, game.sprite_texture)
	}

	// 6. Draw High-Energy Plasma Shot
	if game.mode == .play && game.magic_shot.active {
		sx := grid_offset_x + int(game.magic_shot.x * f64(cell_size)) + cell_size / 2
		sy := grid_offset_y + int(game.magic_shot.y * f64(cell_size)) + cell_size / 2
		draw_plasma_shot(renderer, sx, sy, ticks)
	}

	// 7. Draw Multi-Bounce Laser Segments
	for seg in game.laser_segments {
		x1 := grid_offset_x + seg.x1 * cell_size + cell_size / 2
		y1 := grid_offset_y + seg.y1 * cell_size + cell_size / 2
		x2 := grid_offset_x + seg.x2 * cell_size + cell_size / 2
		y2 := grid_offset_y + seg.y2 * cell_size + cell_size / 2

		// Wide Outer Bloom Halo
		sdl.set_render_draw_blend_mode(renderer, .blend)
		sdl.set_render_draw_color(renderer, 255, 30, 80, 85)
		for off := -3; off <= 3; off++ {
			sdl.render_draw_line(renderer, x1 + off, y1 + off, x2 + off, y2 + off)
		}
		// Medium Crimson Laser Beam
		sdl.set_render_draw_color(renderer, 255, 60, 100, 220)
		for off := -1; off <= 1; off++ {
			sdl.render_draw_line(renderer, x1 + off, y1 + off, x2 + off, y2 + off)
		}
		// White-Hot Core Laser
		sdl.set_render_draw_blend_mode(renderer, .none)
		sdl.set_render_draw_color(renderer, 255, 255, 255, 255)
		sdl.render_draw_line(renderer, x1, y1, x2, y2)

		// Impact Sparks at termination point
		for i in 0 .. 4 {
			sp_x := x2 + ((i * 3) % 7 - 3)
			sp_y := y2 + ((i * 5) % 7 - 3)
			sdl.set_render_draw_color(renderer, 255, 220, 100, 255)
			sdl.render_draw_point(renderer, sp_x, sp_y)
		}
	}

	// 8. Draw Holographic Editor Reticle
	if game.mode == .editor {
		hc := (mx - grid_offset_x) / cell_size
		hr := (my - grid_offset_y) / cell_size
		if hc >= 0 && hc < grid_cols && hr >= 0 && hr < grid_rows {
			hx := grid_offset_x + hc * cell_size
			hy := grid_offset_y + hr * cell_size
			sdl.set_render_draw_color(renderer, 0, 240, 255, 220)
			sdl.render_draw_rect(renderer, &sdl.Rect{ x: hx, y: hy, w: cell_size, h: cell_size })
			sdl.set_render_draw_color(renderer, 255, 220, 0, 255)
			sdl.render_draw_line(renderer, hx, hy, hx + 8, hy)
			sdl.render_draw_line(renderer, hx, hy, hx, hy + 8)
			sdl.render_draw_line(renderer, hx + cell_size - 8, hy, hx + cell_size, hy)
			sdl.render_draw_line(renderer, hx + cell_size, hy, hx + cell_size, hy + 8)
		}
	}
}

fn draw_soft_shadow(renderer &sdl.Renderer, x int, y int, w int) {
	sdl.set_render_draw_blend_mode(renderer, .blend)
	sdl.set_render_draw_color(renderer, 0, 0, 0, 75)
	sh_rect := sdl.Rect{ x: x + 4, y: y + cell_size - 6, w: w, h: 5 }
	sdl.render_fill_rect(renderer, &sh_rect)
	sdl.set_render_draw_blend_mode(renderer, .none)
}

fn draw_futuristic_tile(renderer &sdl.Renderer, x int, y int, tile TileType, r int, c int, ticks u32, theme LevelTheme, dim Dimension, gate_open bool, tex &sdl.Texture) {
	rect := sdl.Rect{ x: x, y: y, w: cell_size, h: cell_size }

	if tex != unsafe { nil } {
		src := match tile {
			.wall { sdl.Rect{192, 64, 32, 32} }
			.rock { sdl.Rect{32, 96, 32, 32} }
			.tree { sdl.Rect{0, 96, 32, 32} }
			.water { sdl.Rect{64 + int((ticks / 250) % 4) * 32, 96, 32, 32} }
			.lava { sdl.Rect{192, 96, 32, 32} }
			.ice { sdl.Rect{224, 96, 32, 32} }
			.warp_a { sdl.Rect{128, 128, 32, 32} }
			.warp_b { sdl.Rect{160, 128, 32, 32} }
			.locked_gate { if gate_open { sdl.Rect{192, 160, 32, 32} } else { sdl.Rect{160, 160, 32, 32} } }
			.pressure_plate, .plate_channel_1, .plate_channel_2 { sdl.Rect{192, 128, 32, 32} }
			.laser_prism_slash, .laser_prism_backslash { sdl.Rect{224, 128, 32, 32} }
			.toggle_laser_gate, .gate_channel_1, .gate_channel_2 { sdl.Rect{224, 128, 32, 32} }
			.conveyor_up { sdl.Rect{0, 128, 32, 32} }
			.conveyor_down { sdl.Rect{32, 128, 32, 32} }
			.conveyor_left { sdl.Rect{64, 128, 32, 32} }
			.conveyor_right { sdl.Rect{96, 128, 32, 32} }
			.bridge { sdl.Rect{32, 64, 32, 32} }
			else { sdl.Rect{0, 0, 0, 0} }
		}
		if src.w > 0 {
			sdl.render_copy(renderer, tex, &src, &rect)
			return
		}
	}

	match tile {
		.grass {
			// Hi-Tech Cyber Deck Flooring with Hexagon Nano-Circuits
			bg_col := match theme {
				.castle { if (r + c) % 2 == 0 { Color{ r: 12, g: 26, b: 50 } } else { Color{ r: 16, g: 34, b: 64 } } }
				.forest { if (r + c) % 2 == 0 { Color{ r: 10, g: 38, b: 24 } } else { Color{ r: 14, g: 50, b: 32 } } }
				.desert { if (r + c) % 2 == 0 { Color{ r: 56, g: 38, b: 18 } } else { Color{ r: 70, g: 48, b: 22 } } }
				.ice { if (r + c) % 2 == 0 { Color{ r: 24, g: 58, b: 96 } } else { Color{ r: 34, g: 74, b: 118 } } }
				.volcanic { if (r + c) % 2 == 0 { Color{ r: 38, g: 14, b: 16 } } else { Color{ r: 50, g: 18, b: 22 } } }
				.haunted { if (r + c) % 2 == 0 { Color{ r: 28, g: 14, b: 42 } } else { Color{ r: 38, g: 20, b: 56 } } }
			}
			sdl.set_render_draw_color(renderer, bg_col.r, bg_col.g, bg_col.b, 255)
			sdl.render_fill_rect(renderer, &rect)

			// Sub-grid panel border
			sdl.set_render_draw_color(renderer, u8(math_min(int(bg_col.r) + 16, 255)), u8(math_min(int(bg_col.g) + 16, 255)), u8(math_min(int(bg_col.b) + 16, 255)), 255)
			sdl.render_draw_rect(renderer, &rect)

			// Circuit nodes at corner junctions
			glow_col := match theme {
				.castle { Color{ r: 0, g: 210, b: 255 } }
				.forest { Color{ r: 40, g: 255, b: 150 } }
				.desert { Color{ r: 255, g: 190, b: 40 } }
				.ice { Color{ r: 140, g: 240, b: 255 } }
				.volcanic { Color{ r: 255, g: 80, b: 40 } }
				.haunted { Color{ r: 200, g: 80, b: 255 } }
			}
			if (r * 11 + c) % 3 == 0 {
				sdl.set_render_draw_color(renderer, glow_col.r, glow_col.g, glow_col.b, 180)
				sdl.render_draw_point(renderer, x + 6, y + 6)
				sdl.render_draw_point(renderer, x + cell_size - 7, y + cell_size - 7)
				sdl.render_draw_line(renderer, x + 6, y + 6, x + 12, y + 6)
			}
		}
		.laser_prism_slash, .laser_prism_backslash {
			// Optical Quartz Refractive Prism with Glowing Mirror
			sdl.set_render_draw_color(renderer, 20, 32, 58, 255)
			sdl.render_fill_rect(renderer, &rect)

			// Chrome Bevel & Polished Titanium Casing
			sdl.set_render_draw_color(renderer, 100, 180, 255, 255)
			sdl.render_draw_rect(renderer, &rect)
			sdl.set_render_draw_color(renderer, 40, 70, 110, 255)
			sdl.render_draw_rect(renderer, &sdl.Rect{ x: x + 2, y: y + 2, w: cell_size - 4, h: cell_size - 4 })

			// Internal Optical Quartz Prism (Translucent Cyan Crystal)
			sdl.set_render_draw_color(renderer, 0, 160, 230, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + 6, y: y + 6, w: cell_size - 12, h: cell_size - 12 })

			// Ultra-Bright 45-Degree Holographic Reflective Core
			pulse := int(math.sin(f64(ticks) / 80.0) * 20.0)
			sdl.set_render_draw_color(renderer, u8(math_min(235 + pulse, 255)), 255, 255, 255)
			if tile == .laser_prism_slash {
				sdl.render_draw_line(renderer, x + 8, y + cell_size - 8, x + cell_size - 8, y + 8)
				sdl.render_draw_line(renderer, x + 9, y + cell_size - 8, x + cell_size - 8, y + 9)
				sdl.render_draw_line(renderer, x + 8, y + cell_size - 9, x + cell_size - 9, y + 8)
				// Corner reflectors
				sdl.set_render_draw_color(renderer, 0, 255, 240, 255)
				sdl.render_draw_point(renderer, x + 5, y + 5)
				sdl.render_draw_point(renderer, x + cell_size - 6, y + cell_size - 6)
			} else {
				sdl.render_draw_line(renderer, x + 8, y + 8, x + cell_size - 8, y + cell_size - 8)
				sdl.render_draw_line(renderer, x + 9, y + 8, x + cell_size - 8, y + cell_size - 9)
				sdl.render_draw_line(renderer, x + 8, y + 9, x + cell_size - 9, y + cell_size - 8)
				// Corner reflectors
				sdl.set_render_draw_color(renderer, 0, 255, 240, 255)
				sdl.render_draw_point(renderer, x + cell_size - 6, y + 5)
				sdl.render_draw_point(renderer, x + 5, y + cell_size - 6)
			}
		}
		.pressure_plate {
			// Conductive Quantum Pressure Pad
			sdl.set_render_draw_color(renderer, 24, 30, 46, 255)
			sdl.render_fill_rect(renderer, &rect)
			sdl.set_render_draw_color(renderer, 50, 65, 95, 255)
			sdl.render_draw_rect(renderer, &rect)

			// Stepped Inset Plate
			plate_bg := if gate_open { Color{ r: 10, g: 60, b: 45 } } else { Color{ r: 60, g: 45, b: 15 } }
			sdl.set_render_draw_color(renderer, plate_bg.r, plate_bg.g, plate_bg.b, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + 6, y: y + 6, w: cell_size - 12, h: cell_size - 12 })

			// Center Glowing Sensor Pad
			glow_col := if gate_open { Color{ r: 0, g: 255, b: 180 } } else { Color{ r: 255, g: 190, b: 30 } }
			sdl.set_render_draw_color(renderer, glow_col.r, glow_col.g, glow_col.b, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + 12, y: y + 12, w: cell_size - 24, h: cell_size - 24 })
			sdl.set_render_draw_color(renderer, 255, 255, 255, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + cell_size / 2 - 3, y: y + cell_size / 2 - 3, w: 6, h: 6 })
		}
		.toggle_laser_gate {
			// Heavy Emitter Pylons with Active High-Energy Laser Barrier
			sdl.set_render_draw_color(renderer, 26, 32, 48, 255)
			sdl.render_fill_rect(renderer, &rect)

			// Metallic Emitter Posts
			sdl.set_render_draw_color(renderer, 70, 90, 120, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + 2, y: y + 3, w: 7, h: cell_size - 6 })
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + cell_size - 9, y: y + 3, w: 7, h: cell_size - 6 })
			sdl.set_render_draw_color(renderer, 150, 190, 230, 255)
			sdl.render_draw_rect(renderer, &sdl.Rect{ x: x + 2, y: y + 3, w: 7, h: cell_size - 6 })
			sdl.render_draw_rect(renderer, &sdl.Rect{ x: x + cell_size - 9, y: y + 3, w: 7, h: cell_size - 6 })

			if !gate_open {
				// Intense Pulsing Red Laser Forcefield
				pulse := int(math.sin(f64(ticks) / 60.0) * 30.0)
				// Outer glow halo
				sdl.set_render_draw_color(renderer, 255, 20, 50, 100)
				sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + 9, y: y + cell_size / 2 - 5, w: cell_size - 18, h: 10 })
				// Core laser beam
				sdl.set_render_draw_color(renderer, u8(math_min(225 + pulse, 255)), 30, 60, 255)
				sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + 9, y: y + cell_size / 2 - 2, w: cell_size - 18, h: 4 })
				// White photon core
				sdl.set_render_draw_color(renderer, 255, 240, 245, 255)
				sdl.render_draw_line(renderer, x + 9, y + cell_size / 2, x + cell_size - 10, y + cell_size / 2)
			} else {
				// Deactivated Green Safety Beam Line
				sdl.set_render_draw_color(renderer, 0, 255, 180, 200)
				sdl.render_draw_line(renderer, x + 9, y + cell_size / 2, x + cell_size - 10, y + cell_size / 2)
			}
		}
		.conveyor_up, .conveyor_down, .conveyor_left, .conveyor_right {
			// Animated Kinetic Conveyor Track with Flowing Neon Chevrons
			sdl.set_render_draw_color(renderer, 25, 34, 50, 255)
			sdl.render_fill_rect(renderer, &rect)
			sdl.set_render_draw_color(renderer, 15, 20, 32, 255)
			sdl.render_draw_rect(renderer, &rect)

			// Hazard border lines
			for i in 0 .. 4 {
				sdl.set_render_draw_color(renderer, 255, 190, 20, 255)
				sdl.render_draw_line(renderer, x + i * 12, y + 1, x + i * 12 + 5, y + 1)
				sdl.render_draw_line(renderer, x + i * 12, y + cell_size - 2, x + i * 12 + 5, y + cell_size - 2)
			}

			// Moving Chevrons
			anim := int((ticks / 80) % 3)
			ch := match tile {
				.conveyor_up { `^` }
				.conveyor_down { `v` }
				.conveyor_left { `<` }
				else { `>` }
			}
			off_y := if tile == .conveyor_up { -anim * 2 } else if tile == .conveyor_down { anim * 2 } else { 0 }
			off_x := if tile == .conveyor_left { -anim * 2 } else if tile == .conveyor_right { anim * 2 } else { 0 }
			draw_char(renderer, x + 18 + off_x, y + 16 + off_y, ch, 2, Color{ r: 0, g: 240, b: 255 })
		}
		.phase_block_alpha {
			if dim == .alpha {
				// Solid Quantum Forcefield (Cyan Alpha)
				sdl.set_render_draw_color(renderer, 0, 140, 220, 255)
				sdl.render_fill_rect(renderer, &rect)
				sdl.set_render_draw_color(renderer, 100, 220, 255, 255)
				sdl.render_draw_rect(renderer, &rect)
				sdl.set_render_draw_color(renderer, 180, 245, 255, 255)
				sdl.render_draw_rect(renderer, &sdl.Rect{ x: x + 3, y: y + 3, w: cell_size - 6, h: cell_size - 6 })
				draw_char(renderer, x + 18, y + 16, `A`, 2, Color{ r: 255, g: 255, b: 255 })
			} else {
				// Ethereal Phased-Out Hologram
				sdl.set_render_draw_color(renderer, 0, 160, 240, 100)
				sdl.render_draw_rect(renderer, &rect)
				// Holographic scanlines
				for sl := 4; sl < cell_size - 4; sl += 6 {
					sdl.set_render_draw_color(renderer, 0, 200, 255, 60)
					sdl.render_draw_line(renderer, x + 4, y + sl, x + cell_size - 4, y + sl)
				}
				draw_char(renderer, x + 18, y + 16, `A`, 1, Color{ r: 0, g: 190, b: 255 })
			}
		}
		.phase_block_beta {
			if dim == .beta {
				// Solid Quantum Forcefield (Magenta Beta)
				sdl.set_render_draw_color(renderer, 200, 30, 180, 255)
				sdl.render_fill_rect(renderer, &rect)
				sdl.set_render_draw_color(renderer, 255, 120, 240, 255)
				sdl.render_draw_rect(renderer, &rect)
				sdl.set_render_draw_color(renderer, 255, 200, 250, 255)
				sdl.render_draw_rect(renderer, &sdl.Rect{ x: x + 3, y: y + 3, w: cell_size - 6, h: cell_size - 6 })
				draw_char(renderer, x + 18, y + 16, `B`, 2, Color{ r: 255, g: 255, b: 255 })
			} else {
				// Ethereal Phased-Out Hologram
				sdl.set_render_draw_color(renderer, 220, 40, 200, 100)
				sdl.render_draw_rect(renderer, &rect)
				// Holographic scanlines
				for sl := 4; sl < cell_size - 4; sl += 6 {
					sdl.set_render_draw_color(renderer, 255, 60, 220, 60)
					sdl.render_draw_line(renderer, x + 4, y + sl, x + cell_size - 4, y + sl)
				}
				draw_char(renderer, x + 18, y + 16, `B`, 1, Color{ r: 220, g: 40, b: 200 })
			}
		}
		.wall {
			// Heavy Modular Sci-Fi Blast Wall with Armor Inset & Light Conduits
			sdl.set_render_draw_color(renderer, 40, 48, 65, 255)
			sdl.render_fill_rect(renderer, &rect)

			// Top / Left Specular Metallic Bevel
			sdl.set_render_draw_color(renderer, 110, 160, 225, 255)
			sdl.render_draw_line(renderer, x + 1, y + 1, x + cell_size - 2, y + 1)
			sdl.render_draw_line(renderer, x + 1, y + 1, x + 1, y + cell_size - 2)

			// Deep Shadow Bevel
			sdl.set_render_draw_color(renderer, 16, 20, 30, 255)
			sdl.render_draw_line(renderer, x + 1, y + cell_size - 2, x + cell_size - 2, y + cell_size - 2)
			sdl.render_draw_line(renderer, x + cell_size - 2, y + 1, x + cell_size - 2, y + cell_size - 2)

			// Reinforced Center Composite Plate
			sdl.set_render_draw_color(renderer, 26, 32, 45, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + 6, y: y + 6, w: cell_size - 12, h: cell_size - 12 })

			// Illuminated Vertical Light Conduit
			conduit_col := match theme {
				.castle { Color{ r: 0, g: 220, b: 255 } }
				.forest { Color{ r: 0, g: 255, b: 160 } }
				.desert { Color{ r: 255, g: 190, b: 30 } }
				.ice { Color{ r: 120, g: 230, b: 255 } }
				.volcanic { Color{ r: 255, g: 60, b: 30 } }
				.haunted { Color{ r: 190, g: 60, b: 255 } }
			}
			sdl.set_render_draw_color(renderer, conduit_col.r, conduit_col.g, conduit_col.b, 255)
			sdl.render_draw_line(renderer, x + cell_size / 2, y + 8, x + cell_size / 2, y + cell_size - 9)

			// Corner Hex Bolts
			sdl.set_render_draw_color(renderer, 200, 225, 255, 255)
			sdl.render_draw_point(renderer, x + 4, y + 4)
			sdl.render_draw_point(renderer, x + cell_size - 5, y + 4)
			sdl.render_draw_point(renderer, x + 4, y + cell_size - 5)
			sdl.render_draw_point(renderer, x + cell_size - 5, y + cell_size - 5)
		}
		.rock {
			// Craggy Cyber Asteroid / Metal Scrap Cluster
			sdl.set_render_draw_color(renderer, 55, 62, 78, 255)
			sdl.render_fill_rect(renderer, &rect)
			sdl.set_render_draw_color(renderer, 95, 115, 145, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + 5, y: y + 5, w: cell_size - 14, h: 12 })
			sdl.set_render_draw_color(renderer, 0, 230, 255, 220)
			sdl.render_draw_line(renderer, x + 8, y + 20, x + cell_size - 10, y + 26)
			sdl.render_draw_line(renderer, x + 12, y + 32, x + cell_size - 14, y + 36)
		}
		.tree {
			// Bioluminescent Quantum Data Spire
			sdl.set_render_draw_color(renderer, 22, 34, 50, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + 16, y: y + 24, w: 16, h: 20 })
			sdl.set_render_draw_color(renderer, 0, 160, 90, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + 5, y: y + 12, w: cell_size - 10, h: 18 })
			sdl.set_render_draw_color(renderer, 0, 240, 140, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + 10, y: y + 4, w: cell_size - 20, h: 14 })
			// Top Emitter Pulse
			sdl.set_render_draw_color(renderer, 220, 255, 240, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + cell_size / 2 - 2, y: y + 2, w: 4, h: 4 })
		}
		.water {
			// Flowing Shimmering Liquid Coolant Channel
			sdl.set_render_draw_color(renderer, 10, 48, 110, 255)
			sdl.render_fill_rect(renderer, &rect)
			wave1 := int(math.sin(f64(ticks) / 140.0 + f64(c * 2)) * 4.0)
			wave2 := int(math.cos(f64(ticks) / 180.0 + f64(r * 2)) * 3.0)
			sdl.set_render_draw_color(renderer, 0, 180, 255, 255)
			sdl.render_draw_line(renderer, x + 3, y + 14 + wave1, x + cell_size - 4, y + 14 + wave1)
			sdl.render_draw_line(renderer, x + 3, y + 30 + wave2, x + cell_size - 4, y + 30 + wave2)
			sdl.set_render_draw_color(renderer, 180, 240, 255, 255)
			sdl.render_draw_point(renderer, x + 8, y + 13 + wave1)
			sdl.render_draw_point(renderer, x + cell_size - 10, y + 29 + wave2)
		}
		.lava {
			// Superheated Molten Plasma Conduit
			sdl.set_render_draw_color(renderer, 150, 18, 18, 255)
			sdl.render_fill_rect(renderer, &rect)
			b_off := int(math.sin(f64(ticks) / 80.0 + f64(c * 3)) * 4.0)
			sdl.set_render_draw_color(renderer, 255, 120, 0, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + 8, y: y + 12 + b_off, w: 16, h: 12 })
			sdl.set_render_draw_color(renderer, 255, 230, 90, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + 12, y: y + 15 + b_off, w: 6, h: 6 })
		}
		.ice {
			// Crystalline Frosted Cryo Glass Plate
			sdl.set_render_draw_color(renderer, 85, 165, 235, 255)
			sdl.render_fill_rect(renderer, &rect)
			sdl.set_render_draw_color(renderer, 235, 250, 255, 255)
			sdl.render_draw_line(renderer, x + 4, y + 6, x + cell_size - 6, y + 6)
			sdl.render_draw_line(renderer, x + 4, y + 6, x + 4, y + cell_size - 6)
			sdl.set_render_draw_color(renderer, 0, 130, 210, 255)
			sdl.render_draw_rect(renderer, &rect)
			// Diamond Facet Reflection
			sdl.set_render_draw_color(renderer, 255, 255, 255, 180)
			sdl.render_draw_line(renderer, x + 10, y + 20, x + cell_size - 12, y + 34)
		}
		.warp_a, .warp_b {
			p_col := if tile == .warp_a { Color{ r: 0, g: 240, b: 255 } } else { Color{ r: 255, g: 40, b: 200 } }
			sdl.set_render_draw_color(renderer, 8, 12, 26, 255)
			sdl.render_fill_rect(renderer, &rect)
			pulse := int((math.sin(f64(ticks) / 70.0) + 1.0) * 3.0)
			sdl.set_render_draw_color(renderer, p_col.r, p_col.g, p_col.b, 255)
			sdl.render_draw_rect(renderer, &sdl.Rect{ x: x + 5 - pulse, y: y + 5 - pulse, w: cell_size - 10 + pulse * 2, h: cell_size - 10 + pulse * 2 })
			tag := if tile == .warp_a { `A` } else { `B` }
			draw_char(renderer, x + 18, y + 16, tag, 2, Color{ r: 255, g: 255, b: 255 })
		}
		.locked_gate {
			sdl.set_render_draw_color(renderer, 36, 42, 54, 255)
			sdl.render_fill_rect(renderer, &rect)
			sdl.set_render_draw_color(renderer, 255, 45, 65, 255)
			for b := 0; b < 3; b++ {
				bx := x + 10 + b * 12
				sdl.render_draw_line(renderer, bx, y + 4, bx, y + cell_size - 4)
			}
			sdl.set_render_draw_color(renderer, 255, 215, 0, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + 16, y: y + 16, w: 16, h: 16 })
		}
		.bridge {
			sdl.set_render_draw_color(renderer, 90, 105, 122, 255)
			sdl.render_fill_rect(renderer, &rect)
			sdl.set_render_draw_color(renderer, 0, 220, 255, 200)
			sdl.render_draw_line(renderer, x + 4, y + 14, x + cell_size - 4, y + 14)
			sdl.render_draw_line(renderer, x + 4, y + 34, x + cell_size - 4, y + 34)
		}
		.arrow_up { draw_arrow_tile(renderer, x, y, `^`) }
		.arrow_down { draw_arrow_tile(renderer, x, y, `v`) }
		.arrow_left { draw_arrow_tile(renderer, x, y, `<`) }
		.arrow_right { draw_arrow_tile(renderer, x, y, `>`) }
		.timed_laser_barrier {
			sdl.set_render_draw_color(renderer, 36, 20, 16, 255)
			sdl.render_fill_rect(renderer, &rect)
			sdl.set_render_draw_color(renderer, 240, 110, 15, 255)
			sdl.render_draw_rect(renderer, &rect)
			if !gate_open {
				sdl.set_render_draw_color(renderer, 255, 130, 25, 255)
				sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + 8, y: y + cell_size / 2 - 3, w: cell_size - 16, h: 6 })
				draw_char(renderer, x + 18, y + 16, `*`, 2, Color{ r: 255, g: 220, b: 100 })
			} else {
				draw_char(renderer, x + 18, y + 16, `*`, 1, Color{ r: 160, g: 90, b: 40 })
			}
		}
		.plate_channel_1, .plate_channel_2 {
			sdl.set_render_draw_color(renderer, 22, 28, 44, 255)
			sdl.render_fill_rect(renderer, &rect)
			ch_name := if tile == .plate_channel_1 { `1` } else { `2` }
			ch_col := if tile == .plate_channel_1 { Color{ r: 255, g: 60, b: 60 } } else { Color{ r: 60, g: 255, b: 120 } }
			sdl.set_render_draw_color(renderer, ch_col.r, ch_col.g, ch_col.b, 255)
			sdl.render_draw_rect(renderer, &sdl.Rect{ x: x + 6, y: y + 6, w: cell_size - 12, h: cell_size - 12 })
			draw_char(renderer, x + 18, y + 16, ch_name, 2, ch_col)
		}
		.gate_channel_1, .gate_channel_2 {
			sdl.set_render_draw_color(renderer, 28, 32, 48, 255)
			sdl.render_fill_rect(renderer, &rect)
			ch_name := if tile == .gate_channel_1 { `1` } else { `2` }
			ch_col := if tile == .gate_channel_1 { Color{ r: 255, g: 60, b: 60 } } else { Color{ r: 60, g: 255, b: 120 } }
			sdl.set_render_draw_color(renderer, ch_col.r, ch_col.g, ch_col.b, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + 8, y: y + cell_size / 2 - 3, w: cell_size - 16, h: 6 })
			draw_char(renderer, x + 18, y + 16, ch_name, 1, Color{ r: 255, g: 255, b: 255 })
		}
	}
}

fn draw_arrow_tile(renderer &sdl.Renderer, x int, y int, ch u8) {
	rect := sdl.Rect{ x: x, y: y, w: cell_size, h: cell_size }
	sdl.set_render_draw_color(renderer, 18, 55, 48, 255)
	sdl.render_fill_rect(renderer, &rect)
	sdl.set_render_draw_color(renderer, 0, 255, 180, 255)
	sdl.render_draw_rect(renderer, &rect)
	draw_char(renderer, x + 16, y + 16, ch, 2, Color{ r: 0, g: 255, b: 200 })
}

// 16x16 Pixel Sprite Matrices for Adventures of Lolo

const lolo_sprite_down = [
	[0,0,0,0,0,0,7,7,7,0,0,0,0,0,0,0],
	[0,0,0,0,0,7,7,7,7,7,0,0,0,0,0,0],
	[0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0],
	[0,0,0,1,1,1,2,2,1,1,1,0,0,0,0,0],
	[0,0,1,2,2,2,2,2,2,2,2,1,0,0,0,0],
	[0,1,2,2,3,3,2,2,3,3,2,2,1,0,0,0],
	[0,1,2,3,4,4,3,3,4,4,3,2,1,0,0,0],
	[1,2,2,3,4,4,3,3,4,4,3,2,2,1,0,0],
	[1,2,5,2,3,3,2,2,3,3,2,5,2,1,0,0],
	[1,2,2,2,2,2,2,2,2,2,2,2,2,1,0,0],
	[1,2,2,2,2,2,2,2,2,2,2,2,2,1,0,0],
	[0,1,2,2,2,2,2,2,2,2,2,2,1,0,0,0],
	[0,0,1,1,2,2,2,2,2,2,1,1,0,0,0,0],
	[0,0,1,6,6,1,1,1,1,6,6,1,0,0,0,0],
	[0,1,6,6,6,6,1,1,6,6,6,6,1,0,0,0],
	[0,0,1,1,1,1,0,0,1,1,1,1,0,0,0,0]
]

const lolo_sprite_up = [
	[0,0,0,0,0,0,7,7,7,0,0,0,0,0,0,0],
	[0,0,0,0,0,7,7,7,7,7,0,0,0,0,0,0],
	[0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0],
	[0,0,0,1,1,1,2,2,1,1,1,0,0,0,0,0],
	[0,0,1,2,2,2,2,2,2,2,2,1,0,0,0,0],
	[0,1,2,2,2,2,2,2,2,2,2,2,1,0,0,0],
	[0,1,2,2,2,2,2,2,2,2,2,2,1,0,0,0],
	[1,2,2,2,2,1,1,1,1,2,2,2,2,1,0,0],
	[1,2,2,2,1,7,7,7,7,1,2,2,2,1,0,0],
	[1,2,2,2,1,7,7,7,7,1,2,2,2,1,0,0],
	[1,2,2,2,2,1,1,1,1,2,2,2,2,1,0,0],
	[0,1,2,2,2,2,2,2,2,2,2,2,1,0,0,0],
	[0,0,1,1,2,2,2,2,2,2,1,1,0,0,0,0],
	[0,0,1,6,6,1,1,1,1,6,6,1,0,0,0,0],
	[0,1,6,6,6,6,1,1,6,6,6,6,1,0,0,0],
	[0,0,1,1,1,1,0,0,1,1,1,1,0,0,0,0]
]

const lolo_sprite_left = [
	[0,0,0,0,0,0,7,7,7,0,0,0,0,0,0,0],
	[0,0,0,0,0,7,7,7,7,7,0,0,0,0,0,0],
	[0,0,0,0,0,0,1,1,0,0,0,0,0,0,0,0],
	[0,0,0,1,1,1,2,2,1,1,1,0,0,0,0,0],
	[0,0,1,2,2,2,2,2,2,2,2,1,0,0,0,0],
	[0,1,2,3,3,2,2,2,2,2,2,2,1,0,0,0],
	[0,1,3,4,4,3,2,2,2,2,2,2,1,0,0,0],
	[1,2,3,4,4,3,2,2,2,2,2,2,2,1,0,0],
	[1,5,2,3,3,2,2,2,2,2,2,2,2,1,0,0],
	[1,2,2,2,2,2,2,2,2,2,2,2,2,1,0,0],
	[1,2,2,2,2,2,2,2,2,2,2,2,2,1,0,0],
	[0,1,2,2,2,2,2,2,2,2,2,2,1,0,0,0],
	[0,0,1,1,2,2,2,2,2,2,1,1,0,0,0,0],
	[0,1,6,6,1,1,1,1,6,6,1,0,0,0,0,0],
	[1,6,6,6,6,1,1,6,6,6,6,1,0,0,0,0],
	[0,1,1,1,1,0,0,1,1,1,1,0,0,0,0,0]
]

const snakey_sprite = [
	[0,0,0,0,1,1,1,1,0,0,0,0,0,0,0,0],
	[0,0,0,1,2,2,2,2,1,0,0,0,0,0,0,0],
	[0,0,1,2,3,4,2,2,2,1,0,0,0,0,0,0],
	[0,0,1,2,3,4,2,2,2,1,0,0,0,0,0,0],
	[0,0,1,2,2,2,2,2,1,0,0,0,0,0,0,0],
	[0,0,0,1,2,2,2,1,0,0,0,0,0,0,0,0],
	[0,0,1,2,2,2,2,2,1,1,1,1,0,0,0,0],
	[0,1,2,2,3,3,2,2,2,2,2,2,1,0,0,0],
	[1,2,2,3,3,3,3,2,2,2,2,2,2,1,0,0],
	[1,2,3,3,3,3,3,3,2,2,2,2,2,1,0,0],
	[1,2,3,3,3,3,3,3,2,2,2,2,2,1,0,0],
	[1,2,2,3,3,3,3,2,2,2,2,2,2,1,0,0],
	[0,1,2,2,3,3,2,2,2,2,2,2,1,0,0,0],
	[0,0,1,1,2,2,2,2,2,2,1,1,0,0,0,0],
	[0,0,0,0,1,1,1,1,1,1,0,0,0,0,0,0],
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
]

const gol_sprite = [
	[0,0,1,1,0,0,0,0,0,0,1,1,0,0,0,0],
	[0,1,3,3,1,0,0,0,0,1,3,3,1,0,0,0],
	[0,1,3,3,1,1,1,1,1,1,3,3,1,0,0,0],
	[0,0,1,1,2,2,2,2,2,2,1,1,0,0,0,0],
	[0,1,2,2,2,2,2,2,2,2,2,2,1,0,0,0],
	[1,2,2,4,4,2,2,2,2,4,4,2,2,1,0,0],
	[1,2,4,5,5,4,2,2,4,5,5,4,2,1,0,0],
	[1,2,2,4,4,2,2,2,2,4,4,2,2,1,0,0],
	[1,2,2,2,2,6,6,6,6,2,2,2,2,1,0,0],
	[1,2,2,2,6,7,7,7,7,6,2,2,2,1,0,0],
	[0,1,2,2,6,7,7,7,7,6,2,2,1,0,0,0],
	[0,0,1,2,2,6,6,6,6,2,2,1,0,0,0,0],
	[0,1,2,2,2,2,2,2,2,2,2,2,1,0,0,0],
	[1,2,2,1,1,2,2,2,2,1,1,2,2,1,0,0],
	[1,1,1,0,0,1,1,1,1,0,0,1,1,1,0,0],
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
]

const skull_sprite = [
	[0,0,0,0,1,1,1,1,1,1,0,0,0,0,0,0],
	[0,0,1,1,2,2,2,2,2,2,1,1,0,0,0,0],
	[0,1,2,2,2,2,2,2,2,2,2,2,1,0,0,0],
	[1,2,2,2,2,2,2,2,2,2,2,2,2,1,0,0],
	[1,2,2,1,1,2,2,2,2,1,1,2,2,1,0,0],
	[1,2,1,3,3,1,2,2,1,3,3,1,2,1,0,0],
	[1,2,1,4,4,1,2,2,1,4,4,1,2,1,0,0],
	[1,2,1,4,4,1,2,2,1,4,4,1,2,1,0,0],
	[1,2,2,1,1,2,2,2,2,1,1,2,2,1,0,0],
	[0,1,2,2,2,2,1,1,2,2,2,2,1,0,0,0],
	[0,0,1,2,2,1,3,3,1,2,2,1,0,0,0,0],
	[0,0,1,2,2,2,1,1,2,2,2,1,0,0,0,0],
	[0,0,1,2,1,2,1,1,2,1,2,1,0,0,0,0],
	[0,0,1,2,1,2,1,1,2,1,2,1,0,0,0,0],
	[0,0,0,1,1,1,1,1,1,1,1,0,0,0,0,0],
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
]

const medusa_sprite = [
	[0,0,0,1,1,1,1,1,1,1,1,0,0,0,0,0],
	[0,0,1,2,2,1,1,1,1,2,2,1,0,0,0,0],
	[0,1,2,1,1,2,2,2,2,1,1,2,1,0,0,0],
	[0,1,2,1,2,2,2,2,2,2,1,2,1,0,0,0],
	[1,2,2,2,2,3,3,3,3,2,2,2,2,1,0,0],
	[1,2,2,2,3,4,5,5,4,3,2,2,2,1,0,0],
	[1,2,2,2,3,5,6,6,5,3,2,2,2,1,0,0],
	[1,2,2,2,3,5,6,6,5,3,2,2,2,1,0,0],
	[1,2,2,2,3,4,5,5,4,3,2,2,2,1,0,0],
	[1,2,2,2,2,3,3,3,3,2,2,2,2,1,0,0],
	[1,2,1,2,2,2,2,2,2,2,2,1,2,1,0,0],
	[0,1,2,1,1,2,2,2,2,1,1,2,1,0,0,0],
	[0,0,1,2,2,1,1,1,1,2,2,1,0,0,0,0],
	[0,0,0,1,1,3,3,3,3,1,1,0,0,0,0,0],
	[0,0,1,3,3,3,3,3,3,3,3,1,0,0,0,0],
	[0,0,1,1,1,1,1,1,1,1,1,1,0,0,0,0]
]

const emerald_block_sprite = [
	[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
	[1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1],
	[1,2,3,3,3,3,3,3,3,3,3,3,3,3,2,1],
	[1,2,3,4,4,4,4,4,4,4,4,4,4,3,2,1],
	[1,2,3,4,5,5,5,5,5,5,5,5,4,3,2,1],
	[1,2,3,4,5,6,6,6,6,6,6,5,4,3,2,1],
	[1,2,3,4,5,6,7,7,7,7,6,5,4,3,2,1],
	[1,2,3,4,5,6,7,7,7,7,6,5,4,3,2,1],
	[1,2,3,4,5,6,7,7,7,7,6,5,4,3,2,1],
	[1,2,3,4,5,6,7,7,7,7,6,5,4,3,2,1],
	[1,2,3,4,5,6,6,6,6,6,6,5,4,3,2,1],
	[1,2,3,4,5,5,5,5,5,5,5,5,4,3,2,1],
	[1,2,3,4,4,4,4,4,4,4,4,4,4,3,2,1],
	[1,2,3,3,3,3,3,3,3,3,3,3,3,3,2,1],
	[1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1],
	[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]
]

const heart_framer_sprite = [
	[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
	[1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1],
	[1,2,3,3,3,3,3,3,3,3,3,3,3,3,2,1],
	[1,2,3,0,1,1,0,0,0,0,1,1,0,3,2,1],
	[1,2,3,1,4,4,1,0,0,1,4,4,1,3,2,1],
	[1,2,3,1,4,5,4,1,1,4,5,4,1,3,2,1],
	[1,2,3,1,4,5,4,4,4,4,5,4,1,3,2,1],
	[1,2,3,1,4,4,4,4,4,4,4,4,1,3,2,1],
	[1,2,3,0,1,4,4,4,4,4,4,1,0,3,2,1],
	[1,2,3,0,0,1,4,4,4,4,1,0,0,3,2,1],
	[1,2,3,0,0,0,1,4,4,1,0,0,0,3,2,1],
	[1,2,3,0,0,0,0,1,1,0,0,0,0,3,2,1],
	[1,2,3,3,3,3,3,3,3,3,3,3,3,3,2,1],
	[1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1],
	[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
	[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
]

const egg_sprite = [
	[0,0,0,0,0,1,1,1,1,0,0,0,0,0,0,0],
	[0,0,0,0,1,2,2,2,2,1,0,0,0,0,0,0],
	[0,0,0,1,2,2,3,3,2,2,1,0,0,0,0,0],
	[0,0,1,2,3,3,3,3,2,2,2,1,0,0,0,0],
	[0,1,2,2,3,3,2,2,2,3,2,2,1,0,0,0],
	[0,1,2,2,2,2,2,3,3,3,3,2,1,0,0,0],
	[1,2,2,3,2,2,2,3,3,3,3,2,2,1,0,0],
	[1,2,3,3,3,2,2,2,2,2,2,2,2,1,0,0],
	[1,2,3,3,3,2,2,2,3,3,2,2,2,1,0,0],
	[1,2,2,3,2,2,2,3,3,3,3,2,2,1,0,0],
	[1,2,2,2,2,2,2,3,3,3,3,2,2,1,0,0],
	[0,1,2,2,2,3,2,2,2,2,2,2,1,0,0,0],
	[0,1,2,2,3,3,3,2,2,2,2,2,1,0,0,0],
	[0,0,1,2,2,3,2,2,2,2,2,1,0,0,0,0],
	[0,0,0,1,2,2,2,2,2,2,1,0,0,0,0,0],
	[0,0,0,0,1,1,1,1,1,1,0,0,0,0,0,0]
]

fn draw_futuristic_entity(renderer &sdl.Renderer, x int, y int, ent EntityType, chest_open bool, door_open bool, ticks u32, tex &sdl.Texture) {
	if tex != unsafe { nil } {
		src := match ent {
			.door { if door_open { sdl.Rect{192, 160, 32, 32} } else { sdl.Rect{160, 160, 32, 32} } }
			.chest { if chest_open { sdl.Rect{128, 160, 32, 32} } else { sdl.Rect{96, 160, 32, 32} } }
			.heart_frame { sdl.Rect{0, 160, 32, 32} }
			.emerald_frame { sdl.Rect{64, 160, 32, 32} }
			.hammer { sdl.Rect{224, 160, 32, 32} }
			.key_item { sdl.Rect{224, 224, 32, 32} }
			.speed_boots { sdl.Rect{128, 32, 32, 32} }
			.holo_terminal { sdl.Rect{64, 64, 32, 32} }
			.lolo_spawn { sdl.Rect{0, 0, 32, 32} }
			.snakey { sdl.Rect{0, 192, 32, 32} }
			.alma { sdl.Rect{64, 192, 32, 32} }
			.leeper { sdl.Rect{96, 224, 32, 32} }
			.skull { sdl.Rect{192, 192, 32, 32} }
			.medusa { sdl.Rect{0, 224, 32, 32} }
			.don_medusa_h, .don_medusa_v { sdl.Rect{64, 224, 32, 32} }
			.gol { sdl.Rect{128, 192, 32, 32} }
			.king_egger { sdl.Rect{128, 224, 32, 32} }
			.gobby { sdl.Rect{32, 192, 32, 32} }
			.rocky { sdl.Rect{32, 96, 32, 32} }
			.moby { sdl.Rect{96, 192, 32, 32} }
			.wisp { sdl.Rect{160, 192, 32, 32} }
			.spike_trap { sdl.Rect{0, 224, 32, 32} }
			else { sdl.Rect{0, 0, 0, 0} }
		}
		if src.w > 0 {
			dst := sdl.Rect{ x: x + 2, y: y + 2, w: cell_size - 4, h: cell_size - 4 }
			sdl.render_copy(renderer, tex, &src, &dst)
			return
		}
	}

	cx := x + cell_size / 2
	cy := y + cell_size / 2

	match ent {
		.holo_terminal {
			sdl.set_render_draw_color(renderer, 10, 28, 52, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + 8, y: y + 12, w: cell_size - 16, h: cell_size - 20 })
			sdl.set_render_draw_color(renderer, 0, 240, 255, 255)
			sdl.render_draw_rect(renderer, &sdl.Rect{ x: x + 8, y: y + 12, w: cell_size - 16, h: cell_size - 20 })
			draw_char(renderer, x + 18, y + 18, `i`, 2, Color{ r: 0, g: 255, b: 255 })
		}
		.emerald_frame {
			scale := cell_size / 16
			for r in 0 .. 16 {
				for c in 0 .. 16 {
					val := emerald_block_sprite[r][c]
					if val == 0 { continue }
					col := match val {
						1 { Color{ r: 12, g: 45, b: 28 } }
						2 { Color{ r: 0, g: 215, b: 120 } }
						3 { Color{ r: 35, g: 255, b: 160 } }
						4 { Color{ r: 15, g: 140, b: 75 } }
						5 { Color{ r: 0, g: 190, b: 100 } }
						6 { Color{ r: 120, g: 255, b: 200 } }
						7 { Color{ r: 220, g: 255, b: 240 } }
						else { Color{ r: 0, g: 200, b: 100 } }
					}
					sdl.set_render_draw_color(renderer, col.r, col.g, col.b, 255)
					sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + c * scale, y: y + r * scale, w: scale, h: scale })
				}
			}
		}
		.heart_frame {
			scale := cell_size / 16
			for r in 0 .. 16 {
				for c in 0 .. 16 {
					val := heart_framer_sprite[r][c]
					if val == 0 { continue }
					col := match val {
						1 { Color{ r: 240, g: 190, b: 25 } }
						2 { Color{ r: 255, g: 230, b: 80 } }
						3 { Color{ r: 40, g: 20, b: 30 } }
						4 { Color{ r: 235, g: 25, b: 50 } }
						5 { Color{ r: 255, g: 160, b: 180 } }
						else { Color{ r: 220, g: 30, b: 50 } }
					}
					sdl.set_render_draw_color(renderer, col.r, col.g, col.b, 255)
					sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + c * scale, y: y + r * scale, w: scale, h: scale })
				}
			}
		}
		.chest {
			rect := sdl.Rect{ x: x + 3, y: y + 6, w: cell_size - 6, h: cell_size - 10 }
			if chest_open {
				sdl.set_render_draw_color(renderer, 24, 38, 68, 255)
				sdl.render_fill_rect(renderer, &rect)
				sdl.set_render_draw_color(renderer, 0, 240, 255, 255)
				sdl.render_draw_rect(renderer, &rect)

				float_y := int(math.sin(f64(ticks) / 120.0) * 5.0)
				sdl.set_render_draw_color(renderer, 0, 255, 230, 255)
				sdl.render_fill_rect(renderer, &sdl.Rect{ x: cx - 7, y: cy - 16 + float_y, w: 14, h: 14 })
				sdl.set_render_draw_color(renderer, 255, 255, 255, 255)
				sdl.render_fill_rect(renderer, &sdl.Rect{ x: cx - 3, y: cy - 12 + float_y, w: 6, h: 6 })
			} else {
				sdl.set_render_draw_color(renderer, 220, 160, 20, 255)
				sdl.render_fill_rect(renderer, &rect)
				sdl.set_render_draw_color(renderer, 255, 215, 60, 255)
				sdl.render_draw_rect(renderer, &rect)
				sdl.set_render_draw_color(renderer, 140, 30, 40, 255)
				sdl.render_fill_rect(renderer, &sdl.Rect{ x: cx - 4, y: cy + 1, w: 8, h: 8 })
			}
		}
		.door {
			rect := sdl.Rect{ x: x + 3, y: y + 1, w: cell_size - 6, h: cell_size - 1 }
			if door_open {
				pulse := int(math.sin(f64(ticks) / 80.0) * 4.0)
				sdl.set_render_draw_color(renderer, 0, 220, 255, 255)
				sdl.render_fill_rect(renderer, &rect)
				sdl.set_render_draw_color(renderer, 255, 255, 255, 255)
				sdl.render_fill_rect(renderer, &sdl.Rect{ x: cx - 6 - pulse / 2, y: cy - 6, w: 12 + pulse, h: 18 })
			} else {
				sdl.set_render_draw_color(renderer, 28, 34, 46, 255)
				sdl.render_fill_rect(renderer, &rect)
				sdl.set_render_draw_color(renderer, 255, 40, 60, 255)
				sdl.render_draw_line(renderer, x + 4, y + cell_size / 2, x + cell_size - 4, y + cell_size / 2)
				sdl.render_draw_rect(renderer, &rect)
			}
		}
		.lolo_spawn {
			draw_char(renderer, x + 16, y + 16, `L`, 2, Color{ r: 0, g: 240, b: 255 })
		}
		.hammer {
			sdl.set_render_draw_color(renderer, 70, 85, 110, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: cx - 2, y: cy - 6, w: 4, h: 18 })
			sdl.set_render_draw_color(renderer, 0, 240, 255, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: cx - 10, y: cy - 12, w: 20, h: 8 })
		}
		.key_item {
			sdl.set_render_draw_color(renderer, 255, 215, 0, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: cx - 8, y: cy - 8, w: 16, h: 16 })
			sdl.set_render_draw_color(renderer, 0, 0, 0, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: cx - 6, y: cy - 6, w: 12, h: 4 })
			sdl.set_render_draw_color(renderer, 0, 255, 200, 255)
			sdl.render_draw_point(renderer, cx + 2, cy + 2)
		}
		.speed_boots {
			sdl.set_render_draw_color(renderer, 0, 240, 255, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: cx - 10, y: cy - 2, w: 20, h: 10 })
			sdl.set_render_draw_color(renderer, 255, 255, 255, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: cx - 12, y: cy - 8, w: 8, h: 6 })
		}
		.snakey, .alma, .leeper, .skull, .medusa, .don_medusa_h, .don_medusa_v, .gol, .king_egger, .gobby, .rocky, .moby, .wisp, .spike_trap {
			dummy := Enemy{ kind: ent, x: 0, y: 0, trap_active: true }
			draw_futuristic_enemy(renderer, x, y, dummy, ticks, tex)
		}
		else {}
	}
}

fn draw_futuristic_enemy(renderer &sdl.Renderer, x int, y int, enemy Enemy, ticks u32, tex &sdl.Texture) {
	if tex != unsafe { nil } {
		if enemy.is_egg {
			src := if enemy.egg_timer < 3.0 { sdl.Rect{160, 224, 32, 32} } else { sdl.Rect{128, 224, 32, 32} }
			dst := sdl.Rect{ x: x + 2, y: y + 2, w: cell_size - 4, h: cell_size - 4 }
			sdl.render_copy(renderer, tex, &src, &dst)
			return
		}
		src := match enemy.kind {
			.snakey { sdl.Rect{int((ticks / 300) % 2) * 32, 192, 32, 32} }
			.alma { sdl.Rect{64 + int((ticks / 200) % 2) * 32, 192, 32, 32} }
			.gol { if !enemy.is_asleep { sdl.Rect{160, 192, 32, 32} } else { sdl.Rect{128, 192, 32, 32} } }
			.skull { if !enemy.is_asleep { sdl.Rect{224, 192, 32, 32} } else { sdl.Rect{192, 192, 32, 32} } }
			.medusa { if !enemy.is_asleep { sdl.Rect{32, 224, 32, 32} } else { sdl.Rect{0, 224, 32, 32} } }
			.don_medusa_h, .don_medusa_v { sdl.Rect{64, 224, 32, 32} }
			.leeper { sdl.Rect{96, 224, 32, 32} }
			.king_egger { sdl.Rect{128, 224, 32, 32} }
			.gobby { sdl.Rect{32, 192, 32, 32} }
			.rocky { sdl.Rect{32, 96, 32, 32} }
			.moby { sdl.Rect{96, 192, 32, 32} }
			.wisp { sdl.Rect{160, 192, 32, 32} }
			.spike_trap { sdl.Rect{0, 224, 32, 32} }
			else { sdl.Rect{0, 192, 32, 32} }
		}
		dst := sdl.Rect{ x: x + 2, y: y + 2, w: cell_size - 4, h: cell_size - 4 }
		sdl.render_copy(renderer, tex, &src, &dst)
		return
	}

	scale := cell_size / 16

	if enemy.is_egg {
		for r in 0 .. 16 {
			for c in 0 .. 16 {
				val := egg_sprite[r][c]
				if val == 0 { continue }
				col := match val {
					1 { Color{ r: 40, g: 30, b: 20 } }
					2 { Color{ r: 245, g: 240, b: 220 } }
					3 { Color{ r: 220, g: 180, b: 60 } }
					else { Color{ r: 240, g: 235, b: 210 } }
				}
				sdl.set_render_draw_color(renderer, col.r, col.g, col.b, 255)
				sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + c * scale, y: y + r * scale, w: scale, h: scale })
			}
		}
		return
	}

	match enemy.kind {
		.snakey {
			for r in 0 .. 16 {
				for c in 0 .. 16 {
					val := snakey_sprite[r][c]
					if val == 0 { continue }
					col := match val {
						1 { Color{ r: 15, g: 60, b: 25 } }
						2 { Color{ r: 35, g: 195, b: 65 } }
						3 { Color{ r: 245, g: 220, b: 40 } }
						4 { Color{ r: 255, g: 30, b: 40 } }
						else { Color{ r: 35, g: 195, b: 65 } }
					}
					sdl.set_render_draw_color(renderer, col.r, col.g, col.b, 255)
					sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + c * scale, y: y + r * scale, w: scale, h: scale })
				}
			}
		}
		.gol {
			for r in 0 .. 16 {
				for c in 0 .. 16 {
					val := gol_sprite[r][c]
					if val == 0 { continue }
					col := match val {
						1 { Color{ r: 20, g: 35, b: 80 } }
						2 { Color{ r: 35, g: 110, b: 235 } }
						3 { Color{ r: 255, g: 200, b: 35 } }
						4 { Color{ r: 255, g: 255, b: 255 } }
						5 { Color{ r: 255, g: 30, b: 30 } }
						6 { Color{ r: 220, g: 90, b: 20 } }
						7 { Color{ r: 255, g: 230, b: 80 } }
						else { Color{ r: 35, g: 110, b: 235 } }
					}
					sdl.set_render_draw_color(renderer, col.r, col.g, col.b, 255)
					sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + c * scale, y: y + r * scale, w: scale, h: scale })
				}
			}
		}
		.skull {
			for r in 0 .. 16 {
				for c in 0 .. 16 {
					val := skull_sprite[r][c]
					if val == 0 { continue }
					col := match val {
						1 { Color{ r: 25, g: 25, b: 35 } }
						2 { Color{ r: 235, g: 240, b: 250 } }
						3 { Color{ r: 15, g: 15, b: 25 } }
						4 { Color{ r: 255, g: 30, b: 50 } }
						else { Color{ r: 220, g: 225, b: 235 } }
					}
					sdl.set_render_draw_color(renderer, col.r, col.g, col.b, 255)
					sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + c * scale, y: y + r * scale, w: scale, h: scale })
				}
			}
		}
		.medusa {
			eye_pulse := int(math.sin(f64(ticks) / 100.0) * 40.0)
			for r in 0 .. 16 {
				for c in 0 .. 16 {
					val := medusa_sprite[r][c]
					if val == 0 { continue }
					col := match val {
						1 { Color{ r: 30, g: 40, b: 55 } }
						2 { Color{ r: 120, g: 140, b: 170 } }
						3 { Color{ r: 60, g: 75, b: 95 } }
						4 { Color{ r: 255, g: 255, b: 255 } }
						5 { Color{ r: u8(math_min(255, 215 + eye_pulse)), g: 30, b: 40 } }
						6 { Color{ r: 255, g: 215, b: 0 } }
						else { Color{ r: 100, g: 120, b: 150 } }
					}
					sdl.set_render_draw_color(renderer, col.r, col.g, col.b, 255)
					sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + c * scale, y: y + r * scale, w: scale, h: scale })
				}
			}
		}
		else {
			// Other enemies with sprite styling
			rect := sdl.Rect{ x: x + 3, y: y + 3, w: cell_size - 6, h: cell_size - 6 }
			sdl.set_render_draw_color(renderer, 180, 50, 70, 255)
			sdl.render_fill_rect(renderer, &rect)
			sdl.set_render_draw_color(renderer, 255, 215, 0, 255)
			sdl.render_draw_rect(renderer, &rect)
		}
	}
}

fn draw_cyber_lolo(renderer &sdl.Renderer, x int, y int, dir Direction, ticks u32, is_boosted bool, skin CyberSkin, tex &sdl.Texture) {
	bob_y := int(math.sin(f64(ticks) / 110.0) * 2.0)
	px := x
	py := y + bob_y

	if tex != unsafe { nil } {
		anim_frame := int((ticks / 180) % 2)
		src := if skin != .neon_blue {
			match skin {
				.cyber_magenta { sdl.Rect{0, 32, 32, 32} }
				.obsidian_gold { sdl.Rect{32, 32, 32, 32} }
				.toxic_lime { sdl.Rect{64, 32, 32, 32} }
				.dark_matter { sdl.Rect{96, 32, 32, 32} }
				else { sdl.Rect{0, 0, 32, 32} }
			}
		} else {
			match dir {
				.down { sdl.Rect{anim_frame * 32, 0, 32, 32} }
				.up { sdl.Rect{64 + anim_frame * 32, 0, 32, 32} }
				.left { sdl.Rect{128 + anim_frame * 32, 0, 32, 32} }
				.right { sdl.Rect{192 + anim_frame * 32, 0, 32, 32} }
			}
		}
		dst := sdl.Rect{ x: px, y: py, w: cell_size, h: cell_size }
		sdl.render_copy(renderer, tex, &src, &dst)

		if is_boosted {
			aura_pulse := int((math.sin(f64(ticks) / 50.0) + 1.0) * 3.0)
			sdl.set_render_draw_blend_mode(renderer, .blend)
			sdl.set_render_draw_color(renderer, 255, 215, 0, 180)
			sdl.render_draw_rect(renderer, &sdl.Rect{
				x: px - 2 - aura_pulse
				y: py - 2 - aura_pulse
				w: cell_size + 4 + aura_pulse * 2
				h: cell_size + 4 + aura_pulse * 2
			})
			sdl.set_render_draw_blend_mode(renderer, .none)
		}
		return
	}
	scale := cell_size / 16

	body_sprite := match dir {
		.up { lolo_sprite_up }
		.left { lolo_sprite_left }
		.right { lolo_sprite_left } // Mirrored horizontally
		else { lolo_sprite_down }
	}

	is_mirrored := dir == .right

	for r in 0 .. 16 {
		for c in 0 .. 16 {
			src_c := if is_mirrored { 15 - c } else { c }
			val := body_sprite[r][src_c]
			if val == 0 { continue }

			col := match val {
				1 { Color{ r: 15, g: 35, b: 85 } }
				2 {
					match skin {
						.neon_blue { Color{ r: 35, g: 135, b: 245 } }
						.cyber_magenta { Color{ r: 235, g: 35, b: 145 } }
						.obsidian_gold { Color{ r: 45, g: 45, b: 55 } }
						.toxic_lime { Color{ r: 45, g: 215, b: 65 } }
						.dark_matter { Color{ r: 85, g: 25, b: 120 } }
					}
				}
				3 { Color{ r: 255, g: 255, b: 255 } }
				4 { Color{ r: 10, g: 15, b: 25 } }
				5 { Color{ r: 255, g: 140, b: 160 } }
				6 { Color{ r: 235, g: 35, b: 45 } }
				7 { Color{ r: 255, g: 215, b: 30 } }
				else { Color{ r: 35, g: 135, b: 245 } }
			}

			sdl.set_render_draw_color(renderer, col.r, col.g, col.b, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: px + c * scale, y: py + r * scale, w: scale, h: scale })
		}
	}

	if is_boosted {
		aura_pulse := int((math.sin(f64(ticks) / 50.0) + 1.0) * 3.0)
		sdl.set_render_draw_blend_mode(renderer, .blend)
		sdl.set_render_draw_color(renderer, 255, 215, 0, 180)
		sdl.render_draw_rect(renderer, &sdl.Rect{
			x: px - 2 - aura_pulse,
			y: py - 2 - aura_pulse,
			w: cell_size + 4 + aura_pulse * 2,
			h: cell_size + 4 + aura_pulse * 2,
		})
		sdl.set_render_draw_blend_mode(renderer, .none)
	}
}

fn draw_plasma_shot(renderer &sdl.Renderer, sx int, sy int, ticks u32) {
	pulse := int(math.sin(f64(ticks) / 50.0) * 3.0)
	sdl.set_render_draw_blend_mode(renderer, .blend)
	sdl.set_render_draw_color(renderer, 0, 200, 255, 130)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: sx - 10 - pulse, y: sy - 10 - pulse, w: 20 + pulse * 2, h: 20 + pulse * 2 })
	sdl.set_render_draw_color(renderer, 0, 240, 255, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: sx - 6, y: sy - 6, w: 12, h: 12 })
	sdl.set_render_draw_color(renderer, 255, 255, 255, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: sx - 3, y: sy - 3, w: 6, h: 6 })
	sdl.set_render_draw_blend_mode(renderer, .none)
}

// --------------------------------------------------
// Mario Maker Cyberpunk Sidebar & Palette Layout
// --------------------------------------------------

fn draw_mario_maker_editor(renderer &sdl.Renderer, game Game, mx int, my int, btn_test Button, btn_clear Button) {
	panel_x := 580
	panel_y := 75
	panel_w := 365
	panel_h := 590

	sdl.set_render_draw_color(renderer, 16, 20, 34, 255)
	card := sdl.Rect{ x: panel_x, y: panel_y, w: panel_w, h: panel_h }
	sdl.render_fill_rect(renderer, &card)

	sdl.set_render_draw_color(renderer, 0, 220, 255, 255)
	sdl.render_draw_rect(renderer, &card)

	// Top Category Tabs: [TILES] [ITEMS] [ENEMIES] [SETTINGS]
	tabs := ['TILES', 'ITEMS', 'ENEMIES', 'SETTINGS']
	for i, t_name in tabs {
		tx := panel_x + 10 + i * 86
		ty := panel_y + 10
		is_active := int(game.editor_tab) == i
		t_col := if is_active { Color{ r: 0, g: 140, b: 220 } } else { Color{ r: 25, g: 35, b: 55 } }
		sdl.set_render_draw_color(renderer, t_col.r, t_col.g, t_col.b, 255)
		sdl.render_fill_rect(renderer, &sdl.Rect{ x: tx, y: ty, w: 82, h: 28 })
		sdl.render_draw_rect(renderer, &sdl.Rect{ x: tx, y: ty, w: 82, h: 28 })
		draw_text_centered(renderer, tx + 41, ty + 6, t_name, 1, Color{ r: 255, g: 255, b: 255 })
	}

	// Tool Selector: [PEN] [LINE] [RECT] [FILL] [ERASE] [PREFAB]
	tools := ['PEN', 'LINE', 'RECT', 'FILL', 'ERASE', 'PREFAB']
	for i, tool_name in tools {
		bx := panel_x + 10 + i * 58
		by := panel_y + 44
		is_tool_active := int(game.editor_tool) == i
		b_col := if is_tool_active { Color{ r: 220, g: 150, b: 20 } } else { Color{ r: 35, g: 45, b: 65 } }
		sdl.set_render_draw_color(renderer, b_col.r, b_col.g, b_col.b, 255)
		sdl.render_fill_rect(renderer, &sdl.Rect{ x: bx, y: by, w: 54, h: 26 })
		sdl.set_render_draw_color(renderer, 150, 150, 150, 255)
		sdl.render_draw_rect(renderer, &sdl.Rect{ x: bx, y: by, w: 54, h: 26 })
		draw_text_centered(renderer, bx + 27, by + 5, tool_name, 1, Color{ r: 255, g: 255, b: 255 })
	}

	// Palette Content
	match game.editor_tab {
		.tiles { draw_tiles_palette(renderer, game, panel_x, panel_y + 78) }
		.items { draw_items_palette(renderer, game, panel_x, panel_y + 78) }
		.enemies { draw_enemies_palette(renderer, game, panel_x, panel_y + 78) }
		.themes { draw_themes_and_slots_palette(renderer, game, panel_x, panel_y + 78) }
		else { draw_tiles_palette(renderer, game, panel_x, panel_y + 78) }
	}

	// Live Mario Maker Checklist HUD
	draw_level_checklist(renderer, game, panel_x + 12, panel_y + 375)

	btn_test.draw(renderer, mx, my)
	btn_clear.draw(renderer, mx, my)
}

fn get_tile_sprite_rect(tile TileType) sdl.Rect {
	return match tile {
		.grass { sdl.Rect{0, 64, 32, 32} }
		.wall { sdl.Rect{192, 64, 32, 32} }
		.rock { sdl.Rect{32, 96, 32, 32} }
		.tree { sdl.Rect{0, 96, 32, 32} }
		.water { sdl.Rect{64, 96, 32, 32} }
		.lava { sdl.Rect{192, 96, 32, 32} }
		.ice { sdl.Rect{224, 96, 32, 32} }
		.warp_a { sdl.Rect{128, 128, 32, 32} }
		.warp_b { sdl.Rect{160, 128, 32, 32} }
		.locked_gate { sdl.Rect{160, 160, 32, 32} }
		.laser_prism_slash, .laser_prism_backslash { sdl.Rect{224, 128, 32, 32} }
		.pressure_plate, .plate_channel_1, .plate_channel_2 { sdl.Rect{192, 128, 32, 32} }
		.toggle_laser_gate, .gate_channel_1, .gate_channel_2 { sdl.Rect{224, 128, 32, 32} }
		.conveyor_up { sdl.Rect{0, 128, 32, 32} }
		.conveyor_down { sdl.Rect{32, 128, 32, 32} }
		.conveyor_left { sdl.Rect{64, 128, 32, 32} }
		.conveyor_right { sdl.Rect{96, 128, 32, 32} }
		.phase_block_alpha { sdl.Rect{64, 64, 32, 32} }
		.phase_block_beta { sdl.Rect{128, 64, 32, 32} }
		.bridge { sdl.Rect{32, 64, 32, 32} }
		.timed_laser_barrier { sdl.Rect{224, 128, 32, 32} }
		else { sdl.Rect{0, 64, 32, 32} }
	}
}

fn get_entity_sprite_rect(ent EntityType) sdl.Rect {
	return match ent {
		.lolo_spawn { sdl.Rect{0, 0, 32, 32} }
		.door { sdl.Rect{160, 160, 32, 32} }
		.chest { sdl.Rect{96, 160, 32, 32} }
		.heart_frame { sdl.Rect{0, 160, 32, 32} }
		.emerald_frame { sdl.Rect{64, 160, 32, 32} }
		.hammer { sdl.Rect{224, 160, 32, 32} }
		.key_item { sdl.Rect{224, 224, 32, 32} }
		.speed_boots { sdl.Rect{128, 32, 32, 32} }
		.holo_terminal { sdl.Rect{64, 64, 32, 32} }
		.snakey { sdl.Rect{0, 192, 32, 32} }
		.alma { sdl.Rect{64, 192, 32, 32} }
		.leeper { sdl.Rect{96, 224, 32, 32} }
		.skull { sdl.Rect{192, 192, 32, 32} }
		.medusa { sdl.Rect{0, 224, 32, 32} }
		.don_medusa_h, .don_medusa_v { sdl.Rect{64, 224, 32, 32} }
		.gol { sdl.Rect{128, 192, 32, 32} }
		.king_egger { sdl.Rect{128, 224, 32, 32} }
		.gobby { sdl.Rect{32, 192, 32, 32} }
		.rocky { sdl.Rect{32, 96, 32, 32} }
		.moby { sdl.Rect{96, 192, 32, 32} }
		.wisp { sdl.Rect{160, 192, 32, 32} }
		.spike_trap { sdl.Rect{0, 224, 32, 32} }
		else { sdl.Rect{0, 0, 32, 32} }
	}
}

fn draw_tiles_palette(renderer &sdl.Renderer, game Game, px int, py int) {
	tiles := [
		TileType.grass,
		TileType.wall,
		TileType.rock,
		TileType.tree,
		TileType.water,
		TileType.bridge,
		TileType.lava,
		TileType.ice,
		TileType.warp_a,
		TileType.warp_b,
		TileType.locked_gate,
		TileType.laser_prism_slash,
		TileType.laser_prism_backslash,
		TileType.pressure_plate,
		TileType.toggle_laser_gate,
		TileType.conveyor_up,
		TileType.conveyor_down,
		TileType.conveyor_left,
		TileType.conveyor_right,
		TileType.phase_block_alpha,
		TileType.phase_block_beta,
		TileType.timed_laser_barrier,
		TileType.plate_channel_1,
		TileType.gate_channel_1,
	]
	tile_names := [
		'GRASS',
		'WALL',
		'ROCK',
		'SPIRE',
		'COOLANT',
		'SCAFFOLD',
		'PLASMA',
		'CRYO ICE',
		'WARP A',
		'WARP B',
		'LOCK GATE',
		'PRISM /',
		'PRISM \\',
		'PLATE',
		'LASER GATE',
		'CONV ^',
		'CONV v',
		'CONV <',
		'CONV >',
		'PHASE A',
		'PHASE B',
		'PULSE GATE',
		'PLATE CH1',
		'GATE CH1',
	]

	for i in 0 .. tiles.len {
		col := i % 3
		row := i / 3
		ix := px + 12 + col * 114
		iy := py + row * 28

		is_sel := !game.is_entity_selected && game.selected_tile == tiles[i]
		bg := if is_sel { Color{ r: 0, g: 140, b: 220 } } else { Color{ r: 25, g: 35, b: 55 } }
		sdl.set_render_draw_color(renderer, bg.r, bg.g, bg.b, 255)
		sdl.render_fill_rect(renderer, &sdl.Rect{ x: ix, y: iy, w: 108, h: 25 })
		sdl.set_render_draw_color(renderer, 0, 200, 255, 255)
		sdl.render_draw_rect(renderer, &sdl.Rect{ x: ix, y: iy, w: 108, h: 25 })

		if game.sprite_texture != unsafe { nil } {
			src := get_tile_sprite_rect(tiles[i])
			dst := sdl.Rect{ x: ix + 3, y: iy + 2, w: 20, h: 20 }
			sdl.render_copy(renderer, game.sprite_texture, &src, &dst)
			draw_text(renderer, ix + 26, iy + 6, tile_names[i], 1, Color{ r: 255, g: 255, b: 255 })
		} else {
			draw_text_centered(renderer, ix + 54, iy + 5, tile_names[i], 1, Color{ r: 255, g: 255, b: 255 })
		}
	}
}

fn draw_items_palette(renderer &sdl.Renderer, game Game, px int, py int) {
	items := [
		EntityType.lolo_spawn,
		EntityType.door,
		EntityType.chest,
		EntityType.heart_frame,
		EntityType.emerald_frame,
		EntityType.hammer,
		EntityType.key_item,
		EntityType.speed_boots,
		EntityType.holo_terminal,
	]
	item_names := [
		'LOLO',
		'DOOR',
		'CHEST',
		'HEART',
		'EMERALD',
		'HAMMER',
		'KEYCARD',
		'BOOTS',
		'BEACON',
	]

	for i in 0 .. items.len {
		col := i % 3
		row := i / 3
		ix := px + 12 + col * 114
		iy := py + row * 36

		is_sel := game.is_entity_selected && game.selected_entity == items[i]
		bg := if is_sel { Color{ r: 0, g: 140, b: 220 } } else { Color{ r: 25, g: 35, b: 55 } }
		sdl.set_render_draw_color(renderer, bg.r, bg.g, bg.b, 255)
		sdl.render_fill_rect(renderer, &sdl.Rect{ x: ix, y: iy, w: 108, h: 32 })
		sdl.set_render_draw_color(renderer, 0, 200, 255, 255)
		sdl.render_draw_rect(renderer, &sdl.Rect{ x: ix, y: iy, w: 108, h: 32 })

		if game.sprite_texture != unsafe { nil } {
			src := get_entity_sprite_rect(items[i])
			dst := sdl.Rect{ x: ix + 4, y: iy + 4, w: 24, h: 24 }
			sdl.render_copy(renderer, game.sprite_texture, &src, &dst)
			draw_text(renderer, ix + 32, iy + 10, item_names[i], 1, Color{ r: 255, g: 255, b: 255 })
		} else {
			draw_text_centered(renderer, ix + 54, iy + 10, item_names[i], 1, Color{ r: 255, g: 255, b: 255 })
		}
	}
}

fn draw_enemies_palette(renderer &sdl.Renderer, game Game, px int, py int) {
	enemies := [
		EntityType.snakey,
		EntityType.alma,
		EntityType.leeper,
		EntityType.skull,
		EntityType.medusa,
		EntityType.don_medusa_h,
		EntityType.don_medusa_v,
		EntityType.gol,
		EntityType.king_egger,
		EntityType.gobby,
		EntityType.rocky,
		EntityType.moby,
		EntityType.wisp,
		EntityType.spike_trap,
	]
	enemy_names := [
		'SNAKEY',
		'ALMA',
		'LEEPER',
		'SKULL',
		'MEDUSA',
		'DON MEDUSA H',
		'DON MEDUSA V',
		'GOL',
		'KING EGGER',
		'GOBBY',
		'ROCKY',
		'MOBY',
		'WISP',
		'SPIKE TRAP',
	]

	for i in 0 .. enemies.len {
		col := i % 2
		row := i / 2
		ix := px + 12 + col * 172
		iy := py + row * 40

		is_sel := game.is_entity_selected && game.selected_entity == enemies[i]
		bg := if is_sel { Color{ r: 0, g: 140, b: 220 } } else { Color{ r: 25, g: 35, b: 55 } }
		sdl.set_render_draw_color(renderer, bg.r, bg.g, bg.b, 255)
		sdl.render_fill_rect(renderer, &sdl.Rect{ x: ix, y: iy, w: 164, h: 34 })
		sdl.set_render_draw_color(renderer, 0, 200, 255, 255)
		sdl.render_draw_rect(renderer, &sdl.Rect{ x: ix, y: iy, w: 164, h: 34 })

		if game.sprite_texture != unsafe { nil } {
			src := get_entity_sprite_rect(enemies[i])
			dst := sdl.Rect{ x: ix + 4, y: iy + 4, w: 26, h: 26 }
			sdl.render_copy(renderer, game.sprite_texture, &src, &dst)
			draw_text(renderer, ix + 36, iy + 10, enemy_names[i], 1, Color{ r: 255, g: 255, b: 255 })
		} else {
			draw_text_centered(renderer, ix + 82, iy + 9, enemy_names[i], 1, Color{ r: 255, g: 255, b: 255 })
		}
	}
}

fn draw_themes_and_slots_palette(renderer &sdl.Renderer, game Game, px int, py int) {
	draw_text(renderer, px + 12, py, 'CYBER BIOMES:', 1, Color{ r: 255, g: 215, b: 0 })
	themes := [
		LevelTheme.castle,
		LevelTheme.forest,
		LevelTheme.desert,
		LevelTheme.ice,
		LevelTheme.volcanic,
		LevelTheme.haunted,
	]
	theme_names := ['CYBER-CORE', 'QUANTUM BIO', 'SOLAR POST', 'CRYO-STASIS', 'PLASMA CORE', 'VOID NETHER']

	for i in 0 .. themes.len {
		col := i % 3
		row := i / 3
		ix := px + 12 + col * 114
		iy := py + 18 + row * 30

		is_active := game.editor_level.theme == themes[i]
		bg := if is_active { Color{ r: 220, g: 150, b: 20 } } else { Color{ r: 25, g: 35, b: 55 } }
		sdl.set_render_draw_color(renderer, bg.r, bg.g, bg.b, 255)
		sdl.render_fill_rect(renderer, &sdl.Rect{ x: ix, y: iy, w: 108, h: 26 })
		sdl.set_render_draw_color(renderer, 0, 220, 255, 255)
		sdl.render_draw_rect(renderer, &sdl.Rect{ x: ix, y: iy, w: 108, h: 26 })
		draw_text_centered(renderer, ix + 54, iy + 5, theme_names[i], 1, Color{ r: 255, g: 255, b: 255 })
	}

	draw_text(renderer, px + 12, py + 86, 'BLUEPRINT TEMPLATES:', 1, Color{ r: 255, g: 215, b: 0 })
	templates := ['BLANK', 'ISLAND', 'LABYRINTH', 'ICE CHAMBER', 'FORTRESS']
	for i, t_name in templates {
		col := i % 3
		row := i / 3
		ix := px + 12 + col * 114
		iy := py + 104 + row * 30
		sdl.set_render_draw_color(renderer, 35, 50, 75, 255)
		sdl.render_fill_rect(renderer, &sdl.Rect{ x: ix, y: iy, w: 108, h: 26 })
		sdl.set_render_draw_color(renderer, 0, 200, 255, 255)
		sdl.render_draw_rect(renderer, &sdl.Rect{ x: ix, y: iy, w: 108, h: 26 })
		draw_text_centered(renderer, ix + 54, iy + 5, t_name, 1, Color{ r: 220, g: 240, b: 255 })
	}

	// Dark Dungeon Mode Modifier
	dark_text := if game.editor_level.is_dark_dungeon { 'DARK VISION: ON' } else { 'DARK VISION: OFF' }
	dark_col := if game.editor_level.is_dark_dungeon { Color{ r: 255, g: 140, b: 0 } } else { Color{ r: 40, g: 55, b: 85 } }
	sdl.set_render_draw_color(renderer, dark_col.r, dark_col.g, dark_col.b, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: px + 12, y: py + 170, w: 338, h: 26 })
	sdl.set_render_draw_color(renderer, 0, 240, 255, 255)
	sdl.render_draw_rect(renderer, &sdl.Rect{ x: px + 12, y: py + 170, w: 338, h: 26 })
	draw_text_centered(renderer, px + 181, py + 175, dark_text, 1, Color{ r: 255, g: 255, b: 255 })

	draw_text(renderer, px + 12, py + 204, 'COMMUNITY & CODE SHARING [K]:', 1, Color{ r: 255, g: 215, b: 0 })
	sdl.set_render_draw_color(renderer, 0, 120, 220, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: px + 12, y: py + 222, w: 338, h: 28 })
	sdl.set_render_draw_color(renderer, 0, 240, 255, 255)
	sdl.render_draw_rect(renderer, &sdl.Rect{ x: px + 12, y: py + 222, w: 338, h: 28 })
	draw_text_centered(renderer, px + 181, py + 228, 'OPEN CYBER-CODE SHARING [K]', 1, Color{ r: 255, g: 255, b: 255 })

	draw_text(renderer, px + 12, py + 258, 'SAVE / LOAD SLOTS:', 1, Color{ r: 255, g: 215, b: 0 })
	for i in 0 .. 5 {
		ix := px + 12 + i * 68
		iy := py + 276
		sdl.set_render_draw_color(renderer, 0, 100, 180, 255)
		sdl.render_fill_rect(renderer, &sdl.Rect{ x: ix, y: iy, w: 62, h: 24 })
		sdl.set_render_draw_color(renderer, 0, 240, 255, 255)
		sdl.render_draw_rect(renderer, &sdl.Rect{ x: ix, y: iy, w: 62, h: 24 })
		draw_text_centered(renderer, ix + 31, iy + 4, 'S${i + 1}', 1, Color{ r: 255, g: 255, b: 255 })
	}
	for i in 0 .. 5 {
		ix := px + 12 + i * 68
		iy := py + 276
		sdl.set_render_draw_color(renderer, 100, 40, 140, 255)
		sdl.render_fill_rect(renderer, &sdl.Rect{ x: ix, y: iy, w: 62, h: 24 })
		sdl.set_render_draw_color(renderer, 220, 100, 255, 255)
		sdl.render_draw_rect(renderer, &sdl.Rect{ x: ix, y: iy, w: 62, h: 24 })
		draw_text_centered(renderer, ix + 31, iy + 4, 'L${i + 1}', 1, Color{ r: 255, g: 255, b: 255 })
	}
}

fn draw_level_checklist(renderer &sdl.Renderer, game Game, x int, y int) {
	mut lolo_count := 0
	mut chest_count := 0
	mut door_count := 0
	mut heart_count := 0

	for r in 0 .. grid_rows {
		for c in 0 .. grid_cols {
			ent := game.editor_level.entities[r][c]
			match ent {
				.lolo_spawn { lolo_count++ }
				.chest { chest_count++ }
				.door { door_count++ }
				.heart_frame { heart_count++ }
				else {}
			}
		}
	}

	draw_text(renderer, x, y, 'CYBER SYSTEM CHECKLIST:', 1, Color{ r: 255, g: 215, b: 0 })

	l_col := if lolo_count == 1 { Color{ r: 0, g: 255, b: 180 } } else { Color{ r: 255, g: 70, b: 70 } }
	draw_text(renderer, x, y + 18, 'SPAWN: ${lolo_count}/1', 1, l_col)

	d_col := if door_count == 1 { Color{ r: 0, g: 255, b: 180 } } else { Color{ r: 255, g: 70, b: 70 } }
	draw_text(renderer, x + 160, y + 18, 'GATE: ${door_count}/1', 1, d_col)

	c_col := if chest_count == 1 { Color{ r: 0, g: 255, b: 180 } } else { Color{ r: 255, g: 70, b: 70 } }
	draw_text(renderer, x, y + 36, 'VAULT: ${chest_count}/1', 1, c_col)

	h_col := if heart_count >= 1 { Color{ r: 0, g: 255, b: 180 } } else { Color{ r: 255, g: 70, b: 70 } }
	draw_text(renderer, x + 160, y + 36, 'CORES: ${heart_count}', 1, h_col)

	// AI Solvability Status
	is_solvable := game.verify_level_solvability()
	solv_str := if is_solvable { 'AI SOLVER: SOLVABLE [PASS]' } else { 'AI SOLVER: UNREACHABLE [!]' }
	solv_col := if is_solvable { Color{ r: 0, g: 255, b: 180 } } else { Color{ r: 255, g: 80, b: 80 } }
	draw_text(renderer, x, y + 54, solv_str, 1, solv_col)

	if game.validation_msg != '' {
		draw_text(renderer, x, y + 70, game.validation_msg, 1, Color{ r: 255, g: 220, b: 80 })
	}
}

fn draw_hud_panel(renderer &sdl.Renderer, game Game, mx int, my int, btn_prev Button, btn_next Button, btn_restart Button, btn_undo Button, btn_level_select Button) {
	panel_x := 580
	panel_y := 75
	panel_w := 365
	panel_h := 590

	sdl.set_render_draw_color(renderer, 16, 20, 34, 255)
	card := sdl.Rect{ x: panel_x, y: panel_y, w: panel_w, h: panel_h }
	sdl.render_fill_rect(renderer, &card)

	sdl.set_render_draw_color(renderer, 0, 220, 255, 255)
	sdl.render_draw_rect(renderer, &card)

	draw_text(renderer, panel_x + 18, panel_y + 14, 'MISSION TELEMETRY', 2, Color{ r: 255, g: 215, b: 0 })

	// Cores Remaining
	draw_text(renderer, panel_x + 18, panel_y + 44, 'POWER CORES: ${game.hearts_remaining} / ${game.total_hearts}', 2, Color{ r: 255, g: 100, b: 140 })

	// Plasma Shots & Keys
	draw_text(renderer, panel_x + 18, panel_y + 70, 'PLASMA: ${game.lolo.shots}   KEYS: ${game.lolo.keys}', 2, Color{ r: 0, g: 240, b: 255 })

	// Wrench & Overdrive
	ham_str := if game.lolo.speed_boost > 0 { 'WRENCH: ${game.lolo.hammers}  OVERDRIVE: ${int(game.lolo.speed_boost)}s' } else { 'WRENCH: ${game.lolo.hammers}' }
	draw_text(renderer, panel_x + 18, panel_y + 96, ham_str, 2, Color{ r: 255, g: 200, b: 80 })

	// Personal Best Telemetry
	pb_time := game.pb_times[game.current_level_idx]
	pb_str := if pb_time > 0 {
		sec := int(pb_time / 1000)
		ms := int((pb_time % 1000) / 10)
		'RECORD PB: ${sec:02d}.${ms:02d}s (${game.pb_moves[game.current_level_idx]} steps)'
	} else {
		'RECORD PB: --.--s'
	}
	draw_text(renderer, panel_x + 18, panel_y + 124, pb_str, 1, Color{ r: 255, g: 215, b: 0 })

	// Goal Instructions
	goal_str := if game.hearts_remaining > 0 {
		'1. Extract all Power Cores'
	} else if !game.door_open {
		'2. Access the Central Matrix Vault'
	} else {
		'3. Warp through the Subspace Gateway!'
	}
	draw_text(renderer, panel_x + 18, panel_y + 148, 'DIRECTIVE:', 1, Color{ r: 255, g: 255, b: 255 })
	draw_text(renderer, panel_x + 18, panel_y + 166, goal_str, 1, Color{ r: 0, g: 255, b: 180 })

	// Controls list
	draw_text(renderer, panel_x + 18, panel_y + 192, 'CYBER CONTROLS:', 1, Color{ r: 255, g: 215, b: 0 })
	draw_text(renderer, panel_x + 18, panel_y + 210, 'WASD/ARROWS: Move  SPACE: Fire Shot', 1, Color{ r: 180, g: 220, b: 255 })
	draw_text(renderer, panel_x + 18, panel_y + 226, 'Q: Phase Dimension  C: Cycle Skins', 1, Color{ r: 180, g: 220, b: 255 })
	draw_text(renderer, panel_x + 18, panel_y + 242, 'H: Toggle AI Hints  V: Instant Replay', 1, Color{ r: 180, g: 220, b: 255 })
	draw_text(renderer, panel_x + 18, panel_y + 258, 'TAB: Designer Mode  K: Share Codes', 1, Color{ r: 180, g: 220, b: 255 })
	draw_text(renderer, panel_x + 18, panel_y + 274, 'U/Z: Undo Step     P: Warp Sectors', 1, Color{ r: 180, g: 220, b: 255 })

	btn_undo.draw(renderer, mx, my)
	btn_level_select.draw(renderer, mx, my)
	btn_prev.draw(renderer, mx, my)
	btn_next.draw(renderer, mx, my)
	btn_restart.draw(renderer, mx, my)
}

fn draw_achievement_toast(renderer &sdl.Renderer, text string, ticks u32) {
	toast_w := 480
	toast_h := 46
	tx := (win_w - toast_w) / 2
	ty := 75

	sdl.set_render_draw_color(renderer, 20, 25, 45, 240)
	card := sdl.Rect{ x: tx, y: ty, w: toast_w, h: toast_h }
	sdl.render_fill_rect(renderer, &card)

	pulse := int((math.sin(f64(ticks) / 80.0) + 1.0) * 15.0)
	sdl.set_render_draw_color(renderer, 255, u8(215 + pulse), 0, 255)
	sdl.render_draw_rect(renderer, &card)
	draw_text_centered(renderer, win_w / 2, ty + 15, text, 2, Color{ r: 255, g: 215, b: 0 })
}

fn draw_replay_overlay(renderer &sdl.Renderer, ticks u32) {
	pulse := int(math.sin(f64(ticks) / 100.0) * 40.0)
	sdl.set_render_draw_color(renderer, 255, 40, 80, 200)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: 20, y: 75, w: 536, h: 36 })
	draw_text_centered(renderer, 20 + 268, 85, 'GHOST REPLAY RUNNING [PRESS V TO EXIT]', 2, Color{ r: 255, g: u8(200 + pulse), b: 255 })
}

fn draw_status_overlay(renderer &sdl.Renderer, game Game) {
	sdl.set_render_draw_blend_mode(renderer, .blend)
	sdl.set_render_draw_color(renderer, 6, 10, 20, 200)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: 0, y: 0, w: win_w, h: win_h })

	col := if game.status == .level_clear { Color{ r: 0, g: 255, b: 200 } } else { Color{ r: 255, g: 60, b: 80 } }
	draw_text_centered(renderer, win_w / 2, win_h / 2 - 30, game.status_msg, 3, col)
	draw_text_centered(renderer, win_w / 2, win_h / 2 + 20, 'PRESS SPACE / ENTER TO PROCEED', 2, Color{ r: 255, g: 255, b: 255 })
}

fn draw_victory_ending(renderer &sdl.Renderer, game Game, ticks u32) {
	sdl.set_render_draw_blend_mode(renderer, .blend)
	sdl.set_render_draw_color(renderer, 8, 12, 28, 240)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: 0, y: 0, w: win_w, h: win_h })

	for i in 0 .. 45 {
		cx := (i * 37 + int(ticks / 10)) % win_w
		cy := (i * 29 + int(ticks / 15)) % win_h
		sdl.set_render_draw_color(renderer, u8((i * 55) % 255), 240, 255, 255)
		sdl.render_fill_rect(renderer, &sdl.Rect{ x: cx, y: cy, w: 4, h: 4 })
	}

	draw_text_centered(renderer, win_w / 2, 90, 'VICTORY! PRINCESS LALA RESCUED!', 3, Color{ r: 255, g: 215, b: 0 })
	draw_text_centered(renderer, win_w / 2, 130, 'KING EGGER HAS BEEN PURGED FROM CYBERSPACE!', 2, Color{ r: 0, g: 240, b: 255 })

	draw_cyber_lolo(renderer, win_w / 2 - 60, 200, .right, ticks, true, game.skin, game.sprite_texture)
	draw_princess_lala(renderer, win_w / 2 + 20, 200, ticks, game.sprite_texture)

	heart_y := 170 + int(math.sin(f64(ticks) / 160.0) * 8.0)
	draw_char(renderer, win_w / 2 - 8, heart_y, `*`, 3, Color{ r: 255, g: 40, b: 120 })

	card_x := win_w / 2 - 200
	card_y := 280
	sdl.set_render_draw_color(renderer, 16, 22, 40, 255)
	card := sdl.Rect{ x: card_x, y: card_y, w: 400, h: 180 }
	sdl.render_fill_rect(renderer, &card)
	sdl.set_render_draw_color(renderer, 0, 230, 255, 255)
	sdl.render_draw_rect(renderer, &card)

	draw_text_centered(renderer, win_w / 2, card_y + 20, 'MISSION REPORT', 2, Color{ r: 255, g: 215, b: 0 })
	draw_text(renderer, card_x + 40, card_y + 60, 'FINAL SCORE: ${game.score}', 2, Color{ r: 255, g: 255, b: 255 })
	draw_text(renderer, card_x + 40, card_y + 90, 'TOTAL STEPS: ${game.moves_count}', 2, Color{ r: 0, g: 240, b: 255 })
	draw_text(renderer, card_x + 40, card_y + 120, 'SECTORS CLEARED: 20 / 20', 2, Color{ r: 0, g: 255, b: 180 })

	draw_text_centered(renderer, win_w / 2, 500, 'PRESS SPACE / ENTER TO REBOOT MISSION', 2, Color{ r: 255, g: 255, b: 255 })
}

fn draw_princess_lala(renderer &sdl.Renderer, x int, y int, ticks u32, tex &sdl.Texture) {
	if tex != unsafe { nil } {
		anim_frame := int((ticks / 250) % 2)
		src := sdl.Rect{192 + anim_frame * 32, 32, 32, 32}
		dst := sdl.Rect{ x: x, y: y, w: cell_size, h: cell_size }
		sdl.render_copy(renderer, tex, &src, &dst)
		return
	}

	cx := x + cell_size / 2
	cy := y + cell_size / 2

	sdl.set_render_draw_color(renderer, 245, 100, 190, 255)
	body := sdl.Rect{ x: x + 6, y: y + 6, w: cell_size - 12, h: cell_size - 12 }
	sdl.render_fill_rect(renderer, &body)

	bow_y := y + 2 + int(math.sin(f64(ticks) / 180.0) * 2.0)
	sdl.set_render_draw_color(renderer, 255, 40, 140, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: cx - 12, y: bow_y, w: 10, h: 8 })
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: cx + 2, y: bow_y, w: 10, h: 8 })

	is_blinking := (ticks / 2400) % 12 == 0
	if !is_blinking {
		sdl.set_render_draw_color(renderer, 0, 240, 255, 255)
		sdl.render_fill_rect(renderer, &sdl.Rect{ x: cx - 8, y: cy - 6, w: 6, h: 8 })
		sdl.render_fill_rect(renderer, &sdl.Rect{ x: cx + 2, y: cy - 6, w: 6, h: 8 })
	}
}

fn draw_share_and_community_modal(renderer &sdl.Renderer, game Game, mx int, my int) {
	sdl.set_render_draw_blend_mode(renderer, .blend)
	sdl.set_render_draw_color(renderer, 6, 10, 22, 230)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: 0, y: 0, w: win_w, h: win_h })

	modal_x := 80
	modal_y := 50
	modal_w := 800
	modal_h := 580

	sdl.set_render_draw_color(renderer, 14, 20, 36, 255)
	modal := sdl.Rect{ x: modal_x, y: modal_y, w: modal_w, h: modal_h }
	sdl.render_fill_rect(renderer, &modal)
	sdl.set_render_draw_color(renderer, 0, 240, 255, 255)
	sdl.render_draw_rect(renderer, &modal)

	draw_text_centered(renderer, win_w / 2, modal_y + 16, 'CYBER LEVEL SHARING & COMMUNITY PACKS', 2, Color{ r: 255, g: 215, b: 0 })
	draw_text_centered(renderer, win_w / 2, modal_y + 42, '[PRESS K / ESC TO RETURN TO CONSOLE]', 1, Color{ r: 0, g: 230, b: 255 })

	// Export Code Box
	code := game.export_cyber_code()
	draw_text(renderer, modal_x + 30, modal_y + 70, 'CURRENT LEVEL SHARING CODE (SHARE ON DISCORD / REDDIT):', 1, Color{ r: 255, g: 215, b: 0 })
	sdl.set_render_draw_color(renderer, 25, 35, 55, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: modal_x + 30, y: modal_y + 90, w: modal_w - 60, h: 36 })
	sdl.set_render_draw_color(renderer, 0, 200, 255, 255)
	sdl.render_draw_rect(renderer, &sdl.Rect{ x: modal_x + 30, y: modal_y + 90, w: modal_w - 60, h: 36 })
	draw_text(renderer, modal_x + 40, modal_y + 102, code[..math_min(code.len, 70)] + '...', 1, Color{ r: 0, g: 255, b: 180 })

	// Featured Community Challenge Packs
	draw_text(renderer, modal_x + 30, modal_y + 145, 'FEATURED COMMUNITY CHALLENGE PACKS (CLICK TO PLAY):', 1, Color{ r: 255, g: 215, b: 0 })
	for i in 0 .. game.community_levels.len {
		by := modal_y + 170 + i * 72
		lvl := game.community_levels[i]

		is_hover := mx >= modal_x + 30 && mx <= modal_x + modal_w - 30 && my >= by && my <= by + 60
		bg := if is_hover { Color{ r: 0, g: 120, b: 200 } } else { Color{ r: 22, g: 30, b: 52 } }

		sdl.set_render_draw_color(renderer, bg.r, bg.g, bg.b, 255)
		sdl.render_fill_rect(renderer, &sdl.Rect{ x: modal_x + 30, y: by, w: modal_w - 60, h: 60 })
		sdl.set_render_draw_color(renderer, 0, 200, 255, 255)
		sdl.render_draw_rect(renderer, &sdl.Rect{ x: modal_x + 30, y: by, w: modal_w - 60, h: 60 })

		draw_text(renderer, modal_x + 45, by + 12, 'PACK ${i + 1}: ${lvl.name}', 2, Color{ r: 255, g: 215, b: 0 })
		draw_text(renderer, modal_x + 45, by + 36, 'PAR TIME: 30.00s   DIFFICULTY: EXPERT', 1, Color{ r: 0, g: 230, b: 255 })
	}
}

fn draw_level_select_modal(renderer &sdl.Renderer, game Game, mx int, my int) {
	sdl.set_render_draw_blend_mode(renderer, .blend)
	sdl.set_render_draw_color(renderer, 6, 10, 22, 230)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: 0, y: 0, w: win_w, h: win_h })

	modal_x := 80
	modal_y := 45
	modal_w := 800
	modal_h := 590

	sdl.set_render_draw_color(renderer, 14, 20, 36, 255)
	modal := sdl.Rect{ x: modal_x, y: modal_y, w: modal_w, h: modal_h }
	sdl.render_fill_rect(renderer, &modal)

	sdl.set_render_draw_color(renderer, 0, 240, 255, 255)
	sdl.render_draw_rect(renderer, &modal)

	draw_text_centered(renderer, win_w / 2, modal_y + 12, 'MASTER CAMPAIGN & ARCADE WORLDS - 65 SECTORS', 2, Color{ r: 255, g: 215, b: 0 })

	// 4 Game & Bonus Worlds Selection Tabs
	tabs := [
		'LOLO 1 (1-20)',
		'LOLO 2 (21-35)',
		'LOLO 3 (36-50)',
		'ARCADE BONUS (51-65)',
	]
	tab_w := 180
	for t_idx, t_name in tabs {
		tx := modal_x + 25 + t_idx * 190
		ty := modal_y + 38
		is_active := game.level_select_tab == t_idx
		is_hover := mx >= tx && mx <= tx + tab_w && my >= ty && my <= ty + 28
		t_col := if is_active {
			Color{ r: 0, g: 140, b: 220 }
		} else if is_hover {
			Color{ r: 40, g: 60, b: 90 }
		} else {
			Color{ r: 22, g: 30, b: 50 }
		}

		sdl.set_render_draw_color(renderer, t_col.r, t_col.g, t_col.b, 255)
		sdl.render_fill_rect(renderer, &sdl.Rect{ x: tx, y: ty, w: tab_w, h: 28 })
		sdl.set_render_draw_color(renderer, 0, 220, 255, 255)
		sdl.render_draw_rect(renderer, &sdl.Rect{ x: tx, y: ty, w: tab_w, h: 28 })
		draw_text_centered(renderer, tx + tab_w / 2, ty + 6, t_name, 1, Color{ r: 255, g: 255, b: 255 })
	}

	start_idx, count := match game.level_select_tab {
		0 { 0, 20 }
		1 { 20, 15 }
		2 { 35, 15 }
		else { 50, 15 }
	}

	for i in 0 .. count {
		idx := start_idx + i
		if idx >= game.campaign_levels.len {
			break
		}
		col := i / 5
		row := i % 5
		bx := modal_x + 30 + col * 185
		by := modal_y + 78 + row * 98

		is_hover := mx >= bx && mx <= bx + 175 && my >= by && my <= by + 88
		bg_c := if is_hover { Color{ r: 0, g: 120, b: 200 } } else { Color{ r: 22, g: 30, b: 50 } }

		sdl.set_render_draw_color(renderer, bg_c.r, bg_c.g, bg_c.b, 255)
		sdl.render_fill_rect(renderer, &sdl.Rect{ x: bx, y: by, w: 175, h: 88 })

		sdl.set_render_draw_color(renderer, 0, 200, 255, 255)
		sdl.render_draw_rect(renderer, &sdl.Rect{ x: bx, y: by, w: 175, h: 88 })

		lvl := game.campaign_levels[idx]
		draw_text(renderer, bx + 8, by + 8, 'ROOM ${idx + 1}', 2, Color{ r: 255, g: 215, b: 0 })
		draw_text(renderer, bx + 8, by + 32, 'F${lvl.floor}: ${lvl.name}', 1, Color{ r: 255, g: 255, b: 255 })
		draw_text(renderer, bx + 8, by + 50, 'PASS: ${lvl.password}', 1, Color{ r: 0, g: 240, b: 255 })

		pb := game.pb_times[idx]
		if pb > 0 {
			sec := int(pb / 1000)
			ms := int((pb % 1000) / 10)
			draw_text(renderer, bx + 8, by + 68, 'PB: ${sec:02d}.${ms:02d}s', 1, Color{ r: 255, g: 200, b: 80 })
		} else {
			draw_text(renderer, bx + 8, by + 68, 'PB: --.--s', 1, Color{ r: 120, g: 140, b: 160 })
		}
	}
}

fn draw_dark_dungeon_mask(renderer &sdl.Renderer, game Game) {
	if !game.current_level.is_dark_dungeon {
		return
	}
	lx := grid_offset_x + game.lolo.x * cell_size + cell_size / 2
	ly := grid_offset_y + game.lolo.y * cell_size + cell_size / 2
	radius := 140

	sdl.set_render_draw_blend_mode(renderer, .blend)
	for r in 0 .. grid_rows {
		for c in 0 .. grid_cols {
			cx := grid_offset_x + c * cell_size + cell_size / 2
			cy := grid_offset_y + r * cell_size + cell_size / 2
			dist := int(math.sqrt(f64((cx - lx) * (cx - lx) + (cy - ly) * (cy - ly))))
			if dist > radius {
				alpha := u8(math_min(255, (dist - radius) * 3 + 120))
				sdl.set_render_draw_color(renderer, 4, 6, 14, alpha)
				sdl.render_fill_rect(renderer, &sdl.Rect{
					x: grid_offset_x + c * cell_size
					y: grid_offset_y + r * cell_size
					w: cell_size
					h: cell_size
				})
			}
		}
	}
	sdl.set_render_draw_blend_mode(renderer, .none)
}

fn draw_dialogue_modal(renderer &sdl.Renderer, dialogue string, ticks u32) {
	sdl.set_render_draw_blend_mode(renderer, .blend)
	sdl.set_render_draw_color(renderer, 6, 12, 26, 235)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: 100, y: 440, w: 760, h: 180 })

	sdl.set_render_draw_color(renderer, 0, 240, 255, 255)
	sdl.render_draw_rect(renderer, &sdl.Rect{ x: 100, y: 440, w: 760, h: 180 })

	// Animated beacon icon
	pulse := int((math.sin(f64(ticks) / 100.0) + 1.0) * 20.0)
	sdl.set_render_draw_color(renderer, 0, u8(200 + pulse), 255, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: 120, y: 460, w: 32, h: 32 })
	draw_char(renderer, 130, 468, `i`, 2, Color{ r: 255, g: 255, b: 255 })

	draw_text(renderer, 165, 466, 'CYBERNETIC HOLOGRAM BEACON TERMINAL', 2, Color{ r: 0, g: 240, b: 255 })
	draw_text(renderer, 120, 510, dialogue, 1, Color{ r: 240, g: 250, b: 255 })
	draw_text_centered(renderer, 480, 580, '[PRESS SPACE / ENTER / MOVE TO DISMISS LOG]', 1, Color{ r: 255, g: 215, b: 0 })
	sdl.set_render_draw_blend_mode(renderer, .none)
}
