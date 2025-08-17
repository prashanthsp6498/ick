const std = @import("std");
const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;
const main_screen = @import("ui/mainscreen.zig");
const exe_options = @import("exe_options");
const logger = @import("logger").Logger;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var log = try logger.init();
    defer log.deinit();

    log.info("Application started", .{});
    defer log.info("Application stopped", .{});

    try main_screen.entry(.{.allocator = allocator, .log = &log});
}
