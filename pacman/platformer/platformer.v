module main

import math
import rand

pub const tile_size = 32
pub const default_gravity = 980.0
pub const default_move_speed = 220.0
pub const default_jump_force = 440.0
pub const coyote_time_max = 0.15
pub const jump_buffer_max = 0.15
pub const dash_speed = 600.0
pub const dash_duration = 0.18
pub const dash_cooldown_max = 0.6
pub const wall_slide_speed = 90.0
pub const wall_jump_vx = 320.0
pub const wall_jump_vy = 380.0

pub enum TileType {
	air = 0
	solid = 1
	oneway = 2
	hazard = 3
	ladder = 4
	coin = 5
	gem = 6
	checkpoint = 7
	breakable = 8
	key = 9
	door = 10
	spring = 11
}

pub enum PowerUpType {
	none
	double_jump
	dash_boots
	fireball
	shield
}

pub enum EnemyType {
	crawler
	slime
	bat
	turret
}

pub struct Player {
pub mut:
	x                 f64
	y                 f64
	vx                f64
	vy                f64
	w                 f64 = 24.0
	h                 f64 = 30.0
	facing_right      bool = true
	grounded          bool
	coyote_timer      f64
	jump_buffer       f64
	on_wall           int  // -1 left, 0 none, 1 right
	is_wall_sliding   bool
	is_dashing        bool
	dash_timer        f64
	dash_cooldown     f64
	can_double_jump   bool
	has_double_jumped bool
	on_ladder         bool
	invuln_timer      f64
	health            int = 3
	max_health        int = 3
	lives             int = 3
	coins             int
	score             int
	has_key           bool
	checkpoint_x      f64
	checkpoint_y      f64
	powerup           PowerUpType = .none
	powerup_timer     f64
	shield_active     bool
}

pub struct Enemy {
pub mut:
	id          int
	kind        EnemyType
	x           f64
	y           f64
	vx          f64
	vy          f64
	w           f64 = 28.0
	h           f64 = 28.0
	start_x     f64
	facing_right bool = true
	health      int  = 1
	timer       f64
	active      bool = true
}

pub struct MovingPlatform {
pub mut:
	x        f64
	y        f64
	w        f64 = 64.0
	h        f64 = 16.0
	start_x  f64
	start_y  f64
	end_x    f64
	end_y    f64
	speed    f64 = 80.0
	progress f64
	dir      f64 = 1.0
	vx       f64
	vy       f64
}

pub struct Projectile {
pub mut:
	x         f64
	y         f64
	vx        f64
	vy        f64
	is_player bool
	life      f64 = 2.0
	active    bool = true
}

pub struct Particle {
pub mut:
	x        f64
	y        f64
	vx       f64
	vy       f64
	r        u8
	g        u8
	b        u8
	life     f64
	max_life f64
	size     f64
}

pub struct TileMap {
pub mut:
	cols  int
	rows  int
	tiles [][]TileType
}

pub struct PlatformerGame {
pub mut:
	map              TileMap
	player           Player
	enemies          []Enemy
	platforms        []MovingPlatform
	projectiles      []Projectile
	particles        []Particle
	current_level    int = 1
	max_levels       int = 4
	game_over        bool
	game_won         bool
	level_completed  bool
	screen_shake     f64
	camera_x         f64
	camera_y         f64
	world_w          f64
	world_h          f64
	sound_event_jump bool
	sound_event_land bool
	sound_event_coin bool
	sound_event_dash bool
	sound_event_fire bool
	sound_event_hit  bool
	sound_event_kill bool
	sound_event_win  bool
}

pub fn new_platformer_game() PlatformerGame {
	mut game := PlatformerGame{}
	game.load_level(1)
	return game
}

