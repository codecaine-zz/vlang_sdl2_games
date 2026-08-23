module main

pub enum StageType {
	side_scroll
	base_3d
	vertical_scroll
	alien_lair
}

pub enum EnemyType {
	runner
	sniper
	turret
	scuba
	barrel
	facehugger
}

pub struct Platform {
pub:
	x        f32
	y        f32
	w        f32
	h        f32
	one_way  bool
	is_water bool
}

pub struct EnemySpawner {
pub mut:
	x            f32
	y            f32
	enemy_type   EnemyType
	interval     f32 = 3.0
	timer        f32
	facing_right bool
}

pub struct Enemy {
pub mut:
	x            f32
	y            f32
	vx           f32
	vy           f32
	enemy_type   EnemyType
	health       int  = 1
	active       bool = true
	facing_right bool
	timer        f32
	shoot_timer  f32
	on_ground    bool
}

pub struct BossPart {
pub mut:
	rel_x     f32
	rel_y     f32
	w         f32
	h         f32
	health    int
	max_health int
	destroyed bool
	is_core   bool
}

pub struct Boss {
pub mut:
	x           f32
	y           f32
	active      bool = true
	parts       []BossPart
	flash_timer f32
	timer       f32
}

pub struct BridgeSegment {
pub mut:
	x             f32
	y             f32
	w             f32
	h             f32
	exploded      bool
	triggered     bool
	explode_delay f32
}

pub struct StageDef {
pub:
	stage_num    int
	name         string
	stage_type   StageType
	length       f32
	spawn_x      f32
	spawn_y      f32
	bg_color_top Color
	bg_color_bot Color
}

pub struct StageData {
pub mut:
	def       StageDef
	platforms []Platform
	spawners  []EnemySpawner
	bridges   []BridgeSegment
	boss      Boss
}

// -------------------------------------------------------------
// STAGE 1: JUNGLE
// -------------------------------------------------------------
pub fn load_stage_1() StageData {
	def := StageDef{
		stage_num: 1
		name: 'STAGE 1: JUNGLE'
		stage_type: .side_scroll
		length: 3200.0
		spawn_x: 60.0
		spawn_y: 380.0
		bg_color_top: Color{r: 8, g: 16, b: 32}
		bg_color_bot: Color{r: 15, g: 30, b: 50}
	}

	mut platforms := []Platform{}
	// Main ground
	platforms << Platform{x: 0, y: 400, w: 750, h: 80, one_way: false}
	platforms << Platform{x: 180, y: 310, w: 180, h: 16, one_way: true}
	platforms << Platform{x: 400, y: 230, w: 220, h: 16, one_way: true}

	// Exploding Bridge 1 gap
	platforms << Platform{x: 750, y: 450, w: 300, h: 30, one_way: true, is_water: true}

	// Mid ground section
	platforms << Platform{x: 1050, y: 400, w: 850, h: 80, one_way: false}
	platforms << Platform{x: 1200, y: 310, w: 220, h: 16, one_way: true}
	platforms << Platform{x: 1480, y: 220, w: 240, h: 16, one_way: true}

	// Water Section
	platforms << Platform{x: 1900, y: 450, w: 300, h: 30, one_way: true, is_water: true}

	// Final Boss Arena
	platforms << Platform{x: 2200, y: 400, w: 1000, h: 80, one_way: false}
	platforms << Platform{x: 2350, y: 310, w: 200, h: 16, one_way: true}
	platforms << Platform{x: 2600, y: 230, w: 240, h: 16, one_way: true}

	mut bridges := [
		BridgeSegment{x: 750, y: 400, w: 100, h: 16, explode_delay: 0.9},
		BridgeSegment{x: 850, y: 400, w: 100, h: 16, explode_delay: 0.9},
		BridgeSegment{x: 950, y: 400, w: 100, h: 16, explode_delay: 0.9}
	]

	mut spawners := [
		EnemySpawner{x: 500, y: 400, enemy_type: .runner, interval: 2.5, facing_right: false},
		EnemySpawner{x: 1300, y: 400, enemy_type: .runner, interval: 2.2, facing_right: false},
		EnemySpawner{x: 600, y: 230, enemy_type: .sniper, interval: 4.0, facing_right: false},
		EnemySpawner{x: 1650, y: 220, enemy_type: .sniper, interval: 3.5, facing_right: false},
		EnemySpawner{x: 1400, y: 400, enemy_type: .turret, interval: 5.0, facing_right: false},
		EnemySpawner{x: 1980, y: 450, enemy_type: .scuba, interval: 3.0, facing_right: false}
	]

	boss := Boss{
		x: 2900.0
		y: 280.0
		active: true
		parts: [
			BossPart{rel_x: 0, rel_y: 60, w: 50, h: 50, health: 18, max_health: 18, is_core: true},
			BossPart{rel_x: -30, rel_y: 0, w: 36, h: 36, health: 12, max_health: 12, is_core: false},
			BossPart{rel_x: 30, rel_y: 0, w: 36, h: 36, health: 12, max_health: 12, is_core: false},
			BossPart{rel_x: 0, rel_y: -60, w: 30, h: 30, health: 8, max_health: 8, is_core: false}
		]
	}

	return StageData{
		def: def
		platforms: platforms
		spawners: spawners
		bridges: bridges
		boss: boss
	}
}

