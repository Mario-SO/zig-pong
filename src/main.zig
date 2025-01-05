const std = @import("std");
const rl = @import("raylib");

const Vector2 = rl.Vector2;

const WIDTH = 640;
const HEIGHT = 480;
const SCORE_BUFFER_SIZE = 32;

const State = struct {
    ballPos: Vector2,
};

const Player = struct {
    pos_y: i32,
    pos_x: i32,
    width: i32 = 20,
    height: i32 = 70,
    score: i32 = 0,
};

const Ball = struct {
    radius: f32 = 10,
    x: i32,
    y: i32,
    bx: f32,
    by: f32,
};

pub fn toString(value: i32, buffer: []u8) ![:0]const u8 {
    return std.fmt.bufPrintZ(buffer, "{d}", .{value});
}

// fn checkCollision(x1: i32, x2: f32, y1: i32, y2: f32, w1: i32, h1: i32, r: f32) bool {}

pub fn main() anyerror!void {
    // Initialization
    rl.initWindow(WIDTH, HEIGHT, "zig-pong");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    var buffer: [SCORE_BUFFER_SIZE]u8 = undefined;

    const player1 = Player{
        .pos_x = 20,
        .pos_y = 100,
    };

    const cpu = Player{
        .pos_x = WIDTH - 35,
        .pos_y = 100,
    };

    // const ball = Ball{
    //     .x = (WIDTH / 2) - .radius,
    //     .y = 120,
    //     .bx = -5,
    //     .by = -5,
    // };

    while (!rl.windowShouldClose()) {
        // Update
        //----------------------------------------------------------------------------------
        // TODO: Update your variables here
        //----------------------------------------------------------------------------------

        // Draw
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black);
        // rl.drawText("PONG", @divExact(WIDTH - rl.measureText("PONG", 20), 2), 20, 20, rl.Color.white);

        // PLAYERS
        rl.drawRectangle(player1.pos_x, player1.pos_y, player1.width, player1.height, rl.Color.white);
        rl.drawRectangle(cpu.pos_x, cpu.pos_y, cpu.width, cpu.height, rl.Color.white);

        rl.drawLine(WIDTH / 2, 0, WIDTH / 2, HEIGHT, rl.Color.white);

        // SCORES
        const score1 = try toString(player1.score, &buffer);
        const score2 = try toString(cpu.score, &buffer);
        rl.drawText(score1.ptr, (WIDTH / 2) - 200, 30, 48, rl.Color.white);
        rl.drawText(score2.ptr, (WIDTH / 2) + 200, 30, 48, rl.Color.white);
    }
}
