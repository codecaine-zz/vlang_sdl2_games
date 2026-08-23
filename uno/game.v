module main

import math
import rand

pub enum UnoColor {
	red
	blue
	green
	yellow
	wild_color // Black / Multicolor Wild
}

pub enum UnoCardType {
	num_0
	num_1
	num_2
	num_3
	num_4
	num_5
	num_6
	num_7
	num_8
	num_9
	skip
	reverse
	draw_two
	wild
	wild_draw_four
}

pub struct Particle {
pub mut:
	x          f64
	y          f64
	vx         f64
	vy         f64
	color      Color
	size       f64
	life       f64
	max_life   f64
	shape_type int // 0: spark, 1: circle/star, 2: confetti
	rot        f64
	vrot       f64
	gravity    f64
}

pub struct FloatingText {
pub mut:
	x        f64
	y        f64
	text     string
	color    Color
	scale    int
	life     f64
	max_life f64
	vy       f64
}

pub struct Shockwave {
pub mut:
	cx         f64
	cy         f64
	radius     f64
	max_radius f64
	color      Color
	life       f64
	max_life   f64
	thickness  f64
}

pub struct FlyingUnoCard {
pub mut:
	card          UnoCard
	is_face_up    bool
	start_x       f64
	start_y       f64
	target_x      f64
	target_y      f64
	x             f64
	y             f64
	progress      f64
	speed         f64
	flip_progress f64
}

pub struct UnoCard {
pub mut:
	id    int
	color UnoColor
	typ   UnoCardType
}

pub struct UnoPlayer {
pub mut:
	name         string
	is_ai        bool
	hand         []UnoCard
	called_uno   bool
	score        int
	avatar_color Color
}

pub enum UnoState {
	player_turn
	color_pick
	ai_thinking
	animating
	round_over
	game_over
}

pub struct UnoGame {
pub mut:
	players       []UnoPlayer
	current_p_idx int
	deck          []UnoCard
	discard_pile  []UnoCard
	active_color  UnoColor
	direction     int = 1 // +1 clockwise, -1 counter-clockwise
	state         UnoState = .player_turn
	selected_card int = -1
	state_timer   f64
	celebration   string
	celeb_timer   f64
	uno_warning   bool
	draw_anim_t   f64

	// VFX State
	particles       []Particle
	floating_texts  []FloatingText
	shockwaves      []Shockwave
	flying_cards    []FlyingUnoCard
	shake_intensity f64
	shake_timer     f64
	anim_timer      f64
	pulse_time      f64
}

pub fn new_uno_game() UnoGame {
	mut game := UnoGame{
		players: [
			UnoPlayer{ name: 'You (P1)', is_ai: false, avatar_color: Color{ r: 40, g: 140, b: 240 } }
			UnoPlayer{ name: 'Bot Alice', is_ai: true, avatar_color: Color{ r: 240, g: 80, b: 80 } }
			UnoPlayer{ name: 'Bot Bob', is_ai: true, avatar_color: Color{ r: 80, g: 200, b: 100 } }
			UnoPlayer{ name: 'Bot Charlie', is_ai: true, avatar_color: Color{ r: 240, g: 190, b: 40 } }
		]
		current_p_idx: 0
		direction: 1
		state: .player_turn
	}
	game.start_new_round()
	return game
}

pub fn (mut g UnoGame) start_new_round() {
	g.deck = generate_uno_deck()
	shuffle_deck(mut g.deck)
	g.discard_pile.clear()

	for mut p in g.players {
		p.hand.clear()
		p.called_uno = false
		for _ in 0 .. 7 {
			if g.deck.len > 0 {
				p.hand << g.deck.pop()
			}
		}
	}

	// Flip first non-wild card to discard pile
	mut first_card := g.deck.pop()
	for first_card.color == .wild_color {
		g.deck.insert(0, first_card)
		first_card = g.deck.pop()
	}
	g.discard_pile << first_card
	g.active_color = first_card.color

	g.current_p_idx = 0
	g.direction = 1
	g.state = .player_turn
	g.selected_card = 0
	g.celebration = ''
}

