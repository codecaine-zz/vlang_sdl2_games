module main

fn test_pong_initialization() {
	game := new_pong_game()
	assert game.score_p1 == 0
	assert game.score_p2 == 0
	assert game.game_over == false
}

fn test_pong_ball_movement() {
	mut game := new_pong_game()
	start_x := game.ball.x
	game.step()
	assert game.ball.x != start_x
}

fn test_pong_paddle_movement() {
	mut game := new_pong_game()
	start_y := game.p1.y
	game.update_p1(true, false) // Move UP
	assert game.p1.y < start_y
}

fn test_pong_winning_condition() {
	mut game := new_pong_game()
	game.score_p1 = winning_score - 1
	game.ball.x = f64(court_w + 10) // Ball past right edge
	game.step()
	assert game.score_p1 == winning_score
	assert game.game_over == true
	assert game.winner_p1 == true
}
