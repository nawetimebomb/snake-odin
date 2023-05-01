package main

import rl "vendor:raylib"
import "core:math/rand"
import "core:strings"
import "core:strconv"

SQUARE_SIZE :: 20

GRID_HORIZONTAL_SIZE :: 40
GRID_VERTICAL_SIZE   :: 30

APPLE_TIMER  :: 60

SCREEN_WIDTH  :: 800
SCREEN_HEIGHT :: 600

Grid_Square :: enum u8 {
	Empty,
	Moving,
	Full,
	Block
}

Direction :: enum u8 {
	UP,
	RIGHT,
	DOWN,
	LEFT
}

v2 :: struct {
	x, y: int
}

Player :: struct {
	head: v2
	tail: [dynamic]v2
}

game_over := false
pause := false
moving_timer := 10
moving_counter := 0
player := Player{}
level := 1

grid: [GRID_HORIZONTAL_SIZE][GRID_VERTICAL_SIZE]Grid_Square

direction := Direction.UP

apple := v2{ 0, 0 }
apple_counter := 0
apple_on_screen := false

fading_alpha: f32 = 1.0

main :: proc() {
	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "My Snake")
	defer rl.CloseWindow()

	init_game()

	rl.SetTargetFPS(60)

	for !rl.WindowShouldClose() {
		update_game()
		draw_game()
	}
}

init_game :: proc() {
	player.head.x = GRID_HORIZONTAL_SIZE / 2
	player.head.y = GRID_VERTICAL_SIZE / 2
	direction = .UP
	apple_on_screen = false
	moving_timer = 10
	level = 1
	fading_alpha = 1.0
	delete(player.tail)
	player.tail = make([dynamic]v2, 0)
	append(&player.tail, v2{ player.head.x, player.head.y })
	append(&player.tail, v2{ player.head.x, player.head.y + 1 })
	append(&player.tail, v2{ player.head.x, player.head.y + 2 })
	game_over = false
	moving_counter = 0
}

update_game :: proc() {
	if game_over {
		if rl.IsKeyPressed(.ENTER) {
			init_game()
			game_over = false
		}
		return
	}

	if rl.IsKeyPressed(.P) {
		pause = !pause
	}

	if pause {
		return
	}

	for j in 0..<GRID_VERTICAL_SIZE {
		for i in 0..<GRID_HORIZONTAL_SIZE {
			grid[i][j] = .Empty
		}
	}

	if rl.IsKeyPressed(.W) && direction != .DOWN {
		direction = .UP
	} else if rl.IsKeyPressed(.D) && direction != .LEFT {
		direction = .RIGHT
	} else if rl.IsKeyPressed(.S) && direction != .UP {
		direction = .DOWN
	} else if rl.IsKeyPressed(.A) && direction != .RIGHT {
		direction = .LEFT
	}

	moving_counter += 1
	if !apple_on_screen {
		apple_counter += 1
	}

	if apple_counter >= APPLE_TIMER && !apple_on_screen {
		create_apple()
		apple_counter = 0
	}

	if moving_counter >= moving_timer {
		switch direction {
 		case .UP:
			player.head.y -= 1
		case .RIGHT:
			player.head.x += 1
		case .DOWN:
			player.head.y += 1
		case .LEFT:
			player.head.x -= 1
		}

		if player.head.x < 0 || player.head.x > GRID_HORIZONTAL_SIZE - 1 ||
			player.head.y < 0 || player.head.y > GRID_VERTICAL_SIZE - 1 {
				game_over = true
				return
			}

		if apple_on_screen &&
			player.head.x == apple.x &&
			player.head.y == apple.y {
				last_tail := player.tail[len(player.tail) - 1]
				append(&player.tail, last_tail)
				apple_on_screen = false
			}

		last_x := player.head.x
		last_y := player.head.y

		for i in 0..<len(player.tail) {
			current_x := player.tail[i].x
			current_y := player.tail[i].y
			player.tail[i].x = last_x
			player.tail[i].y = last_y
			last_x = current_x
			last_y = current_y
		}

		for i in 1..<len(player.tail) {
			if player.head.x == player.tail[i].x && player.head.y == player.tail[i].y {
				game_over = true
				return
			}
		}

		moving_counter = 0
	}

	if apple_on_screen {
		grid[apple.x][apple.y] = .Full
	}

	grid[player.head.x][player.head.y] = .Moving

	for i in 0..<len(player.tail) {
		tail_pos := player.tail[i]
		grid[tail_pos.x][tail_pos.y] = .Moving
	}

	if len(player.tail) % 4 == 0 {
		moving_timer -= 1
		level += 1
		append(&player.tail, player.tail[len(player.tail) - 1])
	}
}

create_apple :: proc() {
	spawn_x := 1 + rand.int_max(GRID_HORIZONTAL_SIZE - 2)
	spawn_y := 1 + rand.int_max(GRID_VERTICAL_SIZE - 2)

	apple.x = spawn_x
	apple.y = spawn_y

	apple_on_screen = true
}

