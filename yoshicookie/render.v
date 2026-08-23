import math
import os
import sdl
import sdl.image

pub struct YoshiCookieTextureManager {
pub mut:
	sprite_texture &sdl.Texture = unsafe { nil }
}

pub fn (mut tm YoshiCookieTextureManager) init(renderer &sdl.Renderer) {
	_ = image.init(int(image.InitFlags.png))
	candidates := [
		'assets/sprites/yoshicookie.png',
		'./assets/sprites/yoshicookie.png',
		'../assets/sprites/yoshicookie.png',
		'yoshicookie/assets/sprites/yoshicookie.png',
	]
	for p in candidates {
		if os.exists(p) {
			surface := image.load(p.str)
			if surface != unsafe { nil } {
				tm.sprite_texture = sdl.create_texture_from_surface(renderer, surface)
				sdl.free_surface(surface)
				if tm.sprite_texture != unsafe { nil } {
					println('YoshiCookie Texture Loaded Successfully: ' + p)
					return
				}
			}
		}
	}
}

pub fn render_yoshi_cookie_game(renderer &sdl.Renderer, mut g YoshiCookieGame, tex &sdl.Texture) {
	// Screen shake offsets
	shake_x := if g.screen_shake > 0.0 { int(math.sin(f64(sdl.get_ticks()) * 0.05) * 4.0) } else { 0 }
	shake_y := if g.screen_shake > 0.0 { int(math.cos(f64(sdl.get_ticks()) * 0.05) * 4.0) } else { 0 }

	// 1. Bakery Kitchen Background
	render_bakery_kitchen(renderer)

	// 2. Baking Sheet & 8x8 Grid Tray
	render_baking_sheet(renderer, mut g, shake_x, shake_y)

	// 3. 3D Baked Cookies
	render_cookies(renderer, mut g, shake_x, shake_y, tex)

	// 4. Cursor / Active Selector & Perimeter Shift Arrows
	render_cursor_and_shift_arrows(renderer, mut g, shake_x, shake_y)

	// 4b. Reserve Cookie Plate (Hold / Stash)
	render_reserve_plate(renderer, mut g, tex)

	// 5. Mario Chef & Yoshi Characters
	render_mario_chef(renderer, mut g)
	render_yoshi_bakery(renderer, mut g, tex)

	// 6. Conveyor Meter & Oven Alert
	render_conveyor_meter(renderer, mut g)

	// 7. Clipboard HUD (Score, High, Round, Cleared)
	render_bakery_hud(renderer, mut g)

	// 8. In-Game Easy Controls Banner
	render_controls_guide_bar(renderer, mut g)

	// 9. Particles & Popups
	render_particles(renderer, mut g)
	render_score_popups(renderer, mut g)

	// 10. CRT Filter
	if g.crt_filter {
		render_crt_overlay(renderer)
	}

	// 11. Game State Overlays
	if g.state == .title {
		render_title_screen(renderer, mut g)
	} else if g.state == .paused {
		render_paused_screen(renderer)
	} else if g.state == .stage_clear {
		render_stage_clear_screen(renderer, mut g)
	} else if g.state == .game_over {
		render_game_over_screen(renderer, mut g)
	}
}

fn render_reserve_plate(renderer &sdl.Renderer, mut g YoshiCookieGame, tex &sdl.Texture) {
	px := 42
	py := 395

	// Porcelain Dish Plate on table
	sdl.set_render_draw_color(renderer, 240, 240, 245, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: px, y: py, w: 58, h: 54 })

	// Golden Plate Rim
	sdl.set_render_draw_color(renderer, 235, 195, 45, 255)
	sdl.render_draw_rect(renderer, &sdl.Rect{ x: px, y: py, w: 58, h: 54 })

	draw_text_centered_shadow(renderer, px + 29, py - 12, 'RESERVE', 1,
		Color{ r: 255, g: 235, b: 60, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, px + 29, py + 56, '[SHIFT]', 1,
		Color{ r: 230, g: 230, b: 240, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })

	if g.has_reserve && g.reserve_cookie != .none {
		render_single_cookie(renderer, px + 5, py + 3, g.reserve_cookie, tex)
	}
}

