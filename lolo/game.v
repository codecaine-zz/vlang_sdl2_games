module main

import os
import sdl
import sdl.image

pub const win_w = 960
pub const win_h = 680
pub const grid_cols = 11
pub const grid_rows = 11
pub const cell_size = 48
pub const grid_offset_x = 24
pub const grid_offset_y = 75

pub enum GameMode {
	play
	editor
}

pub enum LevelTheme {
	castle
	forest
	desert
	ice
	volcanic
	haunted
}

pub enum Dimension {
	alpha
	beta
}

pub enum CyberSkin {
	neon_blue
	cyber_magenta
	obsidian_gold
	toxic_lime
	dark_matter
}

pub enum AchievementBadge {
	minimalist
	speed_demon
	pacifist
	master_architect
	grand_master
}

pub enum TileType {
	grass
	wall
	rock
	tree
	water
	bridge
	lava
	ice
	warp_a
	warp_b
	locked_gate
	arrow_up
	arrow_down
	arrow_left
	arrow_right
	laser_prism_slash
	laser_prism_backslash
	pressure_plate
	toggle_laser_gate
	conveyor_up
	conveyor_down
	conveyor_left
	conveyor_right
	phase_block_alpha
	phase_block_beta
	timed_laser_barrier
	plate_channel_1
	plate_channel_2
	gate_channel_1
	gate_channel_2
}

pub enum EntityType {
	none
	lolo_spawn
	door
	chest
	heart_frame
	emerald_frame
	snakey
	alma
	leeper
	skull
	medusa
	don_medusa_h
	don_medusa_v
	gol
	king_egger
	gobby
	rocky
	moby
	wisp
	spike_trap
	hammer
	key_item
	speed_boots
	holo_terminal
}

pub enum Direction {
	up
	down
	left
	right
}

pub enum GameStatus {
	playing
	level_clear
	won
	lost
}

pub enum EditorTab {
	tiles
	items
	enemies
	themes
	gizmos
}

pub enum EditorTool {
	pencil
	line
	rect
	fill
	eraser
	prefab
}

pub struct Point {
pub mut:
	x int
	y int
}

pub struct Lolo {
pub mut:
	x           int
	y           int
	dir         Direction = .down
	shots       int
	keys        int
	hammers     int
	speed_boost f64
	is_dead     bool
}

pub struct Enemy {
pub mut:
	kind          EntityType
	x             int
	y             int
	dir           Direction = .down
	is_egg        bool
	egg_timer     f64
	is_asleep     bool
	move_timer    f64
	trap_active   bool = true
	charge_active bool
	charge_dir    Direction = .down
}

pub struct MagicShot {
pub mut:
	x      f64
	y      f64
	dx     f64
	dy     f64
	active bool
}

pub struct Level {
pub mut:
	name              string
	floor             int
	password          string
	theme             LevelTheme = .castle
	grid              [11][11]TileType
	entities          [11][11]EntityType
	is_dark_dungeon   bool
	lore_text         string
	target_gold_sec   int = 15
	target_silver_sec int = 30
	target_bronze_sec int = 60
	rule_pacifist     bool
}

pub struct MoveStep {
pub mut:
	dir          Direction
	shots_before int
	keys_before  int
	grid         [11][11]TileType
	entities     [11][11]EntityType
	enemies      []Enemy
}

pub struct LaserSegment {
pub mut:
	x1 int
	y1 int
	x2 int
	y2 int
}

pub struct RecordedMove {
pub mut:
	dir       Direction
	is_shot   bool
	is_phase  bool
	timestamp u32
}

pub struct Game {
pub mut:
	mode                 GameMode = .play
	status               GameStatus = .playing
	status_msg           string
	score                int
	lives                int = 5
	moves_count          int
	total_hearts         int
	hearts_remaining     int
	door_open            bool
	chest_open           bool
	is_sliding           bool
	slide_dir            Direction = .down
	warp_cooldown        f64
	spike_cycle_timer    f64
	gate_open            bool

	// Dimension & Gizmos
	active_dimension     Dimension = .alpha
	skin                 CyberSkin = .neon_blue

	// Speedrun & Replay
	level_time_ms        u32
	is_replaying         bool
	replay_move_idx      int
	replay_timer         f64
	recorded_moves       []RecordedMove
	active_replay_moves  []RecordedMove
	pb_times             map[int]u32
	pb_moves             map[int]int
	unlocked_badges      map[string]bool
	badge_toast          string
	badge_toast_timer    f64

	// AI Hints
	show_hint            bool
	hint_path            []Point

	// Sharing Modal & Community Packs
	is_share_modal_open  bool
	share_code_str       string
	community_pack_idx   int

	// Laser Reflection Beams
	laser_segments       []LaserSegment
	medusa_laser_active  bool
	laser_x1             int
	laser_y1             int
	laser_x2             int
	laser_y2             int

	lolo                 Lolo
	grid                 [11][11]TileType
	entities             [11][11]EntityType
	enemies              []Enemy
	magic_shot           MagicShot
	history              []MoveStep

	current_level_idx    int
	current_level        Level
	campaign_levels      []Level
	community_levels     []Level

	// Level Select & Directory State
	level_select_tab     int

	// Multi-Channel Logic & Timed Laser Clocks
	pulse_clock          f32
	is_pulse_active      bool = true
	channels_open        [4]bool

	// Hologram Dialogue Terminal State
	active_dialogue      string
	is_dialogue_open     bool

	// Speedrun Medal Award
	earned_medal         string

	// Editor State
	editor_level         Level
	editor_tab           EditorTab  = .tiles
	editor_tool          EditorTool = .pencil
	selected_tile        TileType   = .grass
	selected_entity      EntityType = .none
	is_entity_selected   bool
	is_testing_custom    bool
	is_level_select_open bool
	rect_start_col       int = -1
	rect_start_row       int = -1
	line_start_col       int = -1
	line_start_row       int = -1
	selected_prefab      int
	validation_msg       string
	custom_slots         [5]Level
	sprite_texture       &sdl.Texture = unsafe { nil }
}

pub fn (mut g Game) init_textures(renderer &sdl.Renderer) {
	image.init(int(image.InitFlags.png))
	paths := [
		'assets/sprites/lolo.png',
		'../assets/sprites/lolo.png',
		os.join_path('assets', 'sprites', 'lolo.png'),
		os.join_path('..', 'assets', 'sprites', 'lolo.png'),
		os.join_path('lolo', 'assets', 'sprites', 'lolo.png'),
		'/Users/codecaine/vlang_sdl2_games/assets/sprites/lolo.png',
	]
	for p in paths {
		if os.exists(p) {
			surface := image.load(p.str)
			if !isnil(surface) {
				g.sprite_texture = sdl.create_texture_from_surface(renderer, surface)
				sdl.free_surface(surface)
				if !isnil(g.sprite_texture) {
					sdl.set_texture_blend_mode(g.sprite_texture, .blend)
					return
				}
			}
		}
	}
}

pub fn new_game() Game {
	mut g := Game{
		editor_level: create_empty_level_theme('Custom Matrix Level', .castle)
	}
	g.campaign_levels = get_all_campaign_levels()
	g.community_levels = get_community_challenge_packs()
	g.load_level(0)
	return g
}

pub fn (mut g Game) load_level(idx int) {
	if idx < 0 || idx >= g.campaign_levels.len {
		return
	}
	g.current_level_idx = idx
	g.init_level(g.campaign_levels[idx])
}

pub fn (mut g Game) init_level(lvl Level) {
	g.current_level = lvl
	g.grid = lvl.grid
	g.entities = lvl.entities
	g.status = .playing
	g.status_msg = ''
	g.moves_count = 0
	g.level_time_ms = 0
	g.door_open = false
	g.chest_open = false
	g.is_sliding = false
	g.warp_cooldown = 0
	g.spike_cycle_timer = 0
	g.gate_open = false
	g.pulse_clock = 0
	g.is_pulse_active = true
	g.channels_open = [false, false, false, false]!
	g.is_dialogue_open = false
	g.active_dialogue = ''
	g.earned_medal = ''
	g.active_dimension = .alpha
	g.medusa_laser_active = false
	g.laser_segments.clear()
	g.magic_shot = MagicShot{}
	g.history.clear()
	g.enemies.clear()
	g.recorded_moves.clear()
	g.is_replaying = false
	g.show_hint = false
	g.hint_path.clear()

	mut h_count := 0
	mut spawn_found := false

	for r in 0 .. grid_rows {
		for c in 0 .. grid_cols {
			ent := g.entities[r][c]
			match ent {
				.lolo_spawn {
					g.lolo = Lolo{
						x:     c
						y:     r
						dir:   .down
						shots: 0
					}
					g.entities[r][c] = .none
					spawn_found = true
				}
				.heart_frame {
					h_count++
				}
				.snakey, .alma, .leeper, .skull, .medusa, .don_medusa_h, .don_medusa_v, .gol, .king_egger, .gobby, .rocky, .moby, .wisp, .spike_trap {
					g.enemies << Enemy{
						kind: ent
						x:    c
						y:    r
					}
					g.entities[r][c] = .none
				}
				else {}
			}
		}
	}

	if !spawn_found {
		g.lolo = Lolo{
			x:     5
			y:     9
			dir:   .down
			shots: 0
		}
	}

	g.total_hearts = h_count
	g.hearts_remaining = h_count
}

pub fn (mut g Game) restart_level() {
	if g.is_testing_custom {
		g.init_level(g.editor_level)
		g.is_testing_custom = true
	} else {
		g.init_level(g.current_level)
	}
}

pub fn (mut g Game) next_level() {
	if g.is_testing_custom {
		g.mode = .editor
		g.is_testing_custom = false
		return
	}
	if g.current_level_idx + 1 < g.campaign_levels.len {
		g.load_level(g.current_level_idx + 1)
	} else {
		g.status = .won
		g.status_msg = 'MISSION COMPLETE! PRINCESS LALA RESCUED!'
		g.unlock_badge(.grand_master)
	}
}

// --------------------------------------------------
// Modern Gizmos & Physics Updates
// --------------------------------------------------

pub fn (mut g Game) toggle_dimension() {
	g.active_dimension = if g.active_dimension == .alpha { Dimension.beta } else { Dimension.alpha }
	g.recorded_moves << RecordedMove{
		is_phase:  true
		timestamp: g.level_time_ms
	}
}

pub fn (mut g Game) cycle_skin() {
	next := (int(g.skin) + 1) % 5
	g.skin = unsafe { CyberSkin(next) }
}

