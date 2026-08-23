module main

import math
import rand
import os
import sdl
import sdl.image

enum GameMode {
	mode_a_1p
	mode_b_2p
	balloon_trip
}

enum GameState {
	title
	playing
	paused
	phase_clear
	game_over
}

enum CharacterState {
	flying
	parachuting
	pumping
	drowning
	dead
}

enum EnemyRank {
	yellow
	pink
	red
}

struct Player {
pub mut:
	id            int
	motion        MotionState
	balloons      int = 2
	state         CharacterState = .flying
	score         int
	lives         int = 3
	flap_cooldown f64
	pump_timer    f64
	invincibility f64
	w             f64 = 28.0
	h             f64 = 36.0
	facing_right  bool = true
}

fn new_player(id int, x f64, y f64) Player {
	return Player{
		id:            id
		motion:        MotionState{
			x:           x
			y:           y
			is_grounded: false
		}
		balloons:      2
		state:         .flying
		lives:         3
		invincibility: 2.0
	}
}

struct Enemy {
pub mut:
	id          int
	rank        EnemyRank
	motion      MotionState
	balloons    int = 2
	state       CharacterState = .pumping
	ai_timer    f64
	pump_timer  f64
	score_val   int = 500
	w           f64 = 28.0
	h           f64 = 36.0
	active      bool = true
	target_x    f64
}

struct GiantFish {
pub mut:
	x        f64
	y        f64 = 550.0
	vy       f64
	active   bool
	state    int // 0: hidden, 1: leaping, 2: diving
	target_x f64
	cooldown f64
}

struct Spark {
pub mut:
	x      f64
	y      f64
	vx     f64
	vy     f64
	radius f64 = 8.0
}

struct Cloud {
pub mut:
	x           f64
	y           f64
	spark_timer f64
}

struct TripBalloon {
pub mut:
	x         f64
	y         f64
	collected bool
	value     int = 300
}

struct GameEngine {
pub mut:
	mode          GameMode  = .mode_a_1p
	state         GameState = .title
	phase         int       = 1
	score         int
	high_score    int = 25000
	elapsed_time  f64
	world_w       f64 = 800.0
	world_h       f64 = 600.0
	water_level   f64 = 540.0
	players       []Player
	enemies       []Enemy
	platforms     []Platform
	fish          GiantFish
	sparks        []Spark
	clouds        []Cloud
	trip_balloons []TripBalloon
	trip_scroll_x f64
	spawn_timer   f64
	next_enemy_id int = 1

	sprite_texture &sdl.Texture = unsafe { nil }
}

pub fn (mut ge GameEngine) init_textures(renderer &sdl.Renderer) {
	image.init(int(image.InitFlags.png))
	paths := [
		'assets/sprites/balloonfight.png',
		'../assets/sprites/balloonfight.png',
		os.join_path('assets', 'sprites', 'balloonfight.png'),
		os.join_path('..', 'assets', 'sprites', 'balloonfight.png'),
		os.join_path('balloonfight', 'assets', 'sprites', 'balloonfight.png'),
		'/Users/codecaine/vlang_sdl2_games/assets/sprites/balloonfight.png',
	]
	for p in paths {
		if os.exists(p) {
			surface := image.load(p.str)
			if !isnil(surface) {
				ge.sprite_texture = sdl.create_texture_from_surface(renderer, surface)
				sdl.free_surface(surface)
				if !isnil(ge.sprite_texture) {
					sdl.set_texture_blend_mode(ge.sprite_texture, .blend)
					return
				}
			}
		}
	}
}

fn new_game_engine() GameEngine {
	return GameEngine{
		state:      .title
		mode:       .mode_a_1p
		high_score: 25000
	}
}

fn (ge &GameEngine) start_game(mode GameMode) {
	mut mutable_ge := unsafe { &GameEngine(ge) }
	mutable_ge.mode = mode
	mutable_ge.state = .playing
	mutable_ge.phase = 1
	mutable_ge.score = 0
	mutable_ge.elapsed_time = 0
	mutable_ge.trip_scroll_x = 0

	mutable_ge.players.clear()
	mutable_ge.players << new_player(0, 300.0, 420.0)

	if mode == .mode_b_2p {
		mutable_ge.players << new_player(1, 500.0, 420.0)
	}

	mutable_ge.setup_stage()
}

