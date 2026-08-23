module main

import math
import rand

pub enum GameState {
	title
	stage_intro
	playing
	paused
	stage_clear
	game_over
	victory
}

pub enum PlayerState {
	spawning
	standing
	running
	jumping
	crouching
	prone
	in_water
	dead
}

pub struct ScorePopText {
pub mut:
	text  string
	x     f32
	y     f32
	life  f32
	r     u8
	g     u8
	b     u8
}

pub struct Player {
pub mut:
	id              int
	x               f32
	y               f32
	vx              f32
	vy              f32
	aim_x           f32 = 1.0
	aim_y           f32 = 0.0
	facing_right    bool = true
	state           PlayerState = .standing
	lives           int = 3
	score           int
	weapon          WeaponType = .normal
	has_rapid       bool
	barrier_timer   f32
	invuln_timer    f32
	fire_cooldown   f32
	on_ground       bool
	in_water        bool
	drop_down_timer f32
	jump_anim_rot   f32
	spawn_timer     f32
}

pub struct Particle {
pub mut:
	x        f32
	y        f32
	vx       f32
	vy       f32
	life     f32
	max_life f32
	r        u8
	g        u8
	b        u8
	size     f32
	is_smoke bool
}

pub struct ContraGame {
pub mut:
	state              GameState = .title
	current_stage      int       = 1
	stage_data         StageData
	is_2p_mode         bool
	players            []Player
	high_score         int = 20000

	bullets            []Bullet
	enemies            []Enemy
	capsules           []FlyingCapsule
	powerups           []PowerUpItem
	particles          []Particle
	pop_texts          []ScorePopText
	bridge_segments    []BridgeSegment
	boss               Boss

	// Screen Shake & Camera
	cam_x              f32
	cam_y              f32
	shake_trauma       f32
	shake_x            f32
	shake_y            f32
	global_time        f32
	state_timer        f32

	// Konami 30 Lives Code Buffer
	konami_buffer      []int
	konami_activated   bool

	// Inputs Player 1
	p1_left            bool
	p1_right           bool
	p1_up              bool
	p1_down            bool
	p1_fire            bool
	p1_jump            bool

	// Sound Triggers
	sound_rifle        bool
	sound_spread       bool
	sound_laser        bool
	sound_fireball     bool
	sound_jump         bool
	sound_explosion    bool
	sound_powerup      bool
	sound_konami       bool
	sound_stage_clear  bool
	sound_death        bool
}

pub fn new_contra_game() ContraGame {
	mut game := ContraGame{
		stage_data: get_stage_by_number(1)
	}
	game.init_title()
	return game
}

pub fn (mut g ContraGame) init_title() {
	g.state = .title
	g.current_stage = 1
	g.konami_buffer.clear()
	g.konami_activated = false
}

pub fn (mut g ContraGame) push_konami_key(key_code int) {
	// Konami code: Up(1), Up(1), Down(2), Down(2), Left(3), Right(4), Left(3), Right(4), B(5), A(6)
	g.konami_buffer << key_code
	if g.konami_buffer.len > 10 {
		g.konami_buffer.delete(0)
	}
	target := [1, 1, 2, 2, 3, 4, 3, 4, 5, 6]
	if g.konami_buffer.len == 10 {
		mut matches := true
		for i in 0 .. 10 {
			if g.konami_buffer[i] != target[i] {
				matches = false
				break
			}
		}
		if matches {
			g.konami_activated = true
			g.sound_konami = true
		}
	}
}

pub fn (mut g ContraGame) add_pop_text(text string, x f32, y f32, r u8, g_col u8, b u8) {
	g.pop_texts << ScorePopText{
		text: text
		x: x
		y: y
		life: 1.0
		r: r
		g: g_col
		b: b
	}
}

pub fn (mut g ContraGame) trigger_shake(amount f32) {
	g.shake_trauma = f32(math.min(1.0, f64(g.shake_trauma + amount)))
}