pub fn (mut g Game) toggle_hint() {
	g.show_hint = !g.show_hint
	if g.show_hint {
		g.hint_path = g.get_hint_path()
	}
}

pub fn (mut g Game) unlock_badge(badge AchievementBadge) {
	name := match badge {
		.minimalist { 'MINIMALIST' }
		.speed_demon { 'SPEED DEMON' }
		.pacifist { 'PACIFIST' }
		.master_architect { 'MASTER ARCHITECT' }
		.grand_master { 'GRAND MASTER' }
	}
	if !g.unlocked_badges[name] {
		g.unlocked_badges[name] = true
		g.badge_toast = 'ACHIEVEMENT UNLOCKED: ${name}!'
		g.badge_toast_timer = 4.0
	}
}

pub fn (mut g Game) update(dt f64) {
	if g.badge_toast_timer > 0 {
		g.badge_toast_timer -= dt
		if g.badge_toast_timer <= 0 {
			g.badge_toast = ''
		}
	}

	if g.mode != .play || g.status != .playing {
		return
	}

	g.level_time_ms += u32(dt * 1000.0)

	// Ghost Replay playback runner
	if g.is_replaying {
		g.step_replay(dt)
		return
	}

	// Speed Boost timer
	if g.lolo.speed_boost > 0 {
		g.lolo.speed_boost -= dt
		if g.lolo.speed_boost < 0 {
			g.lolo.speed_boost = 0
		}
	}

	// Warp cooldown timer
	if g.warp_cooldown > 0 {
		g.warp_cooldown -= dt
	}

	// Spike Trap cycle timer
	g.spike_cycle_timer += dt
	trap_state := (int(g.spike_cycle_timer * 1.5) % 2) == 0
	for mut enemy in g.enemies {
		if enemy.kind == .spike_trap {
			enemy.trap_active = trap_state
		}
	}

	// Pulse Clock Update (2.0s period)
	g.pulse_clock += f32(dt)
	if g.pulse_clock >= 2.0 {
		g.pulse_clock = 0.0
		g.is_pulse_active = !g.is_pulse_active
	}

	// Pressure Plate Check
	g.check_pressure_plates()

	// Conveyor Belt Automatic Movement
	g.check_conveyor_belts()

	// Update Magic Shot
	if g.magic_shot.active {
		g.magic_shot.x += g.magic_shot.dx * dt * 14.0
		g.magic_shot.y += g.magic_shot.dy * dt * 14.0

		sx := int(g.magic_shot.x + 0.5)
		sy := int(g.magic_shot.y + 0.5)

		if sx < 0 || sx >= grid_cols || sy < 0 || sy >= grid_rows {
			g.magic_shot.active = false
		} else {
			// Check if hits rotatable Laser Prism
			tile := g.grid[sy][sx]
			if tile == .laser_prism_slash {
				g.grid[sy][sx] = .laser_prism_backslash
				g.magic_shot.active = false
			} else if tile == .laser_prism_backslash {
				g.grid[sy][sx] = .laser_prism_slash
				g.magic_shot.active = false
			} else if tile == .wall || tile == .rock || tile == .tree {
				g.magic_shot.active = false
			} else {
				for mut enemy in g.enemies {
					if enemy.x == sx && enemy.y == sy {
						if !enemy.is_egg {
							enemy.is_egg = true
							enemy.egg_timer = 8.0
						} else {
							enemy.x = -10
							enemy.y = -10
						}
						g.magic_shot.active = false
						break
					}
				}
			}
		}
	}

	// Ice Continuous Sliding
	if g.is_sliding {
		g.step_ice_slide()
	}

	// Update Enemies AI
	g.update_enemies_ai(dt)

	// Calculate Multi-Bounce Medusa Laser Beams
	g.calculate_laser_optics()
}

fn (mut g Game) check_pressure_plates() {
	mut is_pressed := false
	if g.grid[g.lolo.y][g.lolo.x] == .pressure_plate {
		is_pressed = true
	}
	for r in 0 .. grid_rows {
		for c in 0 .. grid_cols {
			if g.entities[r][c] == .emerald_frame && g.grid[r][c] == .pressure_plate {
				is_pressed = true
			}
		}
	}
	if is_pressed {
		g.gate_open = true
	}

	// Multi-Channel Pressure Plates
	g.channels_open[0] = false
	g.channels_open[1] = false
	if g.grid[g.lolo.y][g.lolo.x] == .plate_channel_1 {
		g.channels_open[0] = true
	}
	if g.grid[g.lolo.y][g.lolo.x] == .plate_channel_2 {
		g.channels_open[1] = true
	}
	for r in 0 .. grid_rows {
		for c in 0 .. grid_cols {
			if g.entities[r][c] == .emerald_frame {
				if g.grid[r][c] == .plate_channel_1 {
					g.channels_open[0] = true
				} else if g.grid[r][c] == .plate_channel_2 {
					g.channels_open[1] = true
				}
			}
		}
	}
	for enemy in g.enemies {
		if enemy.x >= 0 && enemy.x < grid_cols && enemy.y >= 0 && enemy.y < grid_rows {
			if g.grid[enemy.y][enemy.x] == .pressure_plate {
				is_pressed = true
			}
		}
	}
	g.gate_open = is_pressed
}

fn (mut g Game) check_conveyor_belts() {
	if g.is_sliding {
		return
	}
	cur_tile := g.grid[g.lolo.y][g.lolo.x]
	match cur_tile {
		.conveyor_up { g.step_lolo_in_direction(.up) }
		.conveyor_down { g.step_lolo_in_direction(.down) }
		.conveyor_left { g.step_lolo_in_direction(.left) }
		.conveyor_right { g.step_lolo_in_direction(.right) }
		else {}
	}
}

// --------------------------------------------------
// Advanced Multi-Bounce Laser Optics Calculation
// --------------------------------------------------

fn (mut g Game) calculate_laser_optics() {
	g.medusa_laser_active = false
	g.laser_segments.clear()

	for enemy in g.enemies {
		if enemy.x < 0 || enemy.x >= grid_cols || enemy.y < 0 || enemy.y >= grid_rows {
			continue
		}
		if enemy.is_egg {
			continue
		}

		if enemy.kind == .medusa || enemy.kind == .don_medusa_h || enemy.kind == .don_medusa_v {
			dirs := match enemy.kind {
				.medusa { [Direction.up, Direction.down, Direction.left, Direction.right] }
				.don_medusa_h { [Direction.left, Direction.right] }
				.don_medusa_v { [Direction.up, Direction.down] }
				else { [Direction.down] }
			}

			for d in dirs {
				g.trace_laser_beam(enemy.x, enemy.y, d)
			}
		}
	}
}

fn (mut g Game) trace_laser_beam(start_x int, start_y int, start_dir Direction) {
	mut cx := start_x
	mut cy := start_y
	mut cur_dir := start_dir
	mut max_bounces := 6

	for max_bounces > 0 {
		max_bounces--
		mut hit_x := cx
		mut hit_y := cy
		mut terminated := false

		for {
			match cur_dir {
				.up { hit_y-- }
				.down { hit_y++ }
				.left { hit_x-- }
				.right { hit_x++ }
			}

			if hit_x < 0 || hit_x >= grid_cols || hit_y < 0 || hit_y >= grid_rows {
				terminated = true
				break
			}

			// Check player hit
			if hit_x == g.lolo.x && hit_y == g.lolo.y {
				if g.lolo.speed_boost <= 0 {
					g.medusa_laser_active = true
					g.laser_segments << LaserSegment{ x1: cx, y1: cy, x2: hit_x, y2: hit_y }
					g.laser_x1 = cx
					g.laser_y1 = cy
					g.laser_x2 = hit_x
					g.laser_y2 = hit_y
					g.kill_lolo('ELIMINATED BY HIGH-VOLTAGE LASER TURRET!')
				}
				terminated = true
				break
			}

			// Check Obstacles & Prisms
			tile := g.grid[hit_y][hit_x]
			ent := g.entities[hit_y][hit_x]

			if ent != .none && ent != .lolo_spawn && ent != .door {
				terminated = true
				break
			}

			// Check if beam is blocked by any Enemy or Egg
			mut blocked_by_enemy := false
			for enemy in g.enemies {
				if enemy.x == hit_x && enemy.y == hit_y {
					blocked_by_enemy = true
					break
				}
			}
			if blocked_by_enemy {
				terminated = true
				break
			}

			// Check Phase Blocks in active dimension
			if (tile == .phase_block_alpha && g.active_dimension == .alpha)
				|| (tile == .phase_block_beta && g.active_dimension == .beta) {
				terminated = true
				break
			}

			if tile == .laser_prism_slash {
				// '/' prism reflection:
				// UP -> RIGHT, DOWN -> LEFT, LEFT -> DOWN, RIGHT -> UP
				g.laser_segments << LaserSegment{ x1: cx, y1: cy, x2: hit_x, y2: hit_y }
				g.medusa_laser_active = true
				cx = hit_x
				cy = hit_y
				cur_dir = match cur_dir {
					.up { Direction.right }
					.down { Direction.left }
					.left { Direction.down }
					.right { Direction.up }
				}
				break
			} else if tile == .laser_prism_backslash {
				// '\' prism reflection:
				// UP -> LEFT, DOWN -> RIGHT, LEFT -> UP, RIGHT -> DOWN
				g.laser_segments << LaserSegment{ x1: cx, y1: cy, x2: hit_x, y2: hit_y }
				g.medusa_laser_active = true
				cx = hit_x
				cy = hit_y
				cur_dir = match cur_dir {
					.up { Direction.left }
					.down { Direction.right }
					.left { Direction.up }
					.right { Direction.down }
				}
				break
			} else if tile == .wall || tile == .rock || tile == .tree
				|| (tile == .toggle_laser_gate && !g.gate_open)
				|| (tile == .gate_channel_1 && !g.channels_open[0])
				|| (tile == .gate_channel_2 && !g.channels_open[1])
				|| (tile == .timed_laser_barrier && g.is_pulse_active) {
				terminated = true
				break
			}
		}

		if terminated {
			if cx != hit_x || cy != hit_y {
				g.laser_segments << LaserSegment{ x1: cx, y1: cy, x2: hit_x, y2: hit_y }
				g.medusa_laser_active = true
				g.laser_x1 = cx
				g.laser_y1 = cy
				g.laser_x2 = hit_x
				g.laser_y2 = hit_y
			}
			break
		}
	}
}

// --------------------------------------------------
// Player Movement & Interaction
// --------------------------------------------------

