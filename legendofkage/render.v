import math
import os
import sdl
import sdl.image

pub struct LegendOfKageTextureManager {
pub mut:
	sprite_texture &sdl.Texture = unsafe { nil }
}

pub fn (mut tm LegendOfKageTextureManager) init(renderer &sdl.Renderer) {
	_ = image.init(int(image.InitFlags.png))
	candidates := [
		'assets/sprites/legendofkage.png',
		'./assets/sprites/legendofkage.png',
		'../assets/sprites/legendofkage.png',
		'legendofkage/assets/sprites/legendofkage.png',
	]
	for p in candidates {
		if os.exists(p) {
			surface := image.load(p.str)
			if surface != unsafe { nil } {
				tm.sprite_texture = sdl.create_texture_from_surface(renderer, surface)
				sdl.free_surface(surface)
				if tm.sprite_texture != unsafe { nil } {
					println('Legend of Kage Texture Loaded Successfully: ' + p)
					return
				}
			}
		}
	}
}

pub fn render_legend_of_kage_game(renderer &sdl.Renderer, mut g LegendOfKageGame, tex &sdl.Texture) {
	// 1. Stage Parallax Background
	render_kage_background(renderer, mut g)

	ox := int(g.shake_x) - int(g.camera_x)
	oy := int(g.shake_y)

	// 2. Draw Tree Trunks / Castle Architecture
	render_scenery_structures(renderer, mut g, ox, oy)

	// 3. Draw Tree Branches / Battlements
	render_branches(renderer, mut g, ox, oy)

	// 4. Draw Magic Scrolls
	render_scrolls(renderer, mut g, ox, oy, tex)

	// 5. Draw Projectiles (Shurikens & Fireballs)
	render_projectiles(renderer, mut g, ox, oy, tex)

	// 6. Draw Enemies & Bosses
	render_enemies(renderer, mut g, ox, oy, tex)

	// 7. Draw Kage & Shadow Clones
	render_kage_player(renderer, mut g, ox, oy, tex)

	// 8. Draw Particles & Popups
	render_particles(renderer, mut g, ox, oy)
	render_score_popups(renderer, mut g, ox, oy)

	// 9. Ninjutsu Screen Flashes
	if g.lightning_flash > 0.0 {
		render_lightning_screen_flash(renderer, g.lightning_flash)
	}

	// 10. Gameplay Banners & HUD
	render_hud(renderer, mut g)

	// 11. CRT Filter
	if g.crt_filter {
		render_crt_overlay(renderer)
	}

	// 12. State Overlays
	if g.state == .title {
		render_title_screen(renderer)
	} else if g.state == .paused {
		render_paused_screen(renderer)
	} else if g.state == .stage_clear {
		render_stage_clear_screen(renderer)
	} else if g.state == .game_over {
		render_game_over_screen(renderer, mut g)
	}
}

