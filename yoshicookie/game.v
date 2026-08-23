module main

import math
import rand

pub enum CookieType {
	none
	donut       // Golden glazed ring with sprinkles
	heart       // Frosted strawberry heart
	diamond     // Almond frosted wafer diamond
	checkered   // Two-tone chocolate & vanilla square
	crescent    // Butter vanilla croissant
	yoshi_star  // Green Yoshi dino star / wildcard
}

pub enum GameState {
	title
	playing
	clearing_matches
	compacting
	stage_clear
	game_over
	paused
}

pub enum GameSpeed {
	low
	med
	hi
}

pub struct Particle {
pub mut:
	x      f32
	y      f32
	vx     f32
	vy     f32
	color  Color
	life   f32
	max_l  f32
	size   f32
	active bool = true
}

pub struct ScorePopup {
pub mut:
	x      f32
	y      f32
	text   string
	color  Color
	timer  f32 = 0.85
	active bool = true
}

pub struct YoshiCookieGame {
pub mut:
	state              GameState = .title
	round              int       = 1
	speed              GameSpeed = .med
	score              int
	high_score         int       = 15000
	cookies_cleared    int
	chain_count        int
	grid               [8][8]CookieType
	matched_grid       [8][8]bool
	// Bounding box of the active cookie tray (min_r, max_r, min_c, max_c)
	min_r              int = 2
	max_r              int = 5
	min_c              int = 2
	max_c              int = 5
	// Cursor position
	cursor_r           int = 3
	cursor_c           int = 3
	// Conveyor timer (pushes new cookies into the tray)
	conveyor_timer     f32 = 8.0
	conveyor_max       f32 = 8.0
	conveyor_side      int // 0 = top, 1 = right
	state_timer        f32
	stage_clear_timer  f32
	anim_timer         f32
	screen_shake       f32
	yoshi_eating_timer f32
	mario_anim_frame   int
	sound_mgr          SoundManager
	particles          []Particle
	score_popups       []ScorePopup
	crt_filter         bool = true
	// Reserve Cookie Plate (Hold / Stash)
	reserve_cookie     CookieType = .none
	has_reserve        bool
	can_reserve        bool = true
	hints_enabled      bool = true
	// Mouse Interaction
	mouse_down         bool
	drag_start_x       int
	drag_start_y       int
	drag_r             int = -1
	drag_c             int = -1
	drag_active        bool
	// Controls
	key_left           bool
	key_right          bool
	key_up             bool
	key_down           bool
	key_grab           bool // Hold to shift row/col
}

pub fn new_yoshi_cookie_game() YoshiCookieGame {
	mut g := YoshiCookieGame{
		sound_mgr: new_sound_manager()
	}
	g.reset_to_title()
	return g
}

pub fn (mut g YoshiCookieGame) reset_to_title() {
	g.state = .title
	g.particles.clear()
	g.score_popups.clear()
}

pub fn (mut g YoshiCookieGame) start_game(round int, speed GameSpeed) {
	g.round = round
	g.speed = speed
	g.score = 0
	g.cookies_cleared = 0
	g.init_stage(round)
}

pub fn (mut g YoshiCookieGame) init_stage(round int) {
	g.clear_grid()
	g.state = .playing
	g.chain_count = 0
	g.particles.clear()
	g.score_popups.clear()

	// Initial tray size based on round (starts 4x4 or 5x5 centered in 8x8)
	tray_size := if round <= 2 { 4 } else if round <= 5 { 5 } else { 6 }
	g.min_r = (8 - tray_size) / 2
	g.max_r = g.min_r + tray_size - 1
	g.min_c = (8 - tray_size) / 2
	g.max_c = g.min_c + tray_size - 1

	g.cursor_r = g.min_r + 1
	g.cursor_c = g.min_c + 1

	// Number of cookie types in rotation (4 up to 6)
	num_types := if round <= 1 { 4 } else if round <= 4 { 5 } else { 6 }

	// Populate initial cookies ensuring no pre-cleared full lines
	for r := g.min_r; r <= g.max_r; r++ {
		for c := g.min_c; c <= g.max_c; c++ {
			g.grid[r][c] = g.get_random_cookie(num_types)
		}
	}

	// Break any initial identical rows/columns
	g.sanitize_initial_board()

	g.conveyor_max = match g.speed {
		.low { 9.0 }
		.med { 6.5 }
		.hi { 4.2 }
	}
	g.conveyor_timer = g.conveyor_max
}

