module main

import math
import rand

pub enum WeaponType {
	normal
	machine_gun
	spread_gun
	laser
	fire_gun
	rapid
	barrier
}

pub struct BulletTrailPoint {
pub mut:
	x f32
	y f32
	alpha f32
}

pub struct Bullet {
pub mut:
	x        f32
	y        f32
	vx       f32
	vy       f32
	w_type   WeaponType
	is_player bool
	player_id int
	damage   int   = 1
	piercing bool
	life     f32   = 2.0
	rot      f32
	radius   f32   = 3.5
	trail    []BulletTrailPoint
}

pub struct PowerUpItem {
pub mut:
	x       f32
	y       f32
	vx      f32
	vy      f32
	w_type  WeaponType
	active  bool = true
	on_ground bool
	timer   f32
}

pub struct FlyingCapsule {
pub mut:
	x          f32
	y          f32
	vx         f32
	vy         f32
	w_type     WeaponType
	active     bool = true
	health     int  = 1
	timer      f32
	is_wall_pod bool
}

pub fn create_player_bullets(x f32, y f32, aim_x f32, aim_y f32, w WeaponType, has_rapid bool, p_id int) []Bullet {
	mut bullets := []Bullet{}
	spd := if has_rapid { f32(650.0) } else { f32(500.0) }

	match w {
		.normal {
			bullets << Bullet{
				x: x
				y: y
				vx: aim_x * spd
				vy: aim_y * spd
				w_type: .normal
				is_player: true
				player_id: p_id
				damage: 1
				radius: 4.0
			}
		}
		.machine_gun {
			bullets << Bullet{
				x: x
				y: y
				vx: aim_x * spd * 1.2
				vy: aim_y * spd * 1.2
				w_type: .machine_gun
				is_player: true
				player_id: p_id
				damage: 1
				radius: 4.5
			}
		}
		.spread_gun {
			// 5-way spread fan
			base_angle := math.atan2(f64(aim_y), f64(aim_x))
			spread_offsets := [-0.28, -0.14, 0.0, 0.14, 0.28]
			for off in spread_offsets {
				ang := base_angle + off
				bullets << Bullet{
					x: x
					y: y
					vx: f32(math.cos(ang)) * spd * 0.95
					vy: f32(math.sin(ang)) * spd * 0.95
					w_type: .spread_gun
					is_player: true
					player_id: p_id
					damage: 2
					radius: 6.0
				}
			}
		}
		.laser {
			bullets << Bullet{
				x: x
				y: y
				vx: aim_x * spd * 1.6
				vy: aim_y * spd * 1.6
				w_type: .laser
				is_player: true
				player_id: p_id
				damage: 3
				piercing: true
				radius: 8.0
			}
		}
		.fire_gun {
			bullets << Bullet{
				x: x
				y: y
				vx: aim_x * spd * 0.85
				vy: aim_y * spd * 0.85
				w_type: .fire_gun
				is_player: true
				player_id: p_id
				damage: 2
				radius: 9.0
			}
		}
		else {
			bullets << Bullet{
				x: x
				y: y
				vx: aim_x * spd
				vy: aim_y * spd
				w_type: .normal
				is_player: true
				player_id: p_id
				damage: 1
				radius: 4.0
			}
		}
	}
	return bullets
}

pub fn create_enemy_bullet(x f32, y f32, target_x f32, target_y f32, spd f32) Bullet {
	mut dx := target_x - x
	mut dy := target_y - y
	len := math.sqrt(f64(dx * dx + dy * dy))
	if len > 0.001 {
		dx /= f32(len)
		dy /= f32(len)
	} else {
		dx = -1.0
		dy = 0.0
	}

	return Bullet{
		x: x
		y: y
		vx: dx * spd
		vy: dy * spd
		w_type: .normal
		is_player: false
		damage: 1
		radius: 4.0
	}
}

pub fn random_powerup_type() WeaponType {
	r := rand.intn(100) or { 50 }
	if r < 35 {
		return .spread_gun
	} else if r < 55 {
		return .machine_gun
	} else if r < 72 {
		return .laser
	} else if r < 86 {
		return .fire_gun
	} else if r < 94 {
		return .rapid
	} else {
		return .barrier
	}
}