pub fn (mut g Game) move_lolo(dir Direction) (bool, bool, bool, bool, bool, bool) {
	if g.status != .playing || g.is_sliding {
		return false, false, false, false, false, false
	}
	g.lolo.dir = dir

	mut nx := g.lolo.x
	mut ny := g.lolo.y
	match dir {
		.up { ny-- }
		.down { ny++ }
		.left { nx-- }
		.right { nx++ }
	}

	if nx < 0 || nx >= grid_cols || ny < 0 || ny >= grid_rows {
		return false, false, false, false, false, false
	}

	g.record_history()

	mut s_step := false
	mut s_heart := false
	mut s_push := false
	mut s_chest := false
	mut s_vic := false
	mut s_hammer := false

	target_tile := g.grid[ny][nx]
	target_ent := g.entities[ny][nx]

	// Phase block solid check
	if (target_tile == .phase_block_alpha && g.active_dimension == .alpha)
		|| (target_tile == .phase_block_beta && g.active_dimension == .beta) {
		return false, false, false, false, false, false
	}

	// Toggle laser gate
	if target_tile == .toggle_laser_gate && !g.gate_open {
		return false, false, false, false, false, false
	}

	// Locked Gate
	if target_tile == .locked_gate {
		if g.lolo.keys > 0 {
			g.lolo.keys--
			g.grid[ny][nx] = .grass
			g.lolo.x = nx
			g.lolo.y = ny
			g.moves_count++
			g.log_recorded_move(dir, false)
			return true, false, false, false, false, false
		} else {
			return false, false, false, false, false, false
		}
	}

	// Check Enemy or Pushable Egg
	for mut enemy in g.enemies {
		if enemy.x == nx && enemy.y == ny {
			if enemy.is_egg {
				mut bx := nx
				mut by := ny
				match dir {
					.up { by-- }
					.down { by++ }
					.left { bx-- }
					.right { bx++ }
				}
				if bx >= 0 && bx < grid_cols && by >= 0 && by < grid_rows {
					dest_tile := g.grid[by][bx]
					dest_ent := g.entities[by][bx]
					if dest_ent == .none {
						if dest_tile == .water || dest_tile == .lava {
							// Egg pushed into water floats as bridge
							enemy.x = -10
							enemy.y = -10
							enemy.is_egg = false
							g.grid[by][bx] = .bridge
							g.lolo.x = nx
							g.lolo.y = ny
							g.moves_count++
							g.log_recorded_move(dir, false)
							return true, false, true, false, false, false
						} else if dest_tile == .grass || dest_tile == .bridge || dest_tile == .ice || dest_tile == .pressure_plate {
							enemy.x = bx
							enemy.y = by
							g.lolo.x = nx
							g.lolo.y = ny
							g.moves_count++
							g.log_recorded_move(dir, false)
							return true, false, true, false, false, false
						}
					}
				}
				return false, false, false, false, false, false
			} else {
				// Blocked by living enemy
				if enemy.kind == .snakey || enemy.kind == .gol || enemy.kind == .rocky || enemy.kind == .medusa {
					return false, false, false, false, false, false
				}
			}
		}
	}

	// Pushable Emerald Block
	if target_ent == .emerald_frame {
		mut bx := nx
		mut by := ny
		match dir {
			.up { by-- }
			.down { by++ }
			.left { bx-- }
			.right { bx++ }
		}
		if bx >= 0 && bx < grid_cols && by >= 0 && by < grid_rows {
			dest_tile := g.grid[by][bx]
			dest_ent := g.entities[by][bx]
			if dest_ent == .none {
				if dest_tile == .water || dest_tile == .lava {
					g.entities[ny][nx] = .none
					g.grid[by][bx] = .bridge
					g.lolo.x = nx
					g.lolo.y = ny
					g.moves_count++
					g.log_recorded_move(dir, false)
					return true, false, true, false, false, false
				} else if dest_tile == .grass || dest_tile == .bridge || dest_tile == .ice || dest_tile == .pressure_plate {
					g.entities[ny][nx] = .none
					g.entities[by][bx] = .emerald_frame
					g.lolo.x = nx
					g.lolo.y = ny
					g.moves_count++
					g.log_recorded_move(dir, false)
					return true, false, true, false, false, false
				}
			}
		}
		return false, false, false, false, false, false
	}

	// Rotatable Laser Prism
	if target_tile == .laser_prism_slash {
		g.grid[ny][nx] = .laser_prism_backslash
		s_step = true
		return true, false, false, false, false, false
	} else if target_tile == .laser_prism_backslash {
		g.grid[ny][nx] = .laser_prism_slash
		s_step = true
		return true, false, false, false, false, false
	}

	// Blocked by solid obstacles and laser gates
	if target_tile == .wall || target_tile == .rock || target_tile == .tree || target_tile == .water || target_tile == .lava
		|| (target_tile == .toggle_laser_gate && !g.gate_open)
		|| (target_tile == .gate_channel_1 && !g.channels_open[0])
		|| (target_tile == .gate_channel_2 && !g.channels_open[1])
		|| (target_tile == .timed_laser_barrier && g.is_pulse_active) {
		if target_tile == .rock && g.lolo.hammers > 0 {
			g.lolo.hammers--
			g.grid[ny][nx] = .grass
			s_hammer = true
		}
		return false, false, false, false, false, s_hammer
	}

	// Items & Entities
	match target_ent {
		.holo_terminal {
			g.is_dialogue_open = true
			g.active_dialogue = if g.current_level.lore_text != '' {
				g.current_level.lore_text
			} else {
				'CYBER LOG: FACILITY SENSORS ACTIVE. POWER CORES CHARGE EXIT GATEWAY.'
			}
			return false, false, false, false, false, false
		}
		.heart_frame {
			g.entities[ny][nx] = .none
			g.hearts_remaining--
			g.score += 100
			g.lolo.shots += 2
			s_heart = true
			if g.hearts_remaining == 0 {
				g.chest_open = true
			}
		}
		.key_item {
			g.entities[ny][nx] = .none
			g.lolo.keys++
			s_step = true
		}
		.hammer {
			g.entities[ny][nx] = .none
			g.lolo.hammers++
			s_hammer = true
		}
		.speed_boots {
			g.entities[ny][nx] = .none
			g.lolo.speed_boost = 10.0
			s_step = true
		}
		.chest {
			if g.chest_open {
				if !g.door_open {
					g.door_open = true
					g.score += 500
					s_chest = true
				}
				g.entities[ny][nx] = .none
				g.lolo.x = nx
				g.lolo.y = ny
				g.log_recorded_move(dir, false)
				return true, s_heart, false, s_chest, false, false
			}
			return false, s_heart, false, false, false, false
		}
		.door {
			if g.door_open {
				g.score += 1000
				g.status = .level_clear

				sec := int(g.level_time_ms / 1000)
				gold := if g.current_level.target_gold_sec > 0 { g.current_level.target_gold_sec } else { 15 }
				silver := if g.current_level.target_silver_sec > 0 { g.current_level.target_silver_sec } else { 30 }
				bronze := if g.current_level.target_bronze_sec > 0 { g.current_level.target_bronze_sec } else { 60 }
				g.earned_medal = if sec <= gold {
					'GOLD'
				} else if sec <= silver {
					'SILVER'
				} else if sec <= bronze {
					'BRONZE'
				} else {
					'NONE'
				}

				g.status_msg = 'SECTOR CLEAR! MEDAL: ${g.earned_medal}'
				g.save_personal_best()
				g.active_replay_moves = g.recorded_moves.clone()
				return true, false, false, false, true, false
			}
			return false, false, false, false, false, false
		}
		else {}
	}

	// Warp Portal
	if (target_tile == .warp_a || target_tile == .warp_b) && g.warp_cooldown <= 0 {
		target_warp := if target_tile == .warp_a { TileType.warp_b } else { TileType.warp_a }
		for r in 0 .. grid_rows {
			for c in 0 .. grid_cols {
				if g.grid[r][c] == target_warp {
					g.lolo.x = c
					g.lolo.y = r
					g.warp_cooldown = 1.0
					g.moves_count++
					g.log_recorded_move(dir, false)
					return true, s_heart, false, s_chest, false, s_hammer
				}
			}
		}
	}

	g.lolo.x = nx
	g.lolo.y = ny
	g.moves_count++
	g.log_recorded_move(dir, false)
	s_step = true

	// Check if stepping onto Ice
	if target_tile == .ice {
		g.is_sliding = true
		g.slide_dir = dir
	}

	return s_step, s_heart, s_push, s_chest, s_vic, s_hammer
}

fn (mut g Game) log_recorded_move(dir Direction, is_shot bool) {
	g.recorded_moves << RecordedMove{
		dir:       dir
		is_shot:   is_shot
		timestamp: g.level_time_ms
	}
}

fn (mut g Game) save_personal_best() {
	idx := g.current_level_idx
	if g.pb_times[idx] == 0 || g.level_time_ms < g.pb_times[idx] {
		g.pb_times[idx] = g.level_time_ms
	}
	if g.pb_moves[idx] == 0 || g.moves_count < g.pb_moves[idx] {
		g.pb_moves[idx] = g.moves_count
	}

	// Check speed demon badge
	if g.level_time_ms < 15000 {
		g.unlock_badge(.speed_demon)
	}
	if g.moves_count <= 25 {
		g.unlock_badge(.minimalist)
	}
}

pub fn (mut g Game) fire_magic_shot() bool {
	if g.status != .playing || g.lolo.shots <= 0 || g.magic_shot.active || g.current_level.rule_pacifist {
		return false
	}
	g.lolo.shots--
	g.magic_shot.active = true
	g.magic_shot.x = f64(g.lolo.x)
	g.magic_shot.y = f64(g.lolo.y)
	match g.lolo.dir {
		.up {
			g.magic_shot.dx = 0
			g.magic_shot.dy = -1
		}
		.down {
			g.magic_shot.dx = 0
			g.magic_shot.dy = 1
		}
		.left {
			g.magic_shot.dx = -1
			g.magic_shot.dy = 0
		}
		.right {
			g.magic_shot.dx = 1
			g.magic_shot.dy = 0
		}
	}
	g.log_recorded_move(g.lolo.dir, true)
	return true
}

fn (mut g Game) step_ice_slide() {
	mut nx := g.lolo.x
	mut ny := g.lolo.y
	match g.slide_dir {
		.up { ny-- }
		.down { ny++ }
		.left { nx-- }
		.right { nx++ }
	}

	if nx < 0 || nx >= grid_cols || ny < 0 || ny >= grid_rows {
		g.is_sliding = false
		return
	}

	tile := g.grid[ny][nx]
	ent := g.entities[ny][nx]

	if tile == .wall || tile == .rock || tile == .tree || ent != .none {
		g.is_sliding = false
		return
	}

	g.lolo.x = nx
	g.lolo.y = ny
	if tile != .ice {
		g.is_sliding = false
	}
}

