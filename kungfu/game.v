module main

import math
import rand

pub enum GameState {
	title
	playing
	floor_clear
	paused
	game_over
	victory
}

pub enum AttackType {
	none
	high_punch
	high_kick
	low_punch
	low_kick
	jump_kick
}

pub enum EnemyType {
	gripper
	knife_thrower
	tom_tom
	snake
	moth
	boss_stick
	boss_boomerang
	boss_giant
	boss_magician
	boss_mrx
}

pub struct Projectile {
pub mut:
	x            f32
	y            f32
	vx           f32
	vy           f32
	is_boomerang bool
	is_fire      bool
	active       bool = true
}

pub struct FallingPot {
pub mut:
	x      f32
	y      f32
	vy     f32 = 280.0
	active bool = true
}

pub struct Player {
pub mut:
	x             f32 = 100.0
	y             f32 = 400.0
	vx            f32
	vy            f32
	width         f32 = 28.0
	height        f32 = 64.0
	facing_right  bool = true
	is_grounded   bool = true
	is_crouching  bool
	is_jumping    bool
	attack        AttackType = .none
	attack_timer  f32
	hitstun_timer f32
	invuln_timer  f32
	health        int = 16
	max_health    int = 16
	lives         int = 3
	score         int
	grabbed_count int // Number of grippers clinging
	grab_timer    f32
	walk_frame    int
	anim_timer    f32
	is_dead       bool
	dead_timer    f32
}

pub struct Enemy {
pub mut:
	id           int
	enemy_type   EnemyType
	x            f32
	y            f32
	vx           f32
	vy           f32
	width        f32 = 28.0
	height       f32 = 64.0
	facing_right bool
	is_grounded  bool = true
	health       int = 1
	max_health   int = 1
	is_grabbing  bool
	attack_timer f32
	jump_timer   f32
	anim_timer   f32
	is_hit       bool
	hit_timer    f32
	active       bool = true
}

pub struct Particle {
pub mut:
	x      f32
	y      f32
	vx     f32
	vy     f32
	color  Color
	life   f32
	size   f32
	active bool = true
}

pub struct ScorePopup {
pub mut:
	x      f32
	y      f32
	text   string
	color  Color
	timer  f32 = 0.8
	active bool = true
}

pub struct KungFuGame {
pub mut:
	state        GameState = .title
	floor        int       = 1 // 1..5
	high_score   int       = 20000
	camera_x     f32
	floor_length f32       = 2400.0
	floor_timer  f32       = 120.0
	player       Player
	enemies      []Enemy
	projectiles  []Projectile
	falling_pots []FallingPot
	particles    []Particle
	score_popups []ScorePopup
	sound_mgr    SoundManager
	spawn_timer  f32
	pot_timer    f32
	boss_spawned bool
	banner_timer f32
	screen_shake f32
	crt_filter   bool = true
	// Controls
	key_left     bool
	key_right    bool
	key_up       bool
	key_down     bool
	key_jump     bool
	key_punch    bool
	key_kick     bool
	last_dir_key int
}

pub fn new_kung_fu_game() KungFuGame {
	mut g := KungFuGame{
		sound_mgr: new_sound_manager()
	}
	g.reset_to_title()
	return g
}

pub fn (mut g KungFuGame) reset_to_title() {
	g.state = .title
	g.enemies.clear()
	g.projectiles.clear()
	g.falling_pots.clear()
	g.particles.clear()
	g.score_popups.clear()
}

pub fn (mut g KungFuGame) start_game() {
	g.state = .playing
	g.floor = 1
	g.player = Player{
		x: 100.0
		y: 400.0
		health: 16
		lives: 3
		score: 0
	}
	g.init_floor(1)
}

