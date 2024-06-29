const std = @import("std");
const ray = @import("raylib");
const Rectangle = ray.Rectangle;
const Color = ray.Color;
const Vector2 = ray.Vector2;

const Brick = struct {
    rec: Rectangle,
    color: Color,
    hit: bool = false,
};

const Ball = struct {
    pos: Vector2,
    dir: Vector2,
};

const BRICK_COUNT: usize = 12;
const PLAT_SPEED: f32 = 3;
const BALL_SPEED: f32 = 3;

pub fn main() !void {
    const screen = struct {
        pub const width: i32 = 800;
        pub const height: i32 = 450;
        pub const fps: i32 = 60;
    };
    const brick_size: f32 = @as(f32, @floatFromInt(screen.width)) / @as(f32, @floatFromInt(BRICK_COUNT));
    const texts = setup(.{
        .width = screen.width,
        .height = screen.height,
        .fps = screen.fps,
    });
    defer shutdown(texts);
    var bricks: [BRICK_COUNT * 3]Brick = undefined;
    setupBricks(&bricks, brick_size);
    const ball_def_pos: Vector2 = .{ @as(f32, @floatFromInt(screen.width / 2)) - 3.5, @as(f32, @floatFromInt(screen.height)) - 60 };
    const plat_def_pos: Rectangle = .{ .x = (screen.width / 2) - 25, .y = screen.height - 20, .height = 10, .width = 40 };
    var platform: Rectangle = plat_def_pos;
    var ball: Ball = .{
        .pos = ball_def_pos,
        .dir = .{ 3, 1 },
    };
    var frame: f32 = 0;
    while (!ray.windowShouldClose()) : (frame += 1) {
        const delta = ray.getFrameTime();
        if (ray.isKeyDown(.Right)) {
            platform.x += (PLAT_SPEED * delta) * screen.fps;
        }
        if (ray.isKeyDown(.Left)) {
            platform.x -= (PLAT_SPEED * delta) * screen.fps;
        }
        if (ray.isKeyPressed(.Space)) {
            ball.pos = ball_def_pos;
            ball.dir *= Vector2{ -1, 1 };
            platform = plat_def_pos;
        }
        if (@mod(frame, BALL_SPEED) == 0)
            ball.pos += ball.dir;

        {
            ray.beginTextureMode(texts.screen.texture);
            defer ray.endTextureMode();
            ray.clearBackground(ray.colors.Blank);
            for (bricks) |brick|
                if (!brick.hit)
                    ray.drawTexturePro(texts.brick.texture, texts.brick.source, brick.rec, .{ 0, 0 }, 0, brick.color);
            ray.drawRectangleRec(platform, ray.colors.Black);
            ray.drawCircleV(ball.pos, 7, ray.colors.Green);
        }
        ray.beginDrawing();
        defer ray.endDrawing();
        ray.clearBackground(ray.colors.RayWhite);
        ray.drawTextureRec(texts.screen.texture.texture, texts.screen.source, .{ 0, 0 }, ray.colors.White);
    }
}
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
fn setupBricks(bricks: []Brick, brick_size: f32) void {
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
