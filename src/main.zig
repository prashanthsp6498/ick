const std = @import("std");
const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;
const ui = @import("ui/ui.zig");
const exe_options = @import("exe_options");
const logger = @import("logger");

pub const std_options: std.Options = .{
    .logFn = logger.logFn,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    logger.init();
    defer {
        std.log.info("Application terminated", .{});
        logger.deinit();
    }

    std.log.info("Application Initialize", .{});
    const allocator = gpa.allocator();

    try ui.start(allocator);
}

pub fn panic(msg: []const u8, _: ?*std.builtin.StackTrace, ret_addr: ?usize) noreturn {
    ui.main_screen.recover();
    std.debug.defaultPanic(msg, ret_addr);
}