pub fn (mut g KungFuGame) init_floor(fl int) {
	g.floor = fl
	g.enemies.clear()
	g.projectiles.clear()
	g.falling_pots.clear()
	g.particles.clear()
	g.score_popups.clear()
	g.camera_x = 0.0
	g.floor_timer = 120.0
	g.boss_spawned = false
	g.spawn_timer = 1.0
	g.pot_timer = 3.0
	g.banner_timer = 2.0

	// Odd floors scroll left-to-right (start at X=100); even floors scroll right-to-left (start at X=2300)
	is_even := fl % 2 == 0
	g.player.x = if is_even { f32(2300.0) } else { f32(100.0) }
	g.player.y = 400.0
	g.player.vx = 0.0
	g.player.vy = 0.0
	g.player.facing_right = !is_even
	g.player.health = 16
	g.player.is_grounded = true
	g.player.is_crouching = false
	g.player.is_jumping = false
	g.player.is_dead = false
	g.player.grabbed_count = 0
	g.player.attack = .none
}

pub fn (mut g KungFuGame) get_boss_type() EnemyType {
	return match g.floor {
		1 { EnemyType.boss_stick }
		2 { EnemyType.boss_boomerang }
		3 { EnemyType.boss_giant }
		4 { EnemyType.boss_magician }
		else { EnemyType.boss_mrx }
	}
}

pub fn (mut g KungFuGame) get_boss_max_hp() int {
	return match g.floor {
		1 { 12 }
		2 { 14 }
		3 { 16 }
		4 { 14 }
		else { 16 }
	}
}

pub fn (mut g KungFuGame) spawn_enemy() {
	if g.boss_spawned {
		return
	}

	cam_left := g.camera_x
	cam_right := g.camera_x + 800.0

	from_left := (rand.intn(2) or { 0 }) == 0
	spawn_x := if from_left { cam_left - 40.0 } else { cam_right + 40.0 }
	if spawn_x < 0.0 || spawn_x > g.floor_length {
		return
	}

	r := rand.intn(100) or { 50 }
	mut e_type := EnemyType.gripper

	if r < 55 {
		e_type = .gripper
	} else if r < 82 {
		e_type = .knife_thrower
	} else {
		e_type = .tom_tom
	}

	dir := if from_left { f32(1.0) } else { f32(-1.0) }
	speed := match e_type {
		.gripper { 120.0 + f32(rand.intn(30) or { 10 }) }
		.knife_thrower { 90.0 }
		.tom_tom { 140.0 + f32(rand.intn(40) or { 20 }) }
		else { 100.0 }
	}

	e_y := if e_type == .tom_tom { f32(420.0) } else { f32(400.0) }
	e_h := if e_type == .tom_tom { f32(44.0) } else { f32(64.0) }
	e_jt := if e_type == .tom_tom { f32(0.8) } else { f32(0.0) }

	g.enemies << Enemy{
		id: g.enemies.len + 1
		enemy_type: e_type
		x: spawn_x
		y: e_y
		vx: dir * speed
		vy: 0.0
		height: e_h
		facing_right: from_left
		health: 1
		max_health: 1
		attack_timer: 1.5 + f32(rand.intn(10) or { 5 }) / 10.0
		jump_timer: e_jt
		active: true
	}
}

pub fn (mut g KungFuGame) spawn_boss() {
	g.boss_spawned = true
	b_type := g.get_boss_type()
	b_hp := g.get_boss_max_hp()

	is_even := g.floor % 2 == 0
	boss_x := if is_even { f32(120.0) } else { f32(g.floor_length - 150.0) }
	boss_vx := if is_even { f32(90.0) } else { f32(-90.0) }
	boss_w := if b_type == .boss_giant { f32(36.0) } else { f32(30.0) }
	boss_h := if b_type == .boss_giant { f32(74.0) } else { f32(68.0) }

	g.enemies << Enemy{
		id: 99
		enemy_type: b_type
		x: boss_x
		y: 396.0
		vx: boss_vx
		vy: 0.0
		width: boss_w
		height: boss_h
		facing_right: is_even
		health: b_hp
		max_health: b_hp
		attack_timer: 1.2
		active: true
	}
}

