const std = @import("std");
const Engine = @import("./engine.zig").Engine;
const sdl = @import("./sdl.zig").SDL;
const os = std.os;

const vec = @import("./vec.zig");
const FVec = vec.FVec;
const IVec = vec.IVec;

const IDEAL_FRAME_TIME: f64 = 1000 / 60;

const LIBRARY_PATH = "zig-out/lib/libgame.so";

var game_dyn_lib: ?std.DynLib = null;
var library_modified: i128 = 0;

fn load_game_library() !bool {
    const stat = try std.fs.cwd().statFile(LIBRARY_PATH);
    if (library_modified == stat.mtime) {
        return false;
    }
    library_modified = stat.mtime;
    if (game_dyn_lib) |*dyn_lib| {
        dyn_lib.close();
        game_dyn_lib = null;
    }
    var dyn_lib = std.DynLib.open(LIBRARY_PATH) catch {
        return error.OpenFail;
    };
    game_dyn_lib = dyn_lib;
    gameStructSize = dyn_lib.lookup(@TypeOf(gameStructSize), "gameStructSize") orelse return error.LookupFail;
    gameInit = dyn_lib.lookup(@TypeOf(gameInit), "gameInit") orelse return error.LookupFail;
    gameDeinit = dyn_lib.lookup(@TypeOf(gameDeinit), "gameDeinit") orelse return error.LookupFail;
    gameRender = dyn_lib.lookup(@TypeOf(gameRender), "gameRender") orelse return error.LookupFail;

    std.log.info("Library reloeaded", .{});
    return true;
}

const Game = anyopaque;

var gameStructSize: *const fn () usize = undefined;
var gameInit: *const fn (*sdl.SDL_Renderer) *Game = undefined;
var gameDeinit: *const fn (*Game) void = undefined;
var gameRender: *const fn (*Game, *sdl.SDL_Renderer) void = undefined;

pub fn main() !void {
    var engine = try Engine.init();
    defer engine.deinit();

    _ = try load_game_library();

    var game = gameInit(engine.renderer);

    var quit = false;

    var now: u64 = 0;
    var last: u64 = sdl.SDL_GetPerformanceCounter();
    var delta_time: f64 = 0;
    var fps: f64 = 0.0;

    var ticks: u8 = 0;

    while (!quit) {
        now = sdl.SDL_GetPerformanceCounter();
        delta_time = @as(f64, @floatFromInt(now - last)) / @as(f64, @floatFromInt(sdl.SDL_GetPerformanceFrequency()));
        fps = 1.0 / delta_time;
        last = now;

        if (ticks % 60 == 0) {
            if (try load_game_library()) {
                gameDeinit(game);
                game = gameInit(engine.renderer);
            }
        }

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
        _ = sdl.SDL_SetRenderDrawColor(engine.renderer, 0x20, 0x18, 0x18, 255);
        _ = sdl.SDL_RenderClear(engine.renderer);

        gameRender(game, engine.renderer);

        sdl.SDL_RenderPresent(engine.renderer);

        const delay: f64 = @min(0, std.math.round(IDEAL_FRAME_TIME - delta_time));
        sdl.SDL_Delay(@intFromFloat(delay));

        ticks +%= 1;
    }
}
