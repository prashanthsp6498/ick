const std = @import("std");
const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;
const screen = @import("interfaces/screen.zig");
const TextInput = vaxis.widgets.TextInput;
const Cell = vaxis.Cell;
const border = vaxis.widgets.border;

const Event = union(enum) {
    key_press: vaxis.Key,
    winsize: vaxis.Winsize,
    focus_in,
    foo: u8,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

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

    var color_idx: u8 = 255;
    var text_input = TextInput.init(allocator, &vx.unicode);
    defer text_input.deinit();

    try vx.queryTerminal(tty.anyWriter(), 1 * std.time.ns_per_s);

    while (true) {
        const event = loop.nextEvent();
        switch (event) {
            .key_press => |key| {
                color_idx = switch (color_idx) {
                    255 => 0,
                    else => color_idx + 1,
                };
                if (key.matches('c', .{ .ctrl = true }) or key.matches('q', .{})) {
                    break;
                } else if (key.matches('l', .{ .ctrl = true })) {
                    vx.queueRefresh();
                } else {
                    try text_input.update(.{ .key_press = key });
                }
            },
            .winsize => |ws| try vx.resize(allocator, tty.anyWriter(), ws),
            else => {},
        }

        const win = vx.window();
        win.clear();

        var screen_instance = screen.Screen_{
            .root_dir_name = "/home/hexa/",
            .curr_dir_name = "",
            .child_dir_name = "",
        };

        const screen_sizes = screen_instance.getScreenSizes(win);

        const size = screen_instance.getRootDirSize();

        const left_pane = screen_instance.createLeftPanel(win, screen_sizes);
        const middle_pane = screen_instance.createMiddlePanel(win, screen_sizes);
        const right_pane = screen_instance.createRightPanel(win, screen_sizes);

        var buff: [16]u8 = undefined;
        const file_size = try std.fmt.bufPrint(&buff, "{!}", .{size});
        std.debug.print("file size: {s}\n", .{file_size});

        const get_files = try screen_instance.getRootDirFolder(allocator);
        defer {
            for (get_files) |file| {
                allocator.free(file);
            }
            allocator.free(get_files);
        }

        _ = left_pane.printSegment(.{ .text = "Root Folder" }, .{ .row_offset = 1, .col_offset = 1 });
        _ = left_pane.printSegment(.{ .text = file_size }, .{ .row_offset = 2, .col_offset = 1 });

        var i: u8 = 3;
        for (get_files) |file| {
            _ = left_pane.printSegment(.{ .text = file }, .{ .row_offset = i, .col_offset = 1 });
            i += 1;
        }

        _ = middle_pane.printSegment(.{ .text = "Curr Folder" }, .{ .row_offset = 1, .col_offset = 1 });
        _ = right_pane.printSegment(.{ .text = "Child Folder" }, .{ .row_offset = 1, .col_offset = 1 });

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

        text_input.draw(text);

        try vx.render(tty.anyWriter());
    }

    std.debug.print("Application finished\n", .{});
}