fn render_kage_background(renderer &sdl.Renderer, mut g LegendOfKageGame) {
	ticks := f64(sdl.get_ticks())

	match g.stage {
		.forest {
			// Midnight dark navy forest sky with glowing full moon
			sdl.set_render_draw_color(renderer, 8, 12, 24, 255)
			sdl.render_clear(renderer)

			// Twinkling Stars in Cosmos
			sdl.set_render_draw_color(renderer, 240, 240, 255, 200)
			for s := 0; s < 25; s++ {
				sx := (s * 137) % 800
				sy := (s * 89) % 220
				sdl.render_draw_point(renderer, sx, sy)
			}

			// Glowing Moon & Golden Halo
			sdl.set_render_draw_color(renderer, 90, 80, 50, 80)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: 610, y: 60, w: 68, h: 68 })
			sdl.set_render_draw_color(renderer, 255, 245, 190, 255)
			moon := sdl.Rect{ x: 620, y: 70, w: 48, h: 48 }
			sdl.render_fill_rect(renderer, &moon)
			sdl.set_render_draw_color(renderer, 255, 255, 230, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: 624, y: 74, w: 40, h: 40 })

			// Distant cedar tree silhouettes
			for i := 0; i < 14; i++ {
				tx := i * 70 - int(g.camera_x * 0.2) % 70
				sdl.set_render_draw_color(renderer, 16, 24, 42, 255)
				sdl.render_fill_rect(renderer, &sdl.Rect{ x: tx, y: 160, w: 40, h: 400 })
			}

			// Drifting Golden/Red Autumn Leaves
			sdl.set_render_draw_color(renderer, 230, 140, 40, 230)
			for l := 0; l < 16; l++ {
				seed := f64(l * 157)
				lx := int(math.fmod(ticks * 0.05 + seed * 60.0, 800.0))
				ly := int(math.fmod(ticks * 0.04 + seed * 90.0, 560.0))
				sway := int(math.sin(ticks * 0.003 + seed) * 10.0)
				sdl.render_fill_rect(renderer, &sdl.Rect{ x: lx + sway, y: ly, w: 5, h: 4 })
			}
		}
		.waterway {
			// Misty river twilight sky
			sdl.set_render_draw_color(renderer, 15, 25, 40, 255)
			sdl.render_clear(renderer)

			// Flowing Water Moat with Ripples
			sdl.set_render_draw_color(renderer, 20, 60, 95, 255)
			water := sdl.Rect{ x: 0, y: 510, w: 800, h: 90 }
			sdl.render_fill_rect(renderer, &water)
			sdl.set_render_draw_color(renderer, 40, 110, 160, 255)
			for w := 0; w < 800; w += 60 {
				wx := (w + int(ticks * 0.08)) % 800
				sdl.render_draw_line(renderer, wx, 530, wx + 30, 530)
			}
		}
		.castle_wall {
			// Crimson fortress twilight
			sdl.set_render_draw_color(renderer, 35, 15, 25, 255)
			sdl.render_clear(renderer)

			// Giant stone wall backdrop
			sdl.set_render_draw_color(renderer, 50, 45, 55, 255)
			wall := sdl.Rect{ x: 0, y: 0, w: 800, h: 600 }
			sdl.render_fill_rect(renderer, &wall)
		}
		.castle_keep {
			// Interior Gold & Vermilion Palace
			sdl.set_render_draw_color(renderer, 30, 12, 16, 255)
			sdl.render_clear(renderer)

			// Gold screen tapestry
			sdl.set_render_draw_color(renderer, 140, 110, 30, 255)
			tapestry := sdl.Rect{ x: 100, y: 120, w: 600, h: 260 }
			sdl.render_fill_rect(renderer, &tapestry)
		}
	}
}

fn render_scenery_structures(renderer &sdl.Renderer, mut g LegendOfKageGame, ox int, oy int) {
	if g.stage == .forest {
		// Massive ancient cedar tree trunks
		for i := 0; i < 20; i++ {
			tx := i * 320 + ox
			if tx < -100 || tx > 900 {
				continue
			}
			// Trunk
			sdl.set_render_draw_color(renderer, 65, 38, 20, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: tx, y: oy, w: 44, h: 560 })

			// Bark texture lines
			sdl.set_render_draw_color(renderer, 45, 24, 12, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: tx + 8, y: oy, w: 6, h: 560 })
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: tx + 26, y: oy, w: 8, h: 560 })
		}
	}

	// Ground grass & earth
	sdl.set_render_draw_color(renderer, 28, 70, 35, 255)
	ground := sdl.Rect{ x: 0, y: oy + 528, w: 800, h: 72 }
	sdl.render_fill_rect(renderer, &ground)
}