pub fn (mut g YoshiCookieGame) clear_grid() {
	for r in 0 .. 8 {
		for c in 0 .. 8 {
			g.grid[r][c] = .none
			g.matched_grid[r][c] = false
		}
	}
}

pub fn (g &YoshiCookieGame) get_random_cookie(num_types int) CookieType {
	type_idx := (rand.intn(num_types) or { 0 }) + 1
	return match type_idx {
		1 { CookieType.donut }
		2 { CookieType.heart }
		3 { CookieType.diamond }
		4 { CookieType.checkered }
		5 { CookieType.crescent }
		else { CookieType.yoshi_star }
	}
}

pub fn (mut g YoshiCookieGame) sanitize_initial_board() {
	num_types := if g.round <= 1 { 4 } else if g.round <= 4 { 5 } else { 6 }
	// If a whole row is identical, change the last cell
	for r := g.min_r; r <= g.max_r; r++ {
		mut same := true
		first := g.grid[r][g.min_c]
		for c := g.min_c + 1; c <= g.max_c; c++ {
			if g.grid[r][c] != first {
				same = false
				break
			}
		}
		if same {
			mut alt := g.get_random_cookie(num_types)
			if alt == first {
				alt = if first == .donut { CookieType.heart } else { CookieType.donut }
			}
			g.grid[r][g.max_c] = alt
		}
	}
}

pub fn (mut g YoshiCookieGame) count_cookies() int {
	mut count := 0
	for r in 0 .. 8 {
		for c in 0 .. 8 {
			if g.grid[r][c] != .none {
				count++
			}
		}
	}
	return count
}

pub fn (mut g YoshiCookieGame) update_bounding_box() {
	mut found := false
	mut min_r := 7
	mut max_r := 0
	mut min_c := 7
	mut max_c := 0

	for r in 0 .. 8 {
		for c in 0 .. 8 {
			if g.grid[r][c] != .none {
				found = true
				if r < min_r { min_r = r }
				if r > max_r { max_r = r }
				if c < min_c { min_c = c }
				if c > max_c { max_c = c }
			}
		}
	}

	if found {
		g.min_r = min_r
		g.max_r = max_r
		g.min_c = min_c
		g.max_c = max_c
	}
}

// -------------------------------------------------------------
// Row / Column Shift Logic with Wrap-Around
// -------------------------------------------------------------
pub fn (mut g YoshiCookieGame) shift_row(row int, dir int) {
	if g.state != .playing || row < g.min_r || row > g.max_r {
		return
	}
	width := g.max_c - g.min_c + 1
	if width <= 1 {
		return
	}

	mut temp := []CookieType{len: width}
	for i in 0 .. width {
		temp[i] = g.grid[row][g.min_c + i]
	}

	if dir > 0 {
		// Shift Right
		last := temp[width - 1]
		for i := width - 1; i > 0; i-- {
			temp[i] = temp[i - 1]
		}
		temp[0] = last
	} else {
		// Shift Left
		first := temp[0]
		for i in 0 .. width - 1 {
			temp[i] = temp[i + 1]
		}
		temp[width - 1] = first
	}

	for i in 0 .. width {
		g.grid[row][g.min_c + i] = temp[i]
	}

	g.sound_mgr.play_shift()
	g.trigger_match_check()
}