pub fn (mut g KungFuGame) add_particles(x f32, y f32, count int, color Color) {
	for _ in 0 .. count {
		angle := f32(rand.intn(360) or { 0 }) * f32(math.pi / 180.0)
		speed := 30.0 + f32(rand.intn(120) or { 40 })
		g.particles << Particle{
			x: x
			y: y
			vx: f32(math.cos(f64(angle))) * speed
			vy: f32(math.sin(f64(angle))) * speed
			color: color
			life: 0.35 + f32(rand.intn(25) or { 10 }) / 100.0
			size: 3.0 + f32(rand.intn(3) or { 1 })
			active: true
		}
	}
}

pub fn (mut g KungFuGame) add_score_popup(x f32, y f32, text string, color Color) {
	g.score_popups << ScorePopup{
		x: x
		y: y
		text: text
		color: color
		timer: 0.8
		active: true
	}
}

pub fn (mut g KungFuGame) trigger_attack(attack AttackType) {
	if g.player.attack != .none || g.player.is_dead || g.player.grabbed_count > 0 {
		return
	}
	g.player.attack = attack
	g.player.attack_timer = 0.22

	match attack {
		.high_punch, .low_punch {
			g.sound_mgr.play_punch()
		}
		.high_kick, .low_kick, .jump_kick {
			g.sound_mgr.play_kick()
		}
		else {}
	}

	// Calculate strike hitbox
	mut hit_x := if g.player.facing_right { g.player.x + g.player.width } else { g.player.x - 28.0 }
	mut hit_y := g.player.y + 12.0
	mut hit_w := f32(28.0)
	mut hit_h := f32(20.0)

	match attack {
		.high_punch {
			hit_y = g.player.y + 10.0
		}
		.high_kick {
			hit_y = g.player.y + 16.0
			hit_w = 34.0
		}
		.low_punch {
			hit_y = g.player.y + 36.0
		}
		.low_kick {
			hit_y = g.player.y + 46.0
			hit_w = 36.0
		}
		.jump_kick {
			hit_y = g.player.y + 20.0
			hit_w = 34.0
		}
		else {}
	}

	// 1. Deflect incoming throwing knives / boomerangs
	for mut p in g.projectiles {
		if p.active {
			if p.x > hit_x && p.x < hit_x + hit_w && p.y > hit_y && p.y < hit_y + hit_h {
				p.active = false
				g.sound_mgr.play_deflect()
				g.add_particles(p.x, p.y, 10, Color{ r: 255, g: 240, b: 80, a: 255 })
				g.add_score_popup(p.x, p.y, '+500', Color{ r: 255, g: 230, b: 60, a: 255 })
				g.player.score += 500
			}
		}
	}

	// 2. Strike enemies
	for mut e in g.enemies {
		if !e.active || e.is_hit {
			continue
		}
		if e.x + e.width > hit_x && e.x < hit_x + hit_w && e.y + e.height > hit_y && e.y < hit_y + hit_h {
			// Boss special block condition (e.g. Stick fighter blocking high attacks)
			if e.enemy_type == .boss_stick && (attack == .high_punch || attack == .high_kick) {
				g.sound_mgr.play_deflect()
				g.add_particles(hit_x, hit_y, 6, Color{ r: 200, g: 200, b: 200, a: 255 })
				continue
			}

			// Successful strike!
			e.health--
			e.is_hit = true
			e.hit_timer = 0.25
			g.sound_mgr.play_hit()
			g.add_particles(e.x + e.width * 0.5, e.y + e.height * 0.4, 14, Color{ r: 255, g: 60, b: 60, a: 255 })

			if e.health <= 0 {
				e.active = false
				pts := match e.enemy_type {
					.boss_stick { 2000 }
					.boss_boomerang { 3000 }
					.boss_giant { 4000 }
					.boss_magician { 5000 }
					.boss_mrx { 10000 }
					.knife_thrower { if attack == .high_punch || attack == .low_punch { 200 } else { 100 } }
					.tom_tom { if attack == .jump_kick { 300 } else { 200 } }
					else { if attack == .high_punch || attack == .low_punch { 200 } else { 100 } }
				}
				g.player.score += pts
				g.add_score_popup(e.x, e.y, '+${pts}', Color{ r: 255, g: 230, b: 60, a: 255 })

				// Boss defeat -> Floor clear
				if e.enemy_type in [.boss_stick, .boss_boomerang, .boss_giant, .boss_magician, .boss_mrx] {
					g.state = .floor_clear
					g.sound_mgr.play_floor_clear()
					time_bonus := int(g.floor_timer) * 10
					g.player.score += time_bonus
				}
			}
		}
	}
}

