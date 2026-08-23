module main

import os
import sdl

struct App {
mut:
	window           &sdl.Window   = unsafe { nil }
	renderer         &sdl.Renderer = unsafe { nil }
	game             Game
	sound_mgr        SoundManager
	btn_editor       Button
	btn_sound        Button
	btn_prev         Button
	btn_next         Button
	btn_restart      Button
	btn_undo         Button
	btn_level_select Button
	btn_test         Button
	btn_clear        Button
	mouse_x          int
	mouse_y          int
	is_down          bool
	is_painting_grid bool
	last_grid_col    int = -1
	last_grid_row    int = -1
}

fn new_app() App {
	mut app := App{
		game:             new_game()
		sound_mgr:        new_sound_manager()
		btn_editor:       Button{
			x:            775
			y:            12
			w:            165
			h:            40
			text:         'DESIGNER [TAB]'
			bg_color:     Color{ r: 12, g: 30, b: 65 }
			hover_color:  Color{ r: 0, g: 120, b: 200 }
			text_color:   Color{ r: 0, g: 240, b: 255 }
			border_color: Color{ r: 0, g: 240, b: 255 }
		}
		btn_sound:        Button{
			x:            595
			y:            600
			w:            338
			h:            42
			text:         'AUDIO: ON [S]'
			bg_color:     Color{ r: 15, g: 25, b: 45 }
			hover_color:  Color{ r: 30, g: 50, b: 90 }
			text_color:   Color{ r: 0, g: 230, b: 255 }
			border_color: Color{ r: 0, g: 200, b: 255 }
		}
		btn_undo:         Button{
			x:            595
			y:            380
			w:            165
			h:            38
			text:         'UNDO [U/Z]'
			bg_color:     Color{ r: 10, g: 45, b: 85 }
			hover_color:  Color{ r: 0, g: 100, b: 180 }
			text_color:   Color{ r: 0, g: 240, b: 255 }
			border_color: Color{ r: 0, g: 220, b: 255 }
		}
		btn_level_select: Button{
			x:            768
			y:            380
			w:            165
			h:            38
			text:         'SECTORS [P]'
			bg_color:     Color{ r: 45, g: 15, b: 70 }
			hover_color:  Color{ r: 90, g: 30, b: 140 }
			text_color:   Color{ r: 240, g: 140, b: 255 }
			border_color: Color{ r: 210, g: 80, b: 255 }
		}
		btn_prev:         Button{
			x:            595
			y:            428
			w:            165
			h:            38
			text:         'PREV [<]'
			bg_color:     Color{ r: 20, g: 30, b: 50 }
			hover_color:  Color{ r: 40, g: 60, b: 100 }
			text_color:   Color{ r: 220, g: 240, b: 255 }
			border_color: Color{ r: 0, g: 180, b: 240 }
		}
		btn_next:         Button{
			x:            768
			y:            428
			w:            165
			h:            38
			text:         'NEXT [>]'
			bg_color:     Color{ r: 20, g: 30, b: 50 }
			hover_color:  Color{ r: 40, g: 60, b: 100 }
			text_color:   Color{ r: 220, g: 240, b: 255 }
			border_color: Color{ r: 0, g: 180, b: 240 }
		}
		btn_restart:      Button{
			x:            595
			y:            476
			w:            338
			h:            42
			text:         'RETRY SECTOR [R]'
			bg_color:     Color{ r: 75, g: 18, b: 28 }
			hover_color:  Color{ r: 140, g: 35, b: 55 }
			text_color:   Color{ r: 255, g: 160, b: 180 }
			border_color: Color{ r: 255, g: 60, b: 90 }
		}
		btn_test:         Button{
			x:            595
			y:            545
			w:            165
			h:            42
			text:         'TEST PLAY [F5]'
			bg_color:     Color{ r: 15, g: 70, b: 40 }
			hover_color:  Color{ r: 30, g: 140, b: 80 }
			text_color:   Color{ r: 160, g: 255, b: 200 }
			border_color: Color{ r: 0, g: 255, b: 160 }
		}
		btn_clear:        Button{
			x:            768
			y:            545
			w:            165
			h:            42
			text:         'CLEAR GRID'
			bg_color:     Color{ r: 80, g: 20, b: 30 }
			hover_color:  Color{ r: 150, g: 40, b: 60 }
			text_color:   Color{ r: 255, g: 160, b: 180 }
			border_color: Color{ r: 255, g: 70, b: 90 }
		}
	}
	return app
}