pub fn (mut g YoshiCookieGame) shift_col(col int, dir int) {
	if g.state != .playing || col < g.min_c || col > g.max_c {
		return
	}
	height := g.max_r - g.min_r + 1
	if height <= 1 {
		return
	}

	mut temp := []CookieType{len: height}
	for i in 0 .. height {
		temp[i] = g.grid[g.min_r + i][col]
	}

	if dir > 0 {
		// Shift Down
		last := temp[height - 1]
		for i := height - 1; i > 0; i-- {
			temp[i] = temp[i - 1]
		}
		temp[0] = last
	} else {
		// Shift Up
		first := temp[0]
		for i in 0 .. height - 1 {
			temp[i] = temp[i + 1]
		}
		temp[height - 1] = first
	}

	for i in 0 .. height {
		g.grid[g.min_r + i][col] = temp[i]
	}

	g.sound_mgr.play_shift()
	g.trigger_match_check()
}

pub fn (mut g YoshiCookieGame) swap_reserve_cookie() {
	if g.state != .playing || !g.can_reserve {
		return
	}
	r := g.cursor_r
	c := g.cursor_c
	if r < g.min_r || r > g.max_r || c < g.min_c || c > g.max_c {
		return
	}

	cur_cookie := g.grid[r][c]
	if cur_cookie == .none {
		return
	}

	g.sound_mgr.play_stash()

	if !g.has_reserve {
		g.has_reserve = true
		g.reserve_cookie = cur_cookie
		// Replace current cell with wildcard yoshi_star to give player an instant boost!
		g.grid[r][c] = CookieType.yoshi_star
	} else {
		temp := g.reserve_cookie
		g.reserve_cookie = cur_cookie
		g.grid[r][c] = temp
	}

	// Stash sparkle particles
	cx := f32(180 + c * 52 + 24)
	cy := f32(110 + r * 52 + 24)
	g.add_crumb_particles(cx, cy, 6)

	g.trigger_match_check()
}

pub fn (mut g YoshiCookieGame) instant_conveyor_push() {
	if g.state != .playing {
		return
	}
	g.sound_mgr.play_speed_push()
	g.score += 50 // Fast push bonus points!
	g.conveyor_timer = 0.0
	g.add_score_popup(f32(180 + g.cursor_c * 52), f32(110 + g.cursor_r * 52), '+50 PUSH!', Color{ r: 255, g: 220, b: 50, a: 255 })
	g.inject_conveyor_cookies()
}

pub fn (mut g YoshiCookieGame) move_cursor(dr int, dc int) {
	if g.state != .playing {
		return
	}
	if g.key_grab {
		// Player is holding grab button: shifting row or column!
		if dr != 0 {
			g.shift_col(g.cursor_c, dr)
		}
		if dc != 0 {
			g.shift_row(g.cursor_r, dc)
		}
	} else {
		// Moving cursor
		new_r := g.cursor_r + dr
		new_c := g.cursor_c + dc
		if new_r >= g.min_r && new_r <= g.max_r {
			g.cursor_r = new_r
		}
		if new_c >= g.min_c && new_c <= g.max_c {
			g.cursor_c = new_c
		}
	}
}