// -------------------------------------------------------------
// STAGE 2: 3D BASE
// -------------------------------------------------------------
pub fn load_stage_2() StageData {
	def := StageDef{
		stage_num: 2
		name: 'STAGE 2: BASE 1'
		stage_type: .base_3d
		length: 2000.0
		spawn_x: 420.0
		spawn_y: 400.0
		bg_color_top: Color{r: 5, g: 8, b: 18}
		bg_color_bot: Color{r: 10, g: 20, b: 40}
	}

	mut platforms := [
		Platform{x: 100, y: 420, w: 640, h: 60, one_way: false}
	]

	mut spawners := [
		EnemySpawner{x: 300, y: 420, enemy_type: .barrel, interval: 3.0, facing_right: false},
		EnemySpawner{x: 540, y: 420, enemy_type: .barrel, interval: 3.2, facing_right: false},
		EnemySpawner{x: 420, y: 300, enemy_type: .turret, interval: 4.0, facing_right: false}
	]

	boss := Boss{
		x: 420.0
		y: 240.0
		active: true
		parts: [
			BossPart{rel_x: 0, rel_y: 0, w: 60, h: 60, health: 24, max_health: 24, is_core: true},
			BossPart{rel_x: -60, rel_y: 20, w: 40, h: 40, health: 14, max_health: 14, is_core: false},
			BossPart{rel_x: 60, rel_y: 20, w: 40, h: 40, health: 14, max_health: 14, is_core: false}
		]
	}

	return StageData{
		def: def
		platforms: platforms
		spawners: spawners
		boss: boss
	}
}

// -------------------------------------------------------------
// STAGE 3: WATERFALL
// -------------------------------------------------------------
pub fn load_stage_3() StageData {
	def := StageDef{
		stage_num: 3
		name: 'STAGE 3: WATERFALL'
		stage_type: .vertical_scroll
		length: 3000.0
		spawn_x: 420.0
		spawn_y: 400.0
		bg_color_top: Color{r: 25, g: 30, b: 42}
		bg_color_bot: Color{r: 10, g: 15, b: 25}
	}

	mut platforms := [
		Platform{x: 100, y: 430, w: 640, h: 50, one_way: false},
		Platform{x: 200, y: 350, w: 160, h: 16, one_way: true},
		Platform{x: 480, y: 280, w: 180, h: 16, one_way: true},
		Platform{x: 240, y: 200, w: 200, h: 16, one_way: true},
		Platform{x: 450, y: 120, w: 180, h: 16, one_way: true},
		Platform{x: 220, y: 40, w: 400, h: 20, one_way: false}
	]

	mut spawners := [
		EnemySpawner{x: 350, y: 280, enemy_type: .sniper, interval: 3.5, facing_right: false},
		EnemySpawner{x: 480, y: 120, enemy_type: .turret, interval: 4.0, facing_right: false}
	]

	boss := Boss{
		x: 420.0
		y: 80.0
		active: true
		parts: [
			BossPart{rel_x: 0, rel_y: 0, w: 65, h: 65, health: 26, max_health: 26, is_core: true},
			BossPart{rel_x: -80, rel_y: -20, w: 45, h: 45, health: 15, max_health: 15, is_core: false},
			BossPart{rel_x: 80, rel_y: -20, w: 45, h: 45, health: 15, max_health: 15, is_core: false}
		]
	}

	return StageData{
		def: def
		platforms: platforms
		spawners: spawners
		boss: boss
	}
}

// -------------------------------------------------------------
// STAGE 4: ALIEN LAIR
// -------------------------------------------------------------
pub fn load_stage_4() StageData {
	def := StageDef{
		stage_num: 4
		name: 'STAGE 4: ALIEN LAIR'
		stage_type: .alien_lair
		length: 3000.0
		spawn_x: 60.0
		spawn_y: 380.0
		bg_color_top: Color{r: 28, g: 6, b: 12}
		bg_color_bot: Color{r: 12, g: 3, b: 6}
	}

	mut platforms := []Platform{}
	platforms << Platform{x: 0, y: 400, w: 800, h: 80, one_way: false}
	platforms << Platform{x: 200, y: 310, w: 200, h: 16, one_way: true}
	platforms << Platform{x: 460, y: 220, w: 220, h: 16, one_way: true}

	platforms << Platform{x: 800, y: 450, w: 300, h: 30, one_way: true, is_water: true}

	platforms << Platform{x: 1100, y: 400, w: 900, h: 80, one_way: false}
	platforms << Platform{x: 1300, y: 310, w: 240, h: 16, one_way: true}
	platforms << Platform{x: 1600, y: 220, w: 220, h: 16, one_way: true}

	platforms << Platform{x: 2000, y: 400, w: 1000, h: 80, one_way: false}

	mut spawners := [
		EnemySpawner{x: 500, y: 400, enemy_type: .facehugger, interval: 2.0, facing_right: false},
		EnemySpawner{x: 1400, y: 400, enemy_type: .facehugger, interval: 1.8, facing_right: false},
		EnemySpawner{x: 1600, y: 220, enemy_type: .turret, interval: 3.5, facing_right: false}
	]

	boss := Boss{
		x: 2650.0
		y: 280.0
		active: true
		parts: [
			BossPart{rel_x: 0, rel_y: 0, w: 75, h: 75, health: 32, max_health: 32, is_core: true},
			BossPart{rel_x: -60, rel_y: -40, w: 40, h: 40, health: 16, max_health: 16, is_core: false},
			BossPart{rel_x: 60, rel_y: -40, w: 40, h: 40, health: 16, max_health: 16, is_core: false}
		]
	}

	return StageData{
		def: def
		platforms: platforms
		spawners: spawners
		boss: boss
	}
}

pub fn get_stage_by_number(num int) StageData {
	match num {
		1 { return load_stage_1() }
		2 { return load_stage_2() }
		3 { return load_stage_3() }
		4 { return load_stage_4() }
		else { return load_stage_1() }
	}
}
