module main

import math
import sdl

struct Color {
	r u8
	g u8
	b u8
}

pub fn capture_cyberrunner_snapshot(output_path string) {
	sdl.init(sdl.init_video)
	defer { sdl.quit() }

	w := 1280
	h := 720

	surface := sdl.create_rgb_surface(0, w, h, 32, 0x00FF0000, 0x0000FF00, 0x000000FF, 0xFF000000)
	if unsafe { surface == nil } { return }
	defer { sdl.free_surface(surface) }

	renderer := sdl.create_software_renderer(surface)
	if unsafe { renderer == nil } { return }
	defer { sdl.destroy_renderer(renderer) }

	// Background: Deep Cyberpunk Space Void
	sdl.set_render_draw_color(renderer, 8, 12, 28, 255)
	sdl.render_clear(renderer)

	// Glowing Synthwave Sun on Horizon
	horizon_y := 340
	sun_r := 90
	for dy := -sun_r; dy <= 0; dy++ {
		span := int(math.sqrt(f64(sun_r * sun_r - dy * dy)))
		// Sunset orange/magenta gradient stripes
		t := f64(dy + sun_r) / f64(sun_r)
		r_val := u8(255)
		g_val := u8(t * 180.0)
		b_val := u8((1.0 - t) * 128.0)
		if (dy / 4) % 2 == 0 {
			sdl.set_render_draw_color(renderer, r_val, g_val, b_val, 255)
			sdl.render_draw_line(renderer, w / 2 - span, horizon_y + dy, w / 2 + span, horizon_y + dy)
		}
	}

	// Distant neon stars
	for i := 0; i < 180; i++ {
		sx := int(f64(i * 157 % w))
		sy := int(f64(i * 83 % horizon_y))
		b_val := u8(140 + (i * 37 % 115))
		sdl.set_render_draw_color(renderer, b_val, b_val, 255, 255)
		sdl.render_draw_point(renderer, sx, sy)
	}

	// 3D Perspective Road Grid
	road_bottom_w := 960
	road_top_w := 40

	// Fill road background
	for y := horizon_y; y < h; y++ {
		t := f64(y - horizon_y) / f64(h - horizon_y)
		// Exponential perspective factor
		p := math.pow(t, 2.2)
		cur_hw := int(f64(road_top_w / 2) + p * f64(road_bottom_w / 2 - road_top_w / 2))
		shade := u8(14 + p * 20.0)
		sdl.set_render_draw_color(renderer, shade, shade + 2, shade + 18, 255)
		sdl.render_draw_line(renderer, w / 2 - cur_hw, y, w / 2 + cur_hw, y)
	}

	// Horizontal Neon Grid Lines
	for i := 1; i <= 24; i++ {
		t := f64(i) / 24.0
		p := math.pow(t, 2.2)
		y := horizon_y + int(p * f64(h - horizon_y))
		cur_hw := int(f64(road_top_w / 2) + p * f64(road_bottom_w / 2 - road_top_w / 2))

		sdl.set_render_draw_color(renderer, 255, 0, 128, u8(100 + p * 155.0))
		sdl.render_draw_line(renderer, w / 2 - cur_hw, y, w / 2 + cur_hw, y)
	}

	// Longitudinal Neon Lane Lines (3 lanes: left, center, right)
	lane_factors := [-1.0, -0.333, 0.333, 1.0]
	for lf in lane_factors {
		col := if lf == -1.0 || lf == 1.0 { Color{ r: 0, g: 240, b: 255 } } else { Color{ r: 255, g: 220, b: 0 } }
		sdl.set_render_draw_color(renderer, col.r, col.g, col.b, 255)

		for y := horizon_y; y < h; y += 2 {
			t := f64(y - horizon_y) / f64(h - horizon_y)
			p := math.pow(t, 2.2)
			cur_hw := f64(road_top_w / 2) + p * f64(road_bottom_w / 2 - road_top_w / 2)
			lx := int(f64(w / 2) + lf * cur_hw)
			sdl.render_draw_point(renderer, lx, y)
			sdl.render_draw_point(renderer, lx + 1, y)
		}
	}

	// Elevated Light Pillars on outer edges
	for i := 4; i <= 22; i += 3 {
		t := f64(i) / 22.0
		p := math.pow(t, 2.2)
		y := horizon_y + int(p * f64(h - horizon_y))
		cur_hw := int(f64(road_top_w / 2) + p * f64(road_bottom_w / 2 - road_top_w / 2))
		pillar_h := int(15.0 + p * 90.0)

		sdl.set_render_draw_color(renderer, 0, 240, 255, 255)
		sdl.render_draw_line(renderer, w / 2 - cur_hw, y, w / 2 - cur_hw, y - pillar_h)
		sdl.render_draw_line(renderer, w / 2 + cur_hw, y, w / 2 + cur_hw, y - pillar_h)
		// Glow cap
		sdl.set_render_draw_color(renderer, 255, 0, 128, 255)
		sdl.render_draw_line(renderer, w / 2 - cur_hw - 2, y - pillar_h, w / 2 - cur_hw + 2, y - pillar_h)
		sdl.render_draw_line(renderer, w / 2 + cur_hw - 2, y - pillar_h, w / 2 + cur_hw + 2, y - pillar_h)
	}

	// Speed Boost Pad (Left Lane, Mid distance)
	{
		t := 0.48
		p := math.pow(t, 2.2)
		y := horizon_y + int(p * f64(h - horizon_y))
		cur_hw := f64(road_top_w / 2) + p * f64(road_bottom_w / 2 - road_top_w / 2)
		pad_x := int(f64(w / 2) - 0.666 * cur_hw)
		pad_w := int(30.0 + p * 70.0)
		pad_h := int(8.0 + p * 20.0)

		sdl.set_render_draw_color(renderer, 255, 0, 128, 255)
		pad_r := sdl.Rect{ x: pad_x - pad_w / 2, y: y - pad_h / 2, w: pad_w, h: pad_h }
		sdl.render_fill_rect(renderer, &pad_r)
		sdl.set_render_draw_color(renderer, 255, 255, 255, 255)
		sdl.render_draw_rect(renderer, &pad_r)
	}

	// Glowing Gem (Right Lane, Near distance)
	{
		t := 0.68
		p := math.pow(t, 2.2)
		y := horizon_y + int(p * f64(h - horizon_y)) - int(25.0 * p)
		cur_hw := f64(road_top_w / 2) + p * f64(road_bottom_w / 2 - road_top_w / 2)
		gem_x := int(f64(w / 2) + 0.666 * cur_hw)
		gem_sz := int(10.0 + p * 16.0)

		sdl.set_render_draw_color(renderer, 255, 220, 0, 255)
		for dy := -gem_sz; dy <= gem_sz; dy++ {
			span := gem_sz - int(math.abs(f64(dy)))
			sdl.render_draw_line(renderer, gem_x - span, y + dy, gem_x + span, y + dy)
		}
		sdl.set_render_draw_color(renderer, 255, 255, 255, 255)
		sdl.render_draw_line(renderer, gem_x - gem_sz / 2, y, gem_x + gem_sz / 2, y)
	}

	// Neon Obstacle Barrier (Center Lane, Far-mid distance)
	{
		t := 0.40
		p := math.pow(t, 2.2)
		y := horizon_y + int(p * f64(h - horizon_y))
		obs_x := int(f64(w / 2))
		obs_w := int(20.0 + p * 50.0)
		obs_h := int(15.0 + p * 40.0)

		sdl.set_render_draw_color(renderer, 255, 40, 60, 220)
		obs_r := sdl.Rect{ x: obs_x - obs_w / 2, y: y - obs_h, w: obs_w, h: obs_h }
		sdl.render_fill_rect(renderer, &obs_r)
		sdl.set_render_draw_color(renderer, 255, 200, 200, 255)
		sdl.render_draw_rect(renderer, &obs_r)
	}

	// Player Cyber Stealth Craft (Center Foreground)
	ship_x := w / 2
	ship_y := h - 130

	// Thruster Plume Particles
	for p := 0; p < 35; p++ {
		px := ship_x + (p % 7 - 3) * 4
		py := ship_y + 25 + p * 2
		sdl.set_render_draw_color(renderer, 255, 0, 128, u8(255 - p * 6))
		sdl.render_draw_line(renderer, px - 1, py, px + 1, py)
	}

	// Outer Ship Fuselage (Cyan Neon)
	sdl.set_render_draw_color(renderer, 0, 240, 255, 255)
	// Nose to wings
	sdl.render_draw_line(renderer, ship_x, ship_y - 45, ship_x - 70, ship_y + 25)
	sdl.render_draw_line(renderer, ship_x, ship_y - 45, ship_x + 70, ship_y + 25)
	sdl.render_draw_line(renderer, ship_x - 70, ship_y + 25, ship_x, ship_y + 10)
	sdl.render_draw_line(renderer, ship_x + 70, ship_y + 25, ship_x, ship_y + 10)

	// Inner Cockpit (Magenta Neon)
	sdl.set_render_draw_color(renderer, 255, 0, 128, 255)
	sdl.render_draw_line(renderer, ship_x, ship_y - 25, ship_x - 22, ship_y + 5)
	sdl.render_draw_line(renderer, ship_x, ship_y - 25, ship_x + 22, ship_y + 5)
	sdl.render_draw_line(renderer, ship_x - 22, ship_y + 5, ship_x + 22, ship_y + 5)

	// Top Cockpit HUD Bar
	sdl.set_render_draw_color(renderer, 10, 15, 30, 240)
	top_hud := sdl.Rect{ x: 40, y: 24, w: w - 80, h: 50 }
	sdl.render_fill_rect(renderer, &top_hud)
	sdl.set_render_draw_color(renderer, 0, 240, 255, 255)
	sdl.render_draw_rect(renderer, &top_hud)

	// Boost charge meter
	sdl.set_render_draw_color(renderer, 255, 0, 128, 255)
	boost_bar := sdl.Rect{ x: 60, y: 38, w: 220, h: 22 }
	sdl.render_fill_rect(renderer, &boost_bar)
	sdl.set_render_draw_color(renderer, 255, 255, 255, 255)
	sdl.render_draw_rect(renderer, &boost_bar)

	// Shield Units
	for s := 0; s < 3; s++ {
		sdl.set_render_draw_color(renderer, 0, 240, 255, 255)
		s_rect := sdl.Rect{ x: 310 + s * 32, y: 38, w: 24, h: 22 }
		sdl.render_fill_rect(renderer, &s_rect)
		sdl.set_render_draw_color(renderer, 255, 255, 255, 255)
		sdl.render_draw_rect(renderer, &s_rect)
	}

	sdl.save_bmp(surface, 'screenshots/cyberrunner.bmp'.str)
}