pub fn (mut g YoshiCookieGame) handle_mouse_down(mx int, my int) {
	if g.state == .title {
		g.start_game(g.round, g.speed)
		return
	} else if g.state == .stage_clear {
		g.next_level()
		return
	} else if g.state == .game_over {
		g.reset_to_title()
		return
	} else if g.state != .playing {
		return
	}

	// 1. Check if clicked on perimeter arrow buttons
	// Left arrow of cursor row (x: 136..168, y: 110 + r*52 .. +48)
	cur_ry := 110 + g.cursor_r * 52
	cur_cx := 180 + g.cursor_c * 52

	if mx >= 135 && mx <= 168 && my >= cur_ry && my <= cur_ry + 48 {
		g.shift_row(g.cursor_r, -1)
		return
	}
	// Right arrow of cursor row (x: 600..635)
	if mx >= 600 && mx <= 635 && my >= cur_ry && my <= cur_ry + 48 {
		g.shift_row(g.cursor_r, 1)
		return
	}
	// Top arrow of cursor col (y: 65..95)
	if my >= 65 && my <= 95 && mx >= cur_cx && mx <= cur_cx + 48 {
		g.shift_col(g.cursor_c, -1)
		return
	}
	// Bottom arrow of cursor col (y: 512..545)
	if my >= 512 && my <= 545 && mx >= cur_cx && mx <= cur_cx + 48 {
		g.shift_col(g.cursor_c, 1)
		return
	}

	// 1b. Check if clicked on Reserve Plate (x: 40..102, y: 390..455)
	if mx >= 38 && mx <= 104 && my >= 385 && my <= 455 {
		g.swap_reserve_cookie()
		return
	}

	// 2. Check if clicked inside active 8x8 tray
	if mx >= 180 && mx < 180 + 8 * 52 && my >= 110 && my < 110 + 8 * 52 {
		c := (mx - 180) / 52
		r := (my - 110) / 52
		if r >= g.min_r && r <= g.max_r && c >= g.min_c && c <= g.max_c {
			g.cursor_r = r
			g.cursor_c = c
			g.mouse_down = true
			g.drag_start_x = mx
			g.drag_start_y = my
			g.drag_r = r
			g.drag_c = c
			g.drag_active = false
		}
	}
}

pub fn (mut g YoshiCookieGame) handle_mouse_motion(mx int, my int) {
	if !g.mouse_down || g.state != .playing || g.drag_r < 0 || g.drag_c < 0 {
		return
	}

	dx := mx - g.drag_start_x
	dy := my - g.drag_start_y
	threshold := 24

	if !g.drag_active {
		if math.abs(dx) > threshold && math.abs(dx) > math.abs(dy) {
			// Horizontal Drag Shift
			g.drag_active = true
			g.shift_row(g.drag_r, if dx > 0 { 1 } else { -1 })
			g.drag_start_x = mx
			g.drag_start_y = my
		} else if math.abs(dy) > threshold && math.abs(dy) > math.abs(dx) {
			// Vertical Drag Shift
			g.drag_active = true
			g.shift_col(g.drag_c, if dy > 0 { 1 } else { -1 })
			g.drag_start_x = mx
			g.drag_start_y = my
		}
	}
}

pub fn (mut g YoshiCookieGame) handle_mouse_up() {
	g.mouse_down = false
	g.drag_r = -1
	g.drag_c = -1
	g.drag_active = false
}

// -------------------------------------------------------------
// Line Match Detection & Compacting
// -------------------------------------------------------------
pub fn (mut g YoshiCookieGame) trigger_match_check() {
	matched := g.check_matches()
	if matched {
		g.state = .clearing_matches
		g.state_timer = 0.22
	}
}

pub fn (mut g YoshiCookieGame) check_matches() bool {
	mut matched := false

	// Clear matched flags
	for r in 0 .. 8 {
		for c in 0 .. 8 {
			g.matched_grid[r][c] = false
		}
	}

	width := g.max_c - g.min_c + 1
	height := g.max_r - g.min_r + 1

	if width < 2 && height < 2 {
		return false
	}

	// 1. Check Full Matching Rows
	if width >= 2 {
		for r := g.min_r; r <= g.max_r; r++ {
			first := g.grid[r][g.min_c]
			if first == .none {
				continue
			}
			mut row_matches := true
			for c := g.min_c + 1; c <= g.max_c; c++ {
				cell := g.grid[r][c]
				if cell == .none || (cell != first && cell != .yoshi_star && first != .yoshi_star) {
					row_matches = false
					break
				}
			}
			if row_matches {
				matched = true
				for c := g.min_c; c <= g.max_c; c++ {
					g.matched_grid[r][c] = true
				}
			}
		}
	}

	// 2. Check Full Matching Columns
	if height >= 2 {
		for c := g.min_c; c <= g.max_c; c++ {
			first := g.grid[g.min_r][c]
			if first == .none {
				continue
			}
			mut col_matches := true
			for r := g.min_r + 1; r <= g.max_r; r++ {
				cell := g.grid[r][c]
				if cell == .none || (cell != first && cell != .yoshi_star && first != .yoshi_star) {
					col_matches = false
					break
				}
			}
			if col_matches {
				matched = true
				for r := g.min_r; r <= g.max_r; r++ {
					g.matched_grid[r][c] = true
				}
			}
		}
	}

	return matched
}

