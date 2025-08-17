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

    while (true) {
        const event = loop.nextEvent();
        switch (event) {
            .key_press => |key| {
                if (key.matches('c', .{ .ctrl = true }) or key.matches('q', .{})) {
                    break;
                } else if (key.matches('l', .{ .ctrl = true })) {
                    vx.queueRefresh();
                } else {}
            },
            .winsize => |ws| try vx.resize(allocator, tty.anyWriter(), ws),
            else => {},
        }

        const win = vx.window();
        win.clear();

        var screen_instance = screen.Screen_{
            .root_dir_name = ".",
            .curr_dir_name = "",
            .child_dir_name = "",
        };
        const screen_sizes = screen_instance.getScreenSizes(win);

        const left_pane = screen_instance.createLeftPanel(win, screen_sizes);
        const middle_pane = screen_instance.createMiddlePanel(win, screen_sizes);
        const right_pane = screen_instance.createRightPanel(win, screen_sizes);

        _ = left_pane.printSegment(.{ .text = "Root Folder" }, .{ .row_offset = 0, .col_offset = 1 });
        _ = middle_pane.printSegment(.{ .text = "Curr Folder" }, .{ .row_offset = 1, .col_offset = 1 });
        _ = right_pane.printSegment(.{ .text = "Child Folder" }, .{ .row_offset = 1, .col_offset = 1 });

        var folder_instance = folder.File.init(allocator);
        var contents = try folder_instance.getContent();
        defer contents.deinit();
        const size = contents.folderSize;

        var buff: [22]u8 = undefined;
        const folder_size = try std.fmt.bufPrint(&buff, "No of files: {!}", .{size});
        const get_root_files = contents.getRootFile;

        _ = left_pane.printSegment(.{ .text = folder_size }, .{ .row_offset = 2, .col_offset = 1 });

        var i: u8 = 3;
        // open_folder icon = \u{1F4C2}
        const folder_icon = "\u{1F4C1}";
        const file_icon = "\u{1F5CE}";
        for (get_root_files) |file| {
            params.log.debug("{s}", .{file});

            const stat = try std.fs.cwd().statFile(file);

            switch (stat.kind) {
                .directory => {
                    _ = left_pane.printSegment(.{ .text = folder_icon }, .{ .row_offset = i, .col_offset = 1 });
                    _ = left_pane.printSegment(.{ .text = file }, .{ .row_offset = i, .col_offset = 3 });
                },
                .file => {
                    _ = left_pane.printSegment(.{ .text = file_icon }, .{ .row_offset = i, .col_offset = 1 });
                    _ = left_pane.printSegment(.{ .text = file }, .{ .row_offset = i, .col_offset = 3 });
                },
                else => {
                    continue;
                },
            }
            i += 1;
        }

        const text = win.child(.{
            .x_off = win.width / 2 - 20,
            .y_off = win.height / 2 - 5,
            .width = 40,
            .height = 20,
            .border = .{
                .where = .all,
            },
        });

        _ = text.printSegment(.{ .text = "Find files" }, .{ .row_offset = 3, .col_offset = 10 });

        try vx.render(tty.anyWriter());
    }
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