pub fn (mut game PlatformerGame) load_level(level int) {
	game.current_level = level
	game.level_completed = false
	game.projectiles.clear()
	game.particles.clear()

	match level {
		1 { game.build_level_1() }
		2 { game.build_level_2() }
		3 { game.build_level_3() }
		4 { game.build_level_4() }
		else { game.build_level_1() }
	}

	game.world_w = f64(game.map.cols * tile_size)
	game.world_h = f64(game.map.rows * tile_size)

	// Reset or set player spawn
	game.player.vx = 0
	game.player.vy = 0
	game.player.grounded = false
	game.player.coyote_timer = 0
	game.player.jump_buffer = 0
	game.player.is_dashing = false
	game.player.invuln_timer = 0
}

pub fn (mut game PlatformerGame) build_level_1() {
	// Level 1: Emerald Hills (30 cols x 18 rows)
	cols := 32
	rows := 18
	mut tiles := [][]TileType{len: rows, init: []TileType{len: cols, init: .air}}

	// Border & floor
	for c in 0 .. cols {
		tiles[0][c] = .solid
		tiles[rows - 1][c] = .solid
		tiles[rows - 2][c] = .solid
	}
	for r in 0 .. rows {
		tiles[r][0] = .solid
		tiles[r][cols - 1] = .solid
	}

	// Platforms
	for c in 5 .. 10 {
		tiles[12][c] = .solid
		tiles[12][c] = .solid
	}
	for c in 13 .. 18 {
		tiles[10][c] = .oneway
	}
	for c in 20 .. 25 {
		tiles[13][c] = .solid
	}

	// Items & Hazards
	tiles[15][7] = .coin
	tiles[15][8] = .coin
	tiles[15][9] = .coin
	tiles[9][14] = .coin
	tiles[9][16] = .gem
	tiles[15][21] = .spring
	tiles[rows - 3][12] = .hazard
	tiles[rows - 3][13] = .hazard
	tiles[rows - 3][22] = .checkpoint
	tiles[rows - 3][28] = .door
	tiles[11][6] = .key

	// Breakable blocks
	tiles[12][11] = .breakable
	tiles[12][12] = .breakable

	game.map = TileMap{
		cols:  cols
		rows:  rows
		tiles: tiles
	}

	game.player.x = 2 * tile_size
	game.player.y = (rows - 4) * tile_size
	game.player.checkpoint_x = game.player.x
	game.player.checkpoint_y = game.player.y

	game.enemies = [
		Enemy{
			id: 1, kind: .crawler, x: 7 * tile_size, y: (rows - 3) * tile_size - 28, start_x: 5 * tile_size, vx: 50
		},
		Enemy{
			id: 2, kind: .slime, x: 15 * tile_size, y: (rows - 3) * tile_size - 28, start_x: 13 * tile_size, vx: 40
		},
		Enemy{
			id: 3, kind: .bat, x: 22 * tile_size, y: 6 * tile_size, start_x: 22 * tile_size, vx: 30
		},
	]

	game.platforms = [
		MovingPlatform{
			x: 10 * tile_size, y: 14 * tile_size, start_x: 10 * tile_size, start_y: 14 * tile_size, end_x: 15 * tile_size, end_y: 14 * tile_size, speed: 60
		}
	]
}