pub fn (mut g ContraGame) start_game(stage_num int, is_2p bool) {
	g.current_stage = stage_num
	g.is_2p_mode = is_2p
	g.stage_data = get_stage_by_number(stage_num)
	g.players.clear()

	init_lives := if g.konami_activated { 30 } else { 3 }

	g.players << Player{
		id: 1
		x: g.stage_data.def.spawn_x
		y: g.stage_data.def.spawn_y
		lives: init_lives
		state: .spawning
		spawn_timer: 1.2
		invuln_timer: 3.0
	}

	if is_2p {
		g.players << Player{
			id: 2
			x: g.stage_data.def.spawn_x - 30.0
			y: g.stage_data.def.spawn_y
			lives: init_lives
			state: .spawning
			spawn_timer: 1.2
			invuln_timer: 3.0
		}
	}

	g.bullets.clear()
	g.enemies.clear()
	g.capsules.clear()
	g.powerups.clear()
	g.particles.clear()
	g.pop_texts.clear()
	g.bridge_segments.clear()

	for b in g.stage_data.bridges {
		g.bridge_segments << BridgeSegment{
			x: b.x
			y: b.y
			w: b.w
			h: b.h
			explode_delay: b.explode_delay
		}
	}

	g.boss = g.stage_data.boss
	g.cam_x = 0
	g.cam_y = 0
	g.state = .stage_intro
	g.state_timer = 2.0
}

pub fn (mut g ContraGame) add_particle(x f32, y f32, vx f32, vy f32, life f32, r u8, g_col u8, b u8, size f32, is_smoke bool) {
	g.particles << Particle{
		x: x
		y: y
		vx: vx
		vy: vy
		life: life
		max_life: life
		r: r
		g: g_col
		b: b
		size: size
		is_smoke: is_smoke
	}
}

pub fn (mut g ContraGame) create_explosion(x f32, y f32, count int) {
	g.sound_explosion = true
	g.trigger_shake(0.35)
	for _ in 0 .. count {
		angle := f32(rand.intn(360) or { 0 }) * math.pi / 180.0
		spd := 60.0 + f32(rand.intn(180) or { 90 })
		g.add_particle(
			x, y,
			f32(math.cos(angle)) * spd,
			f32(math.sin(angle)) * spd,
			0.5 + f32(rand.intn(30) or { 15 }) * 0.01,
			255,
			u8(100 + rand.intn(155) or { 100 }),
			30,
			f32(5.0 + f64(rand.intn(8) or { 4 })),
			false
		)
		// Smoke cloud
		g.add_particle(
			x + (f32(rand.intn(20) or { 10 }) - 10.0),
			y + (f32(rand.intn(20) or { 10 }) - 10.0),
			f32(math.cos(angle)) * spd * 0.4,
			f32(math.sin(angle)) * spd * 0.4 - 20.0,
			0.8,
			140, 140, 140,
			7.0,
			true
		)
	}
}

pub fn (mut g ContraGame) update(dt f32) {
	g.global_time += dt

	// Decay screen shake
	if g.shake_trauma > 0 {
		g.shake_trauma = f32(math.max(0.0, f64(g.shake_trauma - dt * 1.8)))
		shake_mag := g.shake_trauma * g.shake_trauma * 14.0
		g.shake_x = (f32(rand.intn(200) or { 100 }) - 100.0) * 0.01 * shake_mag
		g.shake_y = (f32(rand.intn(200) or { 100 }) - 100.0) * 0.01 * shake_mag
	} else {
		g.shake_x = 0
		g.shake_y = 0
	}

	match g.state {
		.title {}
		.stage_intro {
			g.state_timer -= dt
			if g.state_timer <= 0 {
				g.state = .playing
			}
		}
		.playing {
			g.update_playing(dt)
		}
		.paused {}
		.stage_clear {
			g.state_timer -= dt
			g.update_particles(dt)
			g.update_pop_texts(dt)
			if g.state_timer <= 0 {
				if g.current_stage >= 4 {
					g.state = .victory
					g.state_timer = 6.0
				} else {
					g.start_game(g.current_stage + 1, g.is_2p_mode)
				}
			}
		}
		.game_over {
			g.state_timer -= dt
			g.update_particles(dt)
			g.update_pop_texts(dt)
		}
		.victory {
			g.state_timer -= dt
			g.update_particles(dt)
			g.update_pop_texts(dt)
		}
	}
}

