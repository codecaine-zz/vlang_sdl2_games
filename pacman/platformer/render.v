module main

import math
import rand
import sdl

pub fn (game &PlatformerGame) render(renderer &sdl.Renderer) {
	// Screen shake offsets
	mut shake_x := 0
	mut shake_y := 0
	if game.screen_shake > 0 {
		shake_x = int((rand.f64() - 0.5) * game.screen_shake * 20.0)
		shake_y = int((rand.f64() - 0.5) * game.screen_shake * 20.0)
	}

	cam_x := int(game.camera_x) - shake_x
	cam_y := int(game.camera_y) - shake_y

	// Clear screen with sky color depending on level theme
	match game.current_level {
		1 { sdl.set_render_draw_color(renderer, 30, 40, 70, 255) }     // Emerald Hills Twilight
		2 { sdl.set_render_draw_color(renderer, 20, 15, 35, 255) }     // Crystal Caves Dark
		3 { sdl.set_render_draw_color(renderer, 45, 15, 15, 255) }     // Lava Fortress Crimson
		4 { sdl.set_render_draw_color(renderer, 15, 25, 55, 255) }     // Celestial Tower Night
		else { sdl.set_render_draw_color(renderer, 30, 40, 70, 255) }
	}
	sdl.render_clear(renderer)

	// Parallax Distant Mountains / Layers
	render_parallax_background(renderer, cam_x, cam_y, game.current_level)

	// Render Tile Map
	start_col := math.max(0, cam_x / tile_size)
	end_col := math.min(game.map.cols, (cam_x + 800) / tile_size + 2)
	start_row := math.max(0, cam_y / tile_size)
	end_row := math.min(game.map.rows, (cam_y + 600) / tile_size + 2)

	for r in start_row .. end_row {
		for c in start_col .. end_col {
			t := game.map.tiles[r][c]
			if t == .air { continue }

			screen_x := c * tile_size - cam_x
			screen_y := r * tile_size - cam_y

			rect := sdl.Rect{
				x: screen_x
				y: screen_y
				w: tile_size
				h: tile_size
			}

			match t {
				.solid {
					sdl.set_render_draw_color(renderer, 70, 130, 80, 255)
					sdl.render_fill_rect(renderer, &rect)
					// Border top highlights
					sdl.set_render_draw_color(renderer, 110, 190, 120, 255)
					top_rect := sdl.Rect{ x: screen_x, y: screen_y, w: tile_size, h: 4 }
					sdl.render_fill_rect(renderer, &top_rect)
				}
				.oneway {
					sdl.set_render_draw_color(renderer, 180, 140, 90, 255)
					top_rect := sdl.Rect{ x: screen_x, y: screen_y, w: tile_size, h: 8 }
					sdl.render_fill_rect(renderer, &top_rect)
				}
				.hazard {
					// Red spikes
					sdl.set_render_draw_color(renderer, 230, 60, 60, 255)
					for i in 0 .. 4 {
						sx := screen_x + i * 8
						sdl.render_draw_line(renderer, sx, screen_y + tile_size, sx + 4, screen_y)
						sdl.render_draw_line(renderer, sx + 4, screen_y, sx + 8, screen_y + tile_size)
					}
				}
				.coin {
					// Gold coin
					sdl.set_render_draw_color(renderer, 255, 215, 0, 255)
					c_rect := sdl.Rect{ x: screen_x + 8, y: screen_y + 8, w: 16, h: 16 }
					sdl.render_fill_rect(renderer, &c_rect)
				}
				.gem {
					// Diamond gem
					sdl.set_render_draw_color(renderer, 0, 230, 255, 255)
					g_rect := sdl.Rect{ x: screen_x + 6, y: screen_y + 6, w: 20, h: 20 }
					sdl.render_fill_rect(renderer, &g_rect)
				}
				.spring {
					sdl.set_render_draw_color(renderer, 100, 220, 255, 255)
					s_rect := sdl.Rect{ x: screen_x + 4, y: screen_y + 16, w: 24, h: 16 }
					sdl.render_fill_rect(renderer, &s_rect)
				}
				.checkpoint {
					// Flag pole & banner
					sdl.set_render_draw_color(renderer, 200, 200, 200, 255)
					pole := sdl.Rect{ x: screen_x + 14, y: screen_y, w: 4, h: tile_size }
					sdl.render_fill_rect(renderer, &pole)
					sdl.set_render_draw_color(renderer, 50, 220, 100, 255)
					flag := sdl.Rect{ x: screen_x + 18, y: screen_y + 4, w: 12, h: 10 }
					sdl.render_fill_rect(renderer, &flag)
				}
				.breakable {
					sdl.set_render_draw_color(renderer, 140, 90, 50, 255)
					sdl.render_fill_rect(renderer, &rect)
					sdl.set_render_draw_color(renderer, 90, 50, 20, 255)
					sdl.render_draw_rect(renderer, &rect)
				}
				.key {
					sdl.set_render_draw_color(renderer, 255, 180, 0, 255)
					k_rect := sdl.Rect{ x: screen_x + 10, y: screen_y + 10, w: 12, h: 12 }
					sdl.render_fill_rect(renderer, &k_rect)
				}
				.door {
					d_color := if game.player.has_key { sdl.Color{r: 50, g: 200, b: 50} } else { sdl.Color{r: 180, g: 50, b: 50} }
					sdl.set_render_draw_color(renderer, d_color.r, d_color.g, d_color.b, 255)
					d_rect := sdl.Rect{ x: screen_x + 4, y: screen_y, w: 24, h: tile_size }
					sdl.render_fill_rect(renderer, &d_rect)
				}
				else {}
			}
		}
	}

	// Render Moving Platforms
	sdl.set_render_draw_color(renderer, 100, 180, 240, 255)
	for plat in game.platforms {
		p_rect := sdl.Rect{
			x: int(plat.x) - cam_x
			y: int(plat.y) - cam_y
			w: int(plat.w)
			h: int(plat.h)
		}
		sdl.render_fill_rect(renderer, &p_rect)
	}

	// Render Enemies
	for enemy in game.enemies {
		if !enemy.active { continue }
		e_x := int(enemy.x) - cam_x
		e_y := int(enemy.y) - cam_y
		e_rect := sdl.Rect{ x: e_x, y: e_y, w: int(enemy.w), h: int(enemy.h) }

		match enemy.kind {
			.crawler {
				sdl.set_render_draw_color(renderer, 220, 80, 50, 255)
				sdl.render_fill_rect(renderer, &e_rect)
			}
			.slime {
				sdl.set_render_draw_color(renderer, 80, 220, 90, 255)
				sdl.render_fill_rect(renderer, &e_rect)
			}
			.bat {
				sdl.set_render_draw_color(renderer, 180, 70, 220, 255)
				sdl.render_fill_rect(renderer, &e_rect)
			}
			.turret {
				sdl.set_render_draw_color(renderer, 120, 120, 130, 255)
				sdl.render_fill_rect(renderer, &e_rect)
			}
		}
	}

	// Render Projectiles
	for proj in game.projectiles {
		if !proj.active { continue }
		pr_x := int(proj.x) - cam_x
		pr_y := int(proj.y) - cam_y
		color := if proj.is_player { sdl.Color{r: 255, g: 150, b: 0} } else { sdl.Color{r: 255, g: 50, b: 50} }
		sdl.set_render_draw_color(renderer, color.r, color.g, color.b, 255)
		pr_rect := sdl.Rect{ x: pr_x - 4, y: pr_y - 4, w: 8, h: 8 }
		sdl.render_fill_rect(renderer, &pr_rect)
	}

	// Render Particles
	for p in game.particles {
		px := int(p.x) - cam_x
		py := int(p.y) - cam_y
		sz := int(p.size)
		sdl.set_render_draw_color(renderer, p.r, p.g, p.b, 255)
		p_rect := sdl.Rect{ x: px - sz / 2, y: py - sz / 2, w: sz, h: sz }
		sdl.render_fill_rect(renderer, &p_rect)
	}

	// Render Player Sprite
	if game.player.invuln_timer <= 0 || (int(game.player.invuln_timer * 10) % 2 == 0) {
		px := int(game.player.x) - cam_x
		py := int(game.player.y) - cam_y

		p_color := if game.player.is_dashing {
			sdl.Color{r: 100, g: 220, b: 255}
		} else {
			sdl.Color{r: 50, g: 160, b: 240}
		}
		sdl.set_render_draw_color(renderer, p_color.r, p_color.g, p_color.b, 255)
		pl_rect := sdl.Rect{ x: px, y: py, w: int(game.player.w), h: int(game.player.h) }
		sdl.render_fill_rect(renderer, &pl_rect)

		// Visor / Eyes facing direction
		eye_x := if game.player.facing_right { px + int(game.player.w) - 6 } else { px + 2 }
		sdl.set_render_draw_color(renderer, 255, 255, 255, 255)
		eye_rect := sdl.Rect{ x: eye_x, y: py + 6, w: 4, h: 6 }
		sdl.render_fill_rect(renderer, &eye_rect)
	}

	// Render HUD UI Header
	render_hud(renderer, game)
}

