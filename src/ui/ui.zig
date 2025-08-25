const std = @import("std");
pub const main_screen = @import("mainscreen.zig");

pub fn start(allocator: std.mem.Allocator) !void {
    try main_screen.entry(allocator);
}