fn (mut g Game) step_lolo_in_direction(dir Direction) {
	mut nx := g.lolo.x
	mut ny := g.lolo.y
	match dir {
		.up { ny-- }
		.down { ny++ }
		.left { nx-- }
		.right { nx++ }
	}
	if nx >= 0 && nx < grid_cols && ny >= 0 && ny < grid_rows {
		tile := g.grid[ny][nx]
		ent := g.entities[ny][nx]
		if tile != .wall && tile != .rock && tile != .tree && ent == .none {
			g.lolo.x = nx
			g.lolo.y = ny
		}
	}
}

fn (mut g Game) update_enemies_ai(dt f64) {
	for mut enemy in g.enemies {
		if enemy.x < 0 || enemy.x >= grid_cols || enemy.y < 0 || enemy.y >= grid_rows {
			continue
		}

		if enemy.is_egg {
			enemy.egg_timer -= dt
			if enemy.egg_timer <= 0 {
				enemy.is_egg = false
			}
			continue
		}

		enemy.move_timer += dt

		match enemy.kind {
			.alma {
				if enemy.move_timer >= 0.40 {
					enemy.move_timer = 0
					dx := if g.lolo.x > enemy.x { 1 } else if g.lolo.x < enemy.x { -1 } else { 0 }
					dy := if g.lolo.y > enemy.y { 1 } else if g.lolo.y < enemy.y { -1 } else { 0 }
					if dx != 0 && g.is_valid_enemy_move(enemy.x + dx, enemy.y) {
						enemy.x += dx
					} else if dy != 0 && g.is_valid_enemy_move(enemy.x, enemy.y + dy) {
						enemy.y += dy
					}
				}
			}
			.rocky {
				speed := if enemy.charge_active { 0.20 } else { 0.70 }
				if enemy.move_timer >= speed {
					enemy.move_timer = 0
					if !enemy.charge_active {
						if enemy.x == g.lolo.x {
							enemy.charge_active = true
							enemy.charge_dir = if g.lolo.y > enemy.y { .down } else { .up }
						} else if enemy.y == g.lolo.y {
							enemy.charge_active = true
							enemy.charge_dir = if g.lolo.x > enemy.x { .right } else { .left }
						}
					}
					if enemy.charge_active {
						mut nx := enemy.x
						mut ny := enemy.y
						match enemy.charge_dir {
							.up { ny-- }
							.down { ny++ }
							.left { nx-- }
							.right { nx++ }
						}
						if g.is_valid_enemy_move(nx, ny) {
							enemy.x = nx
							enemy.y = ny
						} else {
							enemy.charge_active = false
						}
					}
				}
			}
			.wisp {
				// Boo Ghost: Stalks only when player looks away
				mut is_facing_wisp := false
				if g.lolo.dir == .left && enemy.x < g.lolo.x {
					is_facing_wisp = true
				} else if g.lolo.dir == .right && enemy.x > g.lolo.x {
					is_facing_wisp = true
				} else if g.lolo.dir == .up && enemy.y < g.lolo.y {
					is_facing_wisp = true
				} else if g.lolo.dir == .down && enemy.y > g.lolo.y {
					is_facing_wisp = true
				}

				if !is_facing_wisp && enemy.move_timer >= 0.50 {
					enemy.move_timer = 0
					dx := if g.lolo.x > enemy.x { 1 } else if g.lolo.x < enemy.x { -1 } else { 0 }
					dy := if g.lolo.y > enemy.y { 1 } else if g.lolo.y < enemy.y { -1 } else { 0 }
					if dx != 0 && g.is_valid_enemy_move(enemy.x + dx, enemy.y) {
						enemy.x += dx
					} else if dy != 0 && g.is_valid_enemy_move(enemy.x, enemy.y + dy) {
						enemy.y += dy
					}
				}
			}
			else {}
		}

		// Collision check with Lolo
		if enemy.x == g.lolo.x && enemy.y == g.lolo.y {
			if enemy.kind == .spike_trap && enemy.trap_active {
				g.kill_lolo('ELIMINATED BY TESLA ELECTRIC SPIKE TRAP!')
			} else if enemy.kind != .snakey && enemy.kind != .spike_trap && !enemy.is_asleep {
				if g.lolo.speed_boost <= 0 {
					g.kill_lolo('CAPTURED BY MECHA PATROL DRONE!')
				}
			}
		}
	}
}

fn (g &Game) is_valid_enemy_move(x int, y int) bool {
	if x < 0 || x >= grid_cols || y < 0 || y >= grid_rows {
		return false
	}
	tile := g.grid[y][x]
	ent := g.entities[y][x]
	if tile == .wall || tile == .rock || tile == .tree || tile == .water || tile == .lava || ent != .none {
		return false
	}
	return true
}

fn (mut g Game) kill_lolo(msg string) {
	g.lolo.is_dead = true
	g.status = .lost
	g.status_msg = msg
	if g.lives > 1 {
		g.lives--
	}
}

// --------------------------------------------------
// Instant Ghost Replay Engine
// --------------------------------------------------

pub fn (mut g Game) start_replay() {
	if g.active_replay_moves.len == 0 {
		return
	}
	g.init_level(g.current_level)
	g.is_replaying = true
	g.replay_move_idx = 0
	g.replay_timer = 0
}

fn (mut g Game) step_replay(dt f64) {
	if g.replay_move_idx >= g.active_replay_moves.len {
		g.is_replaying = false
		return
	}
	g.replay_timer += dt
	if g.replay_timer >= 0.15 {
		g.replay_timer = 0
		rec := g.active_replay_moves[g.replay_move_idx]
		if rec.is_phase {
			g.toggle_dimension()
		} else if rec.is_shot {
			g.fire_magic_shot()
		} else {
			g.move_lolo(rec.dir)
		}
		g.replay_move_idx++
	}
}

// --------------------------------------------------
// Undo Step History
// --------------------------------------------------

fn (mut g Game) record_history() {
	mut current_enemies := []Enemy{}
	for e in g.enemies {
		current_enemies << e
	}
	g.history << MoveStep{
		dir:          g.lolo.dir
		shots_before: g.lolo.shots
		keys_before:  g.lolo.keys
		grid:         g.grid
		entities:     g.entities
		enemies:      current_enemies
	}
}

pub fn (mut g Game) undo() bool {
	if g.history.len == 0 {
		return false
	}
	last := g.history.pop()
	g.grid = last.grid
	g.entities = last.entities
	g.lolo.dir = last.dir
	g.lolo.shots = last.shots_before
	g.lolo.keys = last.keys_before
	g.enemies = last.enemies
	if g.moves_count > 0 {
		g.moves_count--
	}
	return true
}

// --------------------------------------------------
// AI Reachability Solver & Hint System
// --------------------------------------------------

pub fn (g &Game) verify_level_solvability() bool {
	mut spawn_x := -1
	mut spawn_y := -1
	for r in 0 .. grid_rows {
		for c in 0 .. grid_cols {
			if g.editor_level.entities[r][c] == .lolo_spawn {
				spawn_x = c
				spawn_y = r
				break
			}
		}
	}
	if spawn_x == -1 {
		return false
	}

	// BFS Reachable flood
	mut visited := [11][11]bool{}
	mut queue := []Point{}
	queue << Point{ x: spawn_x, y: spawn_y }
	visited[spawn_y][spawn_x] = true

	for queue.len > 0 {
		pt := queue[0]
		queue.delete(0)

		dirs := [Point{ x: 0, y: -1 }, Point{ x: 0, y: 1 }, Point{ x: -1, y: 0 }, Point{ x: 1, y: 0 }]
		for d in dirs {
			nx := pt.x + d.x
			ny := pt.y + d.y
			if nx >= 0 && nx < grid_cols && ny >= 0 && ny < grid_rows && !visited[ny][nx] {
				tile := g.editor_level.grid[ny][nx]
				if tile != .wall && tile != .rock && tile != .tree && tile != .water && tile != .lava {
					visited[ny][nx] = true
					queue << Point{ x: nx, y: ny }
				}
			}
		}
	}

	// Verify all hearts, chest, and door are reachable
	for r in 0 .. grid_rows {
		for c in 0 .. grid_cols {
			ent := g.editor_level.entities[r][c]
			if ent == .heart_frame || ent == .chest || ent == .door {
				if !visited[r][c] {
					return false
				}
			}
		}
	}
	return true
}

pub fn (g &Game) get_hint_path() []Point {
	mut target_x := -1
	mut target_y := -1

	// Target 1: Closest Heart
	mut min_dist := 999
	for r in 0 .. grid_rows {
		for c in 0 .. grid_cols {
			if g.entities[r][c] == .heart_frame {
				dist := math_abs(c - g.lolo.x) + math_abs(r - g.lolo.y)
				if dist < min_dist {
					min_dist = dist
					target_x = c
					target_y = r
				}
			}
		}
	}

	// Target 2: Open Chest / Door
	if target_x == -1 {
		for r in 0 .. grid_rows {
			for c in 0 .. grid_cols {
				if g.entities[r][c] == .chest || g.entities[r][c] == .door {
					target_x = c
					target_y = r
					break
				}
			}
		}
	}

	if target_x == -1 {
		return []Point{}
	}

	// BFS Pathfinding
	mut parent := map[string]Point{}
	mut visited := [11][11]bool{}
	mut queue := []Point{}
	start := Point{ x: g.lolo.x, y: g.lolo.y }
	queue << start
	visited[start.y][start.x] = true

	mut found := false
	for queue.len > 0 {
		curr := queue[0]
		queue.delete(0)

		if curr.x == target_x && curr.y == target_y {
			found = true
			break
		}

		dirs := [Point{ x: 0, y: -1 }, Point{ x: 0, y: 1 }, Point{ x: -1, y: 0 }, Point{ x: 1, y: 0 }]
		for d in dirs {
			nx := curr.x + d.x
			ny := curr.y + d.y
			if nx >= 0 && nx < grid_cols && ny >= 0 && ny < grid_rows && !visited[ny][nx] {
				tile := g.grid[ny][nx]
				if tile != .wall && tile != .rock && tile != .tree && tile != .water && tile != .lava {
					visited[ny][nx] = true
					parent['${nx},${ny}'] = curr
					queue << Point{ x: nx, y: ny }
				}
			}
		}
	}

	if !found {
		return []Point{}
	}

	mut path := []Point{}
	mut cur := Point{ x: target_x, y: target_y }
	for cur.x != start.x || cur.y != start.y {
		path << cur
		cur = parent['${cur.x},${cur.y}']
	}
	return path
}

