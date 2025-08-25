const std = @import("std");
const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;
const widgets = vaxis.widgets;
const screen = @import("screen.zig");
pub const ctlseqs = vaxis.ctlseqs;

const Event = union(enum) {
    key_press: vaxis.Key,
    winsize: vaxis.Winsize,
    focus_in,
};

pub fn entry(allocator: std.mem.Allocator) !void {
    var app = try vxfw.App.init(allocator);
    defer app.deinit();
    var tty = try vaxis.Tty.init();
    defer tty.deinit();
    var vx = try vaxis.init(allocator, .{});
    defer vx.deinit(allocator, tty.anyWriter());

    var loop: vaxis.Loop(Event) = .{
        .tty = &tty,
        .vaxis = &vx,
    };
    try loop.init();
    try loop.start();
    defer loop.stop();

    try vx.enterAltScreen(tty.anyWriter());
    try vx.queryTerminal(tty.anyWriter(), 1 * std.time.ns_per_s);

    const screen_instance = try allocator.create(screen.ViewScreen);
    defer allocator.destroy(screen_instance);

    screen_instance.* = .{
        .left_header = .{ .text = "Root" },
        .right_header = .{ .text = "child" },
        .middle_header = .{ .text = "curr" },
        .main_split = .{ .lhs = undefined, .rhs = undefined, .width = 10 },
        .right_split = .{ .lhs = undefined, .rhs = undefined, .width = 10 },
        .allocator = allocator,
    };

    try vx.render(tty.anyWriter());
    try app.run(screen_instance.widget(), .{});
}

pub fn recover() void {
    const reset: []const u8 = ctlseqs.csi_u_pop ++
        ctlseqs.mouse_reset ++
        ctlseqs.bp_reset ++
        ctlseqs.rmcup ++
        ctlseqs.sgr_reset;

    std.log.err("crashed, run `reset` for complete terminal reset", .{});

    if (vaxis.tty.global_tty) |gty| {
        gty.anyWriter().writeAll(reset) catch {};
        gty.deinit();
    }
}
