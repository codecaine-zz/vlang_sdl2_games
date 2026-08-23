module main

import math
import rand

pub enum GameState {
	title
	playing
	stage_clear
	paused
	game_over
	victory
}

pub enum StageType {
	forest
	waterway
	castle_wall
	castle_keep
}

pub enum NinjutsuType {
	none
	lightning
	shadow_clones
	fire_shield
	golden_speed
}

pub enum EnemyType {
	red_ninja
	blue_ninja
	fire_monk
	water_ninja
	boss_warlord
}

pub struct TreeBranch {
pub:
	x f32
	y f32
	w f32
	h f32
}

pub struct Projectile {
pub mut:
	x           f32
	y           f32
	vx          f32
	vy          f32
	is_player   bool
	is_deflected bool
	is_fire     bool
	radius      f32 = 5.0
	life        f32 = 2.5
	active      bool = true
}

pub struct MagicScroll {
pub mut:
	x           f32
	y           f32
	vy          f32 = 40.0
	scroll_type NinjutsuType
	active      bool = true
	anim_timer  f32
}

pub struct Player {
pub mut:
	x               f32 = 120.0
	y               f32 = 490.0
	vx              f32
	vy              f32
	width           f32 = 26.0
	height          f32 = 38.0
	facing_right    bool = true
	is_grounded     bool
	is_jumping      bool
	is_perched      bool
	sword_timer     f32 // Active sword swing duration
	slash_cooldown  f32
	shuriken_cd     f32
	invuln_timer    f32
	lives           int = 3
	score           int
	active_jutsu    NinjutsuType = .none
	jutsu_timer     f32
	anim_timer      f32
	walk_frame      int
	is_dead         bool
	dead_timer      f32
}

