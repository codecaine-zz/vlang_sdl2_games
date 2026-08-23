module main

fn test_uno_deck_generation() {
	deck := generate_uno_deck()
	assert deck.len == 108
}

fn test_uno_initial_hand_distribution() {
	g := new_uno_game()
	assert g.players.len == 4
	for p in g.players {
		assert p.hand.len == 7
	}
	assert g.discard_pile.len >= 1
}

fn test_uno_card_playability() {
	mut g := new_uno_game()
	g.discard_pile = [UnoCard{ id: 1, color: .red, typ: .num_5 }]
	g.active_color = .red

	// Matching color
	assert g.is_card_playable(UnoCard{ id: 2, color: .red, typ: .num_9 }) == true
	// Matching number
	assert g.is_card_playable(UnoCard{ id: 3, color: .blue, typ: .num_5 }) == true
	// Non-matching
	assert g.is_card_playable(UnoCard{ id: 4, color: .green, typ: .num_2 }) == false
	// Wild always playable
	assert g.is_card_playable(UnoCard{ id: 5, color: .wild_color, typ: .wild }) == true
	assert g.is_card_playable(UnoCard{ id: 6, color: .wild_color, typ: .wild_draw_four }) == true
}

fn test_turn_direction_and_skip() {
	mut g := new_uno_game()
	assert g.current_p_idx == 0
	assert g.direction == 1

	// Next player
	assert g.get_next_player_idx() == 1

	// Reverse
	g.direction = -1
	assert g.get_next_player_idx() == 3
}