pub fn (mut game PlatformerGame) build_level_2() {
	// Level 2: Crystal Caves
	cols := 35
	rows := 20
	mut tiles := [][]TileType{len: rows, init: []TileType{len: cols, init: .air}}

	for c in 0 .. cols {
		tiles[0][c] = .solid
		tiles[rows - 1][c] = .solid
		tiles[rows - 2][c] = .solid
	}
	for r in 0 .. rows {
		tiles[r][0] = .solid
		tiles[r][cols - 1] = .solid
	}

	// Vertical climbing & wall jump sections
	for r in 6 .. 15 {
		tiles[r][10] = .solid
		tiles[r][16] = .solid
	}
	for c in 11 .. 16 {
		tiles[14][c] = .oneway
	}
	for c in 18 .. 25 {
		tiles[11][c] = .solid
	}
	tiles[rows - 3][8] = .hazard
	tiles[rows - 3][9] = .hazard
	tiles[rows - 3][17] = .hazard
	tiles[rows - 3][18] = .hazard
	tiles[10][20] = .coin
	tiles[10][22] = .gem
	tiles[10][24] = .coin
	tiles[7][13] = .key
	tiles[rows - 3][31] = .door
	tiles[rows - 3][26] = .checkpoint

	game.map = TileMap{
		cols:  cols
		rows:  rows
		tiles: tiles
	}

	game.player.x = 2 * tile_size
	game.player.y = (rows - 4) * tile_size
	game.player.checkpoint_x = game.player.x
	game.player.checkpoint_y = game.player.y

	game.enemies = [
		Enemy{
			id: 1, kind: .slime, x: 6 * tile_size, y: (rows - 3) * tile_size - 28, start_x: 4 * tile_size, vx: 45
		},
		Enemy{
			id: 2, kind: .bat, x: 13 * tile_size, y: 5 * tile_size, start_x: 13 * tile_size, vx: 50
		},
		Enemy{
			id: 3, kind: .turret, x: 24 * tile_size, y: 10 * tile_size - 28, start_x: 24 * tile_size
		},
	]

	game.platforms = [
		MovingPlatform{
			x: 26 * tile_size, y: 15 * tile_size, start_x: 26 * tile_size, start_y: 15 * tile_size, end_x: 26 * tile_size, end_y: 9 * tile_size, speed: 70
		}
	]
}

pub fn (mut game PlatformerGame) build_level_3() {
	// Level 3: Lava Fortress
	cols := 40
	rows := 20
	mut tiles := [][]TileType{len: rows, init: []TileType{len: cols, init: .air}}

	for c in 0 .. cols {
		tiles[0][c] = .solid
		tiles[rows - 1][c] = .solid
		if c < 4 || c > 35 {
			tiles[rows - 2][c] = .solid
		} else {
			tiles[rows - 2][c] = .hazard // Lava floor!
		}
	}
	for r in 0 .. rows {
		tiles[r][0] = .solid
		tiles[r][cols - 1] = .solid
	}

	// Fortress platforms
	for c in 6 .. 12 {
		tiles[14][c] = .solid
	}
	for c in 15 .. 22 {
		tiles[11][c] = .oneway
	}
	for c in 25 .. 32 {
		tiles[13][c] = .solid
	}

	tiles[13][8] = .spring
	tiles[10][18] = .gem
	tiles[10][20] = .coin
	tiles[12][28] = .key
	tiles[rows - 3][36] = .door
	tiles[10][30] = .checkpoint

	game.map = TileMap{
		cols:  cols
		rows:  rows
		tiles: tiles
	}

	game.player.x = 2 * tile_size
	game.player.y = (rows - 4) * tile_size
	game.player.checkpoint_x = game.player.x
	game.player.checkpoint_y = game.player.y

	game.enemies = [
		Enemy{
			id: 1, kind: .crawler, x: 8 * tile_size, y: 13 * tile_size - 28, start_x: 6 * tile_size, vx: 60
		},
		Enemy{
			id: 2, kind: .turret, x: 21 * tile_size, y: 10 * tile_size - 28, start_x: 21 * tile_size
		},
		Enemy{
			id: 3, kind: .bat, x: 28 * tile_size, y: 6 * tile_size, start_x: 28 * tile_size, vx: 50
		},
	]

	game.platforms = [
		MovingPlatform{
			x: 12 * tile_size, y: 15 * tile_size, start_x: 12 * tile_size, start_y: 15 * tile_size, end_x: 16 * tile_size, end_y: 15 * tile_size, speed: 80
		},
		MovingPlatform{
			x: 22 * tile_size, y: 15 * tile_size, start_x: 22 * tile_size, start_y: 15 * tile_size, end_x: 25 * tile_size, end_y: 15 * tile_size, speed: 90
		}
	]
}