fn render_branches(renderer &sdl.Renderer, mut g LegendOfKageGame, ox int, oy int) {
	for b in g.branches {
		bx := int(b.x) + ox
		by := int(b.y) + oy
		bw := int(b.w)
		bh := int(b.h)

		if bx + bw < -50 || bx > 850 {
			continue
		}

		if g.stage == .forest {
			// Tree Branch Wood
			sdl.set_render_draw_color(renderer, 95, 55, 25, 255)
			branch := sdl.Rect{ x: bx, y: by, w: bw, h: bh }
			sdl.render_fill_rect(renderer, &branch)

			// Foliage cluster on top
			sdl.set_render_draw_color(renderer, 35, 110, 45, 255)
			leaves := sdl.Rect{ x: bx - 4, y: by - 6, w: bw + 8, h: 8 }
			sdl.render_fill_rect(renderer, &leaves)
		} else {
			// Stone Fortress Battlement
			sdl.set_render_draw_color(renderer, 110, 105, 120, 255)
			battlement := sdl.Rect{ x: bx, y: by, w: bw, h: bh }
			sdl.render_fill_rect(renderer, &battlement)

			sdl.set_render_draw_color(renderer, 160, 155, 175, 255)
			top_rim := sdl.Rect{ x: bx, y: by, w: bw, h: 4 }
			sdl.render_fill_rect(renderer, &top_rim)
		}
	}
}

fn render_scrolls(renderer &sdl.Renderer, mut g LegendOfKageGame, ox int, oy int, tex &sdl.Texture) {
	for sc in g.scrolls {
		if !sc.active {
			continue
		}
		sx := int(sc.x) + ox
		sy := int(sc.y) + oy

		if tex != unsafe { nil } {
			col_x := match sc.scroll_type {
				.lightning { 0 }
				.fire_shield { 64 }
				.shadow_clones { 128 }
				.golden_speed { 192 }
				else { 0 }
			}
			src := sdl.Rect{ x: col_x, y: 128, w: 64, h: 64 }
			dst := sdl.Rect{ x: sx - 4, y: sy - 4, w: 32, h: 32 }
			sdl.render_copy(renderer, tex, &src, &dst)
			continue
		}

		// Magic Glowing Scroll
		sdl.set_render_draw_color(renderer, 240, 220, 180, 255)
		parchment := sdl.Rect{ x: sx, y: sy, w: 26, h: 22 }
		sdl.render_fill_rect(renderer, &parchment)

		// Gold Rods
		sdl.set_render_draw_color(renderer, 240, 190, 40, 255)
		sdl.render_fill_rect(renderer, &sdl.Rect{ x: sx - 3, y: sy + 2, w: 32, h: 4 })
		sdl.render_fill_rect(renderer, &sdl.Rect{ x: sx - 3, y: sy + 16, w: 32, h: 4 })

		// Ninjutsu Kanji Emblem
		sdl.set_render_draw_color(renderer, 220, 30, 30, 255)
		sdl.render_fill_rect(renderer, &sdl.Rect{ x: sx + 10, y: sy + 8, w: 6, h: 6 })
	}
}

fn render_projectiles(renderer &sdl.Renderer, mut g LegendOfKageGame, ox int, oy int, tex &sdl.Texture) {
	for p in g.projectiles {
		if !p.active {
			continue
		}
		px := int(p.x) + ox
		py := int(p.y) + oy

		if tex != unsafe { nil } {
			col_x := if p.is_fire { 448 } else { 384 }
			src := sdl.Rect{ x: col_x, y: 128, w: 64, h: 64 }
			dst := sdl.Rect{ x: px - 8, y: py - 8, w: 16, h: 16 }
			sdl.render_copy(renderer, tex, &src, &dst)
			continue
		}

		if p.is_fire {
			// Monk Fireball
			sdl.set_render_draw_color(renderer, 255, 90, 20, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: px - 4, y: py - 4, w: 18, h: 18 })
			sdl.set_render_draw_color(renderer, 255, 230, 50, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: px, y: py, w: 10, h: 10 })
		} else {
			// 4-Point Steel Shuriken Throwing Star
			sh_color := if p.is_player { Color{ r: 245, g: 245, b: 255, a: 255 } } else { Color{ r: 190, g: 190, b: 205, a: 255 } }
			sdl.set_render_draw_color(renderer, sh_color.r, sh_color.g, sh_color.b, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: px - 4, y: py - 4, w: 8, h: 8 })
			// Blades
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: px - 6, y: py - 2, w: 12, h: 4 })
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: px - 2, y: py - 6, w: 4, h: 12 })
		}
	}
}