pub fn generate_uno_deck() []UnoCard {
	mut deck := []UnoCard{cap: 108}
	mut id_counter := 1
	colors := [UnoColor.red, UnoColor.blue, UnoColor.green, UnoColor.yellow]

	for c in colors {
		// 1 Zero card
		deck << UnoCard{ id: id_counter++, color: c, typ: .num_0 }

		// 2 of each 1-9
		for _ in 0 .. 2 {
			deck << UnoCard{ id: id_counter++, color: c, typ: .num_1 }
			deck << UnoCard{ id: id_counter++, color: c, typ: .num_2 }
			deck << UnoCard{ id: id_counter++, color: c, typ: .num_3 }
			deck << UnoCard{ id: id_counter++, color: c, typ: .num_4 }
			deck << UnoCard{ id: id_counter++, color: c, typ: .num_5 }
			deck << UnoCard{ id: id_counter++, color: c, typ: .num_6 }
			deck << UnoCard{ id: id_counter++, color: c, typ: .num_7 }
			deck << UnoCard{ id: id_counter++, color: c, typ: .num_8 }
			deck << UnoCard{ id: id_counter++, color: c, typ: .num_9 }
			deck << UnoCard{ id: id_counter++, color: c, typ: .skip }
			deck << UnoCard{ id: id_counter++, color: c, typ: .reverse }
			deck << UnoCard{ id: id_counter++, color: c, typ: .draw_two }
		}
	}

	// 4 Wild and 4 Wild Draw Four cards
	for _ in 0 .. 4 {
		deck << UnoCard{ id: id_counter++, color: .wild_color, typ: .wild }
		deck << UnoCard{ id: id_counter++, color: .wild_color, typ: .wild_draw_four }
	}

	return deck
}

pub fn shuffle_deck(mut deck []UnoCard) {
	for i := deck.len - 1; i > 0; i-- {
		j := rand.int_in_range(0, i + 1) or { 0 }
		temp := deck[i]
		deck[i] = deck[j]
		deck[j] = temp
	}
}

pub fn (g &UnoGame) top_discard() UnoCard {
	if g.discard_pile.len > 0 {
		return g.discard_pile[g.discard_pile.len - 1]
	}
	return UnoCard{ id: 0, color: .red, typ: .num_0 }
}

pub fn (g &UnoGame) is_card_playable(card UnoCard) bool {
	top := g.top_discard()
	// Wild cards can always be played
	if card.color == .wild_color {
		return true
	}
	// Matches active color
	if card.color == g.active_color {
		return true
	}
	// Matches symbol/number type
	if card.typ == top.typ && card.typ != .wild && card.typ != .wild_draw_four {
		return true
	}
	return false
}

pub fn (mut g UnoGame) draw_card_for_player(p_idx int, mut sound_mgr SoundManager) {
	if g.deck.len == 0 {
		// Reshuffle discard pile into deck
		if g.discard_pile.len > 1 {
			top := g.discard_pile.pop()
			g.deck = g.discard_pile.clone()
			g.discard_pile.clear()
			g.discard_pile << top
			shuffle_deck(mut g.deck)
		} else {
			return
		}
	}

	drawn := g.deck.pop()
	g.players[p_idx].hand << drawn
	sound_mgr.play_card_deal()
}

pub fn (mut g UnoGame) play_card(card_idx int, chosen_color UnoColor, mut sound_mgr SoundManager) bool {
	mut p := &g.players[g.current_p_idx]
	if card_idx < 0 || card_idx >= p.hand.len {
		return false
	}

	card := p.hand[card_idx]
	if !g.is_card_playable(card) {
		return false
	}

	// Remove card from player hand
	p.hand.delete(card_idx)
	g.discard_pile << card
	sound_mgr.play_card_play()

	// Check Uno Call Warning: If down to 1 card and forgot to call UNO
	if p.hand.len == 1 {
		if !p.called_uno {
			// Penalty: Draw 2 cards!
			g.draw_card_for_player(g.current_p_idx, mut sound_mgr)
			g.draw_card_for_player(g.current_p_idx, mut sound_mgr)
			g.celebration = '${p.name.to_upper()} FORGOT UNO! +2 CARDS PENALTY'
			g.celeb_timer = 2.5
			sound_mgr.play_penalty_buzz()
		} else {
			g.celebration = '${p.name.to_upper()} CALLED UNO!!'
			g.celeb_timer = 2.0
			sound_mgr.play_uno_alert()
		}
	} else if p.hand.len == 0 {
		// Round won!
		g.celebration = '${p.name.to_upper()} WINS THE ROUND!'
		g.celeb_timer = 4.0
		g.state = .round_over
		sound_mgr.play_victory_fanfare()
		return true
	}

	// Process Action card effects
	if card.color == .wild_color {
		g.active_color = chosen_color
		if card.typ == .wild_draw_four {
			next_idx := g.get_next_player_idx()
			for _ in 0 .. 4 {
				g.draw_card_for_player(next_idx, mut sound_mgr)
			}
			g.advance_turn() // Skip next player
			sound_mgr.play_action_chime()
		}
	} else {
		g.active_color = card.color
		match card.typ {
			.skip {
				g.advance_turn() // Skip next player
				sound_mgr.play_action_chime()
			}
			.reverse {
				g.direction = -g.direction
				sound_mgr.play_action_chime()
			}
			.draw_two {
				next_idx := g.get_next_player_idx()
				g.draw_card_for_player(next_idx, mut sound_mgr)
				g.draw_card_for_player(next_idx, mut sound_mgr)
				g.advance_turn() // Skip next player
				sound_mgr.play_action_chime()
			}
			else {}
		}
	}

	g.advance_turn()
	return true
}

