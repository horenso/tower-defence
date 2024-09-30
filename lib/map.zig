const std = @import("std");
const log = @import("std").log;

const sdl = @import("./sdl.zig").SDL;

pub const WINDOW_WIDTH = 1344;
pub const WINDOW_HEIGHT = 704;

const vec = @import("../vec.zig");
const FVec = vec.FVec;
const IVec = vec.IVec;

const TEXTURE_PATH = "./res/tiles.png";
const TILE_HEIGHT = 32;
const TILE_WIDTH = 32;
const MAP_FILE = @embedFile("./map.txt");
const MAP_TILES_X = 42;
const MAP_TILES_Y = 22;
const MapDataType = [MAP_TILES_Y][MAP_TILES_X]?Tile;

pub const Tile = enum {
    build_space,
    enemy_spawn,
    path,
    home,

    const PathInfo = struct {
        x: u8 = 0,
        y: u8 = 0,
        flip_h: bool = false,
        flip_v: bool = false,
        rot_90: bool = false,
    };

    pub fn form_character(char: u8) Tile {
        return switch (char) {
            '0' => .build_space,
            '1' => .path,
            '2' => .enemy_spawn,
            '3' => .home,
            else => unreachable,
        };
    }

    inline fn get_path_tile(neighbors: u4) PathInfo {
        return switch (neighbors) {
            //WSEN
            0b0000 => PathInfo{ .x = 0 },
            0b0001 => PathInfo{ .x = 1 },
            0b0010 => PathInfo{ .x = 1, .rot_90 = true },
            0b0011 => PathInfo{ .x = 2, .rot_90 = true, .flip_h = true, .flip_v = true },
            0b0100 => PathInfo{ .x = 1, .flip_v = true },
            0b0101 => PathInfo{ .x = 3 },
            0b0110 => PathInfo{ .x = 2 },
            0b0111 => PathInfo{ .x = 4, .rot_90 = true, .flip_v = true },
            0b1000 => PathInfo{ .x = 1, .rot_90 = true, .flip_v = true },
            0b1001 => PathInfo{ .x = 2, .flip_h = true, .flip_v = true },
            0b1010 => PathInfo{ .x = 3, .rot_90 = true },
            0b1011 => PathInfo{ .x = 4, .flip_v = true },
            0b1100 => PathInfo{ .x = 2, .flip_h = true },
            0b1101 => PathInfo{ .x = 4, .rot_90 = true },
            0b1110 => PathInfo{ .x = 4 },
            0b1111 => PathInfo{ .x = 5 },
        };
    }

    pub fn get_drawing_info(
        self: Tile,
        neighbor_north: ?Tile,
        neighbor_east: ?Tile,
        neighbor_south: ?Tile,
        neighbor_west: ?Tile,
    ) PathInfo {
        return switch (self) {
            .build_space => PathInfo{
                .flip_h = false,
                .flip_v = false,
                .x = 0,
                .y = 1,
            },
            .path, .enemy_spawn => {
                var neightbors: u4 = 0;
                if (Tile.is_path(neighbor_north)) neightbors |= 1;
                if (Tile.is_path(neighbor_east)) neightbors |= 1 << 1;
                if (Tile.is_path(neighbor_south)) neightbors |= 1 << 2;
                if (Tile.is_path(neighbor_west)) neightbors |= 1 << 3;
                return Tile.get_path_tile(neightbors);
            },
            .home => PathInfo{
                .flip_h = false,
                .flip_v = false,
                .x = 3,
                .y = 1,
            },
        };
    }

    inline fn is_path(tile: ?Tile) bool {
        return tile == null or tile == Tile.path or tile == Tile.enemy_spawn;
    }
};

pub const Map = struct {
    map_data: MapDataType,
    bg_texture: *sdl.SDL_Texture,

    pub fn init(renderer: *sdl.SDL_Renderer) !Map {
        std.log.info("Map init()", .{});
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

        const bg_texture = try bake_bg_texture(&map_data, renderer);

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

    pub fn in_bounce(x: isize, y: isize) bool {
        return x >= 0 and x < MAP_TILES_X and y >= 0 and y < MAP_TILES_Y;
    }

    pub fn opt_get(map_data: *const MapDataType, x: isize, y: isize) ?Tile {
        if (in_bounce(x, y)) {
            return map_data[@intCast(y)][@intCast(x)];
        } else {
            return null;
        }
    }

    fn bake_bg_texture(map_data: *const MapDataType, renderer: *sdl.SDL_Renderer) !*sdl.SDL_Texture {
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
                const x_isze = @as(isize, @intCast(x));
                const y_isze = @as(isize, @intCast(y));
                const draw_info = cell.?.get_drawing_info(
                    Map.opt_get(map_data, x_isze, y_isze - 1),
                    Map.opt_get(map_data, x_isze + 1, y_isze),
                    Map.opt_get(map_data, x_isze, y_isze + 1),
                    Map.opt_get(map_data, x_isze - 1, y_isze),
                );
                const source_rect = sdl.SDL_Rect{
                    .w = TILE_WIDTH,
                    .h = TILE_HEIGHT,
                    .x = draw_info.x * TILE_WIDTH,
                    .y = draw_info.y * TILE_HEIGHT,
                };
                const dest_rect = sdl.SDL_Rect{
                    .w = TILE_WIDTH,
                    .h = TILE_HEIGHT,
                    .x = @intCast(x * TILE_WIDTH),
                    .y = @intCast(y * TILE_HEIGHT),
                };
                var flip: c_uint = 0;
                if (draw_info.flip_h) flip |= sdl.SDL_FLIP_HORIZONTAL;
                if (draw_info.flip_v) flip |= sdl.SDL_FLIP_VERTICAL;

                _ = sdl.SDL_RenderCopyEx(
                    renderer,
                    tile_texture,
                    &source_rect,
                    &dest_rect,
                    if (draw_info.rot_90) 90 else 0,
                    null,
                    flip,
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
