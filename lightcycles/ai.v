module main

pub fn compute_ai_move(grid [][]int, head_r int, head_c int, curr_dir Direction, diff Difficulty) Direction {
	rows := grid.len
	cols := grid[0].len

	// Candidate moves (no 180-degree instant reversal)
	mut valid_dirs := []Direction{}
	all_dirs := [Direction.up, Direction.right, Direction.down, Direction.left]

	for d in all_dirs {
		if is_opposite_dir(curr_dir, d) {
			continue
		}
		dr, dc := dir_offsets(d)
		nr := head_r + dr
		nc := head_c + dc
		if nr >= 0 && nr < rows && nc >= 0 && nc < cols {
			if grid[nr][nc] == 0 {
				valid_dirs << d
			}
		}
	}

	if valid_dirs.len == 0 {
		return curr_dir // Trapped
	}
	if valid_dirs.len == 1 {
		return valid_dirs[0]
	}

	// For Easy mode: keep going or pick random safe direction
	if diff == .easy {
		for d in valid_dirs {
			if d == curr_dir {
				return d
			}
		}
		return valid_dirs[0]
	}

	// For Normal and Hard/Master: Flood Fill lookahead to evaluate open territory
	mut best_dir := valid_dirs[0]
	mut max_open := -1

	for d in valid_dirs {
		dr, dc := dir_offsets(d)
		nr := head_r + dr
		nc := head_c + dc
		open_area := flood_fill_count(grid, nr, nc, 60)
		// Small bias to continue straight to avoid jitter
		score := if d == curr_dir { open_area + 2 } else { open_area }
		if score > max_open {
			max_open = score
			best_dir = d
		}
	}

	return best_dir
}

fn flood_fill_count(grid [][]int, start_r int, start_c int, max_depth int) int {
	rows := grid.len
	cols := grid[0].len
	mut visited := [][]bool{len: rows, init: []bool{len: cols, init: false}}
	mut queue := [ [start_r, start_c] ]
	visited[start_r][start_c] = true
	mut count := 0

	for queue.len > 0 && count < max_depth {
		pos := queue[0]
		queue.delete(0)
		count++

		r := pos[0]
		c := pos[1]
		dirs := [[-1, 0], [1, 0], [0, -1], [0, 1]]
		for d in dirs {
			nr := r + d[0]
			nc := c + d[1]
			if nr >= 0 && nr < rows && nc >= 0 && nc < cols {
				if grid[nr][nc] == 0 && !visited[nr][nc] {
					visited[nr][nc] = true
					queue << [nr, nc]
				}
			}
		}
	}
	return count
}
