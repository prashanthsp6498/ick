const std = @import("std");
const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;
const file_ui = @import("fileui.zig");

const dirview = @This();

scroll_bars: vxfw.ScrollBars,
files: std.ArrayList(file_ui),
current_select: usize = 0,

pub fn init(allocator: std.mem.Allocator) !*dirview {
    const data = try allocator.create(dirview);
    data.* = .{
        .scroll_bars = .{
            .scroll_view = .{
                .children = .{
                    .builder = .{
                        .userdata = data,
                        .buildFn = widgetBuilder,
                    },
                },
            },
        },
        .files = std.ArrayList(file_ui).init(allocator),
    };

    for (0..40) |i| {
        try data.*.files.append(.{
            .text = try std.fmt.allocPrint(allocator, "File Name {d}", .{i}),
            .idx = i,
        });
    }

    data.*.files.items[data.current_select].select();

    return data;
}

pub fn scrollDown(self: *dirview) void {
    if (self.current_select + 1 < self.files.items.len) {
        self.current_select = self.current_select + 1;
        _ = self.scroll_bars.scroll_view.scroll.linesDown(1);
    }
}

pub fn scrollUp(self: *dirview) void {
    const next: i32 = @intCast(self.current_select);
    if (next - 1 >= 0) {
        self.current_select = self.current_select - 1;
        _ = self.scroll_bars.scroll_view.scroll.linesUp(1);
    }
}

fn widgetBuilder(ptr: *const anyopaque, idx: usize, _: usize) ?vxfw.Widget {
    const self: *const dirview = @ptrCast(@alignCast(ptr));
    if (idx >= self.files.items.len) return null;

    return self.files.items[idx].widget();
}

pub fn widget(self: *dirview) vxfw.Widget {
    return .{
        .userdata = self,
        .eventHandler = eventHandler,
        .drawFn = drawFn,
    };
}

pub fn eventHandler(userdata: *anyopaque, ctx: *vxfw.EventContext, event: vxfw.Event) !void {
    const self: *dirview = @ptrCast(@alignCast(userdata));

    switch (event) {
        .key_press => |key| {
            if (key.matches('j', .{})) {
                self.files.items[self.current_select].deSelect();
                self.scrollDown();
                self.files.items[self.current_select].select();
                ctx.consumeAndRedraw();
            } else if (key.matches('k', .{})) {
                self.files.items[self.current_select].deSelect();
                self.scrollUp();
                self.files.items[self.current_select].select();

                ctx.consumeAndRedraw();
            }
        },
        else => {},
    }
}

pub fn drawFn(userdata: *anyopaque, ctx: vxfw.DrawContext) !vxfw.Surface {
    const self: *dirview = @ptrCast(@alignCast(userdata));
    const max = ctx.max.size();

    const scroll_view: vxfw.SubSurface = .{
        .origin = .{ .row = 0, .col = 0 },
        .surface = try self.scroll_bars.draw(ctx),
    };

    const children = try ctx.arena.alloc(vxfw.SubSurface, 1);
    children[0] = scroll_view;

    return .{
        .size = max,
        .widget = self.widget(),
        .buffer = &.{},
        .children = children,
    };
}