fn (mut g ContraGame) update_pop_texts(dt f32) {
	for mut pt in g.pop_texts {
		pt.y -= dt * 35.0
		pt.life -= dt
	}
	g.pop_texts = g.pop_texts.filter(it.life > 0)
}

fn (mut g ContraGame) update_playing(dt f32) {
	g.update_players(dt)
	g.update_camera(dt)
	g.update_spawners(dt)
	g.update_enemies(dt)
	g.update_capsules(dt)
	g.update_powerups(dt)
	g.update_bullets(dt)
	g.update_boss(dt)
	g.update_bridges(dt)
	g.update_particles(dt)
	g.update_pop_texts(dt)

	// Check if all players dead
	mut any_alive := false
	for p in g.players {
		if p.lives > 0 || p.state != .dead {
			any_alive = true
			break
		}
	}
	if !any_alive {
		g.state = .game_over
		g.state_timer = 4.0
	}
}

fn (mut g ContraGame) update_players(dt f32) {
	for mut p in g.players {
		if p.state == .dead {
			if p.lives > 0 {
				p.spawn_timer -= dt
				if p.spawn_timer <= 0 {
					p.lives--
					p.state = .spawning
					p.x = g.cam_x + 100.0
					p.y = 100.0
					p.vx = 0
					p.vy = 0
					p.invuln_timer = 3.5
					p.weapon = .normal
					p.has_rapid = false
				}
			}
			continue
		}

		if p.invuln_timer > 0 {
			p.invuln_timer -= dt
		}
		if p.barrier_timer > 0 {
			p.barrier_timer -= dt
		}
		if p.fire_cooldown > 0 {
			p.fire_cooldown -= dt
		}
		if p.drop_down_timer > 0 {
			p.drop_down_timer -= dt
		}

		// Input controls for Player 1
		if p.id == 1 {
			mut mx := f32(0.0)
			if g.p1_left { mx -= 1.0; p.facing_right = false }
			if g.p1_right { mx += 1.0; p.facing_right = true }

			// 8-way Aiming
			if g.p1_up {
				if mx != 0 {
					p.aim_x = if p.facing_right { f32(0.707) } else { f32(-0.707) }
					p.aim_y = -0.707
				} else {
					p.aim_x = 0.0
					p.aim_y = -1.0
				}
			} else if g.p1_down {
				if p.on_ground && mx == 0 {
					p.aim_x = if p.facing_right { f32(1.0) } else { f32(-1.0) }
					p.aim_y = 0.0
				} else {
					if mx != 0 {
						p.aim_x = if p.facing_right { f32(0.707) } else { f32(-0.707) }
						p.aim_y = 0.707
					} else {
						p.aim_x = 0.0
						p.aim_y = 1.0
					}
				}
			} else {
				p.aim_x = if p.facing_right { f32(1.0) } else { f32(-1.0) }
				p.aim_y = 0.0
			}

			// Movement speed
			move_spd := f32(200.0)
			if p.on_ground && g.p1_down && mx == 0 {
				p.vx = 0.0
			} else {
				p.vx = mx * move_spd
			}

			// State resolution
			if p.on_ground {
				if g.p1_down && mx == 0 {
					p.state = .prone
					if g.p1_jump && p.drop_down_timer <= 0 {
						p.drop_down_timer = 0.35
						p.y += 6.0
						p.on_ground = false
						p.state = .jumping
					}
				} else {
					if mx != 0 {
						p.state = .running
					} else {
						p.state = .standing
					}

					if g.p1_jump {
						p.vy = -560.0
						p.on_ground = false
						p.state = .jumping
						p.jump_anim_rot = 0.0
						g.sound_jump = true
					}
				}
			} else {
				p.state = .jumping
				p.jump_anim_rot += dt * 16.0
			}

			// Firing
			if g.p1_fire && p.fire_cooldown <= 0 {
				cooldown := match p.weapon {
					.machine_gun { f32(0.09) }
					.spread_gun { f32(0.24) }
					.laser { f32(0.20) }
					.fire_gun { f32(0.22) }
					else { f32(0.16) }
				}
				p.fire_cooldown = if p.has_rapid { cooldown * 0.65 } else { cooldown }

				// Gun muzzle coordinate
				gun_x := p.x + p.aim_x * 16.0
				gun_y := p.y - 18.0 + p.aim_y * 16.0

				new_bullets := create_player_bullets(gun_x, gun_y, p.aim_x, p.aim_y, p.weapon, p.has_rapid, p.id)
				g.bullets << new_bullets

				match p.weapon {
					.spread_gun { g.sound_spread = true }
					.laser { g.sound_laser = true }
					.fire_gun { g.sound_fireball = true }
					else { g.sound_rifle = true }
				}
			}
		}

		// Gravity
		p.vy += 1200.0 * dt
		if p.vy > 750.0 { p.vy = 750.0 }

		p.x += p.vx * dt
		p.y += p.vy * dt

		// Clamping to camera bounds
		if p.x < g.cam_x + 12.0 { p.x = g.cam_x + 12.0 }
		if p.x > g.cam_x + 828.0 { p.x = g.cam_x + 828.0 }

		// Platform collision
		p.on_ground = false
		p.in_water = false
		p_box_w := f32(18.0)

		for plat in g.stage_data.platforms {
			if plat.is_water {
				if p.x >= plat.x && p.x <= plat.x + plat.w && p.y >= plat.y && p.y <= plat.y + plat.h {
					p.in_water = true
					p.on_ground = true
					p.vy = 0
					p.y = plat.y + 12.0
					p.state = .in_water
				}
				continue
			}

			if p.drop_down_timer > 0 && plat.one_way { continue }

			if p.x + p_box_w * 0.5 >= plat.x && p.x - p_box_w * 0.5 <= plat.x + plat.w {
				if p.vy >= 0 && p.y >= plat.y && p.y - p.vy * dt <= plat.y + 14.0 {
					p.y = plat.y
					p.vy = 0
					p.on_ground = true
				}
			}
		}

		// Check active unexploded bridge segments
		for seg in g.bridge_segments {
			if seg.exploded { continue }
			if p.x + p_box_w * 0.5 >= seg.x && p.x - p_box_w * 0.5 <= seg.x + seg.w {
				if p.vy >= 0 && p.y >= seg.y && p.y - p.vy * dt <= seg.y + 14.0 {
					p.y = seg.y
					p.vy = 0
					p.on_ground = true
				}
			}
		}

		// Check death pit
		if p.y > 540.0 {
			g.kill_player(mut p)
		}
	}
}