fn render_bakery_kitchen(renderer &sdl.Renderer) {
	// Pastel checkered bakery wall
	for y := 0; y < 380; y += 40 {
		for x := 0; x < 800; x += 40 {
			if (x / 40 + y / 40) % 2 == 0 {
				sdl.set_render_draw_color(renderer, 245, 235, 220, 255)
			} else {
				sdl.set_render_draw_color(renderer, 235, 218, 195, 255)
			}
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: x, y: y, w: 40, h: 40 })
		}
	}

	// Glowing Oven in Background (x: 40, y: 70)
	sdl.set_render_draw_color(renderer, 50, 50, 55, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: 30, y: 70, w: 100, h: 70 })
	// Oven window with warm glowing coals
	ticks := f64(sdl.get_ticks())
	f_glow := int(math.sin(ticks * 0.006) * 25.0)
	sdl.set_render_draw_color(renderer, u8(220 + f_glow), 100, 30, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: 42, y: 82, w: 76, h: 46 })

	// Wooden Countertop Table
	sdl.set_render_draw_color(renderer, 160, 95, 45, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: 0, y: 380, w: 800, h: 220 })

	// Table border molding
	sdl.set_render_draw_color(renderer, 120, 68, 28, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: 0, y: 375, w: 800, h: 8 })

	// Wood Grain planks
	sdl.set_render_draw_color(renderer, 140, 80, 36, 255)
	for x := 60; x < 800; x += 90 {
		sdl.render_fill_rect(renderer, &sdl.Rect{ x: x, y: 380, w: 3, h: 220 })
	}
}

fn render_baking_sheet(renderer &sdl.Renderer, mut g YoshiCookieGame, ox int, oy int) {
	// Metallic Baking Pan Outer Shadow
	sdl.set_render_draw_blend_mode(renderer, .blend)
	sdl.set_render_draw_color(renderer, 0, 0, 0, 80)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: 172 + ox, y: 104 + oy, w: 432, h: 432 })

	// Baking Pan Rim (Brushed Steel)
	sdl.set_render_draw_color(renderer, 185, 190, 195, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: 168 + ox, y: 98 + oy, w: 432, h: 432 })

	// Pan Rim Highlights
	sdl.set_render_draw_color(renderer, 230, 235, 240, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: 168 + ox, y: 98 + oy, w: 432, h: 4 })
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: 168 + ox, y: 98 + oy, w: 4, h: 432 })

	// Pan Non-Stick Dark Interior
	sdl.set_render_draw_color(renderer, 46, 50, 56, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: 176 + ox, y: 106 + oy, w: 416, h: 416 })

	// Active row/column highlighted tracks
	if g.state == .playing {
		sdl.set_render_draw_blend_mode(renderer, .blend)
		sdl.set_render_draw_color(renderer, 255, 240, 150, 25)
		// Active Row Track
		sdl.render_fill_rect(renderer, &sdl.Rect{ x: 176 + ox, y: 110 + g.cursor_r * 52 + oy, w: 416, h: 48 })
		// Active Column Track
		sdl.render_fill_rect(renderer, &sdl.Rect{ x: 180 + g.cursor_c * 52 + ox, y: 106 + oy, w: 48, h: 416 })
	}

	// 8x8 Grid Cell Guidelines
	for r in 0 .. 8 {
		for c in 0 .. 8 {
			cx := 180 + c * 52 + ox
			cy := 110 + r * 52 + oy

			// Subtle parchment paper tint inside active bounding box
			if r >= g.min_r && r <= g.max_r && c >= g.min_c && c <= g.max_c {
				sdl.set_render_draw_color(renderer, 72, 60, 48, 255)
				sdl.render_fill_rect(renderer, &sdl.Rect{ x: cx, y: cy, w: 48, h: 48 })
			} else {
				sdl.set_render_draw_color(renderer, 38, 42, 46, 255)
				sdl.render_fill_rect(renderer, &sdl.Rect{ x: cx, y: cy, w: 48, h: 48 })
			}

			// Cell boundary dots
			sdl.set_render_draw_color(renderer, 85, 90, 100, 255)
			sdl.render_draw_point(renderer, cx, cy)
			sdl.render_draw_point(renderer, cx + 47, cy)
			sdl.render_draw_point(renderer, cx, cy + 47)
			sdl.render_draw_point(renderer, cx + 47, cy + 47)
		}
	}
}

