const std = @import("std");
const rl = @import("raylib");

const Vector2 = rl.Vector2;

const WIDTH = 640;
const HEIGHT = 480;
const SCORE_BUFFER_SIZE = 32;
const INITIAL_BALL_SPEED = 5.0;
const INITIAL_PLAYER_SPEED = 5.0;
const SPEED_INCREMENT = 0.5;

// Glow shader
const fragmentShaderCode =
    \\#version 330
    \\
    \\in vec2 fragTexCoord;
    \\in vec4 fragColor;
    \\
    \\uniform sampler2D texture0;
    \\uniform vec4 colDiffuse;
    \\
    \\out vec4 finalColor;
    \\
    \\const float samples = 5.0;
    \\const float quality = 2.5;
    \\
    \\void main()
    \\{
    \\    vec2 size = textureSize(texture0, 0);
    \\    vec4 sum = vec4(0);
    \\    vec2 sizeFactor = vec2(1)/size*quality;
    \\
    \\    vec4 source = texture(texture0, fragTexCoord);
    \\
    \\    const int range = 2;
    \\
    \\    for (int x = -range; x <= range; x++)
    \\    {
    \\        for (int y = -range; y <= range; y++)
    \\        {
    \\            sum += texture(texture0, fragTexCoord + vec2(x, y)*sizeFactor);
    \\        }
    \\    }
    \\
    \\    finalColor = ((sum/(samples*samples)) + source)*colDiffuse;
    \\}
;

const Player = struct {
    pos_y: i32,
    pos_x: i32,
    width: i32 = 20,
    height: i32 = 70,
    score: i32 = 0,
    speed: f32,
};

const Ball = struct {
    radius: f32 = 10.0,
    x: f32,
    y: f32,
    speed: f32,
    dx: f32,
    dy: f32,
};

fn toString(value: i32, buffer: []u8) ![:0]const u8 {
    return std.fmt.bufPrintZ(buffer, "{d}", .{value});
}

fn checkCollision(x1: i32, x2: f32, y1: i32, y2: f32, w1: i32, h1: i32, r: f32) bool {
    if (@as(f32, @floatFromInt(x1)) <= x2 + r and
        @as(f32, @floatFromInt(y1)) <= y2 + r and
        x2 <= @as(f32, @floatFromInt(x1 + w1)) and
        y2 <= @as(f32, @floatFromInt(y1 + h1)))
    {
        return true;
    }
    return false;
}

pub fn main() !void {
    // Initialization
    rl.initWindow(WIDTH, HEIGHT, "zig-pong");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    // Initialize render texture for shader drawing
    const target = rl.loadRenderTexture(WIDTH, HEIGHT);
    defer rl.unloadRenderTexture(target);

    // Load and initialize shader
    const shader = rl.loadShaderFromMemory(null, fragmentShaderCode);
    defer rl.unloadShader(shader);

    var buffer: [SCORE_BUFFER_SIZE]u8 = undefined;

    var player1 = Player{
        .pos_x = 20,
        .pos_y = 100,
        .speed = INITIAL_PLAYER_SPEED,
    };

    var cpu = Player{
        .pos_x = WIDTH - 35,
        .pos_y = 100,
        .speed = INITIAL_PLAYER_SPEED,
    };

    var ball = Ball{
        .x = @as(f32, WIDTH / 2) - 10.0,
        .y = 120.0,
        .speed = INITIAL_BALL_SPEED,
        .dx = -1.0,
        .dy = -1.0,
    };

    while (!rl.windowShouldClose()) {
        // Update variables
        if (checkCollision(player1.pos_x, ball.x, player1.pos_y, ball.y, player1.width, player1.height, ball.radius) or
            checkCollision(cpu.pos_x, ball.x, cpu.pos_y, ball.y, cpu.width, cpu.height, ball.radius))
        {
            ball.dx *= -1.0;
        }

        cpu.pos_y = @min(HEIGHT - cpu.height, @max(0, @as(i32, @intFromFloat(ball.y)) - @divExact(cpu.height, 2)));

        ball.x += ball.dx * ball.speed;
        ball.y += ball.dy * ball.speed;

        if (ball.x < 5.0) {
            cpu.score += 1;
            ball.x = @as(f32, WIDTH / 2) - ball.radius;
            ball.y = 120.0;
            ball.dx = -1.0;
            ball.speed += SPEED_INCREMENT;
            player1.speed += SPEED_INCREMENT;
            cpu.speed += SPEED_INCREMENT;
        } else if (ball.x > @as(f32, WIDTH - 5)) {
            player1.score += 1;
            ball.x = @as(f32, WIDTH / 2) - ball.radius;
            ball.y = 120.0;
            ball.dx = 1.0;
            ball.speed += SPEED_INCREMENT;
            player1.speed += SPEED_INCREMENT;
            cpu.speed += SPEED_INCREMENT;
        }

        if (ball.y < 5.0) {
            ball.dy *= -1.0;
        } else if (ball.y > @as(f32, HEIGHT - 5)) {
            ball.dy *= -1.0;
        }

        // Player movement with variable speed
        if (rl.isKeyDown(rl.KeyboardKey.w) or rl.isKeyDown(rl.KeyboardKey.up)) {
            player1.pos_y = @max(0, player1.pos_y - @as(i32, @intFromFloat(player1.speed)));
        } else if (rl.isKeyDown(rl.KeyboardKey.s) or rl.isKeyDown(rl.KeyboardKey.down)) {
            player1.pos_y = @min(HEIGHT - player1.height, player1.pos_y + @as(i32, @intFromFloat(player1.speed)));
        }

        // Draw game to render texture
        rl.beginTextureMode(target);
        rl.clearBackground(rl.Color.black);

        // BALL
        rl.drawCircle(@intFromFloat(ball.x), @intFromFloat(ball.y), ball.radius, rl.Color.white);

        // PLAYERS
        rl.drawRectangle(player1.pos_x, player1.pos_y, player1.width, player1.height, rl.Color.white);
        rl.drawRectangle(cpu.pos_x, cpu.pos_y, cpu.width, cpu.height, rl.Color.white);

        rl.drawLine(WIDTH / 2, 0, WIDTH / 2, HEIGHT, rl.Color.white);

        // SCORES
        const score1 = try toString(player1.score, &buffer);
        const score2 = try toString(cpu.score, &buffer);
        rl.drawText(score1.ptr, (WIDTH / 2) - 200, 30, 48, rl.Color.white);
        rl.drawText(score2.ptr, (WIDTH / 2) + 200, 30, 48, rl.Color.white);
        rl.endTextureMode();

        // Draw render texture with shader
        rl.beginDrawing();
        rl.clearBackground(rl.Color.black);

        // Draw render texture using shader
        rl.beginShaderMode(shader);
        rl.drawTextureRec(target.texture, .{ .x = 0, .y = 0, .width = @as(f32, @floatFromInt(target.texture.width)), .height = -@as(f32, @floatFromInt(target.texture.height)) }, .{ .x = 0, .y = 0 }, rl.Color.white);
        rl.endShaderMode();
        rl.endDrawing();
    }
}