pub fn (mut g ContraGame) kill_player(mut p Player) {
	if p.state == .dead || p.invuln_timer > 0 || p.barrier_timer > 0 {
		return
	}
	p.state = .dead
	p.spawn_timer = 1.5
	g.sound_death = true
	g.create_explosion(p.x, p.y - 20.0, 16)
}

fn (mut g ContraGame) update_camera(dt f32) {
	if g.players.len == 0 { return }
	p1 := g.players[0]

	match g.stage_data.def.stage_type {
		.side_scroll, .alien_lair {
			target_cam := p1.x - 300.0
			if target_cam > g.cam_x {
				g.cam_x += (target_cam - g.cam_x) * f32(math.min(1.0, f64(dt * 8.0)))
			}
			max_cam := g.stage_data.def.length - 840.0
			if g.cam_x > max_cam { g.cam_x = max_cam }
			if g.cam_x < 0 { g.cam_x = 0 }
		}
		.vertical_scroll {
			target_cam_y := p1.y - 320.0
			if target_cam_y < g.cam_y {
				g.cam_y += (target_cam_y - g.cam_y) * f32(math.min(1.0, f64(dt * 8.0)))
			}
			if g.cam_y > 0 { g.cam_y = 0 }
		}
		.base_3d {}
	}
}

