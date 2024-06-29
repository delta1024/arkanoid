//  Arkanoid - The classic brick destroying game in zig
//  Copyright (C) 2024  Jacob Stannix

//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.

//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.

//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <https://www.gnu.org/licenses/>.

const std = @import("std");
const ray = @import("raylib");
const Rectangle = ray.Rectangle;
const Color = ray.Color;
const Vector2 = ray.Vector2;

const BRICK_COUNT: usize = 12;
const PLAT_SPEED: f32 = 3;
const BALL_SPEED: f32 = 3;

const screen = struct {
    pub const width: i32 = 800;
    pub const height: i32 = 450;
    pub const fps: i32 = 60;
};
const brick_size: f32 = @as(f32, @floatFromInt(screen.width)) / @as(f32, @floatFromInt(BRICK_COUNT));
const ball_def_pos: Vector2 = .{ @as(f32, @floatFromInt(screen.width / 2)) - 3.5, @as(f32, @floatFromInt(screen.height)) - 90 };
const plat_def_pos: Rectangle = .{ .x = (screen.width / 2) - 25, .y = screen.height - 20, .height = 10, .width = 40 };
const def_ball: Ball = .{
    .pos = ball_def_pos,
    .dir = .{ 6, 2 },
    .rad = 7,
};

pub fn main() !void {
    const texts = setup(.{
        .width = screen.width,
        .height = screen.height,
        .fps = screen.fps,
    });
    defer shutdown(texts);
    var bricks: [BRICK_COUNT * 3]Brick = undefined;
    setupBricks(&bricks);
    var platform: Rectangle = plat_def_pos;
    var ball: Ball = def_ball;
    var game_over = false;
    var victory = false;
    var frame: f32 = 0;
    var paused = false;
    while (!ray.windowShouldClose()) : (frame += if (!game_over) 1 else 0) {
        if (ray.isKeyPressed(.Space)) {
            if (game_over or victory) {
                setupBricks(&bricks);
                platform = plat_def_pos;
                ball = def_ball;
                game_over = false;
                victory = false;
            } else {
                paused = !paused;
            }
        }
        if (!paused and !game_over and !victory) {
            const delta = ray.getFrameTime();
            if (ray.isKeyDown(.Right)) {
                platform.x += (PLAT_SPEED * delta) * screen.fps;
            }
            if (ray.isKeyDown(.Left)) {
                platform.x -= (PLAT_SPEED * delta) * screen.fps;
            }

            if (@mod(frame, BALL_SPEED) == 0)
                ball.pos += ball.dir;

            if (ray.checkCollisionCircleRec(ball.pos, ball.rad, platform))
                ball.dir *= .{ 1, -1 };

            const ball_lu_check = (ball.pos - Vector2{ ball.rad, ball.rad }) < Vector2{ 0, 0 };
            const ball_rd_check = (ball.pos + Vector2{ ball.rad, ball.rad }) > Vector2{ screen.width, screen.height };
            if (ball_lu_check[0]) {
                ball.dir *= Vector2{ -1, 1 };
            }
            if (ball_lu_check[1]) {
                ball.dir *= Vector2{ 1, -1 };
            }
            if (ball_rd_check[0]) {
                ball.dir *= Vector2{ -1, 1 };
            }
            if (ball_rd_check[1]) {
                game_over = true;
                ball.dir *= Vector2{ 1, -1 };
            }

            bricks: for (&bricks) |*brick| {
                if (brick.hit)
                    continue :bricks;
                if (ray.checkCollisionCircleRec(ball.pos, ball.rad, brick.rec)) {
                    brick.hit = true;
                    var edge = brick.bottom();
                    var ball_axis = ball.top();
                    if (ray.checkCollisionLines(edge.start, edge.end, ball_axis.start, ball_axis.end)) |_| {
                        ball.dir *= Vector2{ 1, -1 };
                        break :bricks;
                    }
                    edge = brick.left();
                    ball_axis = ball.right();
                    if (ray.checkCollisionLines(edge.start, edge.end, ball_axis.start, ball_axis.end)) |_| {
                        ball.dir *= Vector2{ -1, 1 };
                        break :bricks;
                    }
                    edge = brick.right();
                    ball_axis = ball.left();
                    if (ray.checkCollisionLines(edge.start, edge.end, ball_axis.start, ball_axis.end)) |_| {
                        ball.dir *= Vector2{ -1, 1 };
                        break :bricks;
                    }
                    edge = brick.top();
                    ball_axis = ball.bottom();
                    if (ray.checkCollisionLines(edge.start, edge.end, ball_axis.start, ball_axis.end)) |_| {
                        ball.dir *= Vector2{ 1, -1 };
                        break :bricks;
                    }
                }
            }
            var check_win = true;
            for (bricks) |brick|
                if (!brick.destroied) {
                    check_win = false;
                };
            if (check_win)
                victory = true;
            {
                ray.beginTextureMode(texts.screen.texture);
                defer ray.endTextureMode();
                ray.clearBackground(ray.colors.Blank);
                for (&bricks) |*brick|
                    if (!brick.hit or !brick.destroied) {
                        ray.drawTexturePro(texts.brick.texture, texts.brick.source, brick.rec, .{ 0, 0 }, 0, brick.color);
                        if (brick.hit) {
                            brick.destroied = true;
                        }
                    };
                ray.drawRectangleRec(platform, ray.colors.Black);
                ray.drawCircleV(ball.pos, ball.rad, ray.colors.Green);
            }
        }

        ray.beginDrawing();
        defer ray.endDrawing();
        ray.clearBackground(ray.colors.RayWhite);
        ray.drawTextureRec(texts.screen.texture.texture, texts.screen.source, .{ 0, 0 }, ray.colors.White);
        if (game_over) {
            ray.drawText("GAME OVER", (screen.width / 2) - (5 * 24), (screen.height / 2) - 12, 24, ray.colors.Red);
        }
        if (victory) {
            ray.drawText("VICTORY", (screen.width / 2) - (4 * 24), (screen.height / 2) - 12, 24, ray.colors.Green);
        }
        if (paused) {
            ray.drawText("PAUSED", (screen.width / 2) - (3 * 23), (screen.height / 2) - 12, 24, ray.colors.Black);
        }
    }
}
const Line = struct {
    start: Vector2,
    end: Vector2,
};
const Brick = struct {
    rec: Rectangle,
    color: Color,
    hit: bool = false,
    destroied: bool = false,
    // (x, y) --------- (x1, y)
    fn top(self: Brick) Line {
        const x = self.rec.x;
        const y = self.rec.y;
        const x1 = self.rec.x + self.rec.width;
        return Line{
            .start = .{ x, y },
            .end = .{ x1, y },
        };
    }
    //  (x, y)
    //    |
    //    |
    //    |
    // (x, y1)
    fn left(self: Brick) Line {
        const x = self.rec.x;
        const y = self.rec.y;
        const y1 = self.rec.y + self.rec.height;
        return Line{
            .start = .{ x, y },
            .end = .{ x, y1 },
        };
    }
    //                     (x1, y)
    //                       |
    //                       |
    //                       |
    //                    (x1, y1)
    fn right(self: Brick) Line {
        const x1 = self.rec.x + self.rec.width;
        const y = self.rec.y;
        const y1 = self.rec.y + self.rec.height;
        return Line{
            .start = .{ x1, y },
            .end = .{ x1, y1 },
        };
    }
    //
    //
    //
    // (x, y1) --------- (x1, y1)
    fn bottom(self: Brick) Line {
        const x = self.rec.x;
        const x1 = self.rec.x + self.rec.width;
        const y1 = self.rec.y + self.rec.height;
        return Line{
            .start = .{ x, y1 },
            .end = .{ x1, y1 },
        };
    }
};

