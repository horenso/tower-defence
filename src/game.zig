const std = @import("std");
const math = std.math;
const c = @import("./sdl.zig").SDL;
const Map = @import("./map.zig").Map;

pub const WINDOW_WIDTH = 1344;
pub const WINDOW_HEIGHT = 704;

const GameInitError = error{
    SDLInitializationFailed,
    SDLResourceLoadingFailed,
};

pub const Game = struct {
    window: *c.SDL_Window,
    renderer: *c.SDL_Renderer,
    map: Map,

    pub fn init() GameInitError!Game {
        if (c.SDL_Init(c.SDL_INIT_VIDEO | c.SDL_INIT_TIMER) < 0) {
            c.SDL_Log("Unable to initialize SDL: %s", c.SDL_GetError());
            return GameInitError.SDLInitializationFailed;
        }
        errdefer c.SDL_Quit();

        if (c.IMG_Init(c.IMG_INIT_PNG) != c.IMG_INIT_PNG) {
            c.SDL_Log("Unable to initialize SDL: %s", c.SDL_GetError());
            return GameInitError.SDLInitializationFailed;
        }
        errdefer c.IMG_Quit();

        if (c.TTF_Init() < 0) {
            c.SDL_Log("TTF_Init Error: %s", c.TTF_GetError());
            return GameInitError.SDLInitializationFailed;
        }
        errdefer c.TTF_Quit();

        const window = c.SDL_CreateWindow(
            "Tower Defence",
            c.SDL_WINDOWPOS_CENTERED,
            c.SDL_WINDOWPOS_CENTERED,
            WINDOW_WIDTH,
            WINDOW_HEIGHT,
            0,
        ) orelse {
            c.SDL_Log("Unable to initialize SDL: %s", c.SDL_GetError());
            return GameInitError.SDLInitializationFailed;
        };
        errdefer c.SDL_DestroyWindow(window);

        const renderer = c.SDL_CreateRenderer(
            window,
            -1,
            c.SDL_RENDERER_ACCELERATED | c.SDL_RENDERER_PRESENTVSYNC,
        ) orelse {
            c.SDL_Log("Unable to initialize SDL: %s", c.SDL_GetError());
            return GameInitError.SDLInitializationFailed;
        };
        errdefer c.SDL_DestroyRenderer(renderer);

        const map = try Map.init(renderer);
        errdefer map.deinit();

        return Game{
            .window = window,
            .renderer = renderer,
            .map = map,
        };
    }

    pub fn deinit(self: *Game) void {
        self.map.deinit();
        c.SDL_DestroyRenderer(self.renderer);
        c.SDL_DestroyWindow(self.window);
        c.TTF_Quit();
        c.IMG_Quit();
        c.SDL_Quit();
    }
};