pub fn (mut game PlatformerGame) build_level_4() {
	// Level 4: Celestial Tower (Ascension)
	cols := 25
	rows := 30
	mut tiles := [][]TileType{len: rows, init: []TileType{len: cols, init: .air}}

	for c in 0 .. cols {
		tiles[0][c] = .solid
		tiles[rows - 1][c] = .solid
		tiles[rows - 2][c] = .solid
	}
	for r in 0 .. rows {
		tiles[r][0] = .solid
		tiles[r][cols - 1] = .solid
	}

	// Ascending tower steps
	for c in 2 .. 8 { tiles[25][c] = .solid }
	for c in 12 .. 18 { tiles[22][c] = .oneway }
	for c in 4 .. 10 { tiles[18][c] = .solid }
	for c in 14 .. 20 { tiles[14][c] = .oneway }
	for c in 6 .. 12 { tiles[10][c] = .solid }
	for c in 14 .. 22 { tiles[6][c] = .solid }

	tiles[24][5] = .spring
	tiles[17][7] = .spring
	tiles[5][15] = .key
	tiles[5][20] = .door
	tiles[9][9] = .checkpoint

	game.map = TileMap{
		cols:  cols
		rows:  rows
		tiles: tiles
	}

	game.player.x = 2 * tile_size
	game.player.y = (rows - 4) * tile_size
	game.player.checkpoint_x = game.player.x
	game.player.checkpoint_y = game.player.y

	game.enemies = [
		Enemy{ id: 1, kind: .bat, x: 15 * tile_size, y: 20 * tile_size, start_x: 15 * tile_size, vx: 55 },
		Enemy{ id: 2, kind: .turret, x: 8 * tile_size, y: 17 * tile_size - 28, start_x: 8 * tile_size },
		Enemy{ id: 3, kind: .slime, x: 8 * tile_size, y: 9 * tile_size - 28, start_x: 6 * tile_size, vx: 50 },
	]

	game.platforms = [
		MovingPlatform{
			x: 9 * tile_size, y: 20 * tile_size, start_x: 9 * tile_size, start_y: 20 * tile_size, end_x: 9 * tile_size, end_y: 15 * tile_size, speed: 75
		}
	]
}