fn (mut g ContraGame) update_spawners(dt f32) {
	for mut sp in g.stage_data.spawners {
		sp.timer += dt
		if sp.timer >= sp.interval {
			sp.timer = 0.0
			// Spawn enemy if near camera
			if sp.x >= g.cam_x - 50.0 && sp.x <= g.cam_x + 900.0 {
				g.enemies << Enemy{
					x: sp.x
					y: sp.y
					enemy_type: sp.enemy_type
					facing_right: sp.facing_right
					health: 1
				}
			}
		}
	}
}

fn (mut g ContraGame) update_enemies(dt f32) {
	for mut e in g.enemies {
		if !e.active { continue }
		e.timer += dt
		e.shoot_timer += dt

		match e.enemy_type {
			.runner {
				spd := if e.facing_right { f32(110.0) } else { f32(-110.0) }
				e.vx = spd
				e.vy += 1000.0 * dt
				e.x += e.vx * dt
				e.y += e.vy * dt

				// Platform check
				for plat in g.stage_data.platforms {
					if !plat.is_water && e.x >= plat.x && e.x <= plat.x + plat.w {
						if e.vy >= 0 && e.y >= plat.y && e.y - e.vy * dt <= plat.y + 12.0 {
							e.y = plat.y
							e.vy = 0
							e.on_ground = true
						}
					}
				}

				if e.y > 540.0 || e.x < g.cam_x - 100.0 || e.x > g.cam_x + 940.0 {
					e.active = false
				}
			}
			.sniper {
				if e.shoot_timer >= 2.0 {
					e.shoot_timer = 0.0
					if g.players.len > 0 {
						p := g.players[0]
						g.bullets << create_enemy_bullet(e.x, e.y - 20.0, p.x, p.y - 20.0, 240.0)
					}
				}
			}
			.turret {
				if e.shoot_timer >= 2.4 {
					e.shoot_timer = 0.0
					if g.players.len > 0 {
						p := g.players[0]
						g.bullets << create_enemy_bullet(e.x, e.y - 12.0, p.x, p.y - 20.0, 220.0)
					}
				}
			}
			.scuba {
				e.y = 440.0 + f32(math.sin(f64(e.timer * 2.0))) * 15.0
				if e.shoot_timer >= 2.8 {
					e.shoot_timer = 0.0
					if g.players.len > 0 {
						p := g.players[0]
						g.bullets << create_enemy_bullet(e.x, e.y - 8.0, p.x, p.y - 20.0, 230.0)
					}
				}
			}
			.barrel {
				e.x -= 160.0 * dt
				e.y += e.vy * dt
				e.vy += 800.0 * dt
				for plat in g.stage_data.platforms {
					if !plat.is_water && e.x >= plat.x && e.x <= plat.x + plat.w {
						if e.vy >= 0 && e.y >= plat.y && e.y - e.vy * dt <= plat.y + 12.0 {
							e.y = plat.y
							e.vy = 0
						}
					}
				}
				if e.x < g.cam_x - 50.0 { e.active = false }
			}
			.facehugger {
				if g.players.len > 0 {
					p := g.players[0]
					dx := p.x - e.x
					e.vx = if dx > 0 { f32(140.0) } else { f32(-140.0) }
					e.x += e.vx * dt
				}
			}
		}

		// Check player collision
		for mut p in g.players {
			if p.state != .dead && p.invuln_timer <= 0 && p.barrier_timer <= 0 {
				dx := math.abs(f64(p.x - e.x))
				dy := math.abs(f64((p.y - 18.0) - (e.y - 16.0)))
				if dx < 18.0 && dy < 22.0 {
					g.kill_player(mut p)
				}
			}
		}
	}
}