fn render_cookies(renderer &sdl.Renderer, mut g YoshiCookieGame, ox int, oy int, tex &sdl.Texture) {
	for r in 0 .. 8 {
		for c in 0 .. 8 {
			cookie := g.grid[r][c]
			if cookie == .none {
				continue
			}
			cx := 180 + c * 52 + ox
			cy := 110 + r * 52 + oy

			// Flashing if matched
			if g.matched_grid[r][c] && (int(sdl.get_ticks() / 60) % 2 == 0) {
				continue
			}

			render_single_cookie(renderer, cx, cy, cookie, tex)
		}
	}
}

fn render_single_cookie(renderer &sdl.Renderer, x int, y int, cookie CookieType, tex &sdl.Texture) {
	if tex != unsafe { nil } && cookie != .none {
		src := match cookie {
			.donut { sdl.Rect{x: 0, y: 0, w: 64, h: 64} }
			.heart { sdl.Rect{x: 64, y: 0, w: 64, h: 64} }
			.diamond { sdl.Rect{x: 128, y: 0, w: 64, h: 64} }
			.checkered { sdl.Rect{x: 192, y: 0, w: 64, h: 64} }
			.yoshi_star { sdl.Rect{x: 256, y: 0, w: 64, h: 64} }
			.crescent { sdl.Rect{x: 320, y: 0, w: 64, h: 64} }
			else { sdl.Rect{x: 0, y: 0, w: 0, h: 0} }
		}
		if src.w > 0 {
			dst := sdl.Rect{ x: x + 2, y: y + 2, w: 44, h: 44 }
			sdl.render_copy(renderer, tex, &src, &dst)
			return
		}
	}

	// Cookie Base Shadow
	sdl.set_render_draw_blend_mode(renderer, .blend)
	sdl.set_render_draw_color(renderer, 0, 0, 0, 85)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + 4, y: y + 8, w: 42, h: 40 })

	match cookie {
		.donut {
			// Golden Ring Donut with Pink Strawberry Glaze
			sdl.set_render_draw_color(renderer, 220, 155, 70, 255) // Baked crust
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + 4, y: y + 4, w: 40, h: 40 })
			sdl.set_render_draw_color(renderer, 255, 120, 170, 255) // Strawberry icing
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + 8, y: y + 8, w: 32, h: 32 })
			// Specular gloss arc
			sdl.set_render_draw_color(renderer, 255, 190, 220, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + 10, y: y + 10, w: 16, h: 4 })
			// Center hole
			sdl.set_render_draw_color(renderer, 72, 60, 48, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + 18, y: y + 18, w: 12, h: 12 })
			// Rainbow sprinkles
			sdl.set_render_draw_color(renderer, 255, 240, 50, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + 12, y: y + 14, w: 4, h: 2 })
			sdl.set_render_draw_color(renderer, 50, 210, 255, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + 30, y: y + 14, w: 2, h: 4 })
			sdl.set_render_draw_color(renderer, 255, 255, 255, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + 26, y: y + 30, w: 4, h: 2 })
		}
		.heart {
			// Strawberry Sugar Heart
			sdl.set_render_draw_color(renderer, 215, 140, 60, 255) // Base crust
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + 6, y: y + 6, w: 36, h: 36 })
			sdl.set_render_draw_color(renderer, 245, 45, 75, 255) // Heart Red
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + 8, y: y + 10, w: 14, h: 14 })
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + 24, y: y + 10, w: 14, h: 14 })
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + 10, y: y + 18, w: 26, h: 16 })
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + 16, y: y + 32, w: 14, h: 8 })
			// Glossy jewel sheen
			sdl.set_render_draw_color(renderer, 255, 185, 205, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + 12, y: y + 12, w: 6, h: 6 })
		}
		.diamond {
			// Crisp Almond Wafer Diamond
			sdl.set_render_draw_color(renderer, 205, 155, 80, 255) // Wafer
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + 8, y: y + 8, w: 32, h: 32 })
			sdl.set_render_draw_color(renderer, 245, 225, 165, 255) // Vanilla icing diamond
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + 16, y: y + 10, w: 16, h: 28 })
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + 10, y: y + 16, w: 28, h: 16 })
			// Roasted Almond sliver in center
			sdl.set_render_draw_color(renderer, 130, 75, 30, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + 20, y: y + 18, w: 8, h: 12 })
			sdl.set_render_draw_color(renderer, 255, 215, 140, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + 22, y: y + 20, w: 4, h: 8 })
		}
		.checkered {
			// Two-Tone Chocolate & Vanilla Checkered Square
			sdl.set_render_draw_color(renderer, 85, 48, 24, 255) // Chocolate
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + 6, y: y + 6, w: 36, h: 36 })
			// Vanilla quadrants
			sdl.set_render_draw_color(renderer, 245, 225, 175, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + 8, y: y + 8, w: 15, h: 15 })
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + 24, y: y + 24, w: 15, h: 15 })
			// Chocolate quadrants
			sdl.set_render_draw_color(renderer, 115, 66, 36, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + 24, y: y + 8, w: 15, h: 15 })
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + 8, y: y + 24, w: 15, h: 15 })
			// Specular quadrant edge
			sdl.set_render_draw_color(renderer, 255, 245, 215, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + 9, y: y + 9, w: 5, h: 3 })
		}
		.crescent {
			// Golden Butter Croissant / Moon
			sdl.set_render_draw_color(renderer, 225, 160, 55, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + 6, y: y + 8, w: 34, h: 32 })
			// Crescent curve cutout
			sdl.set_render_draw_color(renderer, 72, 60, 48, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + 16, y: y + 12, w: 22, h: 24 })
			// Golden crust highlights & powdered sugar
			sdl.set_render_draw_color(renderer, 255, 240, 180, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + 8, y: y + 10, w: 8, h: 26 })
		}
		.yoshi_star {
			// Green Yoshi Dino Star
			sdl.set_render_draw_color(renderer, 45, 175, 55, 255) // Yoshi Green
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + 6, y: y + 6, w: 36, h: 36 })
			// Star points / snout
			sdl.set_render_draw_color(renderer, 245, 245, 240, 255) // White cheeks
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + 12, y: y + 18, w: 24, h: 16 })
			// Red crest
			sdl.set_render_draw_color(renderer, 235, 45, 45, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + 28, y: y + 8, w: 8, h: 8 })
			// Eye
			sdl.set_render_draw_color(renderer, 20, 20, 20, 255)
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: x + 16, y: y + 12, w: 4, h: 6 })
		}
		else {}
	}
}