pub fn (mut g YoshiCookieGame) clear_matched_cookies() {
	mut cleared_count := 0

	for r in 0 .. 8 {
		for c in 0 .. 8 {
			if g.matched_grid[r][c] {
				cleared_count++
				g.grid[r][c] = .none
				g.matched_grid[r][c] = false

				// Spawning crumb particles
				cx := f32(180 + c * 52)
				cy := f32(110 + r * 52)
				g.add_crumb_particles(cx + 26.0, cy + 26.0, 10)
			}
		}
	}

	if cleared_count > 0 {
		g.chain_count++
		g.cookies_cleared += cleared_count
		pts := cleared_count * 100 * int(math.pow(2.0, f64(g.chain_count - 1)))
		g.score += pts
		g.add_score_popup(400.0, 240.0, '+${pts}', Color{ r: 255, g: 235, b: 60, a: 255 })

		if g.chain_count > 1 {
			g.sound_mgr.play_combo(g.chain_count)
			g.screen_shake = 0.30
		} else {
			g.sound_mgr.play_clear()
			g.screen_shake = 0.15
		}

		g.yoshi_eating_timer = 0.65
	}
}

pub fn (mut g YoshiCookieGame) compact_grid() bool {
	// Compact rows and columns towards the center if completely empty
	mut modified := false

	// Check if all cookies are gone
	if g.count_cookies() == 0 {
		g.state = .stage_clear
		g.stage_clear_timer = 2.6
		g.sound_mgr.play_stage_clear()
		return false
	}

	g.update_bounding_box()

	// Ensure cursor stays inside valid bounds
	if g.cursor_r < g.min_r { g.cursor_r = g.min_r }
	if g.cursor_r > g.max_r { g.cursor_r = g.max_r }
	if g.cursor_c < g.min_c { g.cursor_c = g.min_c }
	if g.cursor_c > g.max_c { g.cursor_c = g.max_c }

	return modified
}

// -------------------------------------------------------------
// Conveyor Injection
// -------------------------------------------------------------
pub fn (mut g YoshiCookieGame) inject_conveyor_cookies() {
	num_types := if g.round <= 1 { 4 } else if g.round <= 4 { 5 } else { 6 }

	if g.conveyor_side == 0 {
		// Inject from TOP
		if g.min_r <= 0 {
			// Tray Overflow -> Game Over!
			g.state = .game_over
			g.sound_mgr.play_game_over()
			return
		}
		g.min_r--
		for c := g.min_c; c <= g.max_c; c++ {
			g.grid[g.min_r][c] = g.get_random_cookie(num_types)
			cx := f32(180 + c * 52)
			cy := f32(110 + g.min_r * 52)
			g.add_crumb_particles(cx + 26.0, cy + 26.0, 5)
		}
		g.conveyor_side = 1
	} else {
		// Inject from RIGHT
		if g.max_c >= 7 {
			// Tray Overflow -> Game Over!
			g.state = .game_over
			g.sound_mgr.play_game_over()
			return
		}
		g.max_c++
		for r := g.min_r; r <= g.max_r; r++ {
			g.grid[r][g.max_c] = g.get_random_cookie(num_types)
			cx := f32(180 + g.max_c * 52)
			cy := f32(110 + r * 52)
			g.add_crumb_particles(cx + 26.0, cy + 26.0, 5)
		}
		g.conveyor_side = 0
	}

	g.sound_mgr.play_conveyor_tick()
	g.trigger_match_check()
}