fn (mut app App) init_sdl() bool {
	if sdl.init(sdl.init_video | sdl.init_audio) < 0 {
		eprintln('Failed to init SDL')
		return false
	}

	app.window = sdl.create_window(c'Adventures of Lolo: Cyberpunk Edition & Level Designer - V & SDL2',
		sdl.windowpos_centered, sdl.windowpos_centered, win_w, win_h, u32(sdl.WindowFlags.shown) | u32(sdl.WindowFlags.fullscreen_desktop) | u32(sdl.WindowFlags.resizable))
	if app.window == unsafe { nil } {
		eprintln('Failed to create window')
		return false
	}

	app.renderer = sdl.create_renderer(app.window, -1, u32(sdl.RendererFlags.accelerated) | u32(sdl.RendererFlags.presentvsync))
	if app.renderer == unsafe { nil } {
		eprintln('Failed to create renderer')
		return false
	}

	sdl.render_set_logical_size(app.renderer, win_w, win_h)
	app.game.init_textures(app.renderer)
	return true
}

fn (mut app App) run() {
	mut last_ticks := sdl.get_ticks()
	mut should_close := false

	for !should_close {
		current_ticks := sdl.get_ticks()
		dt := f64(current_ticks - last_ticks) / 1000.0
		last_ticks = current_ticks

		mut ev := sdl.Event{}
		for 0 < sdl.poll_event(&ev) {
			match ev.@type {
				.quit {
					should_close = true
				}
				.mousemotion {
					app.mouse_x = ev.motion.x
					app.mouse_y = ev.motion.y

					if app.is_down && app.is_painting_grid && app.game.mode == .editor {
						if !app.game.is_entity_selected && (app.game.editor_tool == .pencil || app.game.editor_tool == .eraser) {
							col := (ev.motion.x - grid_offset_x) / cell_size
							row := (ev.motion.y - grid_offset_y) / cell_size
							if col >= 0 && col < grid_cols && row >= 0 && row < grid_rows {
								if col != app.last_grid_col || row != app.last_grid_row {
									app.last_grid_col = col
									app.last_grid_row = row
									app.game.handle_editor_click(col, row, false)
								}
							}
						}
					}
				}
				.mousebuttondown {
					mx := ev.button.x
					my := ev.button.y
					app.is_down = true

					is_right := ev.button.button == u8(sdl.button_right)

					if app.game.is_share_modal_open {
						modal_x := 80
						modal_y := 50
						modal_w := 800
						// Check Community Pack Click
						for i in 0 .. app.game.community_levels.len {
							by := modal_y + 170 + i * 72
							if mx >= modal_x + 30 && mx <= modal_x + modal_w - 30 && my >= by && my <= by + 60 {
								app.game.init_level(app.game.community_levels[i])
								app.game.is_share_modal_open = false
								break
							}
						}
						app.game.is_share_modal_open = false
						continue
					}

					if app.game.is_level_select_open {
						modal_x := 80
						modal_y := 45
						tab_w := 180
						mut clicked_tab := false

						for t_idx in 0 .. 4 {
							tx := modal_x + 25 + t_idx * 190
							ty := modal_y + 38
							if mx >= tx && mx <= tx + tab_w && my >= ty && my <= ty + 28 {
								app.game.level_select_tab = t_idx
								clicked_tab = true
								break
							}
						}
						if clicked_tab {
							continue
						}

						start_idx, count := match app.game.level_select_tab {
							0 { 0, 20 }
							1 { 20, 15 }
							2 { 35, 15 }
							else { 50, 15 }
						}

						for i in 0 .. count {
							idx := start_idx + i
							if idx >= app.game.campaign_levels.len {
								break
							}
							col := i / 5
							row := i % 5
							bx := modal_x + 30 + col * 185
							by := modal_y + 78 + row * 98
							if mx >= bx && mx <= bx + 175 && my >= by && my <= by + 88 {
								app.game.load_level(idx)
								app.game.is_level_select_open = false
								break
							}
						}
						app.game.is_level_select_open = false
						continue
					}

					if app.game.status == .lost || app.game.status == .level_clear || app.game.status == .won {
						if app.game.status == .won {
							app.game.load_level(0)
						} else if app.game.status == .lost {
							if app.game.is_testing_custom {
								app.game.test_play_custom_level()
							} else {
								app.game.restart_level()
							}
						} else {
							app.game.next_level()
						}
						continue
					}

					if app.game.is_dialogue_open {
						app.game.is_dialogue_open = false
						continue
					}

					if app.btn_editor.contains(mx, my) {
						app.is_painting_grid = false
						app.game.toggle_editor_mode()
						app.btn_editor.text = if app.game.mode == .editor {
							'PLAY MODE [TAB]'
						} else {
							'DESIGNER [TAB]'
						}
					} else if app.btn_sound.contains(mx, my) {
						app.is_painting_grid = false
						is_on := app.sound_mgr.toggle_sound()
						app.btn_sound.text = if is_on { 'AUDIO: ON [S]' } else { 'AUDIO: OFF [S]' }
					} else if app.game.mode == .play {
						app.is_painting_grid = false
						if app.btn_undo.contains(mx, my) {
							if app.game.undo() {
								app.sound_mgr.play_undo()
							}
						} else if app.btn_level_select.contains(mx, my) {
							app.game.is_level_select_open = !app.game.is_level_select_open
						} else if app.btn_prev.contains(mx, my) {
							if app.game.current_level_idx > 0 {
								app.game.load_level(app.game.current_level_idx - 1)
							}
						} else if app.btn_next.contains(mx, my) {
							app.game.next_level()
						} else if app.btn_restart.contains(mx, my) {
							app.game.restart_level()
						}
					} else if app.game.mode == .editor {
						if app.btn_test.contains(mx, my) {
							app.is_painting_grid = false
							if app.game.test_play_custom_level() {
								app.btn_editor.text = 'DESIGNER [TAB]'
							}
						} else if app.btn_clear.contains(mx, my) {
							app.is_painting_grid = false
							app.game.editor_level = create_empty_level_theme('Custom Level',
								app.game.editor_level.theme)
						} else if mx >= grid_offset_x && mx < grid_offset_x + grid_cols * cell_size
							&& my >= grid_offset_y && my < grid_offset_y + grid_rows * cell_size {
							col := (mx - grid_offset_x) / cell_size
							row := (my - grid_offset_y) / cell_size
							if is_right {
								// 1-Click Instant Spawn & Playtest from this cell!
								for r in 0 .. grid_rows {
									for c in 0 .. grid_cols {
										if app.game.editor_level.entities[r][c] == .lolo_spawn {
											app.game.editor_level.entities[r][c] = .none
										}
									}
								}
								app.game.editor_level.entities[row][col] = .lolo_spawn
								if app.game.test_play_custom_level() {
									app.btn_editor.text = 'DESIGNER [TAB]'
								}
								continue
							}
							app.is_painting_grid = true
							app.last_grid_col = col
							app.last_grid_row = row
							app.game.handle_editor_click(col, row, is_right)
						} else if mx >= 580 {
							app.is_painting_grid = false
							app.last_grid_col = -1
							app.last_grid_row = -1
							app.handle_mario_maker_clicks(mx, my)
						}
					}
				}
				.mousebuttonup {
					app.is_down = false
					app.is_painting_grid = false
					app.last_grid_col = -1
					app.last_grid_row = -1
				}
				.keydown {
					sym := ev.key.keysym.sym
					if sym == int(sdl.KeyCode.f11) {
						toggle_fullscreen(app.window)
					} else if sym == int(sdl.KeyCode.escape) {
						if app.game.is_share_modal_open {
							app.game.is_share_modal_open = false
						} else if app.game.is_level_select_open {
							app.game.is_level_select_open = false
						} else if app.game.is_testing_custom {
							app.game.mode = .editor
							app.game.is_testing_custom = false
							app.btn_editor.text = 'PLAY MODE [TAB]'
						} else {
							should_close = true
						}
					} else if sym == int(sdl.KeyCode.tab) {
						app.game.toggle_editor_mode()
						app.btn_editor.text = if app.game.mode == .editor {
							'PLAY MODE [TAB]'
						} else {
							'DESIGNER [TAB]'
						}
					} else if sym == int(sdl.KeyCode.f5) {
						if app.game.mode == .editor {
							if app.game.test_play_custom_level() {
								app.btn_editor.text = 'DESIGNER [TAB]'
							}
						} else if app.game.is_testing_custom {
							app.game.mode = .editor
							app.game.is_testing_custom = false
							app.btn_editor.text = 'PLAY MODE [TAB]'
						}
					} else if sym == int(sdl.KeyCode.q) {
						app.game.toggle_dimension()
						app.sound_mgr.play_phase()
					} else if sym == int(sdl.KeyCode.c) {
						app.game.cycle_skin()
					} else if sym == int(sdl.KeyCode.h) {
						app.game.toggle_hint()
					} else if sym == int(sdl.KeyCode.v) {
						if app.game.is_replaying {
							app.game.is_replaying = false
						} else {
							app.game.start_replay()
						}
					} else if sym == int(sdl.KeyCode.k) {
						app.game.is_share_modal_open = !app.game.is_share_modal_open
					} else if sym == int(sdl.KeyCode.m) {
						app.sound_mgr.toggle_bgm()
					} else if app.game.mode == .editor {
						if sym == int(sdl.KeyCode._1) {
							app.game.editor_tab = .tiles
						} else if sym == int(sdl.KeyCode._2) {
							app.game.editor_tab = .items
						} else if sym == int(sdl.KeyCode._3) {
							app.game.editor_tab = .enemies
						} else if sym == int(sdl.KeyCode._4) {
							app.game.editor_tab = .themes
						} else if sym == int(sdl.KeyCode.b) {
							app.game.editor_tool = .pencil
						} else if sym == int(sdl.KeyCode.e) {
							app.game.editor_tool = .eraser
						} else if sym == int(sdl.KeyCode.g) {
							app.game.editor_tool = .fill
						} else if sym == int(sdl.KeyCode.r) {
							app.game.editor_tool = .rect
						} else if sym == int(sdl.KeyCode.t) {
							next_theme := (int(app.game.editor_level.theme) + 1) % 6
							app.game.editor_level.theme = unsafe { LevelTheme(next_theme) }
						}
					} else if app.game.mode == .play {
						if sym == int(sdl.KeyCode.p) {
							app.game.is_level_select_open = !app.game.is_level_select_open
							continue
						}

						if sym == int(sdl.KeyCode.u) || sym == int(sdl.KeyCode.z) {
							if app.game.undo() {
								app.sound_mgr.play_undo()
							}
							continue
						}

						if app.game.status == .lost || app.game.status == .level_clear || app.game.status == .won {
							if sym == int(sdl.KeyCode.up) || sym == int(sdl.KeyCode.w)
								|| sym == int(sdl.KeyCode.down) || sym == int(sdl.KeyCode.s)
								|| sym == int(sdl.KeyCode.left) || sym == int(sdl.KeyCode.a)
								|| sym == int(sdl.KeyCode.right) || sym == int(sdl.KeyCode.d)
								|| sym == int(sdl.KeyCode.space) || sym == int(sdl.KeyCode.@return) {
								if app.game.status == .won {
									app.game.load_level(0)
								} else if app.game.status == .lost {
									if app.game.is_testing_custom {
										app.game.test_play_custom_level()
									} else {
										app.game.restart_level()
									}
								} else {
									app.game.next_level()
								}
								continue
							}
						}

						mut step := false
						mut heart := false
						mut push := false
						mut chest := false
						mut victory := false
						mut hammer := false

						if sym == int(sdl.KeyCode.up) || sym == int(sdl.KeyCode.w) {
							step, heart, push, chest, victory, hammer = app.game.move_lolo(.up)
						} else if sym == int(sdl.KeyCode.down) || sym == int(sdl.KeyCode.s) {
							step, heart, push, chest, victory, hammer = app.game.move_lolo(.down)
						} else if sym == int(sdl.KeyCode.left) || sym == int(sdl.KeyCode.a) {
							step, heart, push, chest, victory, hammer = app.game.move_lolo(.left)
						} else if sym == int(sdl.KeyCode.right) || sym == int(sdl.KeyCode.d) {
							step, heart, push, chest, victory, hammer = app.game.move_lolo(.right)
						} else if sym == int(sdl.KeyCode.space) || sym == int(sdl.KeyCode.@return) {
							if app.game.fire_magic_shot() {
								app.sound_mgr.play_shot()
							}
						} else if sym == int(sdl.KeyCode.r) {
							app.game.restart_level()
						}

						if step {
							app.sound_mgr.play_step()
						}
						if heart {
							app.sound_mgr.play_heart()
						}
						if push {
							app.sound_mgr.play_push()
						}
						if chest {
							app.sound_mgr.play_chest()
						}
						if victory {
							app.sound_mgr.play_victory()
						}
						if hammer {
							app.sound_mgr.play_hammer()
						}
					}
				}
				else {}
			}
		}

		app.game.update(dt)

		// Dynamic Procedural Cyber Synth BGM stream update
		cur_theme := if app.game.mode == .editor { app.game.editor_level.theme } else { app.game.current_level.theme }
		app.sound_mgr.update_bgm_stream(cur_theme, app.game.door_open)

		draw_game(app.renderer, app.game, app.mouse_x, app.mouse_y, app.btn_editor, app.btn_restart,
			app.btn_sound, app.btn_prev, app.btn_next, app.btn_test, app.btn_clear, app.btn_undo,
			app.btn_level_select)
		prod_fx_render(app.renderer)
		sdl.render_present(app.renderer)

		sdl.delay(16)
	}
}