fn render_cursor_and_shift_arrows(renderer &sdl.Renderer, mut g YoshiCookieGame, ox int, oy int) {
	if g.state != .playing {
		return
	}
	cx := 180 + g.cursor_c * 52 + ox
	cy := 110 + g.cursor_r * 52 + oy

	ticks := f64(sdl.get_ticks())
	pulse := int(math.sin(ticks * 0.008) * 3.0)

	// 1. Selector Bracket Cursor
	if g.key_grab || g.mouse_down {
		sdl.set_render_draw_color(renderer, 255, 225, 40, 255)
	} else {
		sdl.set_render_draw_color(renderer, 60, 230, 255, 255)
	}

	k := 10 + pulse
	// Top Left
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: cx - 3, y: cy - 3, w: k, h: 4 })
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: cx - 3, y: cy - 3, w: 4, h: k })
	// Top Right
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: cx + 51 - k, y: cy - 3, w: k, h: 4 })
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: cx + 47, y: cy - 3, w: 4, h: k })
	// Bottom Left
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: cx - 3, y: cy + 47, w: k, h: 4 })
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: cx - 3, y: cy + 51 - k, w: 4, h: k })
	// Bottom Right
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: cx + 51 - k, y: cy + 47, w: k, h: 4 })
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: cx + 47, y: cy + 51 - k, w: 4, h: k })

	// 2. Interactive Perimeter Shift Buttons (< > ^ v)
	btn_pulse := int(math.sin(ticks * 0.009) * 2.0)

	// Left Row Button (<) at x: 140, y: cy
	sdl.set_render_draw_color(renderer, 245, 210, 40, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: 140 - btn_pulse, y: cy + 12, w: 24, h: 24 })
	draw_text(renderer, 147 - btn_pulse, cy + 16, '<', 2, Color{ r: 40, g: 30, b: 20, a: 255 })

	// Right Row Button (>) at x: 604, y: cy
	sdl.set_render_draw_color(renderer, 245, 210, 40, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: 604 + btn_pulse, y: cy + 12, w: 24, h: 24 })
	draw_text(renderer, 611 + btn_pulse, cy + 16, '>', 2, Color{ r: 40, g: 30, b: 20, a: 255 })

	// Top Col Button (^) at x: cx, y: 70
	sdl.set_render_draw_color(renderer, 80, 220, 255, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: cx + 12, y: 70 - btn_pulse, w: 24, h: 24 })
	draw_text(renderer, cx + 16, 74 - btn_pulse, '^', 2, Color{ r: 20, g: 30, b: 50, a: 255 })

	// Bottom Col Button (v) at x: cx, y: 518
	sdl.set_render_draw_color(renderer, 80, 220, 255, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: cx + 12, y: 518 + btn_pulse, w: 24, h: 22 })
	draw_text(renderer, cx + 17, 521 + btn_pulse, 'v', 2, Color{ r: 20, g: 30, b: 50, a: 255 })
}