fn math_abs(a int) int {
	return if a < 0 { -a } else { a }
}

// --------------------------------------------------
// Level Code Sharing & Serialization
// --------------------------------------------------

pub fn (g &Game) export_cyber_code() string {
	mut code := 'CYBER-'
	theme_digit := int(g.editor_level.theme)
	code += '${theme_digit}'

	for r in 0 .. grid_rows {
		for c in 0 .. grid_cols {
			t := int(g.editor_level.grid[r][c])
			e := int(g.editor_level.entities[r][c])
			code += '${t:x}${e:x}'
		}
	}
	return code
}

pub fn (mut g Game) import_cyber_code(code string) bool {
	if !code.starts_with('CYBER-') || code.len < 128 {
		return false
	}
	theme_idx := int(code[6] - `0`)
	g.editor_level.theme = if theme_idx >= 0 && theme_idx < 6 {
		unsafe { LevelTheme(theme_idx) }
	} else {
		LevelTheme.castle
	}

	mut ptr := 7
	for r in 0 .. grid_rows {
		for c in 0 .. grid_cols {
			if ptr + 1 >= code.len {
				break
			}
			t_val := hex_char_to_int(code[ptr])
			e_val := hex_char_to_int(code[ptr + 1])
			g.editor_level.grid[r][c] = unsafe { TileType(t_val) }
			g.editor_level.entities[r][c] = unsafe { EntityType(e_val) }
			ptr += 2
		}
	}
	return true
}

fn hex_char_to_int(ch u8) int {
	if ch >= `0` && ch <= `9` {
		return int(ch - `0`)
	}
	if ch >= `a` && ch <= `f` {
		return int(ch - `a` + 10)
	}
	if ch >= `A` && ch <= `F` {
		return int(ch - `A` + 10)
	}
	return 0
}

// --------------------------------------------------
// Mario Maker Level Editor Tools & Actions
// --------------------------------------------------

pub fn (mut g Game) handle_editor_click(col int, row int, is_right_click bool) {
	if col < 0 || col >= grid_cols || row < 0 || row >= grid_rows {
		return
	}

	if is_right_click || g.editor_tool == .eraser {
		g.editor_level.grid[row][col] = .grass
		g.editor_level.entities[row][col] = .none
		return
	}

	match g.editor_tool {
		.pencil {
			g.apply_editor_brush_cell(col, row)
		}
		.line {
			if g.line_start_col < 0 {
				g.line_start_col = col
				g.line_start_row = row
			} else {
				g.editor_line_draw(g.line_start_col, g.line_start_row, col, row)
				g.line_start_col = -1
				g.line_start_row = -1
			}
		}
		.fill {
			g.editor_flood_fill(col, row)
		}
		.rect {
			if g.rect_start_col < 0 {
				g.rect_start_col = col
				g.rect_start_row = row
			} else {
				g.editor_rect_fill(g.rect_start_col, g.rect_start_row, col, row)
				g.rect_start_col = -1
				g.rect_start_row = -1
			}
		}
		.prefab {
			g.editor_apply_prefab(col, row, g.selected_prefab)
		}
		else {}
	}
}

fn (mut g Game) editor_line_draw(x0 int, y0 int, x1 int, y1 int) {
	dx := if x1 > x0 { x1 - x0 } else { x0 - x1 }
	dy := if y1 > y0 { y1 - y0 } else { y0 - y1 }
	sx := if x0 < x1 { 1 } else { -1 }
	sy := if y0 < y1 { 1 } else { -1 }
	mut err := dx - dy
	mut cx := x0
	mut cy := y0

	for {
		if cx >= 0 && cx < grid_cols && cy >= 0 && cy < grid_rows {
			g.apply_editor_brush_cell(cx, cy)
		}
		if cx == x1 && cy == y1 {
			break
		}
		e2 := 2 * err
		if e2 > -dy {
			err -= dy
			cx += sx
		}
		if e2 < dx {
			err += dx
			cy += sy
		}
	}
}

fn (mut g Game) editor_apply_prefab(start_c int, start_r int, prefab_id int) {
	match prefab_id {
		0 {
			// Mirror Rig: 2x2 '/' and '\' crystal prism pair with target frame
			if start_c + 2 <= grid_cols && start_r + 2 <= grid_rows {
				g.editor_level.grid[start_r][start_c] = .laser_prism_slash
				g.editor_level.grid[start_r][start_c + 1] = .laser_prism_backslash
				g.editor_level.entities[start_r + 1][start_c] = .emerald_frame
				g.editor_level.entities[start_r + 1][start_c + 1] = .heart_frame
			}
		}
		1 {
			// Warp Hub: 3x3 Warp A and Warp B surrounded by stone barriers
			if start_c + 3 <= grid_cols && start_r + 3 <= grid_rows {
				for r in 0 .. 3 {
					for c in 0 .. 3 {
						g.editor_level.grid[start_r + r][start_c + c] = .rock
					}
				}
				g.editor_level.grid[start_r + 1][start_c + 1] = .warp_a
				g.editor_level.grid[start_r + 2][start_c + 1] = .warp_b
			}
		}
		2 {
			// Conveyor Loop: 3x3 Continuous Clockwise Loop
			if start_c + 3 <= grid_cols && start_r + 3 <= grid_rows {
				g.editor_level.grid[start_r][start_c] = .conveyor_right
				g.editor_level.grid[start_r][start_c + 1] = .conveyor_right
				g.editor_level.grid[start_r][start_c + 2] = .conveyor_down
				g.editor_level.grid[start_r + 1][start_c + 2] = .conveyor_down
				g.editor_level.grid[start_r + 2][start_c + 2] = .conveyor_left
				g.editor_level.grid[start_r + 2][start_c + 1] = .conveyor_left
				g.editor_level.grid[start_r + 2][start_c] = .conveyor_up
				g.editor_level.grid[start_r + 1][start_c] = .conveyor_up
				g.editor_level.entities[start_r + 1][start_c + 1] = .heart_frame
			}
		}
		3 {
			// Turret Bunker: Medusa with protective Emerald Shields
			if start_c + 3 <= grid_cols && start_r + 3 <= grid_rows {
				g.editor_level.entities[start_r + 1][start_c + 1] = .medusa
				g.editor_level.entities[start_r + 1][start_c] = .emerald_frame
				g.editor_level.entities[start_r + 1][start_c + 2] = .emerald_frame
				g.editor_level.entities[start_r + 2][start_c + 1] = .emerald_frame
			}
		}
		else {
			// Pressure Gate: Plate wired to Laser Gate
			if start_c + 3 <= grid_cols && start_r + 2 <= grid_rows {
				g.editor_level.grid[start_r][start_c] = .pressure_plate
				g.editor_level.entities[start_r][start_c + 1] = .emerald_frame
				g.editor_level.grid[start_r + 1][start_c + 2] = .toggle_laser_gate
			}
		}
	}
}

fn (mut g Game) apply_editor_brush_cell(col int, row int) {
	if g.is_entity_selected {
		if g.selected_entity == .lolo_spawn || g.selected_entity == .chest || g.selected_entity == .door {
			for r in 0 .. grid_rows {
				for c in 0 .. grid_cols {
					if g.editor_level.entities[r][c] == g.selected_entity {
						g.editor_level.entities[r][c] = .none
					}
				}
			}
		}
		g.editor_level.entities[row][col] = g.selected_entity
	} else {
		if g.selected_tile == .warp_a || g.selected_tile == .warp_b {
			for r in 0 .. grid_rows {
				for c in 0 .. grid_cols {
					if g.editor_level.grid[r][c] == g.selected_tile {
						g.editor_level.grid[r][c] = .grass
					}
				}
			}
		}
		g.editor_level.grid[row][col] = g.selected_tile
	}
}

fn (mut g Game) editor_flood_fill(start_col int, start_row int) {
	if g.is_entity_selected {
		return
	}
	target_tile := g.editor_level.grid[start_row][start_col]
	if target_tile == g.selected_tile {
		return
	}

	mut visited := [11][11]bool{}
	mut queue := []Point{}
	queue << Point{ x: start_col, y: start_row }
	visited[start_row][start_col] = true

	for queue.len > 0 {
		pt := queue[0]
		queue.delete(0)
		g.editor_level.grid[pt.y][pt.x] = g.selected_tile

		dirs := [Point{ x: 0, y: -1 }, Point{ x: 0, y: 1 }, Point{ x: -1, y: 0 }, Point{ x: 1, y: 0 }]
		for d in dirs {
			nx := pt.x + d.x
			ny := pt.y + d.y
			if nx >= 0 && nx < grid_cols && ny >= 0 && ny < grid_rows && !visited[ny][nx] {
				if g.editor_level.grid[ny][nx] == target_tile {
					visited[ny][nx] = true
					queue << Point{ x: nx, y: ny }
				}
			}
		}
	}
}

fn (mut g Game) editor_rect_fill(x1 int, y1 int, x2 int, y2 int) {
	min_x := if x1 < x2 { x1 } else { x2 }
	max_x := if x1 > x2 { x1 } else { x2 }
	min_y := if y1 < y2 { y1 } else { y2 }
	max_y := if y1 > y2 { y1 } else { y2 }

	for r in min_y .. max_y + 1 {
		for c in min_x .. max_x + 1 {
			if g.is_entity_selected {
				g.editor_level.entities[r][c] = g.selected_entity
			} else {
				g.editor_level.grid[r][c] = g.selected_tile
			}
		}
	}
}

pub fn (mut g Game) save_slot(slot_idx int) {
	if slot_idx >= 0 && slot_idx < 5 {
		g.custom_slots[slot_idx] = g.editor_level
		g.validation_msg = 'SLOT ${slot_idx + 1} SAVED!'
	}
}

pub fn (mut g Game) load_slot(slot_idx int) {
	if slot_idx >= 0 && slot_idx < 5 {
		g.editor_level = g.custom_slots[slot_idx]
		g.validation_msg = 'SLOT ${slot_idx + 1} LOADED!'
	}
}

pub fn (mut g Game) apply_template(template_name string) {
	match template_name {
		'BLANK' {
			g.editor_level = create_empty_level_theme('Blank Canvas', g.editor_level.theme)
		}
		'ISLAND' {
			g.editor_level = create_template_island(g.editor_level.theme)
		}
		'LABYRINTH' {
			g.editor_level = create_template_labyrinth(g.editor_level.theme)
		}
		'ICE CHAMBER' {
			g.editor_level = create_template_ice_chamber(g.editor_level.theme)
		}
		'FORTRESS' {
			g.editor_level = create_template_fortress(g.editor_level.theme)
		}
		else {}
	}
	g.validation_msg = 'APPLIED TEMPLATE: ${template_name}'
}