pub fn (g &UnoGame) get_next_player_idx() int {
	mut next_idx := g.current_p_idx + g.direction
	if next_idx < 0 {
		next_idx += g.players.len
	} else if next_idx >= g.players.len {
		next_idx -= g.players.len
	}
	return next_idx
}

pub fn (mut g UnoGame) advance_turn() {
	g.current_p_idx = g.get_next_player_idx()
	g.players[g.current_p_idx].called_uno = false

	if g.players[g.current_p_idx].is_ai {
		g.state = .ai_thinking
		g.state_timer = 0.0
	} else {
		g.state = .player_turn
		g.selected_card = 0
	}
}

pub fn (mut g UnoGame) call_uno() {
	if g.current_p_idx == 0 && g.players[0].hand.len <= 2 {
		g.players[0].called_uno = true
		g.celebration = 'YOU SHOUTED "UNO!"'
		g.celeb_timer = 2.0
	}
}

pub fn (mut g UnoGame) trigger_shake(intensity f64, duration f64) {
	g.shake_intensity = intensity
	g.shake_timer = duration
}

pub fn (mut g UnoGame) spawn_sparks(x f64, y f64, count int, col Color) {
	for _ in 0 .. count {
		angle := rand.f64() * math.pi * 2.0
		speed := 40.0 + rand.f64() * 180.0
		g.particles << Particle{
			x:          x
			y:          y
			vx:         math.cos(angle) * speed
			vy:         math.sin(angle) * speed
			color:      col
			size:       2.0 + rand.f64() * 3.0
			life:       0.0
			max_life:   0.35 + rand.f64() * 0.35
			shape_type: 0
			rot:        rand.f64() * 6.28
			vrot:       (rand.f64() - 0.5) * 10.0
			gravity:    100.0
		}
	}
}

pub fn (mut g UnoGame) spawn_confetti(x f64, y f64, count int) {
	cols := [
		Color{ r: 235, g: 45, b: 55 },
		Color{ r: 40, g: 130, b: 245 },
		Color{ r: 50, g: 190, b: 75 },
		Color{ r: 250, g: 210, b: 35 },
		Color{ r: 255, g: 255, b: 255 },
	]
	for _ in 0 .. count {
		angle := rand.f64() * math.pi * 2.0
		speed := 70.0 + rand.f64() * 250.0
		col_idx := rand.int_in_range(0, cols.len) or { 0 }
		g.particles << Particle{
			x:          x + (rand.f64() - 0.5) * 40.0
			y:          y + (rand.f64() - 0.5) * 40.0
			vx:         math.cos(angle) * speed
			vy:         math.sin(angle) * speed - 120.0
			color:      cols[col_idx]
			size:       4.0 + rand.f64() * 4.0
			life:       0.0
			max_life:   1.4 + rand.f64() * 0.9
			shape_type: 2
			rot:        rand.f64() * 6.28
			vrot:       (rand.f64() - 0.5) * 8.0
			gravity:    100.0
		}
	}
}

pub fn (mut g UnoGame) spawn_shockwave(cx f64, cy f64, col Color) {
	g.shockwaves << Shockwave{
		cx:         cx
		cy:         cy
		radius:     10.0
		max_radius: 130.0
		color:      col
		life:       0.0
		max_life:   0.45
		thickness:  3.0
	}
}