fn (ge &GameEngine) setup_stage() {
	mut mutable_ge := unsafe { &GameEngine(ge) }
	mutable_ge.enemies.clear()
	mutable_ge.platforms.clear()
	mutable_ge.sparks.clear()
	mutable_ge.clouds.clear()
	mutable_ge.trip_balloons.clear()
	mutable_ge.fish = GiantFish{}

	if mutable_ge.mode == .balloon_trip {
		for i in 0 .. 50 {
			bx := 400.0 + f64(i * 120)
			by := 150.0 + math.sin(f64(i) * 0.8) * 120.0
			mutable_ge.trip_balloons << TripBalloon{
				x: bx
				y: by
			}
		}
		for i in 0 .. 15 {
			sx := 600.0 + f64(i * 250)
			sy := 100.0 + (rand.f64() * 320.0)
			mutable_ge.sparks << Spark{
				x:  sx
				y:  sy
				vx: 0
				vy: 80.0
			}
		}
		return
	}

	// Platforms
	mutable_ge.platforms << Platform{
		x: 100
		y: 450
		w: 160
		h: 18
	}
	mutable_ge.platforms << Platform{
		x: 540
		y: 450
		w: 160
		h: 18
	}
	mutable_ge.platforms << Platform{
		x: 320
		y: 300
		w: 160
		h: 18
	}
	mutable_ge.platforms << Platform{
		x: 150
		y: 180
		w: 140
		h: 18
	}
	mutable_ge.platforms << Platform{
		x: 510
		y: 180
		w: 140
		h: 18
	}

	// Spawn Enemies
	num_enemies := math.min(6, 2 + mutable_ge.phase)
	for i in 0 .. num_enemies {
		plat_idx := i % mutable_ge.platforms.len
		plat := mutable_ge.platforms[plat_idx]

		mut rank := EnemyRank.yellow
		mut score_val := 500
		if mutable_ge.phase >= 2 && i % 2 == 1 {
			rank = .pink
			score_val = 750
		}
		if mutable_ge.phase >= 4 && i % 3 == 2 {
			rank = .red
			score_val = 1000
		}

		spawn_x := plat.x + 20.0 + (f64(i) * 25.0)
		spawn_y := plat.y - 18.0

		id := mutable_ge.next_enemy_id
		mutable_ge.next_enemy_id++

		mutable_ge.enemies << Enemy{
			id:         id
			rank:       rank
			motion:     MotionState{
				x:           spawn_x
				y:           spawn_y
				is_grounded: true
			}
			balloons:   0
			state:      .pumping
			pump_timer: 1.5
			score_val:  score_val
			active:     true
		}
	}

	if mutable_ge.phase >= 2 {
		mutable_ge.clouds << Cloud{
			x: 380
			y: 80
		}
	}
}

