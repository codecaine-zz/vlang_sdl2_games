module main

import sdl
import sdl.image
import os
import math

// --- Production polish layer -------------------------------------------------
// Adds real PNG sprite rendering (corner badges from this game's own sprite
// sheet), an ambient particle/glow sparkle field, and a soft cinematic
// vignette. Purely additive: drawn last, immediately before present, and
// never touches existing game state or logic.

fn prod_fx_texture(renderer &sdl.Renderer) &sdl.Texture {
	_ = image.init(int(image.InitFlags.png))
	candidates := [
		os.join_path('assets', 'sprites', 'sprite_sheet.png'),
		os.join_path('.', 'assets', 'sprites', 'sprite_sheet.png'),
		os.join_path('..', 'assets', 'sprites', 'sprite_sheet.png'),
	]
	for p in candidates {
		if os.exists(p) {
			surface := image.load(p.str)
			if unsafe { surface != nil } {
				texture := sdl.create_texture_from_surface(renderer, surface)
				sdl.free_surface(surface)
				if unsafe { texture != nil } {
					return texture
				}
			}
		}
	}
	return unsafe { nil }
}

fn prod_fx_render(renderer &sdl.Renderer) {
	mut out_w := 0
	mut out_h := 0
	sdl.get_renderer_output_size(renderer, &out_w, &out_h)
	if out_w <= 0 || out_h <= 0 {
		out_w = 800
		out_h = 600
	}
	t := f64(sdl.get_ticks()) / 1000.0

	prod_fx_draw_particles(renderer, out_w, out_h, t)
	prod_fx_draw_corner_badges(renderer, out_w, out_h, t)
	prod_fx_draw_vignette(renderer, out_w, out_h)
	sdl.set_render_draw_blend_mode(renderer, sdl.BlendMode.blend)
}

fn prod_fx_draw_particles(renderer &sdl.Renderer, w int, h int, t f64) {
	sdl.set_render_draw_blend_mode(renderer, sdl.BlendMode.add)
	for i in 0 .. 24 {
		fi := f64(i)
		seed := math.sin(fi * 12.9898) * 43758.5453
		frac := seed - math.floor(seed)
		speed := 0.10 + frac * 0.16
		phase := (frac + t * speed)
		py := int((phase - math.floor(phase)) * f64(h))
		px := int((0.5 + 0.5 * math.sin(fi * 2.31 + t * 0.18)) * f64(w))
		glow := u8(60 + int(60.0 * (0.5 + 0.5 * math.sin(t * 1.3 + fi))))
		size := 2 + (i % 3)
		sdl.set_render_draw_color(renderer, glow, u8(int(glow) * 3 / 4 + 60), 255, 90)
		rect := sdl.Rect{x: px - size, y: py - size, w: size * 2, h: size * 2}
		sdl.render_fill_rect(renderer, &rect)
	}
}

fn prod_fx_draw_corner_badges(renderer &sdl.Renderer, w int, h int, t f64) {
	texture := prod_fx_texture(renderer)
	if unsafe { texture == nil } {
		return
	}
	defer {
		sdl.destroy_texture(texture)
	}
	sdl.set_texture_blend_mode(texture, sdl.BlendMode.blend)
	pulse := u8(140 + int(90.0 * (0.5 + 0.5 * math.sin(t * 1.6))))
	sdl.set_texture_alpha_mod(texture, pulse)
	badge := 46
	pad := 14
	positions := [[pad, pad], [w - pad - badge, pad], [pad, h - pad - badge],
		[w - pad - badge, h - pad - badge]]
	for pos in positions {
		dst := sdl.Rect{x: pos[0], y: pos[1], w: badge, h: badge}
		sdl.render_copy(renderer, texture, sdl.null, &dst)
	}
	sdl.set_texture_alpha_mod(texture, 255)
}

fn prod_fx_draw_vignette(renderer &sdl.Renderer, w int, h int) {
	sdl.set_render_draw_blend_mode(renderer, sdl.BlendMode.blend)
	for i in 0 .. 10 {
		inset := i * 4
		sdl.set_render_draw_color(renderer, 0, 0, 0, u8(6))
		top := sdl.Rect{x: 0, y: inset, w: w, h: 3}
		bottom := sdl.Rect{x: 0, y: h - inset - 3, w: w, h: 3}
		left := sdl.Rect{x: inset, y: 0, w: 3, h: h}
		right := sdl.Rect{x: w - inset - 3, y: 0, w: 3, h: h}
		sdl.render_fill_rect(renderer, &top)
		sdl.render_fill_rect(renderer, &bottom)
		sdl.render_fill_rect(renderer, &left)
		sdl.render_fill_rect(renderer, &right)
	}
}
