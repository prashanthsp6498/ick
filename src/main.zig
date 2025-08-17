const std = @import("std");
const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;
const ui = @import("ui/ui.zig");
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

    try ui.start(.{ .allocator = allocator, .log = &log });
}

pub fn panic(msg: []const u8, _: ?*std.builtin.StackTrace, ret_addr: ?usize) noreturn {
    ui.main_screen.recover();
    std.debug.defaultPanic(msg, ret_addr);
}
