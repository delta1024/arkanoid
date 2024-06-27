const std = @import("std");
const ray = @import("raylib");
const Rectangle = ray.Rectangle;
const Color = ray.Color;
const Brick = struct {
    rec: Rectangle,
    color: Color,
    hit: bool = false,
    pub const Iter = struct {
        buff: []Brick,
        row_len: usize,
        i: usize,
        pub fn next(self: *Iter) ?[]Brick {
            if ((self.i + 1) * self.row_len > self.buff.len)
                return null;
            defer self.i += 1;
            return self.buff[self.i * self.row_len .. (self.i + 1) * self.row_len];
        }
    };
};

const BRICK_COUNT: usize = 12;
pub fn main() !void {
    const screen = struct {
        pub const width: i32 = 800;
        pub const height: i32 = 450;
        pub const fps: i32 = 60;
    };
    const brick_size: f32 = @as(f32, @floatFromInt(screen.width)) / @as(f32, @floatFromInt(BRICK_COUNT));
    ray.initWindow(screen.width, screen.height, "arkanoid");
    defer ray.closeWindow();
    ray.setTargetFps(screen.fps);

    const brick_texture = blk: {
        const image = ray.loadImage("assets/texture_brick_100.png");
        defer ray.unloadImage(image);
        break :blk ray.loadTextureFromImage(image);
    };
    defer ray.unloadTexture(brick_texture);
    const brick_texture_source = ray.Rectangle{
        .x = 0,
        .y = 0,
        .width = @floatFromInt(brick_texture.width),
        .height = @floatFromInt(brick_texture.height),
    };

    var bricks: [BRICK_COUNT * 3]Brick = undefined;
    setUpBricks(&bricks, brick_size);
    const screen_buff = ray.loadRenderTexture(screen.width, screen.height);
    defer ray.unloadRenderTexture(screen_buff);
    const screen_source = Rectangle{
        .x = 0,
        .y = 0,
        .width = @floatFromInt(screen_buff.texture.width),
        .height = @floatFromInt(-screen_buff.texture.height),
    };
    while (!ray.windowShouldClose()) {
        {
            ray.beginTextureMode(screen_buff);
            defer ray.endTextureMode();
            for (bricks) |brick|
                if (!brick.hit)
                    ray.drawTexturePro(brick_texture, brick_texture_source, brick.rec, .{ 0, 0 }, 0, brick.color);
        }
        ray.beginDrawing();
        defer ray.endDrawing();
        ray.clearBackground(ray.colors.RayWhite);
        ray.drawTextureRec(screen_buff.texture, screen_source, .{ 0, 0 }, ray.colors.White);
        ray.drawText("Arkanoid", (screen.width / 2) - (24 * 4), (screen.height / 2) - 12, 24, ray.colors.Black);
    }
}

fn setUpBricks(bricks: []Brick, brick_size: f32) void {
    var iter: Brick.Iter = .{
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
