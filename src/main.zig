const std = @import("std");
const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;
const main_screen = @import("ui/mainscreen.zig");
const logger = @import("logger.zig").Logger;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var log = try logger.init();
    defer log.deinit();

    try main_screen.entry(.{.allocator = allocator, .log = log});
}
