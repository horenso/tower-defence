const Map = @import("./map.zig").Map;
const sdl = @import("./sdl.zig").SDL;
const std = @import("std");

pub const Game = struct {
    map: Map,
    frame: usize,
};

export fn gameStructSize() usize {
    return @sizeOf(Game);
}

export fn gameInit(renderer: *sdl.SDL_Renderer) *Game {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var game = allocator.create(Game) catch @panic("out of memory");
    game.map = Map.init(renderer) catch @panic("map init error");
    game.frame = 0;
    return game;
}

export fn gameDeinit(game: *Game) void {
    game.map.deinit();
}

export fn gameRender(game: *Game, renderer: *sdl.SDL_Renderer) void {
    game.map.render(renderer);
    game.*.frame +%= 1;
    // _ = sdl.SDL_SetRenderDrawColor(renderer, 255, 0, 0, 255);
    // _ = sdl.SDL_RenderDrawRect(renderer, &sdl.SDL_Rect{ .x = 100, .y = 100, .w = 100, .h = 100 });
}
