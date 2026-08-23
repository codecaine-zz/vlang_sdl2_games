module main

import math
import rand

const grid_cols = 5
const grid_rows = 6

enum MathMode {
	multiples
	factors
	primes
	equality
	inequality
}

enum GameStatus {
	playing
	level_clear
	game_over
	paused
}

struct GridCell {
mut:
	display_text string
	value        int
	is_target    bool
	is_munched   bool
}

struct TargetRule {
pub mut:
	mode        MathMode
	target_val  int
	description string
}

struct Muncher {
pub mut:
	col        int
	row        int
	mouth_open bool
	anim_t     f64
}

enum TroggleType {
	reggie
	glitch
	bashful
}

struct Troggle {
pub mut:
	kind       TroggleType
	col        int
	row        int
	dir_col    int
	dir_row    int
	move_timer f64
	active     bool
}

struct Particle {
pub mut:
	x     f64
	y     f64
	vx    f64
	vy    f64
	color Color
	life  f64
}

struct FloatingText {
pub mut:
	x     f64
	y     f64
	text  string
	color Color
	life  f64
}

struct Game {
pub mut:
	grid              [5][6]GridCell
	rule              TargetRule
	muncher           Muncher
	troggles          []Troggle
	particles         []Particle
	popups            []FloatingText
	mode              MathMode   = .multiples
	status            GameStatus = .playing
	score             int
	high_score        int
	lives             int = 3
	level             int = 1
	streak            int
	remaining_targets int
	level_clear_timer f64
	flash_red_timer   f64
	troggle_spawn_t   f64
}

fn is_prime(n int) bool {
	if n <= 1 {
		return false
	}
	if n <= 3 {
		return true
	}
	if n % 2 == 0 || n % 3 == 0 {
		return false
	}
	mut i := 5
	for i * i <= n {
		if n % i == 0 || n % (i + 2) == 0 {
			return false
		}
		i += 6
	}
	return true
}

fn is_multiple(val int, target int) bool {
	if target <= 0 || val <= 0 {
		return false
	}
	return val % target == 0
}

fn is_factor(val int, target int) bool {
	if val <= 0 || target <= 0 {
		return false
	}
	return target % val == 0
}

fn is_greater_than(val int, target int) bool {
	return val > target
}

fn is_less_than(val int, target int) bool {
	return val < target
}

fn new_game(mode MathMode) Game {
	mut g := Game{
		mode:       mode
		lives:      3
		level:      1
		score:      0
		high_score: 0
		status:     .playing
	}
	g.init_level()
	return g
}

fn (mut g Game) set_mode(mode MathMode) {
	g.mode = mode
	g.score = 0
	g.lives = 3
	g.level = 1
	g.streak = 0
	g.status = .playing
	g.init_level()
}

fn (mut g Game) init_level() {
	g.troggles.clear()
	g.particles.clear()
	g.popups.clear()
	g.muncher = Muncher{
		col: 0
		row: 0
	}
	g.troggle_spawn_t = 0.0
	g.flash_red_timer = 0.0
	g.level_clear_timer = 0.0
	g.status = .playing

	// Pick target rule based on mode
	match g.mode {
		.multiples {
			targets := [3, 4, 5, 6, 7, 8, 9, 10, 12]
			target := targets[rand.intn(targets.len) or { 0 }]
			g.rule = TargetRule{
				mode:        .multiples
				target_val:  target
				description: 'Multiples of ${target}'
			}
		}
		.factors {
			targets := [12, 18, 20, 24, 30, 36, 40, 48, 60]
			target := targets[rand.intn(targets.len) or { 0 }]
			g.rule = TargetRule{
				mode:        .factors
				target_val:  target
				description: 'Factors of ${target}'
			}
		}
		.primes {
			g.rule = TargetRule{
				mode:        .primes
				target_val:  0
				description: 'Prime Numbers'
			}
		}
		.equality {
			targets := [8, 10, 12, 14, 15, 16, 18, 20, 24]
			target := targets[rand.intn(targets.len) or { 0 }]
			g.rule = TargetRule{
				mode:        .equality
				target_val:  target
				description: 'Equal to ${target}'
			}
		}
		.inequality {
			is_gt := rand.intn(2) or { 0 } == 0
			val := 10 + rand.intn(30) or { 15 }
			if is_gt {
				g.rule = TargetRule{
					mode:        .inequality
					target_val:  val
					description: 'Greater than ${val}'
				}
			} else {
				g.rule = TargetRule{
					mode:        .inequality
					target_val:  val
					description: 'Less than ${val}'
				}
			}
		}
	}

	// Generate Grid contents
	g.generate_grid()
}

