import os
import sdl
import sdl.image

pub struct MissileCommandTextureManager {
pub mut:
	sprite_texture &sdl.Texture = unsafe { nil }
}

pub fn (mut tm MissileCommandTextureManager) init(renderer &sdl.Renderer) {
	_ = image.init(int(image.InitFlags.png))
	candidates := [
		'assets/sprites/missilecommand.png',
		'./assets/sprites/missilecommand.png',
		'../assets/sprites/missilecommand.png',
		'missilecommand/assets/sprites/missilecommand.png',
	]
	for p in candidates {
		if os.exists(p) {
			surface := image.load(p.str)
			if surface != unsafe { nil } {
				tm.sprite_texture = sdl.create_texture_from_surface(renderer, surface)
				sdl.free_surface(surface)
				if tm.sprite_texture != unsafe { nil } {
					println('Missile Command Texture Loaded Successfully: ' + p)
					return
				}
			}
		}
	}
}

fn render_missilecommand_game(renderer &sdl.Renderer, mut g MissileCommandGame, tex &sdl.Texture) {
	// Black space environment
	sdl.set_render_draw_color(renderer, 5, 5, 12, 255)
	sdl.render_clear(renderer)

	// 1. 16-Bit Ground Terrain Baseline & Camo Silos
	sdl.set_render_draw_color(renderer, 180, 140, 30, 255)
	ground := sdl.Rect{ x: 0, y: 550, w: 800, h: 50 }
	sdl.render_fill_rect(renderer, &ground)
	sdl.set_render_draw_color(renderer, 220, 185, 50, 255)
	sdl.render_draw_line(renderer, 0, 550, 799, 550)

	// Silo Batteries with Radar Dishes
	for s in g.silos {
		if tex != unsafe { nil } {
			src := if s.ammo > 0 {
				sdl.Rect{x: 0, y: 0, w: 64, h: 64}
			} else {
				sdl.Rect{x: 192, y: 0, w: 64, h: 64}
			}
			dst := sdl.Rect{x: int(s.x) - 24, y: 514, w: 48, h: 48}
			sdl.render_copy(renderer, tex, &src, &dst)
			if s.ammo > 0 {
				draw_text(renderer, int(s.x) - 10, 500, '${s.ammo}', 1, Color{ r: 255, g: 255, b: 255, a: 255 })
			}
			continue
		}

		if s.ammo > 0 {
			// Reinforced Silo Bunker
			sdl.set_render_draw_color(renderer, 45, 75, 115, 255)
			silo_box := sdl.Rect{ x: int(s.x) - 22, y: 524, w: 44, h: 26 }
			sdl.render_fill_rect(renderer, &silo_box)

			// Bevel highlight & Radar Dish
			sdl.set_render_draw_color(renderer, 100, 180, 255, 255)
			sdl.render_draw_line(renderer, int(s.x) - 22, 524, int(s.x) + 21, 524)
			sdl.render_draw_line(renderer, int(s.x) - 6, 520, int(s.x) + 6, 520)
			sdl.render_draw_line(renderer, int(s.x), 520, int(s.x), 524)

			// Ammo counter
			draw_text(renderer, int(s.x) - 10, 502, '${s.ammo}', 1, Color{ r: 255, g: 255, b: 255, a: 255 })
		}
	}

	// 2. 16-Bit Lit Skyscraper Cities
	for i, c in g.cities {
		if tex != unsafe { nil } {
			src := if c.active {
				sdl.Rect{x: (i % 3) * 64, y: 64, w: 64, h: 64}
			} else {
				sdl.Rect{x: 192, y: 64, w: 64, h: 64}
			}
			dst := sdl.Rect{x: int(c.x) - 24, y: 506, w: 48, h: 48}
			sdl.render_copy(renderer, tex, &src, &dst)
			continue
		}

		if c.active {
			// Skyscraper 1
			sdl.set_render_draw_color(renderer, 30, 60, 100, 255)
			b1 := sdl.Rect{ x: int(c.x) - 18, y: 518, w: 12, h: 32 }
			sdl.render_fill_rect(renderer, &b1)
			sdl.set_render_draw_color(renderer, 255, 235, 120, 255)
			sdl.render_draw_point(renderer, int(c.x) - 14, 524)
			sdl.render_draw_point(renderer, int(c.x) - 10, 524)
			sdl.render_draw_point(renderer, int(c.x) - 14, 532)
			sdl.render_draw_point(renderer, int(c.x) - 10, 532)

			// Skyscraper 2 (Spire)
			sdl.set_render_draw_color(renderer, 40, 80, 130, 255)
			b2 := sdl.Rect{ x: int(c.x) - 4, y: 506, w: 14, h: 44 }
			sdl.render_fill_rect(renderer, &b2)
			sdl.set_render_draw_color(renderer, 255, 235, 120, 255)
			sdl.render_draw_point(renderer, int(c.x), 514)
			sdl.render_draw_point(renderer, int(c.x) + 4, 514)
			sdl.render_draw_point(renderer, int(c.x), 524)
			sdl.render_draw_point(renderer, int(c.x) + 4, 524)

			// Skyscraper 3
			sdl.set_render_draw_color(renderer, 30, 60, 100, 255)
			b3 := sdl.Rect{ x: int(c.x) + 12, y: 524, w: 10, h: 26 }
			sdl.render_fill_rect(renderer, &b3)
			sdl.set_render_draw_color(renderer, 255, 235, 120, 255)
			sdl.render_draw_point(renderer, int(c.x) + 15, 530)
		} else {
			// Ruined city rubble
			sdl.set_render_draw_color(renderer, 80, 75, 70, 255)
			debris := sdl.Rect{ x: int(c.x) - 18, y: 544, w: 38, h: 6 }
			sdl.render_fill_rect(renderer, &debris)
		}
	}

	// 3. ICBM Trajectories (Red Glow Lines)
	for m in g.icbms {
		if !m.active { continue }
		sdl.set_render_draw_color(renderer, 255, 45, 45, 255)
		sdl.render_draw_line(renderer, int(m.start_x), int(m.start_y), int(m.x), int(m.y))
	}

	// 4. Interceptor Trails (Cyan Lines + Target X)
	for m in g.interceptors {
		if !m.active { continue }
		sdl.set_render_draw_color(renderer, 0, 220, 255, 255)
		sdl.render_draw_line(renderer, int(m.start_x), int(m.start_y), int(m.x), int(m.y))

		// Target X indicator
		tx := int(m.target_x)
		ty := int(m.target_y)
		sdl.set_render_draw_color(renderer, 255, 255, 0, 255)
		sdl.render_draw_line(renderer, tx - 4, ty - 4, tx + 4, ty + 4)
		sdl.render_draw_line(renderer, tx - 4, ty + 4, tx + 4, ty - 4)
	}

	// 5. 16-Bit Expanding Fireball Blast Shockwaves
	for b in g.blasts {
		if !b.active { continue }
		cx := int(b.x)
		cy := int(b.y)
		r := int(b.radius)

		if tex != unsafe { nil } && r > 4 {
			stage := int(b.timer * 6.0) % 4
			src := sdl.Rect{x: stage * 64, y: 128, w: 64, h: 64}
			dst := sdl.Rect{x: cx - r, y: cy - r, w: r * 2, h: r * 2}
			sdl.render_copy(renderer, tex, &src, &dst)
			continue
		}

		// Outer fiery orange corona
		sdl.set_render_draw_color(renderer, 245, 110, 25, 255)
		outer := sdl.Rect{ x: cx - r, y: cy - r, w: r * 2, h: r * 2 }
		sdl.render_fill_rect(renderer, &outer)

		// Middle yellow heat wave
		if r > 4 {
			sdl.set_render_draw_color(renderer, 255, 215, 40, 255)
			mid := sdl.Rect{ x: cx - r * 2 / 3, y: cy - r * 2 / 3, w: r * 4 / 3, h: r * 4 / 3 }
			sdl.render_fill_rect(renderer, &mid)
		}

		// Inner white incandescent core
		if r > 8 {
			sdl.set_render_draw_color(renderer, 255, 255, 255, 255)
			inner := sdl.Rect{ x: cx - r / 3, y: cy - r / 3, w: r * 2 / 3, h: r * 2 / 3 }
			sdl.render_fill_rect(renderer, &inner)
		}
	}

	// 6. Crosshair Cursor
	if g.state == .playing || g.state == .paused {
		cx := int(g.crosshair_x)
		cy := int(g.crosshair_y)
		sdl.set_render_draw_color(renderer, 0, 255, 100, 255)
		sdl.render_draw_line(renderer, cx - 10, cy, cx + 10, cy)
		sdl.render_draw_line(renderer, cx, cy - 10, cx, cy + 10)
	}

	// 7. HUD
	draw_text(renderer, 20, 15, "DEFENSE SCORE: ${g.score}", 2, Color{ r: 255, g: 255, b: 255, a: 255 })
	draw_text(renderer, 350, 15, "HIGH: ${g.high_score}", 2, Color{ r: 255, g: 215, b: 0, a: 255 })
	draw_text(renderer, 650, 15, "WAVE ${g.wave}", 2, Color{ r: 0, g: 255, b: 255, a: 255 })

	// 8. Overlay Menus
	if g.state == .menu {
		draw_text_centered(renderer, 400, 180, "MISSILE COMMAND", 4, Color{ r: 255, g: 50, b: 50, a: 255 })
		draw_text_centered(renderer, 400, 240, "AIR DEFENSE VECTOR SHOOTER", 2, Color{ r: 0, g: 200, b: 255, a: 255 })
		draw_text_centered(renderer, 400, 340, "PRESS SPACE OR CLICK TO START", 2, Color{ r: 255, g: 255, b: 255, a: 255 })
		draw_text_centered(renderer, 400, 400, "AIM WITH MOUSE / ARROWS | FIRE INTERCEPTOR WITH CLICK / SPACE", 1, Color{ r: 180, g: 180, b: 180, a: 255 })
		draw_text_centered(renderer, 400, 420, "PROTECT YOUR 6 CITIES FROM INCOMING ICBM STRIKES!", 1, Color{ r: 180, g: 180, b: 180, a: 255 })
	} else if g.state == .game_over {
		draw_text_centered(renderer, 400, 220, "THE END - ALL CITIES DESTROYED", 4, Color{ r: 255, g: 50, b: 50, a: 255 })
		draw_text_centered(renderer, 400, 310, "FINAL DEFENSE SCORE: ${g.score}", 2, Color{ r: 255, g: 255, b: 255, a: 255 })
		draw_text_centered(renderer, 400, 370, "PRESS SPACE OR R TO RESTART", 2, Color{ r: 0, g: 255, b: 100, a: 255 })
	} else if g.state == .paused {
		draw_text_centered(renderer, 400, 280, "- PAUSED -", 3, Color{ r: 255, g: 255, b: 0, a: 255 })
	}

	prod_fx_render(renderer)
	sdl.render_present(renderer)
}
