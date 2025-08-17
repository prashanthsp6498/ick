const std = @import("std");
const logger = @import("logger").Logger;
pub const main_screen = @import("mainscreen.zig");

pub fn start(params: struct { allocator: std.mem.Allocator, log: *logger }) !void {
    try main_screen.entry(.{ .allocator = params.allocator, .log = params.log });
}