const Ball = struct {
    pos: Vector2,
    dir: Vector2,
    rad: f32,
    fn top(self: Ball) Line {
        return Line{
            .start = self.pos - Vector2{ 0, self.rad },
            .end = self.pos,
        };
    }
    fn right(self: Ball) Line {
        return Line{
            .start = self.pos,
            .end = self.pos + Vector2{ self.rad, 0 },
        };
    }
    fn left(self: Ball) Line {
        return Line{
            .start = self.pos - Vector2{ self.rad, 0 },
            .end = self.pos,
        };
    }
    fn bottom(self: Ball) Line {
        return Line{
            .start = self.pos,
            .end = self.pos + Vector2{ 0, self.rad },
        };
    }
};
const LoadedTextures = struct {
    brick: struct {
        texture: ray.Texture2D,
        source: Rectangle,
    },
    screen: struct {
        texture: ray.RenderTexture2D,
        source: Rectangle,
    },
};
const SetupOpts = struct {
    width: i32,
    height: i32,
    fps: i32,
};
pub fn setup(opts: SetupOpts) LoadedTextures {
    ray.initWindow(opts.width, opts.height, "arkanoid");
    ray.setTargetFps(opts.fps);

    const brick_texture = blk: {
        const image = ray.loadImage("assets/texture_brick_100.png");
        defer ray.unloadImage(image);
        break :blk ray.loadTextureFromImage(image);
    };
    const brick_texture_source = ray.Rectangle{
        .x = 0,
        .y = 0,
        .width = @floatFromInt(brick_texture.width),
        .height = @floatFromInt(brick_texture.height),
    };
    const screen_buff = ray.loadRenderTexture(opts.width, opts.height);
    const screen_source = Rectangle{
        .x = 0,
        .y = 0,
        .width = @floatFromInt(screen_buff.texture.width),
        .height = @floatFromInt(-screen_buff.texture.height),
    };
    return LoadedTextures{
        .brick = .{
            .texture = brick_texture,
            .source = brick_texture_source,
        },
        .screen = .{
            .texture = screen_buff,
            .source = screen_source,
        },
    };
}
fn shutdown(texts: LoadedTextures) void {
    ray.unloadTexture(texts.brick.texture);
    ray.unloadRenderTexture(texts.screen.texture);
    ray.closeWindow();
}
pub const BrickIter = struct {
    buff: []Brick,
    row_len: usize,
    i: usize,
    pub fn next(self: *BrickIter) ?[]Brick {
        if ((self.i + 1) * self.row_len > self.buff.len)
            return null;
        defer self.i += 1;
        return self.buff[self.i * self.row_len .. (self.i + 1) * self.row_len];
    }
};
fn setupBricks(bricks: []Brick) void {
    var iter: BrickIter = .{
        .buff = bricks,
        .row_len = BRICK_COUNT,
        .i = 0,
    };
    while (iter.next()) |buf| {
        const y = @as(f32, @floatFromInt(iter.i - 1)) * brick_size;
        for (buf, 0..) |*brick, i| {
            brick.* = .{
                .rec = .{
                    .x = @as(f32, @floatFromInt(i)) * brick_size,
                    .y = y,
                    .width = brick_size,
                    .height = brick_size,
                },
                .color = if (i % 2 == 0) blk: {
                    if (iter.i % 2 == 0)
                        break :blk ray.colors.White
                    else
                        break :blk ray.colors.Gray;
                } else blk: {
                    if (iter.i % 2 == 0)
                        break :blk ray.colors.Gray
                    else
                        break :blk ray.colors.White;
                },
            };
        }
    }
}
