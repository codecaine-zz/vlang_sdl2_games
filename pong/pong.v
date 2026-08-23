module main

import math
import rand

const court_w = 900
const court_h = 680

const paddle_w = 16
const paddle_h = 96
const ball_size = 14
const winning_score = 7

struct Paddle {
pub mut:
	x  f64
	y  f64
	vy f64
}

struct TrailPoint {
pub mut:
	x f64
	y f64
}

struct Ball {
pub mut:
	x     f64
	y     f64
	vx    f64
	vy    f64
	trail []TrailPoint
}

enum GameMode {
	pve // 1 Player vs AI
	pvp // 2 Player Local
}

struct PongGame {
pub mut:
	p1        Paddle
	p2        Paddle
	ball      Ball
	score_p1  int
	score_p2  int
	mode      GameMode = .pve
	game_over bool
	winner_p1 bool
	is_paused bool
}

fn new_pong_game() PongGame {
	mut game := PongGame{
		p1:        Paddle{
			x: 40
			y: f64(court_h / 2 - paddle_h / 2)
		}
		p2:        Paddle{
			x: f64(court_w - 40 - paddle_w)
			y: f64(court_h / 2 - paddle_h / 2)
		}
		ball:      Ball{}
		score_p1:  0
		score_p2:  0
		mode:      .pve
		game_over: false
		is_paused: false
	}
	game.reset_ball(true)
	return game
}

fn (mut g PongGame) reset_ball(towards_p1 bool) {
	g.ball.x = f64(court_w / 2 - ball_size / 2)
	g.ball.y = f64(court_h / 2 - ball_size / 2)
	g.ball.trail.clear()

	speed := 6.5
	angle := (rand.f64() * 0.8 - 0.4) // -0.4 to 0.4 rad
	dir := if towards_p1 { -1.0 } else { 1.0 }

	g.ball.vx = dir * speed * math.cos(angle)
	g.ball.vy = speed * math.sin(angle)
}

fn (mut g PongGame) update_p1(move_up bool, move_down bool) {
	if g.game_over || g.is_paused {
		return
	}
	speed := 7.0
	if move_up && g.p1.y > 100 {
		g.p1.y -= speed
	}
	if move_down && g.p1.y < f64(court_h - 90 - paddle_h) {
		g.p1.y += speed
	}
}

fn (mut g PongGame) update_p2(move_up bool, move_down bool) {
	if g.game_over || g.is_paused {
		return
	}
	if g.mode == .pvp {
		speed := 7.0
		if move_up && g.p2.y > 100 {
			g.p2.y -= speed
		}
		if move_down && g.p2.y < f64(court_h - 90 - paddle_h) {
			g.p2.y += speed
		}
	} else {
		// Adaptive AI logic
		ai_speed := 5.2
		center_y := g.p2.y + paddle_h / 2.0
		target_y := g.ball.y + ball_size / 2.0
		diff := target_y - center_y

		if diff < -8 && g.p2.y > 100 {
			g.p2.y -= ai_speed
		} else if diff > 8 && g.p2.y < f64(court_h - 90 - paddle_h) {
			g.p2.y += ai_speed
		}
	}
}

fn (mut g PongGame) step() (bool, bool, bool) { // returns (hit_paddle, hit_wall, scored_goal)
	if g.game_over || g.is_paused {
		return false, false, false
	}

	mut hit_paddle := false
	mut hit_wall := false
	mut scored_goal := false

	g.ball.x += g.ball.vx
	g.ball.y += g.ball.vy

	g.ball.trail.prepend(TrailPoint{
		x: g.ball.x + ball_size / 2.0
		y: g.ball.y + ball_size / 2.0
	})
	if g.ball.trail.len > 20 {
		g.ball.trail.pop()
	}

	// Top / Bottom Wall Collision
	if g.ball.y <= 100 {
		g.ball.y = 100
		g.ball.vy = -g.ball.vy
		hit_wall = true
	} else if g.ball.y >= f64(court_h - 90 - ball_size) {
		g.ball.y = f64(court_h - 90 - ball_size)
		g.ball.vy = -g.ball.vy
		hit_wall = true
	}

	// P1 Paddle Collision (Left)
	if g.ball.vx < 0 && g.ball.x <= g.p1.x + paddle_w && g.ball.x + ball_size >= g.p1.x {
		if g.ball.y + ball_size >= g.p1.y && g.ball.y <= g.p1.y + paddle_h {
			g.ball.x = g.p1.x + paddle_w
			rel_y := (g.ball.y + ball_size / 2.0) - (g.p1.y + paddle_h / 2.0)
			norm_rel := rel_y / (paddle_h / 2.0)
			bounce_angle := norm_rel * (math.pi / 4.0) // max 45 deg

			speed := math.min(13.0, math.sqrt(g.ball.vx * g.ball.vx + g.ball.vy * g.ball.vy) * 1.05)
			g.ball.vx = speed * math.cos(bounce_angle)
			g.ball.vy = speed * math.sin(bounce_angle)
			hit_paddle = true
		}
	}

	// P2 Paddle Collision (Right)
	if g.ball.vx > 0 && g.ball.x + ball_size >= g.p2.x && g.ball.x <= g.p2.x + paddle_w {
		if g.ball.y + ball_size >= g.p2.y && g.ball.y <= g.p2.y + paddle_h {
			g.ball.x = g.p2.x - ball_size
			rel_y := (g.ball.y + ball_size / 2.0) - (g.p2.y + paddle_h / 2.0)
			norm_rel := rel_y / (paddle_h / 2.0)
			bounce_angle := norm_rel * (math.pi / 4.0)

			speed := math.min(13.0, math.sqrt(g.ball.vx * g.ball.vx + g.ball.vy * g.ball.vy) * 1.05)
			g.ball.vx = -speed * math.cos(bounce_angle)
			g.ball.vy = speed * math.sin(bounce_angle)
			hit_paddle = true
		}
	}

	// Goal Left (P2 scores)
	if g.ball.x < 0 {
		g.score_p2++
		scored_goal = true
		if g.score_p2 >= winning_score {
			g.game_over = true
			g.winner_p1 = false
		} else {
			g.reset_ball(false)
		}
	} else if g.ball.x > court_w {
		g.score_p1++
		scored_goal = true
		if g.score_p1 >= winning_score {
			g.game_over = true
			g.winner_p1 = true
		} else {
			g.reset_ball(true)
		}
	}

	return hit_paddle, hit_wall, scored_goal
}

fn (mut g PongGame) toggle_mode() {
	g.mode = if g.mode == .pve { .pvp } else { .pve }
	g.reset()
}

fn (mut g PongGame) reset() {
	g.score_p1 = 0
	g.score_p2 = 0
	g.game_over = false
	g.is_paused = false
	g.p1.y = f64(court_h / 2 - paddle_h / 2)
	g.p2.y = f64(court_h / 2 - paddle_h / 2)
	g.reset_ball(true)
}