pub fn (mut g Game) toggle_editor_mode() {
	if g.mode == .play {
		g.mode = .editor
		g.is_testing_custom = false
	} else {
		g.mode = .play
	}
}

pub fn (mut g Game) test_play_custom_level() bool {
	mut lolo_count := 0
	mut chest_count := 0
	mut door_count := 0
	mut heart_count := 0

	for r in 0 .. grid_rows {
		for c in 0 .. grid_cols {
			ent := g.editor_level.entities[r][c]
			match ent {
				.lolo_spawn { lolo_count++ }
				.chest { chest_count++ }
				.door { door_count++ }
				.heart_frame { heart_count++ }
				else {}
			}
		}
	}

	if lolo_count != 1 {
		g.validation_msg = 'ERROR: NEED EXACTLY 1 LOLO SPAWN'
		return false
	}
	if door_count != 1 {
		g.validation_msg = 'ERROR: NEED EXACTLY 1 EXIT DOOR'
		return false
	}
	if chest_count != 1 {
		g.validation_msg = 'ERROR: NEED EXACTLY 1 JEWEL CHEST'
		return false
	}
	if heart_count < 1 {
		g.validation_msg = 'ERROR: NEED AT LEAST 1 HEART FRAME'
		return false
	}

	g.unlock_badge(.master_architect)
	g.init_level(g.editor_level)
	g.is_testing_custom = true
	g.mode = .play
	return true
}

// --------------------------------------------------
// Level Creators & Templates
// --------------------------------------------------

pub fn create_empty_level_theme(name string, theme LevelTheme) Level {
	mut lvl := Level{
		name:     name
		floor:    1
		password: 'CYBER'
		theme:    theme
	}
	for r in 0 .. grid_rows {
		for c in 0 .. grid_cols {
			if r == 0 || r == grid_rows - 1 || c == 0 || c == grid_cols - 1 {
				lvl.grid[r][c] = .wall
			} else {
				lvl.grid[r][c] = .grass
			}
			lvl.entities[r][c] = .none
		}
	}
	lvl.grid[0][5] = .grass
	lvl.entities[0][5] = .door
	lvl.entities[2][5] = .chest
	lvl.entities[6][5] = .heart_frame
	lvl.entities[9][5] = .lolo_spawn
	return lvl
}

fn create_template_island(theme LevelTheme) Level {
	mut lvl := create_empty_level_theme('Island Matrix', theme)
	for r in 2 .. 9 {
		for c in 2 .. 9 {
			if r == 2 || r == 8 || c == 2 || c == 8 {
				lvl.grid[r][c] = .water
			}
		}
	}
	lvl.grid[5][2] = .bridge
	lvl.grid[5][8] = .bridge
	return lvl
}

fn create_template_labyrinth(theme LevelTheme) Level {
	mut lvl := create_empty_level_theme('Labyrinth Core', theme)
	lvl.grid[2][2] = .wall
	lvl.grid[2][3] = .wall
	lvl.grid[2][4] = .wall
	lvl.grid[4][6] = .tree
	lvl.grid[4][7] = .tree
	lvl.grid[4][8] = .tree
	lvl.grid[6][2] = .rock
	lvl.grid[6][3] = .rock
	lvl.grid[6][4] = .rock
	return lvl
}

fn create_template_ice_chamber(theme LevelTheme) Level {
	mut lvl := create_empty_level_theme('Cryo Vault', theme)
	for r in 2 .. 9 {
		for c in 2 .. 9 {
			lvl.grid[r][c] = .ice
		}
	}
	lvl.grid[3][3] = .warp_a
	lvl.grid[7][7] = .warp_b
	return lvl
}

fn create_template_fortress(theme LevelTheme) Level {
	mut lvl := create_empty_level_theme('Apex Fortress', theme)
	for c in 1 .. 10 {
		lvl.grid[4][c] = .lava
	}
	lvl.grid[4][5] = .locked_gate
	lvl.entities[6][2] = .key_item
	lvl.entities[3][5] = .king_egger
	return lvl
}

// --------------------------------------------------
// 5 Featured Community Challenge Packs
// --------------------------------------------------

fn get_community_challenge_packs() []Level {
	mut list := []Level{}

	// Pack 1: Kaizo Cyber
	mut p1 := create_empty_level_theme('KAIZO CYBER', .haunted)
	p1.entities[4][3] = .don_medusa_h
	p1.entities[4][7] = .don_medusa_h
	p1.entities[6][5] = .emerald_frame
	p1.entities[7][5] = .emerald_frame
	list << p1

	// Pack 2: Laser Optics
	mut p2 := create_empty_level_theme('LASER OPTICS', .castle)
	p2.entities[4][2] = .medusa
	p2.grid[4][5] = .laser_prism_slash
	p2.grid[8][5] = .laser_prism_backslash
	list << p2

	// Pack 3: Quantum Shift
	mut p3 := create_empty_level_theme('QUANTUM SHIFT', .desert)
	p3.grid[3][4] = .phase_block_alpha
	p3.grid[3][6] = .phase_block_beta
	p3.grid[7][4] = .phase_block_beta
	p3.grid[7][6] = .phase_block_alpha
	list << p3

	// Pack 4: Conveyor Rush
	mut p4 := create_empty_level_theme('CONVEYOR RUSH', .forest)
	for c in 2 .. 9 {
		p4.grid[5][c] = .conveyor_right
	}
	list << p4

	// Pack 5: Apex Fortress
	mut p5 := create_template_fortress(.volcanic)
	list << p5

	return list
}

// --------------------------------------------------
// Master Campaign Trilogy: 50 Levels from Lolo 1-3
// --------------------------------------------------