pub struct Enemy {
pub mut:
	id           int
	enemy_type   EnemyType
	x            f32
	y            f32
	vx           f32
	vy           f32
	width        f32 = 26.0
	height       f32 = 38.0
	facing_right bool = true
	is_grounded  bool
	hp           int = 1
	attack_timer f32
	jump_timer   f32
	anim_timer   f32
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

pub struct LegendOfKageGame {
pub mut:
	state           GameState = .title
	stage           StageType = .forest
	season          int       = 1 // 1=Summer, 2=Autumn, 3=Winter, 4=Spring
	high_score      int       = 30000
	camera_x        f32
	camera_y        f32
	player          Player
	branches        []TreeBranch
	enemies         []Enemy
	projectiles     []Projectile
	scrolls         []MagicScroll
	particles       []Particle
	score_popups    []ScorePopup
	sound_mgr       SoundManager
	screen_shake    f32
	shake_x         f32
	shake_y         f32
	lightning_flash f32
	enemies_slain   int
	stage_target    int = 14
	spawn_timer     f32
	banner_timer    f32
	crt_filter      bool = true
	// Controls
	key_left        bool
	key_right       bool
	key_up          bool
	key_down        bool
	key_jump        bool
	key_slash       bool
	key_shuriken    bool
}

pub fn new_legend_of_kage_game() LegendOfKageGame {
	mut g := LegendOfKageGame{
		sound_mgr: new_sound_manager()
	}
	g.reset_to_title()
	return g
}

pub fn (mut g LegendOfKageGame) reset_to_title() {
	g.state = .title
	g.enemies.clear()
	g.projectiles.clear()
	g.scrolls.clear()
	g.particles.clear()
	g.score_popups.clear()
	g.branches.clear()
}

pub fn (mut g LegendOfKageGame) start_game() {
	g.state = .playing
	g.stage = .forest
	g.season = 1
	g.player = Player{
		x: 120.0
		y: 490.0
		lives: 3
		score: 0
		invuln_timer: 2.0
	}
	g.init_stage(StageType.forest)
}

pub fn (mut g LegendOfKageGame) init_stage(stage_type StageType) {
	g.stage = stage_type
	g.enemies.clear()
	g.projectiles.clear()
	g.scrolls.clear()
	g.particles.clear()
	g.score_popups.clear()
	g.branches.clear()
	g.camera_x = 0.0
	g.camera_y = 0.0
	g.enemies_slain = 0
	g.spawn_timer = 1.0
	g.banner_timer = 2.0

	// Player initial position
	g.player.x = 140.0
	g.player.y = 490.0
	g.player.vx = 0.0
	g.player.vy = 0.0
	g.player.is_grounded = true
	g.player.is_jumping = false
	g.player.is_dead = false

	match stage_type {
		.forest {
			g.stage_target = 12
			// Generate tall forest tree branches across wide world
			for b_idx in 0 .. 16 {
				bx := 180.0 + f32(b_idx) * 160.0
				by := 180.0 + f32((b_idx * 73) % 220)
				bw := 90.0 + f32((b_idx * 37) % 60)
				g.branches << TreeBranch{ x: bx, y: by, w: bw, h: 14.0 }
			}
		}
		.waterway {
			g.stage_target = 14
			// River platforms & bridge piers
			for b_idx in 0 .. 12 {
				bx := 120.0 + f32(b_idx) * 220.0
				by := 240.0 + f32((b_idx * 51) % 180)
				g.branches << TreeBranch{ x: bx, y: by, w: 100.0, h: 16.0 }
			}
		}
		.castle_wall {
			g.stage_target = 16
			// Vertical fortress battlements
			for b_idx in 0 .. 18 {
				bx := 100.0 + f32((b_idx * 137) % 550)
				by := 120.0 + f32(b_idx) * 90.0
				g.branches << TreeBranch{ x: bx, y: by, w: 110.0, h: 16.0 }
			}
		}
		.castle_keep {
			g.stage_target = 1 // Boss battle!
			// Throne room multi-tiered pillars
			g.branches << TreeBranch{ x: 120.0, y: 360.0, w: 140.0, h: 16.0 }
			g.branches << TreeBranch{ x: 540.0, y: 360.0, w: 140.0, h: 16.0 }
			g.branches << TreeBranch{ x: 300.0, y: 240.0, w: 200.0, h: 16.0 }

			// Spawn Warlord Yoshiro Boss
			g.enemies << Enemy{
				id: 99
				enemy_type: .boss_warlord
				x: 580.0
				y: 320.0
				vx: -90.0
				vy: 0.0
				hp: 6
				facing_right: false
				is_grounded: true
				active: true
			}
		}
	}
}

pub fn (mut g LegendOfKageGame) spawn_enemy() {
	if g.stage == .castle_keep {
		// Only boss in castle keep
		return
	}

	cam_center := g.camera_x + 400.0
	from_left := (rand.intn(2) or { 0 }) == 0
	spawn_x := if from_left { cam_center - 450.0 } else { cam_center + 450.0 }
	spawn_y := if (rand.intn(3) or { 0 }) == 0 { 140.0 + f32(rand.intn(180) or { 0 }) } else { f32(490.0) }

	mut e_type := EnemyType.red_ninja
	r := rand.intn(100) or { 50 }

	match g.stage {
		.forest {
			e_type = if r < 60 { EnemyType.red_ninja } else { EnemyType.blue_ninja }
		}
		.waterway {
			if r < 40 {
				e_type = .red_ninja
			} else if r < 75 {
				e_type = .water_ninja
			} else {
				e_type = .fire_monk
			}
		}
		.castle_wall {
			if r < 50 {
				e_type = .blue_ninja
			} else if r < 80 {
				e_type = .red_ninja
			} else {
				e_type = .fire_monk
			}
		}
		else {}
	}

	dir := if from_left { f32(1.0) } else { f32(-1.0) }
	mut e := Enemy{
		id: g.enemies.len + 1
		enemy_type: e_type
		x: spawn_x
		y: spawn_y
		vx: dir * (110.0 + f32(rand.intn(40) or { 20 }))
		vy: 0.0
		facing_right: from_left
		hp: if e_type == .fire_monk { 2 } else { 1 }
		is_grounded: spawn_y >= 480.0
		attack_timer: 1.0 + f32(rand.intn(15) or { 5 }) / 10.0
		jump_timer: 0.8 + f32(rand.intn(20) or { 10 }) / 10.0
		active: true
	}

	g.enemies << e
}

pub fn (mut g LegendOfKageGame) player_slash() {
	if g.player.slash_cooldown > 0.0 || g.player.is_dead {
		return
	}
	g.player.sword_timer = 0.22
	g.player.slash_cooldown = 0.28
	g.sound_mgr.play_sword_slash()

	// Sword Slash Box
	slash_x := if g.player.facing_right { g.player.x + 12.0 } else { g.player.x - 28.0 }
	slash_y := g.player.y + 4.0
	slash_w := f32(38.0)
	slash_h := f32(32.0)

	// 1. Deflect / Destroy enemy projectiles in mid-air
	for mut p in g.projectiles {
		if p.active && !p.is_player {
			if p.x > slash_x && p.x < slash_x + slash_w && p.y > slash_y && p.y < slash_y + slash_h {
				p.active = false
				g.sound_mgr.play_parry_clink()
				g.add_particles(p.x, p.y, 8, Color{ r: 255, g: 240, b: 120, a: 255 })
				g.add_score_popup(p.x, p.y, 'PARRY +200', Color{ r: 255, g: 230, b: 80, a: 255 })
				g.player.score += 200
			}
		}
	}

	// 2. Slash enemies
	for mut e in g.enemies {
		if !e.active {
			continue
		}
		if e.x + e.width > slash_x && e.x < slash_x + slash_w && e.y + e.height > slash_y && e.y < slash_y + slash_h {
			e.hp--
			g.add_particles(e.x + e.width * 0.5, e.y + e.height * 0.5, 12, Color{ r: 255, g: 80, b: 80, a: 255 })
			if e.hp <= 0 {
				e.active = false
				g.enemies_slain++
				g.sound_mgr.play_enemy_death()
				pts := if e.enemy_type == .boss_warlord { 5000 } else if e.enemy_type == .fire_monk { 500 } else { 300 }
				g.player.score += pts
				g.add_score_popup(e.x, e.y, '+${pts}', Color{ r: 255, g: 220, b: 60, a: 255 })

				// Chance to drop Magic Scroll
				if (rand.intn(100) or { 50 }) < 28 {
					g.spawn_scroll(e.x, e.y)
				}
			} else {
				g.sound_mgr.play_parry_clink()
			}
		}
	}
}

pub fn (mut g LegendOfKageGame) player_throw_shuriken() {
	if g.player.shuriken_cd > 0.0 || g.player.is_dead {
		return
	}
	g.player.shuriken_cd = 0.22
	g.sound_mgr.play_shuriken_throw()

	sx := if g.player.facing_right { g.player.x + g.player.width + 4.0 } else { g.player.x - 8.0 }
	sy := g.player.y + 14.0
	dir := if g.player.facing_right { f32(1.0) } else { f32(-1.0) }
	mut vx := dir * 480.0
	mut vy := f32(0.0)

	if g.key_up {
		if g.key_left || g.key_right {
			vx = dir * 360.0
			vy = -360.0
		} else {
			vx = 0.0
			vy = -480.0
		}
	} else if g.key_down {
		if g.key_left || g.key_right {
			vx = dir * 360.0
			vy = 360.0
		} else {
			vx = 0.0
			vy = 480.0
		}
	}

	g.projectiles << Projectile{
		x: sx
		y: sy
		vx: vx
		vy: vy
		is_player: true
		active: true
	}

	// If shadow clones jutsu active, clones also throw shurikens!
	if g.player.active_jutsu == .shadow_clones {
		g.projectiles << Projectile{
			x: sx - dir * 24.0
			y: sy - 12.0
			vx: vx
			vy: vy - 60.0
			is_player: true
			active: true
		}
		g.projectiles << Projectile{
			x: sx - dir * 24.0
			y: sy + 12.0
			vx: vx
			vy: vy + 60.0
			is_player: true
			active: true
		}
	}
}

pub fn (mut g LegendOfKageGame) spawn_scroll(x f32, y f32) {
	r := rand.intn(4) or { 0 }
	s_type := match r {
		0 { NinjutsuType.lightning }
		1 { NinjutsuType.shadow_clones }
		2 { NinjutsuType.fire_shield }
		else { NinjutsuType.golden_speed }
	}
	g.scrolls << MagicScroll{
		x: x
		y: y
		scroll_type: s_type
		active: true
	}
}

pub fn (mut g LegendOfKageGame) activate_ninjutsu(j_type NinjutsuType) {
	g.player.active_jutsu = j_type
	g.player.jutsu_timer = 12.0

	match j_type {
		.lightning {
			g.lightning_flash = 0.5
			g.screen_shake = 0.4
			g.sound_mgr.play_scroll_jutsu()
			// Clear all non-boss enemies
			for mut e in g.enemies {
				if e.active && e.enemy_type != .boss_warlord {
					e.active = false
					g.enemies_slain++
					g.add_particles(e.x + 12.0, e.y + 16.0, 16, Color{ r: 120, g: 220, b: 255, a: 255 })
					g.player.score += 500
				}
			}
			g.add_score_popup(g.player.x, g.player.y - 30.0, 'LIGHTNING NINJUTSU!', Color{ r: 100, g: 240, b: 255, a: 255 })
		}
		.shadow_clones {
			g.sound_mgr.play_scroll_jutsu()
			g.add_score_popup(g.player.x, g.player.y - 30.0, 'SHADOW CLONE JUTSU!', Color{ r: 255, g: 230, b: 80, a: 255 })
		}
		.fire_shield {
			g.sound_mgr.play_scroll_jutsu()
			g.add_score_popup(g.player.x, g.player.y - 30.0, 'KATON FIRE SHIELD!', Color{ r: 255, g: 120, b: 30, a: 255 })
		}
		.golden_speed {
			g.sound_mgr.play_scroll_jutsu()
			g.add_score_popup(g.player.x, g.player.y - 30.0, 'HAYATE SPEED BOOST!', Color{ r: 255, g: 215, b: 0, a: 255 })
		}
		else {}
	}
}

pub fn (mut g LegendOfKageGame) add_particles(x f32, y f32, count int, color Color) {
	for _ in 0 .. count {
		angle := f32(rand.intn(360) or { 0 }) * f32(math.pi / 180.0)
		speed := 40.0 + f32(rand.intn(140) or { 60 })
		g.particles << Particle{
			x: x
			y: y
			vx: f32(math.cos(f64(angle))) * speed
			vy: f32(math.sin(f64(angle))) * speed
			color: color
			life: 0.35 + f32(rand.intn(30) or { 15 }) / 100.0
			max_l: 0.65
			size: 3.0 + f32(rand.intn(3) or { 1 })
			active: true
		}
	}
}

pub fn (mut g LegendOfKageGame) add_score_popup(x f32, y f32, text string, color Color) {
	g.score_popups << ScorePopup{
		x: x
		y: y
		text: text
		color: color
		timer: 0.85
		active: true
	}
}

pub fn (mut g LegendOfKageGame) update(dt f32) {
	// BGM Streaming
	g.sound_mgr.update_bgm(f64(dt), g.state == .playing)

	if g.state == .paused || g.state == .title || g.state == .game_over {
		return
	}

	gravity := f32(750.0)

	// Screen Shake & Lightning Flash decay
	if g.screen_shake > 0.0 {
		g.screen_shake -= dt
		if g.screen_shake <= 0.0 {
			g.screen_shake = 0.0
			g.shake_x = 0.0
			g.shake_y = 0.0
		} else {
			g.shake_x = f32(rand.intn(11) or { 5 }) - 5.0
			g.shake_y = f32(rand.intn(11) or { 5 }) - 5.0
		}
	}

	if g.lightning_flash > 0.0 {
		g.lightning_flash -= dt
	}

	if g.banner_timer > 0.0 {
		g.banner_timer -= dt
	}

	// 1. Update Player
	if g.player.is_dead {
		g.player.dead_timer -= dt
		g.player.vy += gravity * dt
		g.player.y += g.player.vy * dt
		if g.player.dead_timer <= 0.0 {
			g.player.lives--
			if g.player.lives > 0 {
				g.player.is_dead = false
				g.player.x = g.camera_x + 200.0
				g.player.y = 490.0
				g.player.vx = 0.0
				g.player.vy = 0.0
				g.player.invuln_timer = 3.0
			} else {
				g.state = .game_over
			}
		}
		return
	}

	if g.player.invuln_timer > 0.0 {
		g.player.invuln_timer -= dt
	}

	if g.player.slash_cooldown > 0.0 {
		g.player.slash_cooldown -= dt
	}
	if g.player.sword_timer > 0.0 {
		g.player.sword_timer -= dt
	}
	if g.player.shuriken_cd > 0.0 {
		g.player.shuriken_cd -= dt
	}

	// Ninjutsu Active Timer
	if g.player.jutsu_timer > 0.0 {
		g.player.jutsu_timer -= dt
		if g.player.jutsu_timer <= 0.0 {
			g.player.active_jutsu = .none
		}
	}

	// Fire shield orbiting flames damaging nearby enemies
	if g.player.active_jutsu == .fire_shield {
		for mut e in g.enemies {
			if e.active {
				dist := math.sqrt(math.pow(f64(e.x - g.player.x), 2.0) + math.pow(f64(e.y - g.player.y), 2.0))
				if dist < 65.0 {
					e.hp--
					g.add_particles(e.x + 12.0, e.y + 16.0, 10, Color{ r: 255, g: 120, b: 30, a: 255 })
					if e.hp <= 0 {
						e.active = false
						g.enemies_slain++
						g.sound_mgr.play_enemy_death()
						g.player.score += 400
					}
				}
			}
		}
	}

	// Movement Physics (High-Acrobatics Leaping)
	speed_mult := if g.player.active_jutsu == .golden_speed { f32(1.5) } else { f32(1.0) }
	max_speed := f32(240.0) * speed_mult
	accel := f32(950.0) * speed_mult
	air_accel := f32(650.0) * speed_mult
	friction := f32(800.0)

	cur_accel := if g.player.is_grounded || g.player.is_perched { accel } else { air_accel }

	if g.key_left {
		g.player.vx -= cur_accel * dt
		if g.player.vx < -max_speed {
			g.player.vx = -max_speed
		}
		g.player.facing_right = false
	} else if g.key_right {
		g.player.vx += cur_accel * dt
		if g.player.vx > max_speed {
			g.player.vx = max_speed
		}
		g.player.facing_right = true
	} else if g.player.is_grounded || g.player.is_perched {
		if g.player.vx > 0.0 {
			g.player.vx -= friction * dt
			if g.player.vx < 0.0 {
				g.player.vx = 0.0
			}
		} else if g.player.vx < 0.0 {
			g.player.vx += friction * dt
			if g.player.vx > 0.0 {
				g.player.vx = 0.0
			}
		}
	}

	// Super Ninja High Leap (Ascend into tree canopies!)
	if g.key_jump && (g.player.is_grounded || g.player.is_perched) && !g.player.is_jumping {
		jump_power := if g.player.active_jutsu == .golden_speed { f32(-680.0) } else { f32(-600.0) }
		g.player.vy = jump_power
		g.player.is_grounded = false
		g.player.is_perched = false
		g.player.is_jumping = true
		g.sound_mgr.play_jump_leap()
		g.add_particles(g.player.x + 13.0, g.player.y + g.player.height, 6, Color{ r: 200, g: 200, b: 220, a: 180 })
	}

	// Gravity
	g.player.vy += gravity * dt
	if g.player.vy > 650.0 {
		g.player.vy = 650.0
	}

	old_py := g.player.y
	g.player.x += g.player.vx * dt
	g.player.y += g.player.vy * dt

	// Ground Collision (Y=528)
	g.player.is_grounded = false
	g.player.is_perched = false
	if g.player.y + g.player.height >= 528.0 {
		g.player.y = 528.0 - g.player.height
		g.player.vy = 0.0
		g.player.is_grounded = true
		g.player.is_jumping = false
	}

	// Tree Branch / Castle Battlement Perching
	for b in g.branches {
		if old_py + g.player.height <= b.y + 6.0 && g.player.y + g.player.height >= b.y {
			if g.player.x + g.player.width > b.x && g.player.x < b.x + b.w {
				g.player.y = b.y - g.player.height
				g.player.vy = 0.0
				g.player.is_perched = true
				g.player.is_jumping = false
			}
		}
	}

	// Actions
	if g.key_slash {
		g.player_slash()
	}
	if g.key_shuriken {
		g.player_throw_shuriken()
	}

	// Animation frame
	if math.abs(g.player.vx) > 10.0 {
		g.player.anim_timer += dt * 11.0
		g.player.walk_frame = int(g.player.anim_timer) % 4
	} else {
		g.player.walk_frame = 0
	}

	// Camera Smooth Tracking
	mut target_cam_x := g.player.x - 300.0
	if target_cam_x < 0.0 {
		target_cam_x = 0.0
	}
	g.camera_x += (target_cam_x - g.camera_x) * 6.0 * dt

	// 2. Update Enemies
	if g.stage != .castle_keep {
		g.spawn_timer -= dt
		if g.spawn_timer <= 0.0 && g.enemies.len < 10 {
			g.spawn_enemy()
			g.spawn_timer = 1.2 + f32(rand.intn(15) or { 5 }) / 10.0
		}
	}

	for mut e in g.enemies {
		if !e.active {
			continue
		}

		// AI behavior
		e.anim_timer += dt * 8.0
		e.jump_timer -= dt
		e.attack_timer -= dt

		// Acrobatic Ninja leaps
		if e.jump_timer <= 0.0 && e.is_grounded {
			e.vy = -450.0 - f32(rand.intn(120) or { 40 })
			e.is_grounded = false
			e.jump_timer = 2.0 + f32(rand.intn(20) or { 10 }) / 10.0
		}

		// Enemy Attacks (Throwing Shurikens or Fire Breath)
		if e.attack_timer <= 0.0 {
			e.attack_timer = 1.8 + f32(rand.intn(15) or { 5 }) / 10.0
			dx := g.player.x - e.x
			dy := g.player.y - e.y
			dist := math.sqrt(f64(dx * dx + dy * dy))
			if dist > 1.0 && dist < 500.0 {
				dir_x := f32(f64(dx) / dist)
				dir_y := f32(f64(dy) / dist)

				if e.enemy_type == .fire_monk {
					g.sound_mgr.play_fire_breath()
					for f_step in 1 .. 4 {
						g.projectiles << Projectile{
							x: e.x + (if e.facing_right { e.width + 4.0 } else { -6.0 })
							y: e.y + 12.0
							vx: dir_x * (220.0 + f32(f_step * 30))
							vy: dir_y * 180.0
							is_player: false
							is_fire: true
							radius: 9.0
							life: 1.4
							active: true
						}
					}
				} else {
					g.sound_mgr.play_shuriken_throw()
					g.projectiles << Projectile{
						x: e.x + (if e.facing_right { e.width + 2.0 } else { -4.0 })
						y: e.y + 14.0
						vx: dir_x * 320.0
						vy: dir_y * 320.0
						is_player: false
						radius: 5.0
						life: 2.2
						active: true
					}
				}
			}
		}

		// Boss special dashing attack
		if e.enemy_type == .boss_warlord {
			if (rand.intn(80) or { 0 }) == 0 {
				e.vx = if g.player.x > e.x { f32(280.0) } else { f32(-280.0) }
				e.vy = -200.0
				g.sound_mgr.play_sword_slash()
			}
		}

		// Gravity
		e.vy += gravity * dt
		if e.vy > 600.0 {
			e.vy = 600.0
		}

		old_ey := e.y
		e.x += e.vx * dt
		e.y += e.vy * dt
		e.facing_right = g.player.x > e.x

		// Ground
		e.is_grounded = false
		if e.y + e.height >= 528.0 {
			e.y = 528.0 - e.height
			e.vy = 0.0
			e.is_grounded = true
		}

		// Branch landing
		for b in g.branches {
			if old_ey + e.height <= b.y + 6.0 && e.y + e.height >= b.y {
				if e.x + e.width > b.x && e.x < b.x + b.w {
					e.y = b.y - e.height
					e.vy = 0.0
					e.is_grounded = true
				}
			}
		}

		// Player Body Contact Collision
		if g.player.invuln_timer <= 0.0 && !g.player.is_dead {
			if g.player.x + g.player.width > e.x && g.player.x < e.x + e.width
				&& g.player.y + g.player.height > e.y && g.player.y < e.y + e.height {
				g.player.is_dead = true
				g.player.dead_timer = 2.0
				g.player.vy = -380.0
				g.sound_mgr.play_die()
				g.add_particles(g.player.x + 13.0, g.player.y + 18.0, 20, Color{ r: 255, g: 60, b: 60, a: 255 })
			}
		}
	}

	// 3. Update Projectiles
	for mut p in g.projectiles {
		if !p.active {
			continue
		}
		p.life -= dt
		if p.life <= 0.0 {
			p.active = false
			continue
		}

		p.x += p.vx * dt
		p.y += p.vy * dt

		// Player Projectile hitting Enemies
		if p.is_player {
			for mut e in g.enemies {
				if !e.active {
					continue
				}
				if p.x > e.x && p.x < e.x + e.width && p.y > e.y && p.y < e.y + e.height {
					p.active = false
					e.hp--
					g.add_particles(p.x, p.y, 8, Color{ r: 255, g: 220, b: 80, a: 255 })
					if e.hp <= 0 {
						e.active = false
						g.enemies_slain++
						g.sound_mgr.play_enemy_death()
						pts := if e.enemy_type == .boss_warlord { 5000 } else { 300 }
						g.player.score += pts
						g.add_score_popup(e.x, e.y, '+${pts}', Color{ r: 255, g: 230, b: 60, a: 255 })
					} else {
						g.sound_mgr.play_parry_clink()
					}
				}
			}
		}
		// Enemy Projectile hitting Player
		else if g.player.invuln_timer <= 0.0 && !g.player.is_dead {
			if p.x > g.player.x && p.x < g.player.x + g.player.width && p.y > g.player.y && p.y < g.player.y + g.player.height {
				p.active = false
				g.player.is_dead = true
				g.player.dead_timer = 2.0
				g.player.vy = -380.0
				g.sound_mgr.play_die()
				g.add_particles(g.player.x + 13.0, g.player.y + 18.0, 20, Color{ r: 255, g: 60, b: 60, a: 255 })
			}
		}
	}

	// 4. Update Magic Scrolls
	for mut sc in g.scrolls {
		if !sc.active {
			continue
		}
		sc.anim_timer += dt * 6.0
		sc.y += sc.vy * dt
		if sc.y >= 510.0 {
			sc.y = 510.0
		}

		// Player collection
		if g.player.x + g.player.width > sc.x && g.player.x < sc.x + 28.0 && g.player.y + g.player.height > sc.y && g.player.y < sc.y + 24.0 {
			sc.active = false
			g.activate_ninjutsu(sc.scroll_type)
			g.add_particles(sc.x + 14.0, sc.y + 12.0, 16, Color{ r: 255, g: 240, b: 100, a: 255 })
		}
	}

	// 5. Update Particles
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

	// 6. Update Score Popups
	for mut sp in g.score_popups {
		if !sp.active {
			continue
		}
		sp.timer -= dt
		sp.y -= 30.0 * dt
		if sp.timer <= 0.0 {
			sp.active = false
		}
	}

	// Cleanup inactive entities
	g.projectiles = g.projectiles.filter(it.active)
	g.enemies = g.enemies.filter(it.active)
	g.scrolls = g.scrolls.filter(it.active)
	g.particles = g.particles.filter(it.active)
	g.score_popups = g.score_popups.filter(it.active)

	// High score sync
	if g.player.score > g.high_score {
		g.high_score = g.player.score
	}

	// 7. Check Stage Clear
	if g.enemies_slain >= g.stage_target {
		g.state = .stage_clear
		g.sound_mgr.play_stage_clear()
	}
}

pub fn (mut g LegendOfKageGame) next_stage() {
	match g.stage {
		.forest {
			g.init_stage(.waterway)
			g.state = .playing
		}
		.waterway {
			g.init_stage(.castle_wall)
			g.state = .playing
		}
		.castle_wall {
			g.init_stage(.castle_keep)
			g.state = .playing
		}
		.castle_keep {
			g.season++
			if g.season > 4 {
				g.season = 1
			}
			g.init_stage(.forest)
			g.state = .playing
		}
	}
}
