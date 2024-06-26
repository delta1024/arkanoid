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

    while (!ray.windowShouldClose()) {
        ray.beginDrawing();
        defer ray.endDrawing();
        ray.clearBackground(ray.colors.RayWhite);
        ray.drawText("Arkanoid", (screen.width / 2) - (24 * 4), (screen.height / 2) - 12, 24, ray.colors.Black);
    }
}
