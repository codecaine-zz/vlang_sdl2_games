module main

import math
import rand

pub enum GameState {
	title
	fighting
	round_clear
	game_over
	victory
	paused
}

pub enum MoveType {
	idle
	walk_forward
	walk_backward
	crouch
	jump_straight
	jump_forward
	jump_backward
	// Punches
	high_punch
	mid_punch
	low_punch
	jump_punch
	// Kicks
	high_kick
	mid_kick
	low_kick
	jump_kick
	flying_kick
	hit_stun
	knockdown
}

pub enum OpponentType {
	wang // Bo Staff Master
	tao  // Fireball Spitter
	chen // Chain Whip Master
	lang // Shuriken Fan Master
	mu   // Flying Dive-Bomb Master
}

pub struct Projectile {
pub mut:
	x           f32
	y           f32
	vx          f32
	vy          f32
	is_fire     bool
	radius      f32  = 6.0
	active      bool = true
}

pub struct Fighter {
pub mut:
	x            f32 = 240.0
	y            f32 = 384.0
	vx           f32
	vy           f32
	width        f32 = 48.0
	height       f32 = 96.0
	facing_right bool = true
	hp           int = 100
	max_hp       int = 100
	move         MoveType = .idle
	move_timer   f32
	attack_cooldown f32
	is_grounded  bool = true
	is_jumping   bool
	hit_timer    f32
	anim_timer   f32
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

pub struct YieArKungFuGame {
pub mut:
	state          GameState = .title
	stage_idx      int       // 0..4 (Wang, Tao, Chen, Lang, Mu)
	high_score     int       = 20000
	score          int
	round_timer    f32       = 99.0
	player         Fighter
	opponent       Fighter
	opponent_type  OpponentType = .wang
	projectiles    []Projectile
	particles      []Particle
	score_popups   []ScorePopup
	sound_mgr      SoundManager
	screen_shake   f32
	crt_filter     bool = true
	// Controls
	key_left       bool
	key_right      bool
	key_up         bool
	key_down       bool
	key_punch      bool
	key_kick       bool
}

pub fn new_yie_ar_kung_fu_game() YieArKungFuGame {
	mut g := YieArKungFuGame{
		sound_mgr: new_sound_manager()
	}
	g.reset_to_title()
	return g
}

pub fn (mut g YieArKungFuGame) reset_to_title() {
	g.state = .title
	g.stage_idx = 0
	g.particles.clear()
	g.score_popups.clear()
	g.projectiles.clear()
}

pub fn (mut g YieArKungFuGame) start_game() {
	g.score = 0
	g.stage_idx = 0
	g.init_stage(0)
}

pub fn (mut g YieArKungFuGame) init_stage(idx int) {
	g.stage_idx = idx
	g.state = .fighting
	g.round_timer = 99.0
	g.particles.clear()
	g.score_popups.clear()
	g.projectiles.clear()

	g.opponent_type = match idx % 5 {
		0 { OpponentType.wang }
		1 { OpponentType.tao }
		2 { OpponentType.chen }
		3 { OpponentType.lang }
		else { OpponentType.mu }
	}

	// Player: Oolong
	g.player = Fighter{
		x: 200.0
		y: 384.0
		hp: 100
		max_hp: 100
		facing_right: true
		move: .idle
		is_grounded: true
	}

	// Opponent Master
	g.opponent = Fighter{
		x: 540.0
		y: 384.0
		hp: 100
		max_hp: 100
		facing_right: false
		move: .idle
		is_grounded: true
	}
}

pub fn (mut g YieArKungFuGame) perform_player_attack(is_kick bool) {
	if g.player.move in [.hit_stun, .knockdown] || g.player.attack_cooldown > 0.0 {
		return
	}

	if g.player.is_jumping {
		if is_kick {
			g.player.move = if g.key_right || g.key_left { .flying_kick } else { .jump_kick }
			g.sound_mgr.play_kick_whoosh()
		} else {
			g.player.move = .jump_punch
			g.sound_mgr.play_punch_whoosh()
		}
		g.player.move_timer = 0.28
		g.player.attack_cooldown = 0.35
		return
	}

	if is_kick {
		if g.key_up {
			g.player.move = .high_kick
		} else if g.key_down {
			g.player.move = .low_kick
		} else {
			g.player.move = .mid_kick
		}
		g.sound_mgr.play_kick_whoosh()
	} else {
		if g.key_up {
			g.player.move = .high_punch
		} else if g.key_down {
			g.player.move = .low_punch
		} else {
			g.player.move = .mid_punch
		}
		g.sound_mgr.play_punch_whoosh()
	}

	g.player.move_timer = 0.24
	g.player.attack_cooldown = 0.30
}

pub fn (mut g YieArKungFuGame) update(dt f32) {
	if g.state == .paused || g.state == .title || g.state == .game_over || g.state == .round_clear {
		return
	}

	g.round_timer -= dt
	if g.round_timer <= 0.0 {
		g.state = .game_over
		return
	}

	gravity := f32(850.0)

	// 1. Update Player Movement & State
	if g.player.move_timer > 0.0 {
		g.player.move_timer -= dt
		if g.player.move_timer <= 0.0 {
			if g.player.is_grounded {
				g.player.move = .idle
			}
		}
	}
	if g.player.attack_cooldown > 0.0 {
		g.player.attack_cooldown -= dt
	}
	if g.player.hit_timer > 0.0 {
		g.player.hit_timer -= dt
	}

	// Player Movement Input (When not locked in attack or hitstun)
	if g.player.move in [.idle, .walk_forward, .walk_backward, .crouch] {
		if g.key_up && g.player.is_grounded {
			g.player.is_grounded = false
			g.player.is_jumping = true
			g.player.vy = -460.0
			g.player.vx = if g.key_right { f32(180.0) } else if g.key_left { f32(-180.0) } else { f32(0.0) }
			g.player.move = if g.key_right { .jump_forward } else if g.key_left { .jump_backward } else { .jump_straight }
		} else if g.key_down && g.player.is_grounded {
			g.player.move = .crouch
			g.player.vx = 0.0
		} else if g.key_right && g.player.is_grounded {
			g.player.move = if g.player.facing_right { .walk_forward } else { .walk_backward }
			g.player.vx = 170.0
		} else if g.key_left && g.player.is_grounded {
			g.player.move = if g.player.facing_right { .walk_backward } else { .walk_forward }
			g.player.vx = -170.0
		} else if g.player.is_grounded {
			g.player.move = .idle
			g.player.vx = 0.0
		}
	}

	// Physics
	if !g.player.is_grounded {
		g.player.vy += gravity * dt
	}
	g.player.x += g.player.vx * dt
	g.player.y += g.player.vy * dt

	if g.player.y >= 384.0 {
		g.player.y = 384.0
		g.player.vy = 0.0
		g.player.is_grounded = true
		g.player.is_jumping = false
		if g.player.move in [.jump_straight, .jump_forward, .jump_backward, .jump_punch, .jump_kick, .flying_kick] {
			g.player.move = .idle
			g.player.vx = 0.0
		}
	}

	// Arena boundaries
	if g.player.x < 60.0 {
		g.player.x = 60.0
	}
	if g.player.x > 710.0 {
		g.player.x = 710.0
	}

	// 2. Opponent AI & Movement
	g.update_opponent_ai(dt, gravity)

	// 3. Facing Direction
	g.player.facing_right = g.player.x <= g.opponent.x
	g.opponent.facing_right = g.opponent.x < g.player.x

	// 4. Combat Hitbox Collisions
	g.check_combat_hits()

	// 5. Update Projectiles
	for mut p in g.projectiles {
		if !p.active {
			continue
		}
		p.x += p.vx * dt
		p.y += p.vy * dt

		// Deflection with player attack
		if g.player.move in [.high_punch, .mid_punch, .low_punch, .high_kick, .mid_kick, .jump_punch, .jump_kick] {
			if math.abs(p.x - (g.player.x + 20.0)) < 30.0 && math.abs(p.y - (g.player.y + 20.0)) < 35.0 {
				p.active = false
				g.sound_mgr.play_weapon_clank()
				g.add_particles(p.x, p.y, 8, Color{ r: 255, g: 240, b: 80, a: 255 })
				g.score += 200
				g.add_score_popup(p.x, p.y - 10.0, '+200', Color{ r: 255, g: 220, b: 40, a: 255 })
			}
		}

		// Hit player
		if p.active && g.player.hit_timer <= 0.0 {
			if p.x > g.player.x && p.x < g.player.x + g.player.width && p.y > g.player.y && p.y < g.player.y + g.player.height {
				p.active = false
				g.player.hp -= 12
				g.player.hit_timer = 0.4
				g.player.move = .hit_stun
				g.player.move_timer = 0.3
				g.sound_mgr.play_hit_impact()
				g.add_particles(p.x, p.y, 10, Color{ r: 255, g: 60, b: 60, a: 255 })

				if g.player.hp <= 0 {
					g.player.hp = 0
					g.state = .game_over
				}
			}
		}

		if p.x < -20.0 || p.x > 820.0 {
			p.active = false
		}
	}

	// 6. Particle & Popup updates
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

	g.particles = g.particles.filter(it.active)
	g.score_popups = g.score_popups.filter(it.active)

	// BGM Streaming
	g.sound_mgr.update_bgm(f64(dt), g.state == .fighting)

	if g.screen_shake > 0.0 {
		g.screen_shake -= dt
	}

	if g.state != .fighting {
		return
	}
	g.projectiles = g.projectiles.filter(it.active)

	if g.score > g.high_score {
		g.high_score = g.score
	}
}

fn (mut g YieArKungFuGame) update_opponent_ai(dt f32, gravity f32) {
	if g.opponent.move_timer > 0.0 {
		g.opponent.move_timer -= dt
		if g.opponent.move_timer <= 0.0 && g.opponent.is_grounded {
			g.opponent.move = .idle
		}
	}
	if g.opponent.attack_cooldown > 0.0 {
		g.opponent.attack_cooldown -= dt
	}
	if g.opponent.hit_timer > 0.0 {
		g.opponent.hit_timer -= dt
	}

	dist := math.abs(g.opponent.x - g.player.x)

	// Decision Loop
	if g.opponent.attack_cooldown <= 0.0 && g.opponent.move in [.idle, .walk_forward, .walk_backward] {
		// Opponent special attacks
		match g.opponent_type {
			.wang {
				// Bo Staff Master: Poke attack or Staff Swing
				if dist < 90.0 {
					g.opponent.move = if (rand.intn(2) or { 0 }) == 0 { .mid_punch } else { .high_punch }
					g.opponent.move_timer = 0.28
					g.opponent.attack_cooldown = 0.55
					g.sound_mgr.play_weapon_clank()
				} else {
					g.opponent.vx = if g.opponent.x > g.player.x { f32(-110.0) } else { f32(110.0) }
				}
			}
			.tao {
				// Fireball Master
				if dist > 140.0 && (rand.intn(60) or { 0 }) == 0 {
					g.opponent.move = .high_punch
					g.opponent.move_timer = 0.3
					g.opponent.attack_cooldown = 1.1
					dir := if g.opponent.facing_right { f32(280.0) } else { f32(-280.0) }
					g.projectiles << Projectile{
						x: g.opponent.x + (if g.opponent.facing_right { f32(34.0) } else { f32(-10.0) })
						y: g.opponent.y + 18.0
						vx: dir
						vy: 0.0
						is_fire: true
						active: true
					}
					g.sound_mgr.play_punch_whoosh()
				} else {
					g.opponent.vx = if g.opponent.x > g.player.x { f32(-90.0) } else { f32(90.0) }
				}
			}
			.chen {
				// Chain Whip Master
				if dist < 120.0 {
					g.opponent.move = .mid_kick
					g.opponent.move_timer = 0.32
					g.opponent.attack_cooldown = 0.65
					g.sound_mgr.play_weapon_clank()
				} else {
					g.opponent.vx = if g.opponent.x > g.player.x { f32(-100.0) } else { f32(100.0) }
				}
			}
			.lang {
				// Shuriken Fan Master
				if dist > 120.0 && (rand.intn(45) or { 0 }) == 0 {
					g.opponent.move = .high_kick
					g.opponent.move_timer = 0.25
					g.opponent.attack_cooldown = 0.9
					dir := if g.opponent.facing_right { f32(320.0) } else { f32(-320.0) }
					g.projectiles << Projectile{
						x: g.opponent.x + (if g.opponent.facing_right { f32(30.0) } else { f32(-8.0) })
						y: g.opponent.y + 14.0
						vx: dir
						vy: 0.0
						is_fire: false
						active: true
					}
					g.sound_mgr.play_punch_whoosh()
				} else {
					g.opponent.vx = if g.opponent.x > g.player.x { f32(-120.0) } else { f32(120.0) }
				}
			}
			.mu {
				// Flying Somersault Master
				if g.opponent.is_grounded && (rand.intn(80) or { 0 }) == 0 {
					g.opponent.is_grounded = false
					g.opponent.is_jumping = true
					g.opponent.vy = -450.0
					g.opponent.vx = if g.opponent.facing_right { f32(200.0) } else { f32(-200.0) }
					g.opponent.move = .flying_kick
					g.opponent.attack_cooldown = 1.0
					g.sound_mgr.play_kick_whoosh()
				} else if g.opponent.is_grounded {
					g.opponent.vx = if g.opponent.x > g.player.x { f32(-130.0) } else { f32(130.0) }
				}
			}
		}
	}

	if !g.opponent.is_grounded {
		g.opponent.vy += gravity * dt
	}
	g.opponent.x += g.opponent.vx * dt
	g.opponent.y += g.opponent.vy * dt

	if g.opponent.y >= 384.0 {
		g.opponent.y = 384.0
		g.opponent.vy = 0.0
		g.opponent.is_grounded = true
		g.opponent.is_jumping = false
		if g.opponent.move == .flying_kick {
			g.opponent.move = .idle
			g.opponent.vx = 0.0
		}
	}

	if g.opponent.x < 60.0 {
		g.opponent.x = 60.0
	}
	if g.opponent.x > 710.0 {
		g.opponent.x = 710.0
	}
}

fn (mut g YieArKungFuGame) check_combat_hits() {
	dist := math.abs(g.player.x - g.opponent.x)
	y_diff := math.abs(g.player.y - g.opponent.y)

	// 1. Player hits Opponent
	if g.player.move in [.high_punch, .mid_punch, .low_punch, .high_kick, .mid_kick, .low_kick, .jump_punch, .jump_kick, .flying_kick] {
		reach := if g.player.move in [.high_kick, .flying_kick] { f32(65.0) } else { f32(48.0) }
		if dist < reach && y_diff < 45.0 && g.opponent.hit_timer <= 0.0 {
			dmg := match g.player.move {
				.flying_kick { 18 }
				.high_kick, .jump_kick { 14 }
				.mid_kick, .high_punch { 11 }
				else { 8 }
			}
			g.opponent.hp -= dmg
			g.opponent.hit_timer = 0.35
			g.opponent.move = .hit_stun
			g.opponent.move_timer = 0.25
			g.sound_mgr.play_hit_impact()
			hit_x := (g.player.x + g.opponent.x) * 0.5 + 16.0
			hit_y := g.opponent.y + 24.0
			g.add_particles(hit_x, hit_y, 12, Color{ r: 255, g: 230, b: 60, a: 255 })
			pts := dmg * 80
			g.score += pts
			g.add_score_popup(hit_x, hit_y - 20.0, '+${pts}', Color{ r: 255, g: 220, b: 40, a: 255 })

			if g.opponent.hp <= 0 {
				g.opponent.hp = 0
				g.opponent.move = .knockdown
				g.state = .round_clear
				g.sound_mgr.play_ko_victory()
			}
		}
	}

	// 2. Opponent hits Player
	if g.opponent.move in [.high_punch, .mid_punch, .high_kick, .mid_kick, .flying_kick] {
		reach := f32(54.0)
		if dist < reach && y_diff < 45.0 && g.player.hit_timer <= 0.0 {
			dmg := 12
			g.player.hp -= dmg
			g.player.hit_timer = 0.35
			g.player.move = .hit_stun
			g.player.move_timer = 0.25
			g.sound_mgr.play_hit_impact()
			hit_x := (g.player.x + g.opponent.x) * 0.5 + 16.0
			hit_y := g.player.y + 24.0
			g.add_particles(hit_x, hit_y, 12, Color{ r: 255, g: 60, b: 60, a: 255 })

			if g.player.hp <= 0 {
				g.player.hp = 0
				g.player.move = .knockdown
				g.state = .game_over
			}
		}
	}
}

pub fn (mut g YieArKungFuGame) next_stage() {
	g.stage_idx++
	if g.stage_idx >= 5 {
		g.state = .victory
	} else {
		g.init_stage(g.stage_idx)
	}
}

pub fn (mut g YieArKungFuGame) add_particles(x f32, y f32, count int, color Color) {
	for _ in 0 .. count {
		angle := f32(rand.intn(360) or { 0 }) * f32(math.pi / 180.0)
		speed := 30.0 + f32(rand.intn(100) or { 50 })
		g.particles << Particle{
			x: x
			y: y
			vx: f32(math.cos(f64(angle))) * speed
			vy: f32(math.sin(f64(angle))) * speed
			color: color
			life: 0.3 + f32(rand.intn(20) or { 10 }) / 100.0
			size: 3.5 + f32(rand.intn(3) or { 1 })
			active: true
		}
	}
}

pub fn (mut g YieArKungFuGame) add_score_popup(x f32, y f32, text string, color Color) {
	g.score_popups << ScorePopup{
		x: x
		y: y
		text: text
		color: color
		timer: 0.8
		active: true
	}
}