pub fn (mut g UnoGame) spawn_floating_text(x f64, y f64, text string, col Color, scale int) {
	g.floating_texts << FloatingText{
		x:        x
		y:        y
		text:     text
		color:    col
		scale:    scale
		life:     0.0
		max_life: 1.6
		vy:       -28.0
	}
}

pub fn (mut g UnoGame) update(dt f64, mut sound_mgr SoundManager) {
	g.anim_timer += dt
	g.pulse_time += dt

	if g.shake_timer > 0.0 {
		g.shake_timer -= dt
		if g.shake_timer <= 0.0 {
			g.shake_intensity = 0.0
		}
	}

	for mut p in g.particles {
		p.life += dt
		p.x += p.vx * dt
		p.y += p.vy * dt
		p.vy += p.gravity * dt
		p.rot += p.vrot * dt
		p.vx *= (1.0 - 0.5 * dt)
	}
	g.particles = g.particles.filter(it.life < it.max_life)

	for mut sw in g.shockwaves {
		sw.life += dt
		prog := sw.life / sw.max_life
		sw.radius = 10.0 + (sw.max_radius - 10.0) * math.sin(prog * math.pi * 0.5)
	}
	g.shockwaves = g.shockwaves.filter(it.life < it.max_life)

	for mut ft in g.floating_texts {
		ft.life += dt
		ft.y += ft.vy * dt
		ft.vy *= (1.0 - 0.8 * dt)
	}
	g.floating_texts = g.floating_texts.filter(it.life < it.max_life)

	for mut fc in g.flying_cards {
		fc.progress += fc.speed * dt
		if fc.progress > 1.0 {
			fc.progress = 1.0
		}
		t := fc.progress
		ease := 1.0 - math.pow(1.0 - t, 3.0)
		fc.x = fc.start_x + (fc.target_x - fc.start_x) * ease
		fc.y = fc.start_y + (fc.target_y - fc.start_y) * ease
		fc.flip_progress = t
	}
	g.flying_cards = g.flying_cards.filter(it.progress < 1.0)

	if g.celeb_timer > 0.0 {
		g.celeb_timer -= dt
		if g.celeb_timer <= 0.0 {
			g.celebration = ''
		}
	}

	match g.state {
		.ai_thinking {
			g.state_timer += dt
			if g.state_timer > 0.8 {
				g.process_ai_turn(mut sound_mgr)
			}
		}
		.round_over {
			g.state_timer += dt
			if g.state_timer > 3.5 {
				g.start_new_round()
			}
		}
		else {}
	}
}

fn (mut g UnoGame) process_ai_turn(mut sound_mgr SoundManager) {
	mut p := &g.players[g.current_p_idx]

	// AI always calls Uno when down to 2 cards
	if p.hand.len == 2 {
		p.called_uno = true
	}

	// Find best playable card
	mut play_idx := -1
	for idx, c in p.hand {
		if g.is_card_playable(c) {
			play_idx = idx
			// Prefer non-wild first
			if c.color != .wild_color {
				break
			}
		}
	}

	if play_idx != -1 {
		// Choose dominant color if wild
		mut chosen_col := UnoColor.red
		mut col_counts := [0, 0, 0, 0]
		for c in p.hand {
			match c.color {
				.red { col_counts[0]++ }
				.blue { col_counts[1]++ }
				.green { col_counts[2]++ }
				.yellow { col_counts[3]++ }
				else {}
			}
		}
		mut max_c := -1
		for i, count in col_counts {
			if count > max_c {
				max_c = count
				chosen_col = match i {
					0 { UnoColor.red }
					1 { UnoColor.blue }
					2 { UnoColor.green }
					else { UnoColor.yellow }
				}
			}
		}

		g.play_card(play_idx, chosen_col, mut sound_mgr)
	} else {
		// Draw a card
		g.draw_card_for_player(g.current_p_idx, mut sound_mgr)
		// Try playing drawn card
		last_idx := p.hand.len - 1
		if last_idx >= 0 && g.is_card_playable(p.hand[last_idx]) {
			g.play_card(last_idx, UnoColor.red, mut sound_mgr)
		} else {
			g.advance_turn()
		}
	}
}