fn (mut g Game) generate_grid() {
	mut valid_count := 0
	for r in 0 .. grid_rows {
		for c in 0 .. grid_cols {
			// Decide if this cell should be a target (aim for ~35-45% targets)
			should_be_target := rand.intn(100) or { 0 } < 40
			mut cell := GridCell{
				is_munched: false
			}

			if g.rule.mode == .equality {
				target := g.rule.target_val
				if should_be_target {
					// Expression evaluating to target
					op_type := rand.intn(3) or { 0 }
					if op_type == 0 {
						// Addition: a + b = target
						a := 1 + rand.intn(target - 1) or { 1 }
						b := target - a
						cell.display_text = '${a}+${b}'
						cell.value = target
						cell.is_target = true
					} else if op_type == 1 {
						// Subtraction: a - b = target
						b := 1 + rand.intn(15) or { 3 }
						a := target + b
						cell.display_text = '${a}-${b}'
						cell.value = target
						cell.is_target = true
					} else {
						// Multiplication if possible
						mut factors := []int{}
						for f in 1 .. target + 1 {
							if target % f == 0 {
								factors << f
							}
						}
						f1 := factors[rand.intn(factors.len) or { 0 }]
						f2 := target / f1
						cell.display_text = '${f1}x${f2}'
						cell.value = target
						cell.is_target = true
					}
				} else {
					// Expression NOT equal to target
					mut diff_val := target + (1 + rand.intn(8) or { 2 })
					if rand.intn(2) or { 0 } == 0 && target > 3 {
						diff_val = target - (1 + rand.intn(target - 2) or { 1 })
					}
					a := 1 + rand.intn(diff_val - 1) or { 1 }
					b := diff_val - a
					cell.display_text = '${a}+${b}'
					cell.value = diff_val
					cell.is_target = false
				}
			} else {
				// Number cell
				if should_be_target {
					val := g.generate_target_number()
					cell.value = val
					cell.display_text = '${val}'
					cell.is_target = true
				} else {
					val := g.generate_non_target_number()
					cell.value = val
					cell.display_text = '${val}'
					cell.is_target = false
				}
			}

			if cell.is_target {
				valid_count++
			}
			g.grid[c][r] = cell
		}
	}

	// Guarantee at least 5 targets on the board
	if valid_count < 5 {
		g.ensure_minimum_targets(5 - valid_count)
	}

	g.count_remaining_targets()
}

fn (g &Game) generate_target_number() int {
	target := g.rule.target_val
	match g.rule.mode {
		.multiples {
			mult := 1 + rand.intn(8) or { 2 }
			return target * mult
		}
		.factors {
			mut factors := []int{}
			for f in 1 .. target + 1 {
				if target % f == 0 {
					factors << f
				}
			}
			return factors[rand.intn(factors.len) or { 0 }]
		}
		.primes {
			primes := [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97]
			return primes[rand.intn(primes.len) or { 0 }]
		}
		.inequality {
			if g.rule.description.starts_with('Greater than') {
				return target + 1 + rand.intn(40) or { 5 }
			} else {
				return rand.intn(target) or { 1 }
			}
		}
		else {
			return target
		}
	}
}

fn (g &Game) generate_non_target_number() int {
	target := g.rule.target_val
	match g.rule.mode {
		.multiples {
			for _ in 0 .. 50 {
				candidate := 2 + rand.intn(75) or { 5 }
				if candidate % target != 0 {
					return candidate
				}
			}
			return target + 1
		}
		.factors {
			for _ in 0 .. 50 {
				candidate := 2 + rand.intn(target + 20) or { 7 }
				if target % candidate != 0 {
					return candidate
				}
			}
			return target + 2
		}
		.primes {
			composites := [4, 6, 8, 9, 10, 12, 14, 15, 16, 18, 20, 21, 22, 24, 25, 26, 27, 28, 30, 32, 33, 34, 35, 36, 38, 40, 42, 44, 45, 46, 48, 49, 50]
			return composites[rand.intn(composites.len) or { 0 }]
		}
		.inequality {
			if g.rule.description.starts_with('Greater than') {
				return rand.intn(target + 1) or { 0 }
			} else {
				return target + rand.intn(40) or { 5 }
			}
		}
		else {
			return target + 5
		}
	}
}

