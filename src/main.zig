const std = @import("std");
const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;

const EventLoop = union(enum) {
    key_press: vaxis.Key,
    winsize: vaxis.Winsize,
    focus_in,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var tty = try vaxis.Tty.init();
    defer tty.deinit();

    var vx = try vaxis.init(allocator, .{});
    defer vx.deinit(allocator, tty.anyWriter());

    var loop: vaxis.Loop(EventLoop) = .{
        .tty = &tty,
        .vaxis = &vx,
    };

    try loop.init();
    try loop.start();
    defer loop.stop();

    try vx.enterAltScreen(tty.anyWriter());

    try vx.queryTerminal(tty.anyWriter(), 1 * std.time.ns_per_s);

    var quit = false;
    var color_id: u8 = 0;

    var text_1 = vaxis.widgets.TextInput.init(allocator, &vx.unicode);
    defer text_1.deinit();

    while (!quit) {
        const event = loop.nextEvent();
        switch (event) {
            .key_press => |key| {
                color_id = switch (color_id) {
                    255 => 0,
                    else => color_id + 1,
                };

                if (key.matches('q', .{})) {
                    quit = true;
                } else {
                    try text_1.update(.{ .key_press = key });
                }
            },
            .winsize => |ws| try vx.resize(allocator, tty.anyWriter(), ws),
            else => {},
        }

        const window = vx.window();
        window.clear();

        const style: vaxis.Style = .{
            .fg = .{ .index = color_id },
        };

        const child_1 = window.child(.{
            .border = .{ .style = style, .where = .all },
            .width = window.width,
            .height = window.height,
            .x_off = 1,
            .y_off = 1,
        });

        text_1.draw(child_1);
        try vx.render(tty.anyWriter());
    }
}