fn (mut g ContraGame) update_capsules(dt f32) {
	for mut cap in g.capsules {
		if !cap.active { continue }
		cap.timer += dt
		cap.x += cap.vx * dt
		cap.y += f32(math.sin(f64(cap.timer * 3.0))) * 1.5

		if cap.x > g.cam_x + 900.0 || cap.x < g.cam_x - 100.0 {
			cap.active = false
		}
	}

	// Periodically spawn flying capsules
	if rand.intn(300) or { 0 } == 0 && g.capsules.len < 2 {
		g.capsules << FlyingCapsule{
			x: g.cam_x - 20.0
			y: 120.0 + f32(rand.intn(100) or { 50 })
			vx: 120.0
			vy: 0
			w_type: random_powerup_type()
		}
	}
}

fn (mut g ContraGame) update_powerups(dt f32) {
	for mut item in g.powerups {
		if !item.active { continue }
		item.timer += dt
		if !item.on_ground {
			item.vy += 600.0 * dt
			item.x += item.vx * dt
			item.y += item.vy * dt

			for plat in g.stage_data.platforms {
				if !plat.is_water && item.x >= plat.x && item.x <= plat.x + plat.w {
					if item.vy >= 0 && item.y >= plat.y && item.y - item.vy * dt <= plat.y + 10.0 {
						item.y = plat.y
						item.vy = 0
						item.on_ground = true
					}
				}
			}
		}

		// Check player pickup
		for mut p in g.players {
			if p.state != .dead {
				dx := math.abs(f64(p.x - item.x))
				dy := math.abs(f64((p.y - 18.0) - item.y))
				if dx < 24.0 && dy < 24.0 {
					item.active = false
					g.sound_powerup = true
					p.score += 500
					name := match item.w_type {
						.machine_gun { 'MACHINE GUN!' }
						.spread_gun { 'SPREAD GUN!' }
						.laser { 'LASER GUN!' }
						.fire_gun { 'FIRE GUN!' }
						.rapid { 'RAPID FIRE!' }
						.barrier { 'BARRIER SHIELD!' }
						else { 'POWER UP!' }
					}
					g.add_pop_text('+500 ${name}', p.x, p.y - 30.0, 255, 220, 40)

					match item.w_type {
						.rapid { p.has_rapid = true }
						.barrier { p.barrier_timer = 12.0 }
						else { p.weapon = item.w_type }
					}
				}
			}
		}
	}
}