fn (ge &GameEngine) update(dt f64, p1_left bool, p1_right bool, p1_flap bool, p2_left bool, p2_right bool, p2_flap bool, sound_mgr &SoundManager) {
	mut mutable_ge := unsafe { &GameEngine(ge) }
	if mutable_ge.state != .playing {
		return
	}

	mutable_ge.elapsed_time += dt

	if mutable_ge.mode == .balloon_trip {
		mutable_ge.update_balloon_trip_mode(dt, p1_left, p1_right, p1_flap, sound_mgr)
		return
	}

	// Update Players
	for i in 0 .. mutable_ge.players.len {
		mut p := unsafe { &Player(&mutable_ge.players[i]) }

		if p.state == .dead {
			continue
		}

		if p.invincibility > 0 {
			p.invincibility -= dt
		}

		left := if i == 0 { p1_left } else { p2_left }
		right := if i == 0 { p1_right } else { p2_right }
		flap := if i == 0 { p1_flap } else { p2_flap }

		if p.state == .pumping {
			p.pump_timer -= dt
			if p.pump_timer <= 0 {
				p.balloons++
				sound_mgr.play_pickup()
				if p.balloons >= 2 {
					p.state = .flying
					p.motion.is_grounded = false
					apply_flap(mut p.motion, 200.0)
				} else {
					p.pump_timer = 0.8
				}
			}
			continue
		}

		if left {
			accel := if p.motion.is_grounded { 360.0 } else { 200.0 }
			p.motion.vx -= accel * dt
			p.facing_right = false
		}
		if right {
			accel := if p.motion.is_grounded { 360.0 } else { 200.0 }
			p.motion.vx += accel * dt
			p.facing_right = true
		}

		if p.flap_cooldown > 0 {
			p.flap_cooldown -= dt
		}

		if flap && p.flap_cooldown <= 0 && p.balloons > 0 {
			p.flap_cooldown = 0.18
			apply_flap(mut p.motion, 180.0)
			sound_mgr.play_flap()
		}

		if p.state == .parachuting {
			p.motion.vy = 70.0
		}

		update_motion(mut p.motion, dt, mutable_ge.world_w)

		// Platform collisions & ledge support
		if update_platforms_collision(mut p.motion, p.w, p.h, mutable_ge.platforms) {
			if p.state == .parachuting {
				// Player lost both balloons and crashed!
				p.state = .drowning
				sound_mgr.play_splash()
				p.lives--
				if p.lives <= 0 {
					p.state = .dead
					mutable_ge.state = .game_over
				} else {
					// Respawn safely with full balloons
					p.motion.x = 400.0
					p.motion.y = 200.0
					p.motion.vx = 0
					p.motion.vy = 0
					p.balloons = 2
					p.state = .flying
					p.invincibility = 2.5
				}
			}
		}

		// Water drowning check
		if p.motion.y >= mutable_ge.water_level {
			p.state = .drowning
			sound_mgr.play_splash()
			p.lives--
			if p.lives <= 0 {
				p.state = .dead
				mutable_ge.state = .game_over
			} else {
				// Respawn safely
				p.motion.x = 400.0
				p.motion.y = 200.0
				p.motion.vx = 0
				p.motion.vy = 0
				p.balloons = 2
				p.state = .flying
				p.invincibility = 2.0
			}
		}
	}

	// Update Enemies AI
	for mut enemy in mutable_ge.enemies {
		if !enemy.active {
			continue
		}

		match enemy.state {
			.pumping {
				enemy.pump_timer -= dt
				if enemy.pump_timer <= 0 {
					enemy.balloons++
					if enemy.balloons >= 2 {
						enemy.state = .flying
						enemy.motion.is_grounded = false
						apply_flap(mut enemy.motion, 220.0)
					} else {
						enemy.pump_timer = 1.2
					}
				}
			}
			.flying {
				enemy.ai_timer += dt
				speed_mult := match enemy.rank {
					.yellow { 1.0 }
					.pink { 1.3 }
					.red { 1.6 }
				}

				if enemy.ai_timer >= (1.0 / speed_mult) {
					enemy.ai_timer = 0
					if rand.f64() < 0.65 {
						apply_flap(mut enemy.motion, 190.0 * speed_mult)
					}
					if rand.f64() < 0.5 {
						enemy.motion.vx = (rand.f64() * 200.0 - 100.0) * speed_mult
					}
				}

				update_motion(mut enemy.motion, dt, mutable_ge.world_w)
				update_platforms_collision(mut enemy.motion, enemy.w, enemy.h, mutable_ge.platforms)

				if enemy.motion.y >= mutable_ge.water_level {
					enemy.active = false
					sound_mgr.play_splash()
				}
			}
			.parachuting {
				enemy.motion.vy = 60.0
				update_motion(mut enemy.motion, dt, mutable_ge.world_w)

				if update_platforms_collision(mut enemy.motion, enemy.w, enemy.h, mutable_ge.platforms) {
					enemy.state = .pumping
					enemy.balloons = 0
					enemy.pump_timer = 1.0
				}

				if enemy.motion.y >= mutable_ge.water_level {
					enemy.active = false
					sound_mgr.play_splash()
				}
			}
			else {}
		}
	}

	// Balloon Popping Collisions
	mutable_ge.check_balloon_collisions(sound_mgr)

	// Giant Fish Water Hazard
	mutable_ge.update_giant_fish(dt, sound_mgr)

	// Storm Clouds & Spark Emissions
	for mut cloud in mutable_ge.clouds {
		cloud.spark_timer += dt
		if cloud.spark_timer >= 5.0 {
			cloud.spark_timer = 0
			mutable_ge.sparks << Spark{
				x:  cloud.x
				y:  cloud.y + 20.0
				vx: 120.0
				vy: 120.0
			}
		}
	}

	// Update Sparks
	mut keep_sparks := []Spark{}
	for mut spark in mutable_ge.sparks {
		spark.x += spark.vx * dt
		spark.y += spark.vy * dt

		if spark.x <= 10.0 || spark.x >= mutable_ge.world_w - 10.0 {
			spark.vx *= -1.0
		}
		if spark.y <= 10.0 || spark.y >= mutable_ge.water_level - 20.0 {
			spark.vy *= -1.0
		}

		for mut p in mutable_ge.players {
			if (p.state == .flying || p.state == .parachuting) && p.invincibility <= 0 {
				dist := math.hypot(spark.x - p.motion.x, spark.y - p.motion.y)
				if dist <= (spark.radius + 14.0) {
					sound_mgr.play_spark_zap()
					p.lives--
					if p.lives <= 0 {
						p.state = .dead
						mutable_ge.state = .game_over
					} else {
						p.motion.x = 400.0
						p.motion.y = 200.0
						p.motion.vx = 0
						p.motion.vy = 0
						p.balloons = 2
						p.state = .flying
						p.invincibility = 2.5
					}
				}
			}
		}
		keep_sparks << spark
	}
	mutable_ge.sparks = keep_sparks

	// Check Phase Clear
	mut active_enemies := 0
	for enemy in mutable_ge.enemies {
		if enemy.active {
			active_enemies++
		}
	}

	if active_enemies == 0 {
		mutable_ge.phase++
		mutable_ge.state = .phase_clear
		sound_mgr.play_phase_clear()
	}
}

