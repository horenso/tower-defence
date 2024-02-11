const std = @import("std");
const log = @import("std").log;

const sdl = @import("./sdl.zig").SDL;

const game = @import("./game.zig");
const Game = game.Game;
const WINDOW_HEIGHT = game.WINDOW_HEIGHT;
const WINDOW_WIDTH = game.WINDOW_WIDTH;

const vec = @import("./vec.zig");
const FVec = vec.FVec;
const IVec = vec.IVec;

const TEXTURE_PATH = "./res/tiles.png";
const TILE_HEIGHT = 32;
const TILE_WIDTH = 32;
const MAP_FILE = @embedFile("./map.txt");
const MAP_TILES_X = 42;
const MAP_TILES_Y = 22;
const MapDataType = [MAP_TILES_Y][MAP_TILES_X]Tile;

pub const Tile = enum {
    build_space,
    wall,
    path,
    home,

    pub fn form_character(char: u8) Tile {
        return switch (char) {
            '0' => .build_space,
            '1' => .wall,
            '2' => .path,
            '3' => .home,
            else => unreachable,
        };
    }

    pub fn get_id(self: Tile) IVec {
        return switch (self) {
            .build_space => IVec{ .x = 0, .y = 0 },
            .wall => IVec{ .x = 1, .y = 0 },
            .path => IVec{ .x = 2, .y = 0 },
            .home => IVec{ .x = 3, .y = 0 },
        };
    }
};

pub const Map = struct {
    map_data: MapDataType,
    bg_texture: *sdl.SDL_Texture,

    pub fn init(renderer: *sdl.SDL_Renderer) !Map {
        var map_data: MapDataType = undefined;

        var it = std.mem.split(u8, MAP_FILE, "\n");
        var row_index: usize = 0;
        while (it.next()) |row| {
            for (row, 0..) |character, col_index| {
                const wow = Tile.form_character(character);
                map_data[row_index][col_index] = wow;
            }
            row_index += 1;
        }

        const bg_texture = try bake_bg_texture(map_data, renderer);

        return Map{
            .map_data = map_data,
            .bg_texture = bg_texture,
        };
    }

    pub fn render(self: *Map, renderer: *sdl.SDL_Renderer) void {
        const source_rect = sdl.SDL_Rect{
            .w = WINDOW_WIDTH,
            .h = WINDOW_HEIGHT,
            .x = 0,
            .y = 0,
        };
        const dest_rect = sdl.SDL_Rect{
            .w = WINDOW_WIDTH,
            .h = WINDOW_HEIGHT,
            .x = 0,
            .y = 0,
        };
        _ = sdl.SDL_RenderCopy(
            renderer,
            self.bg_texture,
            &source_rect,
            &dest_rect,
        );
    }

    fn bake_bg_texture(map_data: MapDataType, renderer: *sdl.SDL_Renderer) !*sdl.SDL_Texture {
        const tile_texture = sdl.IMG_LoadTexture(renderer, TEXTURE_PATH) orelse {
            sdl.SDL_Log("Failed to load resource: %s", sdl.SDL_GetError());
            return error.SDLResourceLoadingFailed;
        };

        const bg_texture = sdl.SDL_CreateTexture(
            renderer,
            sdl.SDL_PIXELFORMAT_RGB888,
            sdl.SDL_TEXTUREACCESS_TARGET,
            WINDOW_WIDTH,
            WINDOW_HEIGHT,
        ) orelse {
            sdl.SDL_Log("Failed to load resource: %s", sdl.SDL_GetError());
            return error.SDLResourceLoadingFailed;
        };

        _ = sdl.SDL_SetRenderTarget(renderer, bg_texture);
        for (map_data, 0..) |row, y| {
            for (row, 0..) |cell, x| {
                const id = cell.get_id();
                const source_rect = sdl.SDL_Rect{
                    .w = TILE_WIDTH,
                    .h = TILE_HEIGHT,
                    .x = id.x * TILE_WIDTH,
                    .y = id.y * TILE_HEIGHT,
                };
                const dest_rect = sdl.SDL_Rect{
                    .w = TILE_WIDTH,
                    .h = TILE_HEIGHT,
                    .x = @intCast(x * TILE_WIDTH),
                    .y = @intCast(y * TILE_HEIGHT),
                };
                _ = sdl.SDL_RenderCopy(
                    renderer,
                    tile_texture,
                    &source_rect,
                    &dest_rect,
                );
            }
        }
        _ = sdl.SDL_SetRenderTarget(renderer, null);
        _ = sdl.SDL_DestroyTexture(tile_texture);
        return bg_texture;
    }

    pub fn deinit(self: *Map) void {
        sdl.SDL_DestroyTexture(self.bg_texture);
    }
};