pub fn (mut game PlatformerGame) update(dt f64, input_left bool, input_right bool, input_jump bool, input_jump_released bool, input_down bool, input_dash bool, input_fire bool) {
	if game.game_over || game.game_won {
		return
	}

	// Reset sound flags
	game.sound_event_jump = false
	game.sound_event_land = false
	game.sound_event_coin = false
	game.sound_event_dash = false
	game.sound_event_fire = false
	game.sound_event_hit = false
	game.sound_event_kill = false
	game.sound_event_win = false

	// Update timers
	if game.player.invuln_timer > 0 {
		game.player.invuln_timer -= dt
	}
	if game.screen_shake > 0 {
		game.screen_shake -= dt * 5.0
		if game.screen_shake < 0 { game.screen_shake = 0 }
	}

	// Update Dash
	if game.player.dash_cooldown > 0 {
		game.player.dash_cooldown -= dt
	}
	if game.player.is_dashing {
		game.player.dash_timer -= dt
		if game.player.dash_timer <= 0 {
			game.player.is_dashing = false
		} else {
			// Particle dash trail
			game.particles << Particle{
				x: game.player.x + game.player.w / 2
				y: game.player.y + game.player.h / 2
				vx: (rand.f64() - 0.5) * 40
				vy: (rand.f64() - 0.5) * 40
				r: 100, g: 200, b: 255
				life: 0.2, max_life: 0.2
				size: 6
			}
		}
	}

	// Update Moving Platforms
	for mut plat in game.platforms {
		dx := plat.end_x - plat.start_x
		dy := plat.end_y - plat.start_y
		dist := math.sqrt(dx * dx + dy * dy)
		if dist > 0 {
			step := (plat.speed * dt) / dist
			plat.progress += step * plat.dir
			if plat.progress >= 1.0 {
				plat.progress = 1.0
				plat.dir = -1.0
			} else if plat.progress <= 0.0 {
				plat.progress = 0.0
				plat.dir = 1.0
			}
			new_x := plat.start_x + dx * plat.progress
			new_y := plat.start_y + dy * plat.progress
			plat.vx = (new_x - plat.x) / dt
			plat.vy = (new_y - plat.y) / dt
			plat.x = new_x
			plat.y = new_y
		}
	}

	// Player Movement Physics
	was_grounded := game.player.grounded
	if !game.player.is_dashing {
		// Horizontal input
		mut target_vx := 0.0
		if input_left {
			target_vx -= default_move_speed
			game.player.facing_right = false
		}
		if input_right {
			target_vx += default_move_speed
			game.player.facing_right = true
		}

		// Acceleration / Friction
		accel := if game.player.grounded { 12.0 } else { 6.0 }
		game.player.vx += (target_vx - game.player.vx) * math.min(1.0, accel * dt)

		// Dash Trigger
		if input_dash && game.player.dash_cooldown <= 0 {
			game.player.is_dashing = true
			game.player.dash_timer = dash_duration
			game.player.dash_cooldown = dash_cooldown_max
			dash_dir := if game.player.facing_right { 1.0 } else { -1.0 }
			game.player.vx = dash_dir * dash_speed
			game.player.vy = 0
			game.sound_event_dash = true
		}

		// Gravity & Wall Slide
		if !game.player.grounded {
			game.player.coyote_timer -= dt
			mut current_gravity := default_gravity
			if game.player.is_wall_sliding && game.player.vy > 0 {
				current_gravity = default_gravity * 0.2
			}
			game.player.vy += current_gravity * dt

			// Variable jump height limit
			if input_jump_released && game.player.vy < -100 {
				game.player.vy = -100
			}
		} else {
			game.player.coyote_timer = coyote_time_max
			game.player.has_double_jumped = false
		}

		// Jump buffering
		if input_jump {
			game.player.jump_buffer = jump_buffer_max
		} else if game.player.jump_buffer > 0 {
			game.player.jump_buffer -= dt
		}

		// Perform Jump
		if game.player.jump_buffer > 0 {
			if game.player.coyote_timer > 0 {
				// Normal Jump
				game.player.vy = -default_jump_force
				game.player.grounded = false
				game.player.coyote_timer = 0
				game.player.jump_buffer = 0
				game.sound_event_jump = true
				game.spawn_dust_particles(game.player.x + game.player.w / 2, game.player.y + game.player.h, 6)
			} else if game.player.is_wall_sliding {
				// Wall Jump
				jump_dir := if game.player.on_wall == -1 { 1.0 } else { -1.0 }
				game.player.vx = jump_dir * wall_jump_vx
				game.player.vy = -wall_jump_vy
				game.player.jump_buffer = 0
				game.player.is_wall_sliding = false
				game.sound_event_jump = true
				game.spawn_dust_particles(game.player.x + game.player.w / 2, game.player.y + game.player.h / 2, 8)
			} else if !game.player.has_double_jumped && game.player.powerup == .double_jump {
				// Double Jump
				game.player.vy = -default_jump_force * 0.9
				game.player.has_double_jumped = true
				game.player.jump_buffer = 0
				game.sound_event_jump = true
				game.spawn_dust_particles(game.player.x + game.player.w / 2, game.player.y + game.player.h, 8)
			}
		}

		// Fireball Attack
		if input_fire && game.player.powerup == .fireball && game.player.invuln_timer <= 0 {
			f_vx := if game.player.facing_right { 450.0 } else { -450.0 }
			game.projectiles << Projectile{
				x: game.player.x + game.player.w / 2
				y: game.player.y + game.player.h / 2
				vx: f_vx
				vy: -50
				is_player: true
				life: 1.5
			}
			game.sound_event_fire = true
		}
	}

	// Move Player & Resolve Map Collisions
	game.move_player_and_collide(dt, input_down)

	if !was_grounded && game.player.grounded {
		game.sound_event_land = true
		game.spawn_dust_particles(game.player.x + game.player.w / 2, game.player.y + game.player.h, 4)
	}

	// Moving Platform ride check
	for plat in game.platforms {
		if game.player.vy >= 0 && game.player.y + game.player.h >= plat.y && game.player.y + game.player.h <= plat.y + 10 {
			if game.player.x + game.player.w > plat.x && game.player.x < plat.x + plat.w {
				game.player.y = plat.y - game.player.h
				game.player.vy = 0
				game.player.grounded = true
				game.player.x += plat.vx * dt
			}
		}
	}

	// Update Projectiles
	for mut proj in game.projectiles {
		if !proj.active { continue }
		proj.x += proj.vx * dt
		proj.y += proj.vy * dt
		proj.life -= dt
		if proj.life <= 0 {
			proj.active = false
		} else {
			// Check map collision for projectile
			tx := int(proj.x / tile_size)
			ty := int(proj.y / tile_size)
			if tx >= 0 && tx < game.map.cols && ty >= 0 && ty < game.map.rows {
				t := game.map.tiles[ty][tx]
				if t == .solid || t == .breakable {
					proj.active = false
					if t == .breakable {
						game.map.tiles[ty][tx] = .air
						game.spawn_tile_break_particles(tx, ty)
					}
				}
			}
		}
	}

	// Update Enemies & AI
	for mut enemy in game.enemies {
		if !enemy.active { continue }
		enemy.timer += dt

		match enemy.kind {
			.crawler {
				enemy.x += enemy.vx * dt
				if enemy.x < enemy.start_x || enemy.x > enemy.start_x + 180 {
					enemy.vx = -enemy.vx
				}
			}
			.slime {
				enemy.x += enemy.vx * dt
				if enemy.x < enemy.start_x || enemy.x > enemy.start_x + 140 {
					enemy.vx = -enemy.vx
				}
				enemy.vy += default_gravity * 0.5 * dt
				enemy.y += enemy.vy * dt
				if enemy.y >= enemy.start_x { // Ground level check
					enemy.y = enemy.start_x
					enemy.vy = -180 // Hop
				}
			}
			.bat {
				enemy.x += enemy.vx * dt
				enemy.y += math.sin(enemy.timer * 4.0) * 40.0 * dt
				if enemy.x < enemy.start_x - 100 || enemy.x > enemy.start_x + 100 {
					enemy.vx = -enemy.vx
				}
			}
			.turret {
				if enemy.timer >= 2.0 {
					enemy.timer = 0
					// Shoot at player direction
					dir := if game.player.x > enemy.x { 1.0 } else { -1.0 }
					game.projectiles << Projectile{
						x: enemy.x + 14
						y: enemy.y + 14
						vx: dir * 250
						vy: 0
						is_player: false
						life: 2.5
					}
				}
			}
		}

		// Enemy - Player collision
		if game.player.invuln_timer <= 0 && !game.player.is_dashing {
			if game.player.x + game.player.w > enemy.x && game.player.x < enemy.x + enemy.w &&
			   game.player.y + game.player.h > enemy.y && game.player.y < enemy.y + enemy.h {
				// Jump stomp on enemy head!
				if game.player.vy > 0 && game.player.y + game.player.h < enemy.y + 14 {
					enemy.active = false
					game.player.vy = -280
					game.player.score += 200
					game.sound_event_kill = true
					game.spawn_dust_particles(enemy.x + 14, enemy.y + 14, 10)
				} else {
					// Player hit
					game.hurt_player()
				}
			}
		}

		// Enemy - Player Projectile collision
		for mut proj in game.projectiles {
			if proj.active && proj.is_player {
				if proj.x > enemy.x && proj.x < enemy.x + enemy.w &&
				   proj.y > enemy.y && proj.y < enemy.y + enemy.h {
					enemy.active = false
					proj.active = false
					game.player.score += 150
					game.sound_event_kill = true
					game.spawn_dust_particles(enemy.x + 14, enemy.y + 14, 8)
				}
			}
		}
	}

	// Enemy Projectile - Player collision
	for mut proj in game.projectiles {
		if proj.active && !proj.is_player && game.player.invuln_timer <= 0 {
			if proj.x > game.player.x && proj.x < game.player.x + game.player.w &&
			   proj.y > game.player.y && proj.y < game.player.y + game.player.h {
				proj.active = false
				game.hurt_player()
			}
		}
	}

	// Update Particles
	for mut p in game.particles {
		p.x += p.vx * dt
		p.y += p.vy * dt
		p.life -= dt
	}
	game.particles = game.particles.filter(it.life > 0)
	game.projectiles = game.projectiles.filter(it.active)

	// Smooth Camera follow
	target_cam_x := game.player.x + game.player.w / 2 - 400.0
	target_cam_y := game.player.y + game.player.h / 2 - 300.0

	// Clamp camera to map bounds
	max_cam_x := math.max(0.0, game.world_w - 800.0)
	max_cam_y := math.max(0.0, game.world_h - 600.0)

	game.camera_x += (math.clamp(target_cam_x, 0.0, max_cam_x) - game.camera_x) * math.min(1.0, 8.0 * dt)
	game.camera_y += (math.clamp(target_cam_y, 0.0, max_cam_y) - game.camera_y) * math.min(1.0, 8.0 * dt)
}