fn render_controls_guide_bar(renderer &sdl.Renderer, mut g YoshiCookieGame) {
	if g.state != .playing {
		return
	}
	// Bottom helper prompt
	draw_text_centered_shadow(renderer, 400, 578, 'CONTROLS: DRAG COOKIES | IJKL SHIFT | [SHIFT] RESERVE | [SPACE] PUSH | [T] BGM', 1,
		Color{ r: 255, g: 240, b: 140, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
}

fn render_mario_chef(renderer &sdl.Renderer, mut g YoshiCookieGame) {
	// Mario Chef on Left Side (x: 45, y: 190)
	mx := 45
	my := 190

	// Chef Toque Hat
	sdl.set_render_draw_color(renderer, 250, 250, 250, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: mx + 14, y: my, w: 36, h: 28 })
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: mx + 8, y: my + 10, w: 48, h: 18 })
	// Red Hat Rim
	sdl.set_render_draw_color(renderer, 225, 45, 45, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: mx + 10, y: my + 24, w: 44, h: 6 })

	// Mario Face
	sdl.set_render_draw_color(renderer, 255, 195, 145, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: mx + 16, y: my + 30, w: 32, h: 22 })

	// Big Mustache & Nose
	sdl.set_render_draw_color(renderer, 45, 30, 20, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: mx + 20, y: my + 42, w: 26, h: 8 })
	sdl.set_render_draw_color(renderer, 255, 180, 130, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: mx + 28, y: my + 36, w: 14, h: 10 })

	// Eyes
	sdl.set_render_draw_color(renderer, 20, 20, 20, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: mx + 36, y: my + 32, w: 4, h: 6 })

	// Chef White Apron & Red Shirt
	sdl.set_render_draw_color(renderer, 225, 45, 45, 255) // Red sleeves
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: mx + 10, y: my + 52, w: 44, h: 44 })
	sdl.set_render_draw_color(renderer, 245, 245, 245, 255) // White Apron
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: mx + 18, y: my + 54, w: 28, h: 42 })

	// Blue Overalls under apron
	sdl.set_render_draw_color(renderer, 40, 80, 200, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: mx + 16, y: my + 96, w: 32, h: 22 })

	// Brown Shoes
	sdl.set_render_draw_color(renderer, 90, 50, 25, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: mx + 12, y: my + 118, w: 16, h: 12 })
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: mx + 36, y: my + 118, w: 16, h: 12 })

	// Wooden Rolling Pin
	sdl.set_render_draw_color(renderer, 210, 150, 75, 255)
	pin_offset := if g.mario_anim_frame % 2 == 0 { 0 } else { 4 }
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: mx + 46, y: my + 48 + pin_offset, w: 14, h: 36 })
}