fn render_enemies(renderer &sdl.Renderer, mut g LegendOfKageGame, ox int, oy int, tex &sdl.Texture) {
	for e in g.enemies {
		if !e.active {
			continue
		}
		ex := int(e.x) + ox
		ey := int(e.y) + oy
		ew := int(e.width)
		eh := int(e.height)

		if tex != unsafe { nil } {
			col_x := match e.enemy_type {
				.blue_ninja { 0 }
				.red_ninja { 128 }
				.water_ninja { 0 }
				.fire_monk { 256 }
				.boss_warlord { 320 }
			}
			src := sdl.Rect{ x: col_x, y: 64, w: 64, h: 64 }
			dst := sdl.Rect{ x: ex - 4, y: ey - 8, w: ew + 8, h: eh + 8 }
			flip := if e.facing_right { sdl.RendererFlip.none } else { sdl.RendererFlip.horizontal }
			sdl.render_copy_ex(renderer, tex, &src, &dst, 0.0, unsafe { nil }, flip)
			continue
		}

		match e.enemy_type {
			.red_ninja {
				render_ninja_sprite(renderer, ex, ey, ew, eh, e.facing_right, Color{ r: 215, g: 35, b: 35, a: 255 })
			}
			.blue_ninja {
				render_ninja_sprite(renderer, ex, ey, ew, eh, e.facing_right, Color{ r: 35, g: 95, b: 215, a: 255 })
			}
			.water_ninja {
				render_ninja_sprite(renderer, ex, ey, ew, eh, e.facing_right, Color{ r: 30, g: 160, b: 170, a: 255 })
			}
			.fire_monk {
				render_monk_sprite(renderer, ex, ey, ew, eh, e.facing_right)
			}
			.boss_warlord {
				render_boss_warlord(renderer, ex, ey, ew, eh, e.facing_right)
			}
		}
	}
}

fn render_ninja_sprite(renderer &sdl.Renderer, x int, y int, w int, h int, facing_right bool, color Color) {
	// Shinobi Shozoku Robe
	sdl.set_render_draw_color(renderer, color.r, color.g, color.b, 255)
	body := sdl.Rect{ x: x + 4, y: y + 14, w: w - 8, h: h - 14 }
	sdl.render_fill_rect(renderer, &body)

	// Hood & Mask
	hood := sdl.Rect{ x: x + 5, y: y + 2, w: w - 10, h: 14 }
	sdl.render_fill_rect(renderer, &hood)

	// Eye Slit
	sdl.set_render_draw_color(renderer, 255, 200, 150, 255)
	eye_x := if facing_right { x + w - 10 } else { x + 6 }
	slit := sdl.Rect{ x: eye_x, y: y + 6, w: 4, h: 3 }
	sdl.render_fill_rect(renderer, &slit)

	// Drawn Katana
	sdl.set_render_draw_color(renderer, 240, 240, 245, 255)
	k_x := if facing_right { x + w } else { x - 12 }
	blade := sdl.Rect{ x: k_x, y: y + 16, w: 12, h: 3 }
	sdl.render_fill_rect(renderer, &blade)
}

fn render_monk_sprite(renderer &sdl.Renderer, x int, y int, w int, h int, facing_right bool) {
	// Yellow Monk Kasaya
	sdl.set_render_draw_color(renderer, 235, 185, 30, 255)
	robe := sdl.Rect{ x: x + 2, y: y + 12, w: w - 4, h: h - 12 }
	sdl.render_fill_rect(renderer, &robe)

	// Bald Head
	sdl.set_render_draw_color(renderer, 245, 190, 140, 255)
	head := sdl.Rect{ x: x + 6, y: y + 2, w: w - 12, h: 12 }
	sdl.render_fill_rect(renderer, &head)

	// Fire Breath Nozzle
	sdl.set_render_draw_color(renderer, 255, 80, 20, 255)
	n_x := if facing_right { x + w - 2 } else { x - 4 }
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: n_x, y: y + 10, w: 6, h: 6 })
}

