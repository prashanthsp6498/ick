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