fn (mut app App) handle_mario_maker_clicks(mx int, my int) {
	panel_x := 580
	panel_y := 75

	// Check Tab Clicks
	for i in 0 .. 4 {
		tx := panel_x + 10 + i * 86
		ty := panel_y + 10
		if mx >= tx && mx <= tx + 82 && my >= ty && my <= ty + 28 {
			app.game.editor_tab = unsafe { EditorTab(i) }
			return
		}
	}

	// Check Tool Clicks (6 tools: PEN, LINE, RECT, FILL, ERASE, PREFAB)
	for i in 0 .. 6 {
		bx := panel_x + 10 + i * 58
		by := panel_y + 44
		if mx >= bx && mx <= bx + 54 && my >= by && my <= by + 26 {
			if app.game.editor_tool == unsafe { EditorTool(i) } && i == 5 {
				app.game.selected_prefab = (app.game.selected_prefab + 1) % 5
			} else {
				app.game.editor_tool = unsafe { EditorTool(i) }
			}
			return
		}
	}

	py := panel_y + 78
	match app.game.editor_tab {
		.tiles {
			tiles := [
				TileType.grass,
				TileType.wall,
				TileType.rock,
				TileType.tree,
				TileType.water,
				TileType.bridge,
				TileType.lava,
				TileType.ice,
				TileType.warp_a,
				TileType.warp_b,
				TileType.locked_gate,
				TileType.laser_prism_slash,
				TileType.laser_prism_backslash,
				TileType.pressure_plate,
				TileType.toggle_laser_gate,
				TileType.conveyor_up,
				TileType.conveyor_down,
				TileType.conveyor_left,
				TileType.conveyor_right,
				TileType.phase_block_alpha,
				TileType.phase_block_beta,
				TileType.timed_laser_barrier,
				TileType.plate_channel_1,
				TileType.gate_channel_1,
			]
			for i in 0 .. tiles.len {
				col := i % 3
				row := i / 3
				ix := panel_x + 12 + col * 114
				iy := py + row * 28
				if mx >= ix && mx <= ix + 108 && my >= iy && my <= iy + 25 {
					app.game.is_entity_selected = false
					app.game.selected_tile = tiles[i]
					return
				}
			}
		}
		.items {
			items := [
				EntityType.lolo_spawn,
				EntityType.door,
				EntityType.chest,
				EntityType.heart_frame,
				EntityType.emerald_frame,
				EntityType.hammer,
				EntityType.key_item,
				EntityType.speed_boots,
				EntityType.holo_terminal,
			]
			for i in 0 .. items.len {
				col := i % 3
				row := i / 3
				ix := panel_x + 12 + col * 114
				iy := py + row * 36
				if mx >= ix && mx <= ix + 108 && my >= iy && my <= iy + 32 {
					app.game.is_entity_selected = true
					app.game.selected_entity = items[i]
					return
				}
			}
		}
		.enemies {
			enemies := [
				EntityType.snakey,
				EntityType.alma,
				EntityType.leeper,
				EntityType.skull,
				EntityType.medusa,
				EntityType.don_medusa_h,
				EntityType.don_medusa_v,
				EntityType.gol,
				EntityType.king_egger,
				EntityType.gobby,
				EntityType.rocky,
				EntityType.moby,
				EntityType.wisp,
				EntityType.spike_trap,
			]
			for i in 0 .. enemies.len {
				col := i % 2
				row := i / 2
				ix := panel_x + 12 + col * 172
				iy := py + row * 40
				if mx >= ix && mx <= ix + 164 && my >= iy && my <= iy + 34 {
					app.game.is_entity_selected = true
					app.game.selected_entity = enemies[i]
					return
				}
			}
		}
		.themes {
			// Biome Selector
			for i in 0 .. 6 {
				col := i % 3
				row := i / 3
				ix := panel_x + 12 + col * 114
				iy := py + 18 + row * 30
				if mx >= ix && mx <= ix + 108 && my >= iy && my <= iy + 26 {
					app.game.editor_level.theme = unsafe { LevelTheme(i) }
					return
				}
			}

			// Templates
			templates := ['BLANK', 'ISLAND', 'LABYRINTH', 'ICE CHAMBER', 'FORTRESS']
			for i, t_name in templates {
				col := i % 3
				row := i / 3
				ix := panel_x + 12 + col * 114
				iy := py + 104 + row * 30
				if mx >= ix && mx <= ix + 108 && my >= iy && my <= iy + 26 {
					app.game.apply_template(t_name)
					return
				}
			}

			// Dark Dungeon Mode Modifier Toggle
			if mx >= panel_x + 12 && mx <= panel_x + 350 && my >= py + 170 && my <= py + 196 {
				app.game.editor_level.is_dark_dungeon = !app.game.editor_level.is_dark_dungeon
				return
			}

			// Open Community / Share modal
			if mx >= panel_x + 12 && mx <= panel_x + 350 && my >= py + 222 && my <= py + 250 {
				app.game.is_share_modal_open = true
				return
			}

			// Slots Save (S1..S5)
			for i in 0 .. 5 {
				ix := panel_x + 12 + i * 68
				iy := py + 276
				if mx >= ix && mx <= ix + 62 && my >= iy && my <= iy + 24 {
					app.game.save_slot(i)
					return
				}
			}

			// Slots Load (L1..L5)
			for i in 0 .. 5 {
				ix := panel_x + 12 + i * 68
				iy := py + 304
				if mx >= ix && mx <= ix + 62 && my >= iy && my <= iy + 24 {
					app.game.load_slot(i)
					return
				}
			}
		}
		else {}
	}
}