pub fn (mut game PlatformerGame) hurt_player() {
	if game.player.shield_active {
		game.player.shield_active = false
		game.player.invuln_timer = 1.0
		game.sound_event_hit = true
		return
	}
	game.player.health--
	game.player.invuln_timer = 1.5
	game.screen_shake = 0.4
	game.sound_event_hit = true

	if game.player.health <= 0 {
		game.player.lives--
		if game.player.lives <= 0 {
			game.game_over = true
		} else {
			// Respawn at checkpoint
			game.player.health = game.player.max_health
			game.player.x = game.player.checkpoint_x
			game.player.y = game.player.checkpoint_y
			game.player.vx = 0
			game.player.vy = 0
		}
	}
}

pub fn (mut game PlatformerGame) move_player_and_collide(dt f64, input_down bool) {
	// X axis move & test
	game.player.x += game.player.vx * dt
	game.player.on_wall = 0

	min_tx := int(math.max(0.0, game.player.x / tile_size))
	max_tx := int(math.min(f64(game.map.cols - 1), (game.player.x + game.player.w) / tile_size))
	min_ty := int(math.max(0.0, game.player.y / tile_size))
	max_ty := int(math.min(f64(game.map.rows - 1), (game.player.y + game.player.h - 1) / tile_size))

	for ty in min_ty .. max_ty + 1 {
		for tx in min_tx .. max_tx + 1 {
			t := game.map.tiles[ty][tx]
			if t == .solid || t == .breakable || (t == .door && !game.player.has_key) {
				tile_box_x := f64(tx * tile_size)
				if game.player.vx > 0 {
					game.player.x = tile_box_x - game.player.w
					game.player.on_wall = 1
				} else if game.player.vx < 0 {
					game.player.x = tile_box_x + tile_size
					game.player.on_wall = -1
				}
				game.player.vx = 0
			}
		}
	}

	// Y axis move & test
	game.player.y += game.player.vy * dt
	game.player.grounded = false

	min_tx_y := int(math.max(0.0, game.player.x / tile_size))
	max_tx_y := int(math.min(f64(game.map.cols - 1), (game.player.x + game.player.w - 1) / tile_size))
	min_ty_y := int(math.max(0.0, game.player.y / tile_size))
	max_ty_y := int(math.min(f64(game.map.rows - 1), (game.player.y + game.player.h) / tile_size))

	for ty in min_ty_y .. max_ty_y + 1 {
		for tx in min_tx_y .. max_tx_y + 1 {
			t := game.map.tiles[ty][tx]
			tile_box_y := f64(ty * tile_size)

			if t == .solid || t == .breakable || (t == .door && !game.player.has_key) {
				if game.player.vy > 0 {
					game.player.y = tile_box_y - game.player.h
					game.player.vy = 0
					game.player.grounded = true
				} else if game.player.vy < 0 {
					game.player.y = tile_box_y + tile_size
					game.player.vy = 0
				}
			} else if t == .oneway && !input_down {
				// One way platform pass through from bottom
				if game.player.vy > 0 && (game.player.y + game.player.h - game.player.vy * dt) <= tile_box_y + 4 {
					game.player.y = tile_box_y - game.player.h
					game.player.vy = 0
					game.player.grounded = true
				}
			}

			// Interactive tile triggers
			game.handle_tile_trigger(tx, ty, t)
		}
	}

	// Wall slide detection
	if !game.player.grounded && game.player.on_wall != 0 && game.player.vy > 0 {
		game.player.is_wall_sliding = true
		if game.player.vy > wall_slide_speed {
			game.player.vy = wall_slide_speed
		}
	} else {
		game.player.is_wall_sliding = false
	}
}