fn render_boss_warlord(renderer &sdl.Renderer, x int, y int, w int, h int, facing_right bool) {
	// Samurai Armor & Twin Katana Warlord
	sdl.set_render_draw_color(renderer, 160, 20, 20, 255)
	armor := sdl.Rect{ x: x + 2, y: y + 10, w: w - 4, h: h - 10 }
	sdl.render_fill_rect(renderer, &armor)

	// Gold Crest Helmet (Kabuto)
	sdl.set_render_draw_color(renderer, 240, 210, 40, 255)
	crest := sdl.Rect{ x: x + 4, y: y - 4, w: w - 8, h: 8 }
	sdl.render_fill_rect(renderer, &crest)

	// Head
	sdl.set_render_draw_color(renderer, 240, 180, 130, 255)
	head := sdl.Rect{ x: x + 6, y: y + 2, w: w - 12, h: 12 }
	sdl.render_fill_rect(renderer, &head)

	// Twin Long Katanas
	sdl.set_render_draw_color(renderer, 255, 255, 255, 255)
	k1_x := if facing_right { x + w } else { x - 20 }
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: k1_x, y: y + 12, w: 20, h: 3 })
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: k1_x, y: y + 24, w: 20, h: 3 })
}

fn render_kage_player(renderer &sdl.Renderer, mut g LegendOfKageGame, ox int, oy int, tex &sdl.Texture) {
	p := g.player
	px := int(p.x) + ox
	py := int(p.y) + oy
	pw := int(p.width)
	ph := int(p.height)

	if p.invuln_timer > 0.0 && (int(p.invuln_timer * 18.0) % 2 == 0) {
		return
	}

	if tex != unsafe { nil } {
		// Shadow Clones
		if p.active_jutsu == .shadow_clones {
			c_src := sdl.Rect{ x: 384, y: 0, w: 64, h: 64 }
			c_flip := if p.facing_right { sdl.RendererFlip.none } else { sdl.RendererFlip.horizontal }
			c1_dst := sdl.Rect{ x: px - (if p.facing_right { 26 } else { -26 }), y: py - 4, w: pw + 8, h: ph + 8 }
			c2_dst := sdl.Rect{ x: px - (if p.facing_right { 48 } else { -48 }), y: py - 8, w: pw + 8, h: ph + 8 }
			sdl.render_copy_ex(renderer, tex, &c_src, &c1_dst, 0.0, unsafe { nil }, c_flip)
			sdl.render_copy_ex(renderer, tex, &c_src, &c2_dst, 0.0, unsafe { nil }, c_flip)
		}

		col_x := if p.active_jutsu == .golden_speed {
			320
		} else if p.sword_timer > 0.0 {
			128
		} else if p.is_jumping {
			64
		} else {
			0
		}
		src := sdl.Rect{ x: col_x, y: 0, w: 64, h: 64 }
		dst := sdl.Rect{ x: px - 6, y: py - 6, w: pw + 12, h: ph + 12 }
		flip := if p.facing_right { sdl.RendererFlip.none } else { sdl.RendererFlip.horizontal }
		sdl.render_copy_ex(renderer, tex, &src, &dst, 0.0, unsafe { nil }, flip)

		// Fire Shield Rings
		if p.active_jutsu == .fire_shield {
			for f_idx in 0 .. 4 {
				angle := f64(sdl.get_ticks()) / 120.0 + f64(f_idx) * (math.pi / 2.0)
				fx := px + pw / 2 + int(math.cos(angle) * 48.0)
				fy := py + ph / 2 + int(math.sin(angle) * 48.0)
				f_src := sdl.Rect{ x: 448, y: 128, w: 64, h: 64 }
				f_dst := sdl.Rect{ x: fx - 10, y: fy - 10, w: 20, h: 20 }
				sdl.render_copy(renderer, tex, &f_src, &f_dst)
			}
		}
		return
	}

	// Shadow Clones (Bunshin)
	if p.active_jutsu == .shadow_clones {
		clone_c := Color{ r: 255, g: 230, b: 80, a: 150 }
		render_kage_single(renderer, px - (if p.facing_right { 30 } else { -30 }), py - 8, pw, ph, p.facing_right, p.is_jumping, p.sword_timer > 0.0, clone_c)
		render_kage_single(renderer, px - (if p.facing_right { 54 } else { -54 }), py - 16, pw, ph, p.facing_right, p.is_jumping, p.sword_timer > 0.0, clone_c)
	}

	// Player Garb Color (Red shinobi by default, or Gold when speed boost active)
	garb_c := if p.active_jutsu == .golden_speed {
		Color{ r: 255, g: 215, b: 20, a: 255 }
	} else {
		Color{ r: 235, g: 45, b: 45, a: 255 }
	}

	render_kage_single(renderer, px, py, pw, ph, p.facing_right, p.is_jumping, p.sword_timer > 0.0, garb_c)

	// Fire Shield Rings
	if p.active_jutsu == .fire_shield {
		for f_idx in 0 .. 4 {
			angle := f64(sdl.get_ticks()) / 120.0 + f64(f_idx) * (math.pi / 2.0)
			fx := px + pw / 2 + int(math.cos(angle) * 48.0)
			fy := py + ph / 2 + int(math.sin(angle) * 48.0)
			sdl.set_render_draw_color(renderer, 255, 110, 20, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: fx - 6, y: fy - 6, w: 12, h: 12 })
			sdl.set_render_draw_color(renderer, 255, 230, 40, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: fx - 3, y: fy - 3, w: 6, h: 6 })
		}
	}
}