fn render_yoshi_bakery(renderer &sdl.Renderer, mut g YoshiCookieGame, tex &sdl.Texture) {
	// Yoshi sitting on Right Side (x: 650, y: 190)
	yx := 640
	yy := 180

	if tex != unsafe { nil } {
		src := sdl.Rect{x: 0, y: 64, w: 64, h: 64}
		dst := sdl.Rect{x: yx, y: yy, w: 84, h: 84}
		sdl.render_copy(renderer, tex, &src, &dst)

		if g.yoshi_eating_timer > 0.0 {
			sdl.set_render_draw_color(renderer, 255, 100, 140, 255) // Pink Tongue
			sdl.render_fill_rect(renderer, &sdl.Rect{ x: yx - 24, y: yy + 44, w: 32, h: 10 })
		}
		return
	}

	// Yoshi Big Snout
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: yx + 6, y: my_adj(yy, 16), w: 38, h: 32 })

	// White Belly & Cheeks
	sdl.set_render_draw_color(renderer, 245, 245, 240, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: yx + 10, y: my_adj(yy, 28), w: 26, h: 20 })
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: yx + 22, y: my_adj(yy, 50), w: 26, h: 42 })

	// Yoshi Eye & Pupils
	sdl.set_render_draw_color(renderer, 255, 255, 255, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: yx + 28, y: my_adj(yy, 8), w: 16, h: 22 })
	sdl.set_render_draw_color(renderer, 20, 20, 20, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: yx + 32, y: my_adj(yy, 12), w: 6, h: 12 })

	// Red Crest on Head
	sdl.set_render_draw_color(renderer, 235, 45, 45, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: yx + 46, y: my_adj(yy, 16), w: 14, h: 24 })

	// Orange Boots
	sdl.set_render_draw_color(renderer, 245, 130, 30, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: yx + 16, y: my_adj(yy, 96), w: 20, h: 18 })
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: yx + 40, y: my_adj(yy, 96), w: 20, h: 18 })

	// Eating Animation / Tongue
	if g.yoshi_eating_timer > 0.0 {
		sdl.set_render_draw_color(renderer, 255, 100, 140, 255) // Pink Tongue
		sdl.render_fill_rect(renderer, &sdl.Rect{ x: yx - 24, y: my_adj(yy, 32), w: 32, h: 10 })
	}
}

fn my_adj(base int, offset int) int {
	return base + offset
}

