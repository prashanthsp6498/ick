const std = @import("std");
const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;
const widgets = vaxis.widgets;
const screen = @import("screen.zig");
const folder = @import("../core/core.zig");
const logger = @import("logger").Logger;
pub const ctlseqs = vaxis.ctlseqs;

const Event = union(enum) {
    key_press: vaxis.Key,
    winsize: vaxis.Winsize,
    focus_in,
};

pub fn entry(params: struct { allocator: std.mem.Allocator, log: *logger }) !void {
    const allocator = params.allocator;
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

    var middle_scroll_offset: u16 = 0;

    while (true) {
        const event = loop.nextEvent();
        const win = vx.window();
        win.clear();

        const screen_size = screen.Screen_.getScreenSizes(win);
        var screen_instance = screen.Screen_.initscreen(win, screen_size);

        const middle_panel = try screen_instance.createWindows();

        var fs = folder.File.init(allocator);
        var files = try fs.currDir();
        defer {
            for (files.curr) |f| {
                allocator.free(f);
            }
            allocator.free(files.curr);
        }

        var scroll = screen.Scroll.initscroll(win.height, &files);
        switch (event) {
            .key_press => |key| {
                if (key.matches('c', .{ .ctrl = true }) or key.matches('q', .{})) {
                    break;
                } else if (key.matches('l', .{ .ctrl = true })) {
                    vx.queueRefresh();
                } else if (key.matches('j', .{})) {
                    middle_scroll_offset += 1;
                } else if (key.matches('k', .{})) {
                    if (middle_scroll_offset > 0) {
                        middle_scroll_offset -= 1;
                    }
                } else if (key.matches('g', .{ .shift = true })) {
                    if (middle_scroll_offset > 0) {
                        middle_scroll_offset = 0;
                    }
                }
            },
            .winsize => |ws| try vx.resize(allocator, tty.anyWriter(), ws),
            else => {},
        }

        try scroll.makescroll(middle_scroll_offset, middle_panel);

        try vx.render(tty.anyWriter());
    }
}

pub fn recover() void {
    const reset: []const u8 = ctlseqs.csi_u_pop ++
        ctlseqs.mouse_reset ++
        ctlseqs.bp_reset ++
        ctlseqs.rmcup ++
        ctlseqs.sgr_reset;
    var log = logger.init() catch {
        @panic("adf");
    };
    log.debug("crashed, run `reset` for complete terminal reset", .{});
    if (vaxis.tty.global_tty) |gty| {
        gty.anyWriter().writeAll(reset) catch {};
        gty.deinit();
    }
}