draw_game :: proc() {
	rl.BeginDrawing()
	defer rl.EndDrawing()

	rl.ClearBackground(rl.RAYWHITE)

	if game_over {
		text :: "PRESS [ENTER] TO PLAY AGAIN"
		rl.DrawText(text, rl.GetScreenWidth() / 2 - rl.MeasureText(text, 20) / 2,
					rl.GetScreenHeight() / 2 - 50, 20, rl.GRAY)
		return
	}

	offset := [2]i32{
		0, 0
	}

	controller := offset.x

	for j in 0..<GRID_VERTICAL_SIZE {
		for i in 0..<GRID_HORIZONTAL_SIZE {
			switch grid[i][j] {
				case .Empty: {
					rl.DrawLine(offset.x, offset.y,
								offset.x + SQUARE_SIZE, offset.y, rl.LIGHTGRAY)
					rl.DrawLine(offset.x, offset.y, offset.x,
								offset.y + SQUARE_SIZE, rl.LIGHTGRAY)
					rl.DrawLine(offset.x + SQUARE_SIZE, offset.y,
								offset.x + SQUARE_SIZE, offset.y + SQUARE_SIZE, rl.LIGHTGRAY)
					rl.DrawLine(offset.x, offset.y + SQUARE_SIZE,
								offset.x + SQUARE_SIZE, offset.y + SQUARE_SIZE, rl.LIGHTGRAY)
				}
				case .Full: {
					rl.DrawRectangle(offset.x, offset.y, SQUARE_SIZE, SQUARE_SIZE, rl.RED)
				}
				case .Moving: {
					rl.DrawRectangle(offset.x, offset.y, SQUARE_SIZE, SQUARE_SIZE, rl.DARKGRAY)
				}
				case .Block: {
					rl.DrawRectangle(offset.x, offset.y, SQUARE_SIZE, SQUARE_SIZE, rl.LIGHTGRAY)
				}
			}
			offset.x += SQUARE_SIZE
		}

		offset.x = controller
		offset.y += SQUARE_SIZE
	}

	show_level()

	if fading_alpha > 0 {
		draw_instructions()
	}


	if pause {
		text :: "GAME PAUSED"
		rl.DrawText(text, SCREEN_WIDTH / 2 - rl.MeasureText(text, 40) / 2,
					SCREEN_HEIGHT / 2 - 40, 40, rl.GRAY)
	}
}

show_level :: proc() {
	builder := strings.builder_make()
	strings.write_bytes(&builder, {'l', 'e', 'v', 'e', 'l', ' '})
	strings.write_int(&builder, level)
	text := strings.clone_to_cstring(strings.to_string(builder))

	rl.DrawText(text, SCREEN_WIDTH - rl.MeasureText(text, 30), 5, 20, rl.GRAY)
}

draw_instructions :: proc() {
	w_text :: "W"; up_text    :: "Up"
	a_text :: "A"; left_text  :: "Left"
	s_text :: "S"; down_text  :: "Down"
	d_text :: "D"; right_text :: "Right"
	text_size := rl.MeasureText(w_text, 40) / 2
	block_size := i32(SQUARE_SIZE * 3)
	fading_alpha -= 0.005
	dark_color := rl.ColorAlpha(rl.DARKGRAY, fading_alpha)
	margin: i32 = 20

	rl.DrawRectangle(10, SCREEN_HEIGHT - block_size, block_size, block_size, dark_color)
	rl.DrawText(w_text, 10 + text_size
				SCREEN_HEIGHT - 40, 40, rl.RAYWHITE)
	rl.DrawText(up_text, 10,
				SCREEN_HEIGHT - 80, 20, dark_color)

	rl.DrawRectangle(margin + block_size,
					 SCREEN_HEIGHT - block_size, block_size, block_size, dark_color)
	rl.DrawText(a_text, margin + block_size + text_size,
				SCREEN_HEIGHT - 40, 40, rl.RAYWHITE)
	rl.DrawText(left_text,
				margin + block_size,
				SCREEN_HEIGHT - 80, 20, dark_color)

	rl.DrawRectangle((margin + block_size) * 2,
					 SCREEN_HEIGHT - block_size, block_size, block_size, dark_color)
	rl.DrawText(s_text, (margin + block_size) * 2 + text_size,
				SCREEN_HEIGHT - 40, 40, rl.RAYWHITE)
	rl.DrawText(down_text,
				(margin + block_size) * 2,
				SCREEN_HEIGHT - 80, 20, dark_color)

	rl.DrawRectangle((margin + block_size) * 3,
					 SCREEN_HEIGHT - block_size, block_size, block_size, dark_color)
	rl.DrawText(d_text, (margin + block_size) * 3 + text_size,
				SCREEN_HEIGHT - 40, 40, rl.RAYWHITE)
	rl.DrawText(right_text,
				(margin + block_size) * 3,
				SCREEN_HEIGHT - 80, 20, dark_color)
}