fn (mut app App) cleanup() {
	app.sound_mgr.cleanup()
	if app.renderer != unsafe { nil } {
		sdl.destroy_renderer(app.renderer)
	}
	if app.window != unsafe { nil } {
		sdl.destroy_window(app.window)
	}
	sdl.quit()
}

fn main() {
	if os.args.contains('--snapshot') || os.args.contains('--snap') || os.getenv('SNAPSHOT') == '1' {
		if sdl.init(sdl.init_video) != 0 {
			return
		}
		defer {
			sdl.quit()
		}
		surface := sdl.create_rgb_surface(0, 960, 680, 32, 0x00FF0000, 0x0000FF00, 0x000000FF,
			0xFF000000)
		s_renderer := sdl.create_software_renderer(surface)
		mut app := new_app()

		// 1. Play Mode Snapshot
		draw_game(s_renderer, app.game, 0, 0, app.btn_editor, app.btn_restart, app.btn_sound,
			app.btn_prev, app.btn_next, app.btn_test, app.btn_clear, app.btn_undo, app.btn_level_select)
		sdl.save_bmp(surface, 'screenshots/lolo.bmp'.str)
		sdl.save_bmp(surface, 'screenshots/lolo_play.bmp'.str)

		// 2. Mario Maker Editor Snapshot
		app.game.mode = .editor
		app.game.editor_tab = .tiles
		draw_game(s_renderer, app.game, 0, 0, app.btn_editor, app.btn_restart, app.btn_sound,
			app.btn_prev, app.btn_next, app.btn_test, app.btn_clear, app.btn_undo, app.btn_level_select)
		sdl.save_bmp(surface, 'screenshots/lolo_editor.bmp'.str)

		sdl.destroy_renderer(s_renderer)
		sdl.free_surface(surface)
		return
	}
	mut app := new_app()
	if !app.init_sdl() {
		return
	}
	defer {
		app.cleanup()
	}
	app.run()
}

fn toggle_fullscreen(window &sdl.Window) {
	flags := sdl.get_window_flags(window)
	if (flags & u32(sdl.WindowFlags.fullscreen_desktop)) != 0
		|| (flags & u32(sdl.WindowFlags.fullscreen)) != 0 {
		sdl.set_window_fullscreen(window, 0)
	} else {
		sdl.set_window_fullscreen(window, u32(sdl.WindowFlags.fullscreen_desktop))
	}
}
