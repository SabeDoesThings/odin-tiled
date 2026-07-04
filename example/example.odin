package main

import "../tiled"
import "vendor:raylib"
import "core:fmt"

main :: proc() {
    raylib.InitWindow(320, 480, "Tiled Example")

    tiled_map := tiled.parse_tilemap("tileMap.json")

    tileset_texture := raylib.LoadTexture("tiles.png")

    for !raylib.WindowShouldClose() {
        raylib.BeginDrawing()
        raylib.ClearBackground(raylib.BLACK)
        draw_map(tiled_map, tileset_texture)
        raylib.EndDrawing()
    }
}

draw_map :: proc(tilemap: tiled.Map, texture: raylib.Texture2D) {
	tile_width: i32 = 16
	tile_height: i32 = 16

	tileset_columns := texture.width / tile_width

	for layer in tilemap.layers {
		for row in 0 ..< layer.height {
			for column in 0 ..< layer.width {
				global_tile_id := layer.data[row * layer.width + column]

				if global_tile_id == 0 {
					continue
				}

				tile_x := i32(global_tile_id - 1) % tileset_columns
				tile_y := i32(global_tile_id - 1) / tileset_columns

				source_rectangle := raylib.Rectangle {
					x      = f32(tile_x * tile_width),
					y      = f32(tile_y * tile_height),
					width  = f32(tile_width),
					height = f32(tile_height),
				}

				destination_rectangle := raylib.Rectangle {
					x      = f32(column * tile_width),
					y      = f32(row * tile_height),
					width  = f32(tile_width),
					height = f32(tile_height),
				}

				raylib.DrawTexturePro(
					texture,
					source_rectangle,
					destination_rectangle,
					raylib.Vector2{0, 0},
					0,
					raylib.WHITE,
				)
			}
		}
	}
}