fn get_all_campaign_levels() []Level {
	raw_rooms := [
		// --------------------------------------------------
		// ADVENTURES OF LOLO 1 (Floors 1 - 4)
		// --------------------------------------------------
		RoomDef{ name: 'First Steps', floor: 1, password: 'AAAA', theme: .castle, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . . . . C . . . . W',
			'W . . . . . . . . . W',
			'W . R . . . . . R . W',
			'W H . . H . H . . H W',
			'W . . B . . . B . . W',
			'W . . . . S . . . . W',
			'W . . . . . . . . . W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'Emerald Shields', floor: 1, password: 'BAAA', theme: .castle, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . H . W',
			'W . . . . B . . . . W',
			'W . B . M . . . B . W',
			'W . . . . . . . . . W',
			'W . . . B . B . . . W',
			'W . . . . S . . . . W',
			'W H . . . . . . . H W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'Serpent Crossing', floor: 1, password: 'CAAA', theme: .forest, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . . . W',
			'W ~ ~ ~ ~ . ~ ~ ~ ~ W',
			'W . . . . . . . . . W',
			'W . S . . S . . S . W',
			'W . . . . . . . . . W',
			'W H . . . H . . . H W',
			'W . . . . . . . . . W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'The Sleeping Sentry', floor: 1, password: 'DAAA', theme: .forest, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . . C . . . . . . W',
			'W . T T T . T T T . W',
			'W . T . . . . . T . W',
			'W . T . Z . . . T . W',
			'W . T . . . . . T . W',
			'W . T T . . . T T . W',
			'W H . . . . . . . H W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'Gol Dragon Fire', floor: 1, password: 'EAAA', theme: .forest, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . . . . C . . . . W',
			'W . G . . . . . G . W',
			'W . . . B . B . . . W',
			'W . . . . . . . . . W',
			'W . G . . . . . G . W',
			'W . . . . . . . . . W',
			'W H . H . . . H . H W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'Rocky Golem Charge', floor: 2, password: 'FAAA', theme: .desert, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . H . W',
			'W . . R . . . R . . W',
			'W . . . . . . . . . W',
			'W . . K . . . . . . W',
			'W . . . . . . . . . W',
			'W . R . . . . . R . W',
			'W H . . . . . . . H W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'Cryo Ice Slide', floor: 2, password: 'GAAA', theme: .ice, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . . . W',
			'W . I I I I I I I . W',
			'W . I . . . . . I . W',
			'W . I . H . H . I . W',
			'W . I . . . . . I . W',
			'W . I I I I I I I . W',
			'W . . . . . . . . . W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'Warp Portals', floor: 2, password: 'HAAA', theme: .ice, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . . . W',
			'W W W W . . . W W W W',
			'W H . 1 . . . 2 . H W',
			'W W W W . . . W W W W',
			'W . . . . . . . . . W',
			'W . . . . . . . . . W',
			'W . . . . H . . . . W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'Whale Current', floor: 2, password: 'IAAA', theme: .desert, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . . . W',
			'W . . . . . . . . . W',
			'W . . . . O . . . . W',
			'W . . . . . . . . . W',
			'W H . . . . . . . H W',
			'W . . . . . . . . . W',
			'W . . . . H . . . . W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'Gargoyle Skies', floor: 2, password: 'JAAA', theme: .desert, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . H . W',
			'W ~ ~ ~ . ~ . ~ ~ ~ W',
			'W . . . . Y . . . . W',
			'W ~ ~ ~ . ~ . ~ ~ ~ W',
			'W . . . . . . . . . W',
			'W . . . . . . . . . W',
			'W H . . . . . . . H W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'Phantom Ghost', floor: 3, password: 'KAAA', theme: .haunted, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . . . W',
			'W . . R . . . R . . W',
			'W . . . . P . . . . W',
			'W . . R . . . R . . W',
			'W H . . . . . . . H W',
			'W . . . . . . . . . W',
			'W . . . . H . . . . W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'Tesla Spikes', floor: 3, password: 'LAAA', theme: .haunted, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . . . W',
			'W . X . . . . . X . W',
			'W . . . . . . . . . W',
			'W . . . . H . . . . W',
			'W . . . . . . . . . W',
			'W . X . . . . . X . W',
			'W H . . . . . . . H W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'Key & Laser Gate', floor: 3, password: 'MAAA', theme: .volcanic, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . . . W',
			'W W W W W J W W W W W',
			'W . . . . . . . . . W',
			'W . . . . N . . . . W',
			'W . . . . . . . . . W',
			'W H . . . . . . . H W',
			'W . . . . . . . . . W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'Lava Crossing', floor: 3, password: 'NAAA', theme: .volcanic, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . . . W',
			'W V V V . V . V V V W',
			'W . . . . . . . . . W',
			'W . B . . . . . B . W',
			'W . . . . . . . . . W',
			'W H . . . . . . . H W',
			'W . . . . . . . . . W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'Speed Boosters', floor: 3, password: 'OAAA', theme: .volcanic, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . . . W',
			'W . . . . . . . . . W',
			'W . . . . . . . . . W',
			'W . M . . . . . M . W',
			'W . . . . . . . . . W',
			'W . B . . F . . B . W',
			'W H . . . . . . . H W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'Laser Optics Reflex', floor: 4, password: 'PAAA', theme: .castle, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . . . W',
			'W . M . . / . . . . W',
			'W . . . . . . . . . W',
			'W . . . . H . . . . W',
			'W . . . . . . . . . W',
			'W . . . . \\ . . M . W',
			'W H . B . . . B . H W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'Pressure Link', floor: 4, password: 'QAAA', theme: .castle, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . . . W',
			'W W W W W E W W W W W',
			'W . . . . . . . . . W',
			'W . . Q . . . . . . W',
			'W . . . . B . . . . W',
			'W . . . . . . . . . W',
			'W H . . . . . . . H W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'Quantum Dimensions', floor: 4, password: 'RAAA', theme: .haunted, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . . . W',
			'W . 8 . . . . . 9 . W',
			'W . . . . . . . . . W',
			'W . 9 . . H . . 8 . W',
			'W . . . . . . . . . W',
			'W . 8 . . . . . 9 . W',
			'W H . . . . . . . H W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'Conveyor Maze', floor: 4, password: 'SAAA', theme: .ice, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . . . W',
			'W . 4 4 4 4 4 4 4 . W',
			'W . . . . . . . . . W',
			'W . 5 5 5 5 5 5 5 . W',
			'W . . . . . . . . . W',
			'W H . . . . . . . H W',
			'W . . . . . . . . . W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'Castle Gatekeeper', floor: 4, password: 'TAAA', theme: .volcanic, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . . . W',
			'W V V V . V . V V V W',
			'W . . . . K . . . . W',
			'W . . . . . . . . . W',
			'W . B . . . . . B . W',
			'W . . . . . . . . . W',
			'W H . . . . . . . H W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },

		// --------------------------------------------------
		// ADVENTURES OF LOLO 2 (Floors 5 - 7)
		// --------------------------------------------------
		RoomDef{ name: 'Lolo 2 Genesis', floor: 5, password: 'ABAA', theme: .castle, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . . . W',
			'W . . . . S . . . . W',
			'W . B . . . . . B . W',
			'W . . . . H . . . . W',
			'W . B . . . . . B . W',
			'W . . . . S . . . . W',
			'W H . . . . . . . H W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'Dual Gobby Skies', floor: 5, password: 'BBAA', theme: .forest, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . H . W',
			'W ~ ~ ~ . ~ . ~ ~ ~ W',
			'W . Y . . . . . Y . W',
			'W ~ ~ ~ . ~ . ~ ~ ~ W',
			'W . . . . . . . . . W',
			'W . . . B . B . . . W',
			'W H . . . . . . . H W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'Turbine Moby Sea', floor: 5, password: 'CBAA', theme: .forest, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . . . W',
			'W . . . . O . . . . W',
			'W . ~ ~ ~ . ~ ~ ~ . W',
			'W . . . . H . . . . W',
			'W . ~ ~ ~ . ~ ~ ~ . W',
			'W . . . . O . . . . W',
			'W H . . . . . . . H W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'Cracked Rock Quarry', floor: 5, password: 'DBAA', theme: .desert, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . . . W',
			'W . R R R R R R R . W',
			'W . . . . . . . . . W',
			'W . . . . K . . . . W',
			'W . . . . . . . . . W',
			'W . R R R R R R R . W',
			'W H . . . . . . . H W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'Keycard Portcullis', floor: 5, password: 'EBAA', theme: .desert, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . . . W',
			'W W W W W J W W W W W',
			'W . . . . . . . . . W',
			'W . N . . . . . N . W',
			'W . . . . . . . . . W',
			'W W W W W J W W W W W',
			'W H . . . . . . . H W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'Sub-Zero Slide', floor: 6, password: 'FBAA', theme: .ice, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . . . W',
			'W . I I I . I I I . W',
			'W . I . . . . . I . W',
			'W . I . H . H . I . W',
			'W . I . . . . . I . W',
			'W . I I I . I I I . W',
			'W H . . . . . . . H W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'Twin Singularity', floor: 6, password: 'GBAA', theme: .ice, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . . . W',
			'W W W W . . . W W W W',
			'W H . 1 . . . 2 . H W',
			'W W W W . . . W W W W',
			'W . . . . . . . . . W',
			'W . . . . H . . . . W',
			'W . . . . . . . . . W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'Molten Magma Run', floor: 6, password: 'HBAA', theme: .volcanic, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . . . W',
			'W V V V . V . V V V W',
			'W . . . . . . . . . W',
			'W . B . . H . . B . W',
			'W . . . . . . . . . W',
			'W V V V . V . V V V W',
			'W H . . . . . . . H W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'Tesla Spikes Array', floor: 6, password: 'IBAA', theme: .haunted, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . . . W',
			'W . X . . . . . X . W',
			'W . . . . X . . . . W',
			'W . . . . H . . . . W',
			'W . . . . X . . . . W',
			'W . X . . . . . X . W',
			'W H . . . . . . . H W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'Overdrive Circuit', floor: 6, password: 'JBAA', theme: .volcanic, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . . . W',
			'W . . . . . . . . . W',
			'W . M . . . . . M . W',
			'W . . . . . . . . . W',
			'W . B . . F . . B . W',
			'W . M . . . . . M . W',
			'W H . . . . . . . H W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'Optics Laboratory', floor: 7, password: 'KBAA', theme: .castle, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . . . W',
			'W . M . . / . . . . W',
			'W . . . . . . . . . W',
			'W . . . . H . . . . W',
			'W . . . . . . . . . W',
			'W . . . . \\ . . M . W',
			'W H . B . . . B . H W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'Pressure Gate Array', floor: 7, password: 'LBAA', theme: .castle, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . . . W',
			'W W W W W E W W W W W',
			'W . . . . . . . . . W',
			'W . Q . . H . . Q . W',
			'W . . . . B . . . . W',
			'W W W W W E W W W W W',
			'W H . . . . . . . H W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'Phase Shift Alpha', floor: 7, password: 'MBAA', theme: .haunted, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . . . W',
			'W . 8 . . . . . 9 . W',
			'W . . . . . . . . . W',
			'W . 9 . . H . . 8 . W',
			'W . . . . . . . . . W',
			'W . 8 . . . . . 9 . W',
			'W H . . . . . . . H W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'Conveyor Express', floor: 7, password: 'NBAA', theme: .ice, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . . . W',
			'W . 4 4 4 4 4 4 4 . W',
			'W . . . . . . . . . W',
			'W . 5 5 5 5 5 5 5 . W',
			'W . . . . . . . . . W',
			'W H . . . . . . . H W',
			'W . . . . . . . . . W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'King Eggers Trap', floor: 7, password: 'OBAA', theme: .volcanic, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . . . W',
			'W V V V . V . V V V W',
			'W . . . . K . . . . W',
			'W . . . . . . . . . W',
			'W . B . . . . . B . W',
			'W . . . . . . . . . W',
			'W H . . . . . . . H W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },

		// --------------------------------------------------
		// ADVENTURES OF LOLO 3 (Floors 8 - 10)
		// --------------------------------------------------
		RoomDef{ name: 'Lolo 3 Overworld', floor: 8, password: 'ACAA', theme: .forest, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . . . W',
			'W . T T T . T T T . W',
			'W . . . . S . . . . W',
			'W . B . . H . . B . W',
			'W . . . . S . . . . W',
			'W . T T T . T T T . W',
			'W H . . . . . . . H W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'Whale Rapids', floor: 8, password: 'BCAA', theme: .forest, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . . . W',
			'W ~ ~ ~ . ~ . ~ ~ ~ W',
			'W . . . . O . . . . W',
			'W . . . . H . . . . W',
			'W . . . . O . . . . W',
			'W ~ ~ ~ . ~ . ~ ~ ~ W',
			'W H . . . . . . . H W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'Phantom Crypt', floor: 8, password: 'CCAA', theme: .haunted, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . . . W',
			'W . R . . . . . R . W',
			'W . . . . P . . . . W',
			'W . . . . H . . . . W',
			'W . . . . P . . . . W',
			'W . R . . . . . R . W',
			'W H . . . . . . . H W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'Titan Golem Arena', floor: 8, password: 'DCAA', theme: .desert, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . . . W',
			'W . R R . . . R R . W',
			'W . . . . K . . . . W',
			'W . . . . H . . . . W',
			'W . . . . K . . . . W',
			'W . R R . . . R R . W',
			'W H . . . . . . . H W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'Aero Gobby Patrol', floor: 8, password: 'ECAA', theme: .desert, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . . . W',
			'W ~ ~ ~ . ~ . ~ ~ ~ W',
			'W . Y . . H . . Y . W',
			'W ~ ~ ~ . ~ . ~ ~ ~ W',
			'W . . . . . . . . . W',
			'W . . . B . B . . . W',
			'W H . . . . . . . H W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'Cryo Ice Mirror', floor: 9, password: 'FCAA', theme: .ice, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . . . W',
			'W . I I I . I I I . W',
			'W . M . . / . . M . W',
			'W . I . . H . . I . W',
			'W . M . . \\ . . M . W',
			'W . I I I . I I I . W',
			'W H . B . . . B . H W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'Volcanic Caldron', floor: 9, password: 'GCAA', theme: .volcanic, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . . . W',
			'W V V V . V . V V V W',
			'W . . . . G . . . . W',
			'W . B . . H . . B . W',
			'W . . . . G . . . . W',
			'W V V V . V . V V V W',
			'W H . . . . . . . H W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'Quantum Paradox', floor: 9, password: 'HCAA', theme: .haunted, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . . . W',
			'W . 8 . 9 . 8 . 9 . W',
			'W . . . . . . . . . W',
			'W . 9 . . H . . 8 . W',
			'W . . . . . . . . . W',
			'W . 8 . 9 . 8 . 9 . W',
			'W H . . . . . . . H W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'Kinetic Storm', floor: 9, password: 'ICAA', theme: .ice, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . . . W',
			'W . 4 4 4 . 4 4 4 . W',
			'W . . . . . . . . . W',
			'W . 5 5 5 . 5 5 5 . W',
			'W . . . . H . . . . W',
			'W H . . . . . . . H W',
			'W . . . . . . . . . W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'Tesla Gauntlet', floor: 9, password: 'JCAA', theme: .haunted, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . . . W',
			'W . X . X . X . X . W',
			'W . . . . . . . . . W',
			'W . . . . H . . . . W',
			'W . . . . . . . . . W',
			'W . X . X . X . X . W',
			'W H . . . . . . . H W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'Don Medusa Fleet', floor: 10, password: 'KCAA', theme: .castle, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . . . W',
			'W . . . . . . . . . W',
			'W . M . . . . . M . W',
			'W . . . . H . . . . W',
			'W . M . . . . . M . W',
			'W . B . . . . . B . W',
			'W H . . . . . . . H W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'Quad Gol Artillery', floor: 10, password: 'LCAA', theme: .forest, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . . . W',
			'W . G . . . . . G . W',
			'W . . . B . B . . . W',
			'W . . . . H . . . . W',
			'W . . . B . B . . . W',
			'W . G . . . . . G . W',
			'W H . . . . . . . H W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'The Master Vault', floor: 10, password: 'MCAA', theme: .volcanic, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . . . W',
			'W W W W W J W W W W W',
			'W . N . . . . . N . W',
			'W . . . . H . . . . W',
			'W . N . . . . . N . W',
			'W W W W W J W W W W W',
			'W H . . . . . . . H W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'Grand Laser Array', floor: 10, password: 'NCAA', theme: .castle, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . . . W',
			'W . M . . / . . . . W',
			'W . . . . . . . . . W',
			'W . . . . H . . . . W',
			'W . . . . . . . . . W',
			'W . . . . \\ . . M . W',
			'W H . B . . . B . H W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'Final Showdown', floor: 10, password: 'OCAA', theme: .volcanic, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . . . W',
			'W V V V . V . V V V W',
			'W . . . . K . . . . W',
			'W . B . . H . . B . W',
			'W . . . . K . . . . W',
			'W V V V . V . V V V W',
			'W H . . . . . . . H W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },

		// --------------------------------------------------
		// ARCADE & MODERN INNOVATION BONUS WORLDS (Rooms 51 - 65)
		// --------------------------------------------------
		RoomDef{ name: 'Pac-Man Cyber Maze', floor: 11, password: 'PACA', theme: .haunted, rows: [
			'W W W W W D W W W W W',
			'W H . . W . . . W . H W',
			'W . W . W . C . W . W W',
			'W . W . . . . . . . W W',
			'W . . . W W . W W . . W',
			'W W . . P . F . P . . W',
			'W . . . W W . W W . . W',
			'W . W . . . . . . . W W',
			'W H . . W . . . W . H W',
			'W . . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'Mario Warp Pipes', floor: 11, password: 'MARA', theme: .forest, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . . . W',
			'W W W W . . . W W W W',
			'W H . 1 . T . 2 . . W',
			'W W W W . . . W W W W',
			'W . . . . . . . . . W',
			'W . T . . H . . T . W',
			'W H . . . . . . . H W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'Zelda Triforce Vault', floor: 11, password: 'ZELA', theme: .desert, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . . . . C . . . . W',
			'W W W W W J W W W W W',
			'W . R . . . . . R . W',
			'W . N . . H . . N . W',
			'W . R . . . . . R . W',
			'W W W W W J W W W W W',
			'W H . . . . . . . H W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'Space Invaders Field', floor: 11, password: 'INVA', theme: .castle, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . . . . C . . . . W',
			'W . G . G . G . G . W',
			'W . . . . . . . . . W',
			'W . B . B . B . B . W',
			'W . . . . . . . . . W',
			'W H . . H . H . . H W',
			'W . . . . . . . . . W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'Cyber Pong Optics Matrix', floor: 11, password: 'PONA', theme: .castle, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . . . W',
			'W . M . . / . . . . W',
			'W . . . . . . . . . W',
			'W . . . . H . . . . W',
			'W . . . . . . . . . W',
			'W . . . . \\ . . M . W',
			'W H . B . . . B . H W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'Hyper Conveyor Coaster', floor: 12, password: 'RUSA', theme: .ice, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . . . W',
			'W . 4 4 4 4 4 4 4 . W',
			'W . 4 . . . . . 5 . W',
			'W . 4 . . H . . 5 . W',
			'W . 4 . . . . . 5 . W',
			'W . 5 5 5 5 5 5 5 . W',
			'W H . . . . . . . H W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'Quantum Paradox Chamber', floor: 12, password: 'QUAA', theme: .haunted, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . . . W',
			'W . 8 . 9 . 8 . 9 . W',
			'W . 9 . 8 . 9 . 8 . W',
			'W . 8 . 9 . H . 9 . W',
			'W . 9 . 8 . 9 . 8 . W',
			'W . 8 . 9 . 8 . 9 . W',
			'W H . . . . . . . H W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'Bomberman Blast Grid', floor: 12, password: 'BOMA', theme: .volcanic, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . . . W',
			'W . R . R . R . R . W',
			'W . . Z . . . Z . . W',
			'W . R . R . R . R . W',
			'W . . . . H . . . . W',
			'W . R . R . R . R . W',
			'W H . . . . . . . H W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'Snake Egg Super Highway', floor: 12, password: 'SNKA', theme: .forest, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . . . W',
			'W ~ ~ ~ ~ . ~ ~ ~ ~ W',
			'W . S . . . . . S . W',
			'W ~ ~ ~ ~ . ~ ~ ~ ~ W',
			'W . S . . H . . S . W',
			'W ~ ~ ~ ~ . ~ ~ ~ ~ W',
			'W H . . . . . . . H W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'Lava Bridge Builder', floor: 12, password: 'LAVA', theme: .volcanic, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . . . W',
			'W V V V . V . V V V W',
			'W . . . . . . . . . W',
			'W . B . . H . . B . W',
			'W . . . . . . . . . W',
			'W V V V . V . V V V W',
			'W H . . . . . . . H W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'Laser Defense 3000', floor: 13, password: 'TURA', theme: .castle, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . . . W',
			'W . M . . / . . M . W',
			'W . . . . . . . . . W',
			'W . . . . H . . . . W',
			'W . . . . . . . . . W',
			'W . M . . \\ . . M . W',
			'W H . B . . . B . H W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'Ghostbusters Spook Manor', floor: 13, password: 'GHSA', theme: .haunted, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . . . W',
			'W . P . . . . . P . W',
			'W . . . . Z . . . . W',
			'W . . . . H . . . . W',
			'W . . . . Z . . . . W',
			'W . P . . . . . P . W',
			'W H . . . . . . . H W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'F-Zero Nitro Drift', floor: 13, password: 'FZRA', theme: .ice, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . . . W',
			'W . I I I I I I I . W',
			'W . I . . F . . I . W',
			'W . I . . H . . I . W',
			'W . I . . . . . I . W',
			'W . I I I I I I I . W',
			'W H . . . . . . . H W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'Sokoban Brain Vault', floor: 13, password: 'SOKA', theme: .desert, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . . . W',
			'W W W W W E W W W W W',
			'W . Q . . . . . Q . W',
			'W . . . B H B . . . W',
			'W . Q . . . . . Q . W',
			'W W W W W E W W W W W',
			'W H . . . . . . . H W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
		RoomDef{ name: 'Mecha Egger Kaizo Final', floor: 13, password: 'BOSS', theme: .volcanic, rows: [
			'W W W W W D W W W W W',
			'W . . . . . . . . . W',
			'W . C . . . . . . . W',
			'W V V V . V . V V V W',
			'W . . . . K . . . . W',
			'W . B . 1 H 2 . B . W',
			'W . . . . K . . . . W',
			'W V V V . V . V V V W',
			'W H . . . . . . . H W',
			'W . . . . L . . . . W',
			'W W W W W W W W W W W',
		] },
	]

	mut list := []Level{}
	for room in raw_rooms {
		list << parse_room_def(room)
	}
	return list
}

struct RoomDef {
	name     string
	floor    int
	password string
	theme    LevelTheme
	rows     []string
}

fn parse_room_def(def RoomDef) Level {
	mut lvl := Level{
		name:     def.name
		floor:    def.floor
		password: def.password
		theme:    def.theme
	}

	for r in 0 .. grid_rows {
		row_str := def.rows[r]
		tokens := row_str.split(' ')
		for c in 0 .. grid_cols {
			ch := if c < tokens.len { tokens[c] } else { '.' }
			match ch {
				'W' { lvl.grid[r][c] = .wall }
				'R' { lvl.grid[r][c] = .rock }
				'T' { lvl.grid[r][c] = .tree }
				'~' { lvl.grid[r][c] = .water }
				'V' { lvl.grid[r][c] = .lava }
				'I' { lvl.grid[r][c] = .ice }
				'1' { lvl.grid[r][c] = .warp_a }
				'2' { lvl.grid[r][c] = .warp_b }
				'J' { lvl.grid[r][c] = .locked_gate }
				'/' { lvl.grid[r][c] = .laser_prism_slash }
				'\\' { lvl.grid[r][c] = .laser_prism_backslash }
				'Q' { lvl.grid[r][c] = .pressure_plate }
				'E' { lvl.grid[r][c] = .toggle_laser_gate }
				'4' { lvl.grid[r][c] = .conveyor_right }
				'5' { lvl.grid[r][c] = .conveyor_left }
				'8' { lvl.grid[r][c] = .phase_block_alpha }
				'9' { lvl.grid[r][c] = .phase_block_beta }
				else { lvl.grid[r][c] = .grass }
			}

			match ch {
				'L' { lvl.entities[r][c] = .lolo_spawn }
				'D' { lvl.entities[r][c] = .door }
				'C' { lvl.entities[r][c] = .chest }
				'H' { lvl.entities[r][c] = .heart_frame }
				'B' { lvl.entities[r][c] = .emerald_frame }
				'S' { lvl.entities[r][c] = .snakey }
				'A' { lvl.entities[r][c] = .alma }
				'Z' { lvl.entities[r][c] = .leeper }
				'U' { lvl.entities[r][c] = .skull }
				'M' { lvl.entities[r][c] = .medusa }
				'G' { lvl.entities[r][c] = .gol }
				'K' { lvl.entities[r][c] = .king_egger }
				'Y' { lvl.entities[r][c] = .gobby }
				'O' { lvl.entities[r][c] = .moby }
				'P' { lvl.entities[r][c] = .wisp }
				'X' { lvl.entities[r][c] = .spike_trap }
				'N' { lvl.entities[r][c] = .key_item }
				'F' { lvl.entities[r][c] = .speed_boots }
				else { lvl.entities[r][c] = .none }
			}
		}
	}
	return lvl
}