pub fn (mut game PlatformerGame) handle_tile_trigger(tx int, ty int, t TileType) {
	match t {
		.coin {
			game.map.tiles[ty][tx] = .air
			game.player.coins++
			game.player.score += 100
			game.sound_event_coin = true
			game.spawn_sparkle_particles(f64(tx * tile_size + 16), f64(ty * tile_size + 16), 5)
		}
		.gem {
			game.map.tiles[ty][tx] = .air
			game.player.score += 500
			game.sound_event_coin = true
			game.spawn_sparkle_particles(f64(tx * tile_size + 16), f64(ty * tile_size + 16), 8)
			// Unlock powerup randomly
			game.player.powerup = .double_jump
		}
		.key {
			game.map.tiles[ty][tx] = .air
			game.player.has_key = true
			game.sound_event_coin = true
			game.spawn_sparkle_particles(f64(tx * tile_size + 16), f64(ty * tile_size + 16), 10)
		}
		.door {
			if game.player.has_key {
				game.sound_event_win = true
				if game.current_level < game.max_levels {
					game.load_level(game.current_level + 1)
				} else {
					game.game_won = true
				}
			}
		}
		.hazard {
			if game.player.invuln_timer <= 0 {
				game.hurt_player()
			}
		}
		.spring {
			game.player.vy = -default_jump_force * 1.3
			game.player.grounded = false
			game.sound_event_jump = true
			game.spawn_dust_particles(f64(tx * tile_size + 16), f64(ty * tile_size + 32), 6)
		}
		.checkpoint {
			game.player.checkpoint_x = f64(tx * tile_size)
			game.player.checkpoint_y = f64((ty - 1) * tile_size)
		}
		else {}
	}
}