fn (ge &GameEngine) check_balloon_collisions(sound_mgr &SoundManager) {
	mut mutable_ge := unsafe { &GameEngine(ge) }

	for mut p in mutable_ge.players {
		if p.state != .flying && p.state != .parachuting {
			continue
		}

		for mut enemy in mutable_ge.enemies {
			if !enemy.active {
				continue
			}

			dx := math.abs(p.motion.x - enemy.motion.x)
			dy := math.abs(p.motion.y - enemy.motion.y)

			if dx <= 30.0 && dy <= 34.0 {
				if enemy.state == .pumping || enemy.state == .parachuting {
					// Defeat pumping or parachuting enemy by running into or stomping them!
					enemy.active = false
					sound_mgr.play_pickup()
					p.score += enemy.score_val
					mutable_ge.score += enemy.score_val
					if mutable_ge.score > mutable_ge.high_score {
						mutable_ge.high_score = mutable_ge.score
					}
					if p.motion.y < enemy.motion.y {
						p.motion.vy = -160.0
					}
				} else if p.motion.y < enemy.motion.y - 4.0 {
					// Player is ABOVE Enemy -> Player pops enemy balloon!
					p.motion.vy = -180.0 // Tactile upward bounce
					enemy.balloons--
					sound_mgr.play_balloon_pop()
					if enemy.balloons <= 0 {
						enemy.state = .parachuting
					}
				} else if enemy.motion.y < p.motion.y - 4.0 && p.invincibility <= 0 {
					// Enemy is ABOVE Player -> Enemy pops player balloon!
					if p.state == .flying {
						p.balloons--
						p.invincibility = 0.6 // Invincibility frame window to avoid losing all balloons in 1 frame
						p.motion.vy = 120.0
						sound_mgr.play_balloon_pop()
						if p.balloons <= 0 {
							// Lost both balloons -> Immediately lose life and respawn/game over!
							p.lives--
							if p.lives <= 0 {
								p.state = .dead
								mutable_ge.state = .game_over
							} else {
								p.motion.x = 400.0
								p.motion.y = 200.0
								p.motion.vx = 0
								p.motion.vy = 0
								p.balloons = 2
								p.state = .flying
								p.invincibility = 2.5
							}
						}
					}
				}
			}
		}
	}
}

