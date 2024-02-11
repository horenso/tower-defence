const std = @import("std");
const Game = @import("./game.zig").Game;
const sdl = @import("./sdl.zig").SDL;
const tile_map = @import("./map.zig");

const vec = @import("./vec.zig");
const FVec = vec.FVec;
const IVec = vec.IVec;

const IDEAL_FRAME_TIME: f64 = 1000 / 60;

pub fn main() !void {
    var game = try Game.init();
    defer game.deinit();

    var quit = false;

    var now: u64 = 0;
    var last: u64 = sdl.SDL_GetPerformanceCounter();
    var delta_time: f64 = 0;
    var fps: f64 = 0.0;

    while (!quit) {
        now = sdl.SDL_GetPerformanceCounter();
        delta_time = @as(f64, @floatFromInt(now - last)) / @as(f64, @floatFromInt(sdl.SDL_GetPerformanceFrequency()));
        fps = 1.0 / delta_time;
        last = now;

        var event: sdl.SDL_Event = undefined;
        while (sdl.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                sdl.SDL_QUIT => {
                    quit = true;
                },
                sdl.SDL_KEYDOWN => switch (event.key.keysym.sym) {
                    sdl.SDLK_ESCAPE => quit = true,
                    else => {},
                },
                else => {},
            }
        }
        _ = sdl.SDL_SetRenderDrawColor(game.renderer, 0x20, 0x18, 0x18, 255);
        _ = sdl.SDL_RenderClear(game.renderer);

        game.map.render(game.renderer);

        sdl.SDL_RenderPresent(game.renderer);

        const delay: f64 = @min(0, std.math.round(IDEAL_FRAME_TIME - delta_time));
        sdl.SDL_Delay(@intFromFloat(delay));
    }
}