fn (mut g Game) ensure_minimum_targets(needed int) {
	mut added := 0
	for r in 0 .. grid_rows {
		for c in 0 .. grid_cols {
			if !g.grid[c][r].is_target {
				if g.rule.mode == .equality {
					t := g.rule.target_val
					g.grid[c][r] = GridCell{
						display_text: '${t / 2}+${t - t / 2}'
						value:        t
						is_target:    true
						is_munched:   false
					}
				} else {
					val := g.generate_target_number()
					g.grid[c][r] = GridCell{
						display_text: '${val}'
						value:        val
						is_target:    true
						is_munched:   false
					}
				}
				added++
				if added >= needed {
					return
				}
			}
		}
	}
}

fn (mut g Game) count_remaining_targets() {
	mut count := 0
	for r in 0 .. grid_rows {
		for c in 0 .. grid_cols {
			if g.grid[c][r].is_target && !g.grid[c][r].is_munched {
				count++
			}
		}
	}
	g.remaining_targets = count
}

fn (mut g Game) move_muncher(dcol int, drow int) bool {
	if g.status != .playing {
		return false
	}
	new_c := g.muncher.col + dcol
	new_r := g.muncher.row + drow

	if new_c >= 0 && new_c < grid_cols && new_r >= 0 && new_r < grid_rows {
		g.muncher.col = new_c
		g.muncher.row = new_r
		return true
	}
	return false
}

enum MunchResult {
	correct
	incorrect
	already_munched
}

fn (mut g Game) munch_current_cell() MunchResult {
	if g.status != .playing {
		return .already_munched
	}
	c := g.muncher.col
	r := g.muncher.row

	if g.grid[c][r].is_munched {
		return .already_munched
	}

	g.grid[c][r].is_munched = true
	g.muncher.mouth_open = true
	g.muncher.anim_t = 0.25

	if g.grid[c][r].is_target {
		g.streak++
		pts := 100 + (g.streak - 1) * 20
		g.score += pts
		if g.score > g.high_score {
			g.high_score = g.score
		}
		g.count_remaining_targets()

		// Add popup floating score
		cell_x := 180 + c * 150 + 75
		cell_y := 160 + r * 95 + 47
		g.popups << FloatingText{
			x:     f64(cell_x)
			y:     f64(cell_y)
			text:  '+${pts}'
			color: Color{
				r: 50
				g: 255
				b: 100
			}
			life:  1.0
		}

		// Add particle burst
		for _ in 0 .. 12 {
			ang := (rand.f64() * 2.0 * math.pi)
			spd := 40.0 + rand.f64() * 80.0
			g.particles << Particle{
				x:     f64(cell_x)
				y:     f64(cell_y)
				vx:    math.cos(ang) * spd
				vy:    math.sin(ang) * spd
				color: Color{
					r: 100
					g: 255
					b: 150
				}
				life:  0.6
			}
		}

		// Check level clear
		if g.remaining_targets == 0 {
			g.status = .level_clear
			g.level_clear_timer = 2.0
		}

		return .correct
	} else {
		g.streak = 0
		g.lives--
		g.flash_red_timer = 0.5

		cell_x := 180 + c * 150 + 75
		cell_y := 160 + r * 95 + 47
		g.popups << FloatingText{
			x:     f64(cell_x)
			y:     f64(cell_y)
			text:  'WRONG!'
			color: Color{
				r: 255
				g: 50
				b: 50
			}
			life:  1.2
		}

		if g.lives <= 0 {
			g.status = .game_over
		}

		return .incorrect
	}
}