fn render_kage_single(renderer &sdl.Renderer, x int, y int, w int, h int, facing_right bool, is_jumping bool, is_slashing bool, color Color) {
	// Shinobi Robe
	sdl.set_render_draw_color(renderer, color.r, color.g, color.b, color.a)
	body := sdl.Rect{ x: x + 4, y: y + 14, w: w - 8, h: h - 14 }
	sdl.render_fill_rect(renderer, &body)

	// Ninja Head & Mask
	head := sdl.Rect{ x: x + 5, y: y + 2, w: w - 10, h: 14 }
	sdl.render_fill_rect(renderer, &head)

	// White Eye Slit & Forehead Protector
	sdl.set_render_draw_color(renderer, 255, 255, 255, 255)
	eye_x := if facing_right { x + w - 10 } else { x + 6 }
	slit := sdl.Rect{ x: eye_x, y: y + 6, w: 4, h: 3 }
	sdl.render_fill_rect(renderer, &slit)

	// Flowing Shinobi Scarf Tails
	sdl.set_render_draw_color(renderer, 255, 240, 240, 255)
	scarf_x := if facing_right { x - 12 } else { x + w + 2 }
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: scarf_x, y: y + 12, w: 12, h: 4 })

	// Sword Slash Arc & Kodachi
	if is_slashing {
		sdl.set_render_draw_color(renderer, 255, 255, 255, 255)
		sword_x := if facing_right { x + w - 2 } else { x - 26 }
		// Flashing metallic blade arc
		sdl.render_fill_rect(renderer, &sdl.Rect{ x: sword_x, y: y + 6, w: 28, h: 20 })
		sdl.set_render_draw_color(renderer, 80, 190, 255, 255)
		sdl.render_fill_rect(renderer, &sdl.Rect{ x: sword_x + 4, y: y + 10, w: 20, h: 12 })
	} else {
		// Sheathed Kodachi on Back
		sdl.set_render_draw_color(renderer, 200, 200, 210, 255)
		s_x := if facing_right { x - 4 } else { x + w }
		sdl.render_fill_rect(renderer, &sdl.Rect{ x: s_x, y: y + 10, w: 4, h: 18 })
	}

	// Flying Jump Pose legs
	if is_jumping {
		sdl.set_render_draw_color(renderer, 40, 40, 40, 255)
		sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + 2, y: y + h - 8, w: 8, h: 6 })
		sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + w - 10, y: y + h - 12, w: 8, h: 6 })
	}
}