fn render_conveyor_meter(renderer &sdl.Renderer, mut g YoshiCookieGame) {
	// Conveyor Timer Meter Bar at top of board (x: 210, y: 44, w: 350, h: 16)
	sdl.set_render_draw_color(renderer, 30, 30, 35, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: 210, y: 44, w: 350, h: 16 })

	progress := math.max(0.0, math.min(1.0, f64(g.conveyor_timer / g.conveyor_max)))
	meter_w := int(346.0 * progress)

	// Meter color (Green -> Yellow -> Red alert)
	if progress > 0.5 {
		sdl.set_render_draw_color(renderer, 60, 215, 80, 255)
	} else if progress > 0.25 {
		sdl.set_render_draw_color(renderer, 245, 210, 40, 255)
	} else {
		sdl.set_render_draw_color(renderer, 245, 50, 50, 255)
	}
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: 212, y: 46, w: meter_w, h: 12 })

	draw_text_shadow(renderer, 216, 30, 'CONVEYOR TIMER', 1,
		Color{ r: 255, g: 235, b: 60, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
}

fn render_bakery_hud(renderer &sdl.Renderer, mut g YoshiCookieGame) {
	// Top Header Board
	draw_text_shadow(renderer, 30, 16, '1P SCORE', 1,
		Color{ r: 255, g: 215, b: 60, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_shadow(renderer, 30, 30, '${g.score:06d}', 2,
		Color{ r: 255, g: 255, b: 255, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })

	draw_text_shadow(renderer, 630, 16, 'HIGH SCORE', 1,
		Color{ r: 255, g: 215, b: 60, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_shadow(renderer, 630, 30, '${g.high_score:06d}', 2,
		Color{ r: 255, g: 255, b: 255, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })

	// Bottom Stats
	draw_text_shadow(renderer, 30, 545, 'ROUND: ${g.round:02d}', 2,
		Color{ r: 255, g: 235, b: 60, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })

	spd_text := match g.speed {
		.low { 'LOW' }
		.med { 'MED' }
		.hi { 'HI' }
	}
	draw_text_shadow(renderer, 175, 545, 'SPEED: ${spd_text}', 2,
		Color{ r: 80, g: 230, b: 255, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })

	bgm_text := match g.sound_mgr.bgm_type {
		.type_a { 'TYPE A' }
		.type_b { 'TYPE B' }
		.off { 'OFF' }
	}
	draw_text_shadow(renderer, 360, 545, 'BGM: ${bgm_text}', 2,
		Color{ r: 120, g: 255, b: 140, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })

	draw_text_shadow(renderer, 550, 545, 'CLEARED: ${g.cookies_cleared}', 2,
		Color{ r: 255, g: 190, b: 230, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
}

fn render_particles(renderer &sdl.Renderer, mut g YoshiCookieGame) {
	for pt in g.particles {
		if !pt.active { continue }
		sdl.set_render_draw_color(renderer, pt.color.r, pt.color.g, pt.color.b, 255)
		rect := sdl.Rect{
			x: int(pt.x)
			y: int(pt.y)
			w: int(pt.size)
			h: int(pt.size)
		}
		sdl.render_fill_rect(renderer, &rect)
	}
}

fn render_score_popups(renderer &sdl.Renderer, mut g YoshiCookieGame) {
	for sp in g.score_popups {
		if !sp.active { continue }
		draw_text_centered_shadow(renderer, int(sp.x), int(sp.y), sp.text, 2,
			sp.color, Color{ r: 0, g: 0, b: 0, a: 255 })
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

fn render_title_screen(renderer &sdl.Renderer, mut g YoshiCookieGame) {
	sdl.set_render_draw_blend_mode(renderer, .blend)
	sdl.set_render_draw_color(renderer, 15, 20, 30, 225)
	scrim := sdl.Rect{ x: 0, y: 0, w: 800, h: 600 }
	sdl.render_fill_rect(renderer, &scrim)

	// Retro Title
	draw_text_centered_shadow(renderer, 400, 40, "YOSHI'S COOKIE", 5,
		Color{ r: 255, g: 195, b: 45, a: 255 }, Color{ r: 215, g: 50, b: 50, a: 255 })

	draw_text_centered_shadow(renderer, 400, 96, '1992 NINTENDO / BPS CLASSIC ARCADE PUZZLE', 2,
		Color{ r: 80, g: 220, b: 255, a: 255 }, Color{ r: 10, g: 20, b: 40, a: 255 })

	// Start Game Config Box
	spd_name := match g.speed {
		.low { 'LOW' }
		.med { 'MED' }
		.hi { 'HI' }
	}
	bgm_name := match g.sound_mgr.bgm_type {
		.type_a { 'TYPE A' }
		.type_b { 'TYPE B' }
		.off { 'OFF' }
	}

	draw_text_centered_shadow(renderer, 400, 138, 'START ROUND: ${g.round:02d}  (CHANGE: LEFT / RIGHT ARROWS)', 2,
		Color{ r: 255, g: 235, b: 40, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 164, 'SPEED: ${spd_name} (1/2/3)  |  MUSIC: ${bgm_name} (T KEY)', 2,
		Color{ r: 80, g: 230, b: 255, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })

	draw_text_centered_shadow(renderer, 400, 205, 'PRESS SPACE OR ENTER TO START', 2,
		Color{ r: 110, g: 255, b: 130, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })

	// Modern & Easy Controls Box
	draw_text_centered_shadow(renderer, 400, 250, 'MODERN ENHANCED CONTROLS', 2,
		Color{ r: 255, g: 175, b: 45, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 282, 'MOUSE : CLICK & DRAG COOKIES  OR  CLICK ARROW BUTTONS (< > ^ v)', 1,
		Color{ r: 255, g: 235, b: 100, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 304, 'DIRECT KEYS : I / J / K / L TO SHIFT ROWS & COLUMNS INSTANTLY', 1,
		Color{ r: 100, g: 240, b: 255, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 326, 'CLASSIC KEYS : W / A / S / D MOVE  +  HOLD [Z] TO SHIFT', 1,
		Color{ r: 220, g: 220, b: 220, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 348, 'LSHIFT / H : SWAP / STASH COOKIE ON RESERVE PLATE', 1,
		Color{ r: 255, g: 160, b: 220, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 370, 'SPACE / ENTER : FAST CONVEYOR PUSH (+50 BONUS PTS)', 1,
		Color{ r: 255, g: 215, b: 110, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 392, 'T / B : SWITCH SOUNDTRACK (TYPE A / TYPE B / OFF)', 1,
		Color{ r: 110, g: 255, b: 140, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 420, '[P] PAUSE  [M] MUTE AUDIO  [C] CRT SCANLINES  [R] RESTART  [F11] Fullscreen', 1,
		Color{ r: 180, g: 180, b: 190, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })

	draw_text_centered_shadow(renderer, 400, 560, '(C) 1992 NINTENDO / BPS', 1,
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

fn render_stage_clear_screen(renderer &sdl.Renderer, mut g YoshiCookieGame) {
	sdl.set_render_draw_blend_mode(renderer, .blend)
	sdl.set_render_draw_color(renderer, 0, 0, 0, 185)
	scrim := sdl.Rect{ x: 0, y: 0, w: 800, h: 600 }
	sdl.render_fill_rect(renderer, &scrim)

	// Flashing Golden Victory Banner
	sdl.set_render_draw_color(renderer, 245, 210, 40, 255)
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: 120, y: 190, w: 560, h: 6 })
	sdl.render_fill_rect(renderer, &sdl.Rect{ x: 120, y: 390, w: 560, h: 6 })

	draw_text_centered_shadow(renderer, 400, 220, 'ROUND CLEAR!', 4,
		Color{ r: 80, g: 255, b: 110, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 280, 'ALL COOKIES BAKED & SERVED!', 2,
		Color{ r: 255, g: 235, b: 60, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })

	next_rnd := if g.round < 10 { g.round + 1 } else { 10 }
	draw_text_centered_shadow(renderer, 400, 335, 'ADVANCING TO ROUND ${next_rnd:02d}', 2,
		Color{ r: 100, g: 230, b: 255, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 365, 'PRESS SPACE OR WAIT TO PROCEED', 1,
		Color{ r: 240, g: 240, b: 240, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
}

fn render_game_over_screen(renderer &sdl.Renderer, mut g YoshiCookieGame) {
	sdl.set_render_draw_blend_mode(renderer, .blend)
	sdl.set_render_draw_color(renderer, 0, 0, 0, 210)
	scrim := sdl.Rect{ x: 0, y: 0, w: 800, h: 600 }
	sdl.render_fill_rect(renderer, &scrim)

	draw_text_centered_shadow(renderer, 400, 230, 'GAME OVER', 5,
		Color{ r: 255, g: 45, b: 45, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 300, 'FINAL SCORE: ${g.score}', 2,
		Color{ r: 255, g: 255, b: 255, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
	draw_text_centered_shadow(renderer, 400, 360, 'PRESS SPACE TO RETRY', 2,
		Color{ r: 255, g: 230, b: 40, a: 255 }, Color{ r: 0, g: 0, b: 0, a: 255 })
}