fn (ge &GameEngine) update_giant_fish(dt f64, sound_mgr &SoundManager) {
	mut mutable_ge := unsafe { &GameEngine(ge) }

	if !mutable_ge.fish.active {
		mutable_ge.fish.cooldown += dt
		if mutable_ge.fish.cooldown >= 3.0 {
			for p in mutable_ge.players {
				if p.state == .flying && p.motion.y > 460.0 && p.motion.y < mutable_ge.water_level {
					mutable_ge.fish.active = true
					mutable_ge.fish.state = 1
					mutable_ge.fish.x = p.motion.x
					mutable_ge.fish.y = 560.0
					mutable_ge.fish.vy = -350.0
					mutable_ge.fish.cooldown = 0
					sound_mgr.play_fish_gulp()
					break
				}
			}
		}
	} else {
		mutable_ge.fish.y += mutable_ge.fish.vy * dt
		if mutable_ge.fish.state == 1 && mutable_ge.fish.y <= 430.0 {
			mutable_ge.fish.state = 2
			mutable_ge.fish.vy = 280.0
		} else if mutable_ge.fish.state == 2 && mutable_ge.fish.y >= 560.0 {
			mutable_ge.fish.active = false
			mutable_ge.fish.state = 0
		}

		for mut p in mutable_ge.players {
			if p.state != .dead && p.invincibility <= 0 {
				dist := math.hypot(p.motion.x - mutable_ge.fish.x, p.motion.y - mutable_ge.fish.y)
				if dist <= 35.0 {
					p.state = .dead
					p.lives--
					sound_mgr.play_fish_gulp()
					if p.lives <= 0 {
						mutable_ge.state = .game_over
					}
				}
			}
		}
	}
}

fn (ge &GameEngine) update_balloon_trip_mode(dt f64, left bool, right bool, flap bool, sound_mgr &SoundManager) {
	mut mutable_ge := unsafe { &GameEngine(ge) }
	mutable_ge.trip_scroll_x += 120.0 * dt

	mut p := unsafe { &Player(&mutable_ge.players[0]) }

	if left {
		p.motion.vx -= 180.0 * dt
	}
	if right {
		p.motion.vx += 180.0 * dt
	}
	if flap && p.flap_cooldown <= 0 {
		p.flap_cooldown = 0.18
		apply_flap(mut p.motion, 180.0)
		sound_mgr.play_flap()
	}
	if p.flap_cooldown > 0 {
		p.flap_cooldown -= dt
	}

	update_motion(mut p.motion, dt, mutable_ge.world_w)

	for mut tb in mutable_ge.trip_balloons {
		if !tb.collected {
			screen_x := tb.x - mutable_ge.trip_scroll_x
			if screen_x > -20.0 && screen_x < 820.0 {
				dist := math.hypot(p.motion.x - screen_x, p.motion.y - tb.y)
				if dist <= 22.0 {
					tb.collected = true
					p.score += tb.value
					mutable_ge.score += tb.value
					sound_mgr.play_pickup()
				}
			}
		}
	}

	for spark in mutable_ge.sparks {
		screen_x := spark.x - mutable_ge.trip_scroll_x
		if screen_x > -20.0 && screen_x < 820.0 {
			dist := math.hypot(p.motion.x - screen_x, p.motion.y - spark.y)
			if dist <= 20.0 {
				p.state = .dead
				mutable_ge.state = .game_over
				sound_mgr.play_spark_zap()
			}
		}
	}
}