fn render_parallax_background(renderer &sdl.Renderer, cam_x int, cam_y int, _level int) {
	// Mountain silhouette
	sdl.set_render_draw_color(renderer, 40, 50, 80, 255)
	for i in 0 .. 5 {
		mx := i * 300 - (cam_x / 3) % 300
		sdl.render_draw_line(renderer, mx, 400 - cam_y / 4, mx + 150, 250 - cam_y / 4)
		sdl.render_draw_line(renderer, mx + 150, 250 - cam_y / 4, mx + 300, 400 - cam_y / 4)
	}
}

fn render_hud(renderer &sdl.Renderer, game &PlatformerGame) {
	// Top status bar overlay
	sdl.set_render_draw_color(renderer, 15, 20, 30, 220)
	bar_rect := sdl.Rect{ x: 0, y: 0, w: 800, h: 45 }
	sdl.render_fill_rect(renderer, &bar_rect)

	// Health Hearts
	draw_text(renderer, 15, 12, 'HP:', 2, Color{r: 255, g: 255, b: 255})
	for i in 0 .. game.player.max_health {
		color := if i < game.player.health { Color{r: 255, g: 60, b: 60} } else { Color{r: 70, g: 70, b: 80} }
		draw_text(renderer, 65 + i * 22, 12, '*', 2, color)
	}

	// Level & Score
	draw_text(renderer, 200, 12, 'LVL ${game.current_level}', 2, Color{r: 100, g: 220, b: 255})
	draw_text(renderer, 320, 12, 'COINS: ${game.player.coins}', 2, Color{r: 255, g: 215, b: 0})
	draw_text(renderer, 520, 12, 'SCORE: ${game.player.score}', 2, Color{r: 255, g: 255, b: 255})

	// Key indicator
	if game.player.has_key {
		draw_text(renderer, 720, 12, 'KEY', 2, Color{r: 255, g: 215, b: 0})
	}

	// Game Over / Win overlays
	if game.game_over {
		sdl.set_render_draw_color(renderer, 0, 0, 0, 180)
		full_rect := sdl.Rect{ x: 0, y: 0, w: 800, h: 600 }
		sdl.render_fill_rect(renderer, &full_rect)
		draw_text_centered(renderer, 400, 240, 'GAME OVER', 4, Color{r: 255, g: 60, b: 60})
		draw_text_centered(renderer, 400, 310, 'PRESS [R] TO RESTART', 2, Color{r: 255, g: 255, b: 255})
	} else if game.game_won {
		sdl.set_render_draw_color(renderer, 0, 0, 0, 180)
		full_rect := sdl.Rect{ x: 0, y: 0, w: 800, h: 600 }
		sdl.render_fill_rect(renderer, &full_rect)
		draw_text_centered(renderer, 400, 220, 'VICTORY!', 5, Color{r: 255, g: 215, b: 0})
		draw_text_centered(renderer, 400, 300, 'FINAL SCORE: ${game.player.score}', 3, Color{r: 255, g: 255, b: 255})
		draw_text_centered(renderer, 400, 360, 'PRESS [R] TO REPLAY', 2, Color{r: 100, g: 220, b: 255})
	}
}