fn (mut g ContraGame) update_bullets(dt f32) {
	for mut b in g.bullets {
		b.x += b.vx * dt
		b.y += b.vy * dt
		b.life -= dt
		b.rot += dt * 10.0

		// Add trail points
		b.trail << BulletTrailPoint{x: b.x, y: b.y, alpha: 1.0}
		if b.trail.len > 5 {
			b.trail.delete(0)
		}
		for mut tp in b.trail {
			tp.alpha -= dt * 3.0
		}

		if b.is_player {
			// Player bullet vs Enemies
			for mut e in g.enemies {
				if !e.active { continue }
				dx := math.abs(f64(b.x - e.x))
				dy := math.abs(f64(b.y - (e.y - 16.0)))
				if dx < 18.0 && dy < 20.0 {
					e.health -= b.damage
					if !b.piercing { b.life = 0 }

					if e.health <= 0 {
						e.active = false
						g.create_explosion(e.x, e.y - 16.0, 10)
						if g.players.len > 0 {
							g.players[0].score += 100
							g.add_pop_text('+100', e.x, e.y - 20.0, 255, 255, 255)
						}
					}
				}
			}

			// Player bullet vs Flying Capsules
			for mut cap in g.capsules {
				if !cap.active { continue }
				dx := math.abs(f64(b.x - cap.x))
				dy := math.abs(f64(b.y - cap.y))
				if dx < 20.0 && dy < 16.0 {
					cap.active = false
					if !b.piercing { b.life = 0 }
					g.create_explosion(cap.x, cap.y, 8)
					g.powerups << PowerUpItem{
						x: cap.x
						y: cap.y
						vx: 0
						vy: -150.0
						w_type: cap.w_type
					}
				}
			}

			// Player bullet vs Boss Parts
			if g.boss.active {
				for mut part in g.boss.parts {
					if part.destroyed { continue }
					px := g.boss.x + part.rel_x
					py := g.boss.y + part.rel_y
					dx := math.abs(f64(b.x - px))
					dy := math.abs(f64(b.y - py))
					if dx < f64(part.w * 0.5) && dy < f64(part.h * 0.5) {
						part.health -= b.damage
						g.boss.flash_timer = 0.1
						if !b.piercing { b.life = 0 }

						if part.health <= 0 {
							part.destroyed = true
							g.create_explosion(px, py, 18)
							if g.players.len > 0 {
								g.players[0].score += 1000
								g.add_pop_text('+1000 BOSS PART!', px, py, 255, 215, 0)
							}
						}
					}
				}
			}
		} else {
			// Enemy bullet vs Players
			for mut p in g.players {
				if p.state != .dead && p.invuln_timer <= 0 && p.barrier_timer <= 0 {
					dx := math.abs(f64(b.x - p.x))
					dy := math.abs(f64(b.y - (p.y - 18.0)))
					if dx < 14.0 && dy < 18.0 {
						b.life = 0
						g.kill_player(mut p)
					}
				}
			}
		}
	}

	// Projectile Vaporization: Lasers & Fireballs vaporize enemy bullets
	for mut pb in g.bullets {
		if !pb.is_player || (pb.w_type != .laser && pb.w_type != .fire_gun) { continue }
		for mut eb in g.bullets {
			if eb.is_player || eb.life <= 0 { continue }
			dx := math.abs(f64(pb.x - eb.x))
			dy := math.abs(f64(pb.y - eb.y))
			if dx < 14.0 && dy < 14.0 {
				eb.life = 0
				g.add_particle(eb.x, eb.y, 0, 0, 0.2, 100, 220, 255, 4.0, false)
			}
		}
	}

	g.bullets = g.bullets.filter(it.life > 0 && it.x >= g.cam_x - 60.0 && it.x <= g.cam_x + 900.0 && it.y >= -50.0 && it.y <= 520.0)
}

fn (mut g ContraGame) update_boss(dt f32) {
	if !g.boss.active { return }
	g.boss.timer += dt
	if g.boss.flash_timer > 0 { g.boss.flash_timer -= dt }

	// Boss attack logic
	if g.boss.timer >= 2.2 {
		g.boss.timer = 0.0
		for part in g.boss.parts {
			if part.destroyed { continue }
			px := g.boss.x + part.rel_x
			py := g.boss.y + part.rel_y
			if g.players.len > 0 {
				p := g.players[0]
				g.bullets << create_enemy_bullet(px, py, p.x, p.y - 18.0, 260.0)
			}
		}
	}

	// Check if core destroyed -> Boss Defeated!
	mut core_alive := false
	for part in g.boss.parts {
		if part.is_core && !part.destroyed {
			core_alive = true
			break
		}
	}

	if !core_alive {
		g.boss.active = false
		g.sound_stage_clear = true
		g.create_explosion(g.boss.x, g.boss.y, 40)
		g.state = .stage_clear
		g.state_timer = 4.0
		if g.players.len > 0 {
			g.players[0].score += 5000
			g.add_pop_text('+5000 STAGE CLEAR!', g.boss.x, g.boss.y - 40.0, 40, 255, 120)
		}
	}
}

fn (mut g ContraGame) update_bridges(dt f32) {
	if g.players.len == 0 { return }
	p1 := g.players[0]

	for mut seg in g.bridge_segments {
		if seg.exploded { continue }
		if p1.x >= seg.x && !seg.triggered {
			seg.triggered = true
		}
		if seg.triggered {
			seg.explode_delay -= dt
			if seg.explode_delay <= 0 {
				seg.exploded = true
				g.create_explosion(seg.x + seg.w * 0.5, seg.y + seg.h * 0.5, 14)
				g.trigger_shake(0.25)
			}
		}
	}
}

fn (mut g ContraGame) update_particles(dt f32) {
	for mut p in g.particles {
		p.x += p.vx * dt
		p.y += p.vy * dt
		p.life -= dt
	}
	g.particles = g.particles.filter(it.life > 0)
}
