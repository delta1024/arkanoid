const std = @import("std");
const ray = @import("raylib");

pub fn main() !void {
    const screen = struct {
        pub const width: i32 = 800;
        pub const height: i32 = 450;
        pub const fps: i32 = 60;
    };
    ray.initWindow(screen.width, screen.height, "arkanoid");
    defer ray.closeWindow();
    ray.setTargetFps(screen.fps);
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
    defer ray.unloadTexture(brick_texture);
    while (!ray.windowShouldClose()) {
        ray.beginDrawing();
        defer ray.endDrawing();
        ray.clearBackground(ray.colors.RayWhite);
        ray.drawTexturePro(brick_texture, brick_texture_source, .{
            .x = 0,
            .y = 0,
            .width = @floatFromInt(screen.width),
            .height = @floatFromInt(screen.height),
        }, .{ 0, 0 }, 0, ray.colors.Gray);
        ray.drawText("Arkanoid", (screen.width / 2) - (24 * 4), (screen.height / 2) - 12, 24, ray.colors.Black);
    }
}