fn render_particles(renderer &sdl.Renderer, mut g LegendOfKageGame, ox int, oy int) {
	for pt in g.particles {
		if !pt.active {
			continue
		}
		sdl.set_render_draw_color(renderer, pt.color.r, pt.color.g, pt.color.b, 255)
		rect := sdl.Rect{
			x: int(pt.x) + ox
			y: int(pt.y) + oy
			w: int(pt.size)
			h: int(pt.size)
		}
		sdl.render_fill_rect(renderer, &rect)
	}
}

fn render_score_popups(renderer &sdl.Renderer, mut g LegendOfKageGame, ox int, oy int) {
	for sp in g.score_popups {
		if !sp.active {
			continue
		}
		draw_text_centered_shadow(renderer, int(sp.x) + ox, int(sp.y) + oy, sp.text, 2,
			sp.color, Color{ r: 0, g: 0, b: 0, a: 255 })
	}
}

fn render_lightning_screen_flash(renderer &sdl.Renderer, flash f32) {
	alpha := u8(math.min(255.0, f64(flash * 510.0)))
	sdl.set_render_draw_blend_mode(renderer, .blend)
	sdl.set_render_draw_color(renderer, 230, 245, 255, alpha)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: 0, y: 0, w: 800, h: 600 })
}

fn render_hud(renderer &sdl.Renderer, mut g LegendOfKageGame) {
	// Score
	draw_text_shadow(renderer, 30, 16, '1P  ${g.player.score:06d}', 2,
		Color{ r: 255, g: 255, b: 255, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })

	draw_text_centered_shadow(renderer, 400, 16, 'HIGH  ${g.high_score:06d}', 2,
		Color{ r: 255, g: 215, b: 40, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })

	stage_name := match g.stage {
		.forest { 'FOREST' }
		.waterway { 'MOAT' }
		.castle_wall { 'WALL' }
		.castle_keep { 'BOSS' }
	}

	draw_text_shadow(renderer, 650, 16, stage_name, 2,
		Color{ r: 80, g: 220, b: 255, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })

	// Target progress
	remaining := if g.stage_target > g.enemies_slain { g.stage_target - g.enemies_slain } else { 0 }
	draw_text_shadow(renderer, 650, 42, 'LEFT: ${remaining:02d}', 2,
		Color{ r: 255, g: 180, b: 40, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })

	// Lives
	draw_text(renderer, 30, 568, 'LIVES:', 2, Color{ r: 240, g: 240, b: 240, a: 255 })
	for i in 0 .. g.player.lives {
		sdl.set_render_draw_color(renderer, 240, 50, 50, 255)
		sdl.render_fill_rect(renderer, &sdl.Rect{ x: 130 + i * 18, y: 566, w: 12, h: 14 })
	}
}

fn render_crt_overlay(renderer &sdl.Renderer) {
	sdl.set_render_draw_blend_mode(renderer, .blend)
	sdl.set_render_draw_color(renderer, 0, 0, 0, 24)
	for y := 0; y < 600; y += 3 {
		line := sdl.Rect{ x: 0, y: y, w: 800, h: 1 }
		sdl.render_fill_rect(renderer, &line)
	}
}