fn (mut g Game) spawn_troggle() {
	if g.troggles.len >= 3 || g.status != .playing {
		return
	}
	kind_idx := rand.intn(3) or { 0 }
	kind := match kind_idx {
		0 { TroggleType.reggie }
		1 { TroggleType.glitch }
		else { TroggleType.bashful }
	}

	// Spawn at border edge away from Muncher
	spawn_side := rand.intn(4) or { 0 }
	mut c := 0
	mut r := 0
	mut dc := 0
	mut dr := 0

	match spawn_side {
		0 { // Top row moving down
			c = rand.intn(grid_cols) or { 0 }
			r = 0
			dr = 1
		}
		1 { // Bottom row moving up
			c = rand.intn(grid_cols) or { 0 }
			r = grid_rows - 1
			dr = -1
		}
		2 { // Left col moving right
			c = 0
			r = rand.intn(grid_rows) or { 0 }
			dc = 1
		}
		else { // Right col moving left
			c = grid_cols - 1
			r = rand.intn(grid_rows) or { 0 }
			dc = -1
		}
	}

	if c == g.muncher.col && r == g.muncher.row {
		c = (c + 2) % grid_cols
	}
	g.troggles << Troggle{
		kind:       kind
		col:        c
		row:        r
		dir_col:    dc
		dir_row:    dr
		move_timer: 1.5 - (f64(g.level) * 0.1)
		active:     true
	}
}

fn (mut g Game) update(dt f64) (bool, bool, bool) {
	mut play_spawn := false
	mut play_eaten := false
	mut play_win := false

	if g.flash_red_timer > 0 {
		g.flash_red_timer -= dt
		if g.flash_red_timer < 0 {
			g.flash_red_timer = 0
		}
	}

	if g.muncher.anim_t > 0 {
		g.muncher.anim_t -= dt
		if g.muncher.anim_t <= 0 {
			g.muncher.anim_t = 0
			g.muncher.mouth_open = false
		}
	}

	// Update floating popups & particles
	for i := g.popups.len - 1; i >= 0; i-- {
		g.popups[i].life -= dt
		g.popups[i].y -= 30.0 * dt
		if g.popups[i].life <= 0 {
			g.popups.delete(i)
		}
	}

	for i := g.particles.len - 1; i >= 0; i-- {
		g.particles[i].life -= dt
		g.particles[i].x += g.particles[i].vx * dt
		g.particles[i].y += g.particles[i].vy * dt
		if g.particles[i].life <= 0 {
			g.particles.delete(i)
		}
	}

	if g.status == .level_clear {
		g.level_clear_timer -= dt
		if g.level_clear_timer <= 0 {
			g.level++
			g.init_level()
			play_win = true
		}
		return play_spawn, play_eaten, play_win
	}

	if g.status != .playing {
		return play_spawn, play_eaten, play_win
	}

	// Spawn troggles over time
	g.troggle_spawn_t += dt
	spawn_interval := math.max(3.0, 7.0 - f64(g.level) * 0.5)
	if g.troggle_spawn_t >= spawn_interval {
		g.troggle_spawn_t = 0
		g.spawn_troggle()
		play_spawn = true
	}

	// Update troggles
	for i := g.troggles.len - 1; i >= 0; i-- {
		g.troggles[i].move_timer -= dt
		if g.troggles[i].move_timer <= 0 {
			g.troggles[i].move_timer = math.max(0.6, 1.6 - f64(g.level) * 0.1)

			// Troggle movement AI
			mut nc := g.troggles[i].col + g.troggles[i].dir_col
			mut nr := g.troggles[i].row + g.troggles[i].dir_row

			if nc < 0 || nc >= grid_cols || nr < 0 || nr >= grid_rows {
				// Reverse direction or pick new
				g.troggles[i].dir_col = -g.troggles[i].dir_col
				g.troggles[i].dir_row = -g.troggles[i].dir_row
				nc = g.troggles[i].col + g.troggles[i].dir_col
				nr = g.troggles[i].row + g.troggles[i].dir_row
			}

			if nc >= 0 && nc < grid_cols && nr >= 0 && nr < grid_rows {
				g.troggles[i].col = nc
				g.troggles[i].row = nr
			}

			// Glitch Troggle eats or alters cell
			if g.troggles[i].kind == .glitch {
				if !g.grid[nc][nr].is_munched {
					if rand.intn(2) or { 0 } == 0 {
						g.grid[nc][nr].is_munched = true
						g.count_remaining_targets()
					}
				}
			}

			// Check collision with Muncher
			if g.troggles[i].col == g.muncher.col && g.troggles[i].row == g.muncher.row {
				g.lives--
				play_eaten = true
				g.muncher.col = 0
				g.muncher.row = 0
				g.troggles.delete(i)
				g.flash_red_timer = 0.6

				if g.lives <= 0 {
					g.status = .game_over
				}
				continue
			}
		}
	}

	return play_spawn, play_eaten, play_win
}