pub fn (mut g KungFuGame) update(dt f32) {
	if g.state == .paused || g.state == .title || g.state == .game_over {
		return
	}

	gravity := f32(900.0)

	// BGM Streaming
	g.sound_mgr.update_bgm(f64(dt), g.state == .playing)

	if g.screen_shake > 0.0 {
		g.screen_shake -= dt
	}

	if g.banner_timer > 0.0 {
		g.banner_timer -= dt
	}

	// Floor Timer
	g.floor_timer -= dt
	if g.floor_timer <= 0.0 && !g.player.is_dead {
		g.player.is_dead = true
		g.player.dead_timer = 2.0
		g.sound_mgr.play_die()
	}

	// 1. Update Player
	if g.player.is_dead {
		g.player.dead_timer -= dt
		if g.player.dead_timer <= 0.0 {
			g.player.lives--
			if g.player.lives > 0 {
				g.init_floor(g.floor)
			} else {
				g.state = .game_over
			}
		}
		return
	}

	if g.player.invuln_timer > 0.0 {
		g.player.invuln_timer -= dt
	}

	// Grabber drain damage while pinned
	if g.player.grabbed_count > 0 {
		g.player.grab_timer += dt
		if g.player.grab_timer > 0.45 {
			g.player.grab_timer = 0.0
			g.player.health -= g.player.grabbed_count
			g.sound_mgr.play_grab()
			if g.player.health <= 0 {
				g.player.health = 0
				g.player.is_dead = true
				g.player.dead_timer = 2.0
				g.sound_mgr.play_die()
			}
		}
	}

	// Attack timer
	if g.player.attack_timer > 0.0 {
		g.player.attack_timer -= dt
		if g.player.attack_timer <= 0.0 {
			g.player.attack = .none
		}
	}

	// Player Movement (Disabled if currently pinned by grippers)
	if g.player.grabbed_count == 0 {
		g.player.is_crouching = g.key_down && g.player.is_grounded

		speed := f32(140.0)
		if g.player.is_crouching {
			g.player.vx = 0.0
		} else if g.key_left {
			g.player.vx = -speed
			g.player.facing_right = false
		} else if g.key_right {
			g.player.vx = speed
			g.player.facing_right = true
		} else {
			g.player.vx = 0.0
		}

		// Jump
		if g.key_jump && g.player.is_grounded && !g.player.is_jumping {
			g.player.vy = -420.0
			g.player.is_grounded = false
			g.player.is_jumping = true
		}

		// Attacks
		if g.key_punch {
			if g.player.is_jumping {
				g.trigger_attack(.jump_kick)
			} else if g.player.is_crouching {
				g.trigger_attack(.low_punch)
			} else {
				g.trigger_attack(.high_punch)
			}
		} else if g.key_kick {
			if g.player.is_jumping {
				g.trigger_attack(.jump_kick)
			} else if g.player.is_crouching {
				g.trigger_attack(.low_kick)
			} else {
				g.trigger_attack(.high_kick)
			}
		}
	}

	// Gravity & Position
	g.player.vy += gravity * dt
	if g.player.vy > 600.0 {
		g.player.vy = 600.0
	}

	g.player.x += g.player.vx * dt
	g.player.y += g.player.vy * dt

	// Floor Boundaries
	if g.player.x < 30.0 {
		g.player.x = 30.0
	}
	if g.player.x > g.floor_length - 40.0 {
		g.player.x = g.floor_length - 40.0
	}

	// Ground collision (Y=400)
	if g.player.y >= 400.0 {
		g.player.y = 400.0
		g.player.vy = 0.0
		g.player.is_grounded = true
		g.player.is_jumping = false
	}

	// Walk animation
	if math.abs(g.player.vx) > 5.0 {
		g.player.anim_timer += dt * 8.0
		g.player.walk_frame = int(g.player.anim_timer) % 4
	} else {
		g.player.walk_frame = 0
	}

	// Camera Tracking
	mut target_cam_x := g.player.x - 380.0
	if target_cam_x < 0.0 {
		target_cam_x = 0.0
	}
	if target_cam_x > g.floor_length - 800.0 {
		target_cam_x = g.floor_length - 800.0
	}
	g.camera_x += (target_cam_x - g.camera_x) * 8.0 * dt

	// Check if near boss spawn zone
	is_even := g.floor % 2 == 0
	near_end := if is_even { g.player.x < 450.0 } else { g.player.x > g.floor_length - 550.0 }
	if near_end && !g.boss_spawned {
		g.spawn_boss()
	}

	// 2. Spawn Regular Enemies
	if !g.boss_spawned {
		g.spawn_timer -= dt
		if g.spawn_timer <= 0.0 && g.enemies.len < 6 {
			g.spawn_enemy()
			g.spawn_timer = 1.0 + f32(rand.intn(12) or { 5 }) / 10.0
		}
	}

	// 3. Falling Pots on Floors 2 and 4
	if g.floor in [2, 4] && !g.boss_spawned {
		g.pot_timer -= dt
		if g.pot_timer <= 0.0 {
			g.pot_timer = 2.5 + f32(rand.intn(20) or { 10 }) / 10.0
			pot_x := g.camera_x + 100.0 + f32(rand.intn(600) or { 300 })
			g.falling_pots << FallingPot{ x: pot_x, y: 140.0, active: true }
		}
	}

	// Update Falling Pots
	for mut pot in g.falling_pots {
		if !pot.active {
			continue
		}
		pot.y += pot.vy * dt
		if pot.y >= 440.0 {
			pot.active = false
			g.sound_mgr.play_pot_smash()
			g.add_particles(pot.x, 440.0, 10, Color{ r: 180, g: 120, b: 60, a: 255 })
			// Spawn Snake or Moth
			if (rand.intn(2) or { 0 }) == 0 {
				s_vx := if g.player.x > pot.x { f32(130.0) } else { f32(-130.0) }
				g.enemies << Enemy{
					id: g.enemies.len + 1
					enemy_type: .snake
					x: pot.x
					y: 446.0
					vx: s_vx
					vy: 0.0
					height: 18.0
					facing_right: g.player.x > pot.x
					health: 1
					active: true
				}
			} else {
				m_vx := if g.player.x > pot.x { f32(110.0) } else { f32(-110.0) }
				g.enemies << Enemy{
					id: g.enemies.len + 1
					enemy_type: .moth
					x: pot.x
					y: 380.0
					vx: m_vx
					vy: -60.0
					height: 22.0
					facing_right: g.player.x > pot.x
					health: 1
					active: true
				}
			}
		}
	}

	// 4. Update Enemies
	for mut e in g.enemies {
		if !e.active {
			continue
		}

		if e.is_hit {
			e.hit_timer -= dt
			if e.hit_timer <= 0.0 {
				e.is_hit = false
			}
		}

		e.anim_timer += dt * 7.0
		e.attack_timer -= dt

		// Enemy AI Logic
		match e.enemy_type {
			.gripper {
				if e.is_grabbing {
					e.x = if e.facing_right { g.player.x - 14.0 } else { g.player.x + 14.0 }
					e.y = g.player.y
				} else {
					dx := g.player.x - e.x
					e.vx = (if dx > 0.0 { f32(1.0) } else { f32(-1.0) }) * 120.0
					e.facing_right = dx > 0.0
					e.x += e.vx * dt

					// Latch onto player
					if math.abs(dx) < 18.0 && g.player.invuln_timer <= 0.0 && !g.player.is_dead {
						e.is_grabbing = true
						g.player.grabbed_count++
						g.sound_mgr.play_grab()
					}
				}
			}
			.knife_thrower {
				dx := g.player.x - e.x
				dist := math.abs(dx)
				e.facing_right = dx > 0.0

				if dist > 260.0 {
					e.vx = (if dx > 0.0 { f32(1.0) } else { f32(-1.0) }) * 90.0
					e.x += e.vx * dt
				} else {
					e.vx = 0.0
					if e.attack_timer <= 0.0 {
						e.attack_timer = 2.0
						dir := if e.facing_right { f32(1.0) } else { f32(-1.0) }
						is_high := (rand.intn(2) or { 0 }) == 0
						p_y := if is_high { f32(416.0) } else { f32(448.0) }
						g.projectiles << Projectile{
							x: e.x + (if e.facing_right { e.width } else { -10.0 })
							y: p_y
							vx: dir * 320.0
							vy: 0.0
							active: true
						}
					}
				}
			}
			.tom_tom {
				dx := g.player.x - e.x
				e.facing_right = dx > 0.0
				e.jump_timer -= dt
				if e.jump_timer <= 0.0 && e.is_grounded {
					e.vy = -340.0
					e.is_grounded = false
					e.jump_timer = 1.6
				}
				e.vy += gravity * dt
				e.x += (if dx > 0.0 { f32(1.0) } else { f32(-1.0) }) * 140.0 * dt
				e.y += e.vy * dt
				if e.y >= 420.0 {
					e.y = 420.0
					e.vy = 0.0
					e.is_grounded = true
				}
			}
			.snake {
				e.x += e.vx * dt
			}
			.moth {
				e.x += e.vx * dt
				e.y += e.vy * dt
				if e.y < 280.0 || e.y > 440.0 {
					e.vy = -e.vy
				}
			}
			.boss_stick {
				dx := g.player.x - e.x
				e.facing_right = dx > 0.0
				e.vx = (if dx > 0.0 { f32(1.0) } else { f32(-1.0) }) * 90.0
				e.x += e.vx * dt
			}
			.boss_boomerang {
				dx := g.player.x - e.x
				e.facing_right = dx > 0.0
				if e.attack_timer <= 0.0 {
					e.attack_timer = 2.4
					dir := if e.facing_right { f32(1.0) } else { f32(-1.0) }
					g.projectiles << Projectile{
						x: e.x + (if e.facing_right { e.width } else { -10.0 })
						y: 420.0
						vx: dir * 280.0
						vy: 0.0
						is_boomerang: true
						active: true
					}
				}
			}
			.boss_giant {
				dx := g.player.x - e.x
				e.facing_right = dx > 0.0
				e.vx = (if dx > 0.0 { f32(1.0) } else { f32(-1.0) }) * 75.0
				e.x += e.vx * dt
			}
			.boss_magician {
				dx := g.player.x - e.x
				e.facing_right = dx > 0.0
				if e.attack_timer <= 0.0 {
					e.attack_timer = 2.2
					dir := if e.facing_right { f32(1.0) } else { f32(-1.0) }
					g.projectiles << Projectile{
						x: e.x + (if e.facing_right { e.width } else { -10.0 })
						y: 424.0
						vx: dir * 260.0
						vy: 0.0
						is_fire: true
						active: true
					}
				}
			}
			.boss_mrx {
				dx := g.player.x - e.x
				e.facing_right = dx > 0.0
				e.vx = (if dx > 0.0 { f32(1.0) } else { f32(-1.0) }) * 110.0
				e.x += e.vx * dt
			}
		}

		// Body damage collision with player (for non-grippers)
		if e.enemy_type != .gripper && g.player.invuln_timer <= 0.0 && !g.player.is_dead {
			if g.player.x + g.player.width > e.x && g.player.x < e.x + e.width
				&& g.player.y + g.player.height > e.y && g.player.y < e.y + e.height {
				g.player.health -= 3
				g.player.invuln_timer = 1.0
				g.sound_mgr.play_hit()
				g.add_particles(g.player.x + 14.0, g.player.y + 24.0, 16, Color{ r: 255, g: 60, b: 60, a: 255 })
				if g.player.health <= 0 {
					g.player.health = 0
					g.player.is_dead = true
					g.player.dead_timer = 2.0
					g.sound_mgr.play_die()
				}
			}
		}
	}

	// 5. Update Projectiles
	for mut p in g.projectiles {
		if !p.active {
			continue
		}
		p.x += p.vx * dt
		p.y += p.vy * dt

		// Boomerang return arc
		if p.is_boomerang && math.abs(p.x - g.player.x) > 300.0 {
			p.vx = -p.vx
		}

		// Check collision with player
		if g.player.invuln_timer <= 0.0 && !g.player.is_dead {
			// If crouching under high projectile, avoid damage
			if g.player.is_crouching && p.y < 430.0 {
				continue
			}
			if p.x > g.player.x && p.x < g.player.x + g.player.width && p.y > g.player.y && p.y < g.player.y + g.player.height {
				p.active = false
				g.player.health -= 2
				g.player.invuln_timer = 1.0
				g.sound_mgr.play_hit()
				g.add_particles(p.x, p.y, 14, Color{ r: 255, g: 60, b: 60, a: 255 })
				if g.player.health <= 0 {
					g.player.health = 0
					g.player.is_dead = true
					g.player.dead_timer = 2.0
					g.sound_mgr.play_die()
				}
			}
		}

		if p.x < g.camera_x - 60.0 || p.x > g.camera_x + 860.0 {
			p.active = false
		}
	}

	// 6. Update Particles
	for mut pt in g.particles {
		if !pt.active {
			continue
		}
		pt.life -= dt
		pt.x += pt.vx * dt
		pt.y += pt.vy * dt
		if pt.life <= 0.0 {
			pt.active = false
		}
	}

	// 7. Update Score Popups
	for mut sp in g.score_popups {
		if !sp.active {
			continue
		}
		sp.timer -= dt
		sp.y -= 25.0 * dt
		if sp.timer <= 0.0 {
			sp.active = false
		}
	}

	// Filter inactive
	g.enemies = g.enemies.filter(it.active)
	g.projectiles = g.projectiles.filter(it.active)
	g.falling_pots = g.falling_pots.filter(it.active)
	g.particles = g.particles.filter(it.active)
	g.score_popups = g.score_popups.filter(it.active)

	if g.player.score > g.high_score {
		g.high_score = g.player.score
	}
}

pub fn (mut g KungFuGame) shake_off_grippers() {
	if g.player.grabbed_count > 0 {
		g.player.grabbed_count = 0
		for mut e in g.enemies {
			if e.enemy_type == .gripper && e.is_grabbing {
				e.active = false
				g.add_particles(e.x + 14.0, e.y + 20.0, 10, Color{ r: 200, g: 200, b: 240, a: 255 })
			}
		}
	}
}

pub fn (mut g KungFuGame) next_floor() {
	g.floor++
	if g.floor > 5 {
		g.state = .victory
	} else {
		g.init_floor(g.floor)
		g.state = .playing
	}
}