pub fn (mut game PlatformerGame) spawn_dust_particles(x f64, y f64, count int) {
	for _ in 0 .. count {
		game.particles << Particle{
			x: x
			y: y
			vx: (rand.f64() - 0.5) * 80
			vy: -rand.f64() * 50 - 10
			r: 200, g: 200, b: 200
			life: 0.35, max_life: 0.35
			size: 4
		}
	}
}

pub fn (mut game PlatformerGame) spawn_sparkle_particles(x f64, y f64, count int) {
	for _ in 0 .. count {
		game.particles << Particle{
			x: x
			y: y
			vx: (rand.f64() - 0.5) * 100
			vy: (rand.f64() - 0.5) * 100
			r: 255, g: 220, b: 50
			life: 0.4, max_life: 0.4
			size: 5
		}
	}
}

pub fn (mut game PlatformerGame) spawn_tile_break_particles(tx int, ty int) {
	cx := f64(tx * tile_size + 16)
	cy := f64(ty * tile_size + 16)
	for _ in 0 .. 8 {
		game.particles << Particle{
			x: cx
			y: cy
			vx: (rand.f64() - 0.5) * 160
			vy: (rand.f64() - 0.5) * 160
			r: 160, g: 110, b: 60
			life: 0.4, max_life: 0.4
			size: 6
		}
	}
}