fn render_title_screen(renderer &sdl.Renderer) {
	sdl.set_render_draw_blend_mode(renderer, .blend)
	sdl.set_render_draw_color(renderer, 8, 12, 22, 225)
	scrim := sdl.Rect{ x: 0, y: 0, w: 800, h: 600 }
	sdl.render_fill_rect(renderer, &scrim)

	// Arcade Marquee Title
	draw_text_centered_shadow(renderer, 400, 75, 'THE LEGEND OF KAGE', 4,
		Color{ r: 255, g: 45, b: 45, a: 255 }, Color{ r: 245, g: 220, b: 30, a: 255 })

	draw_text_centered_shadow(renderer, 400, 135, '1985 TAITO ARCADE / NES CLASSIC', 2,
		Color{ r: 60, g: 210, b: 255, a: 255 }, Color{ r: 10, g: 20, b: 40, a: 255 })

	draw_text_centered_shadow(renderer, 400, 215, 'RESCUE PRINCESS KIRI ACROSS 4 DEADLY SEASONS!', 1,
		Color{ r: 240, g: 240, b: 240, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })

	draw_text_centered_shadow(renderer, 400, 265, 'PRESS SPACE OR ENTER TO START', 2,
		Color{ r: 255, g: 235, b: 40, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })

	// Controls Summary
	draw_text_centered_shadow(renderer, 400, 335, 'CONTROLS & COMBAT', 2,
		Color{ r: 255, g: 180, b: 40, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 370, 'A / D (LEFT / RIGHT) : MOVE & AERIAL STEERING', 1,
		Color{ r: 230, g: 230, b: 230, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 395, 'SPACE / W : SUPER NINJA HIGH LEAP (ASCEND INTO TREES!)', 1,
		Color{ r: 230, g: 230, b: 230, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 420, 'J / Z : KATANA SLASH (SLICES ENEMIES & DEFLECTS WEAPONS!)', 1,
		Color{ r: 110, g: 255, b: 130, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 445, 'K / X : THROW SHURIKEN (8-WAY THROWING STARS)', 1,
		Color{ r: 110, g: 255, b: 130, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 470, 'COLLECT MAGIC SCROLLS FOR LIGHTNING, CLONES, \u0026 FIRE JUTSU!', 1,
		Color{ r: 100, g: 220, b: 255, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 495, '[P] PAUSE  [M] MUTE  [C] CRT SCANLINES  [R] RESTART  [F11] Fullscreen', 1,
		Color{ r: 255, g: 215, b: 110, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })

	draw_text_centered_shadow(renderer, 400, 560, '(C) 1985 TAITO CORP. / NINTENDO', 1,
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

fn render_stage_clear_screen(renderer &sdl.Renderer) {
	sdl.set_render_draw_blend_mode(renderer, .blend)
	sdl.set_render_draw_color(renderer, 0, 0, 0, 180)
	scrim := sdl.Rect{ x: 0, y: 0, w: 800, h: 600 }
	sdl.render_fill_rect(renderer, &scrim)

	draw_text_centered_shadow(renderer, 400, 230, 'STAGE CLEAR!', 4,
		Color{ r: 80, g: 255, b: 100, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 290, 'BONUS: +2000 PTS', 2,
		Color{ r: 255, g: 230, b: 60, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 345, 'PRESS SPACE FOR NEXT STAGE', 2,
		Color{ r: 255, g: 255, b: 255, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
}

fn render_game_over_screen(renderer &sdl.Renderer, mut g LegendOfKageGame) {
	sdl.set_render_draw_blend_mode(renderer, .blend)
	sdl.set_render_draw_color(renderer, 0, 0, 0, 210)
	scrim := sdl.Rect{ x: 0, y: 0, w: 800, h: 600 }
	sdl.render_fill_rect(renderer, &scrim)

	draw_text_centered_shadow(renderer, 400, 230, 'GAME OVER', 5,
		Color{ r: 255, g: 40, b: 40, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 300, 'FINAL SCORE: ${g.player.score}', 2,
		Color{ r: 255, g: 255, b: 255, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 360, 'PRESS SPACE TO RETRY', 2,
		Color{ r: 255, g: 230, b: 40, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
}