pub fn (mut g YoshiCookieGame) add_crumb_particles(x f32, y f32, count int) {
	for _ in 0 .. count {
		angle := f32((rand.intn(628) or { 0 })) / 100.0
		speed := f32((rand.intn(180) or { 90 })) + 40.0
		g.particles << Particle{
			x: x
			y: y
			vx: f32(math.cos(f64(angle))) * speed
			vy: f32(math.sin(f64(angle))) * speed
			color: Color{ r: 240, g: 190, b: 120, a: 255 }
			life: 0.55
			max_l: 0.55
			size: f32(rand.intn(4) or { 2 }) + 2.0
		}
	}
}

pub fn (mut g YoshiCookieGame) add_score_popup(x f32, y f32, text string, color Color) {
	g.score_popups << ScorePopup{
		x: x
		y: y
		text: text
		color: color
		timer: 0.85
		active: true
	}
}

// -------------------------------------------------------------
// Update Loop
// -------------------------------------------------------------
pub fn (mut g YoshiCookieGame) update(dt f32) {
	g.anim_timer += dt
	if g.anim_timer >= 0.25 {
		g.anim_timer = 0.0
		g.mario_anim_frame = (g.mario_anim_frame + 1) % 4
	}

	// BGM Streaming
	g.sound_mgr.update_bgm(f64(dt), g.state == .playing)

	if g.screen_shake > 0.0 {
		g.screen_shake -= dt
		if g.screen_shake < 0.0 { g.screen_shake = 0.0 }
	}

	if g.yoshi_eating_timer > 0.0 {
		g.yoshi_eating_timer -= dt
	}

	// Particle & Score Updates
	for mut p in g.particles {
		if !p.active { continue }
		p.x += p.vx * dt
		p.y += p.vy * dt
		p.vy += 320.0 * dt // Gravity
		p.life -= dt
		if p.life <= 0.0 { p.active = false }
	}
	for mut sp in g.score_popups {
		if !sp.active { continue }
		sp.y -= 35.0 * dt
		sp.timer -= dt
		if sp.timer <= 0.0 { sp.active = false }
	}
	g.particles = g.particles.filter(it.active)
	g.score_popups = g.score_popups.filter(it.active)

	if g.score > g.high_score {
		g.high_score = g.score
	}

	if g.state == .stage_clear {
		g.stage_clear_timer -= dt
		if g.stage_clear_timer <= 0.0 {
			g.next_level()
		}
		return
	}

	if g.state == .paused || g.state == .title || g.state == .game_over {
		return
	}

	// State Machine for matches and cascading
	if g.state == .clearing_matches {
		g.state_timer -= dt
		if g.state_timer <= 0.0 {
			g.clear_matched_cookies()
			g.state = .compacting
			g.state_timer = 0.15
		}
		return
	}

	if g.state == .compacting {
		g.state_timer -= dt
		if g.state_timer <= 0.0 {
			g.compact_grid()
			matched := g.check_matches()
			if matched {
				g.state = .clearing_matches
				g.state_timer = 0.20
			} else {
				g.state = .playing
				g.chain_count = 0
			}
		}
		return
	}

	// Conveyor countdown during active gameplay
	if g.state == .playing {
		g.conveyor_timer -= dt
		if g.conveyor_timer <= 0.0 {
			g.conveyor_timer = g.conveyor_max
			g.inject_conveyor_cookies()
		}
	}
}

pub fn (mut g YoshiCookieGame) next_level() {
	g.round++
	if g.round > 10 {
		g.round = 10
	}
	g.init_stage(g.round)
}
