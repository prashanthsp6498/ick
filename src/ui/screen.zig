const std = @import("std");
const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;
const file_ui = @import("fileui.zig");
pub const dirview = @import("dirview.zig");

const screen = @This();

main_split: vxfw.SplitView,
right_split: vxfw.SplitView,
left_header: vxfw.Text,
right_header: vxfw.Text,
middle_header: vxfw.Text,
children: [3]vxfw.SubSurface = undefined,
allocator: std.mem.Allocator,
dirView: *dirview,

pub fn init(allocator: std.mem.Allocator) void {
    return .{
        .left_header = .{ .text = "Root" },
        .right_header = .{ .text = "child" },
        .middle_header = .{ .text = "curr" },
        .allocator = allocator,
    };
}

pub fn widget(self: *screen) vxfw.Widget {
    return .{
        .userdata = self,
        .eventHandler = screen.eventHandler,
        .drawFn = screen.drawFn,
    };
}

fn eventHandler(ptr: *anyopaque, ctx: *vxfw.EventContext, event: vxfw.Event) anyerror!void {
    const self: *screen = @ptrCast(@alignCast(ptr));
    switch (event) {
        .init => {},
        .key_press => |key| {
            if (key.matches('c', .{ .ctrl = true }) or key.matches('q', .{})) {
                ctx.quit = true;
                return;
            } else {
                try dirview.eventHandler(self.dirView, ctx, event);
            }
        },
        else => {},
    }
}

/// create panel surface with specific width depends on offset i,e 0, 1 or 2
inline fn getPanel(
    self: *screen,
    title: []const u8,
    widgetComp: vxfw.Widget,
    ctx: vxfw.DrawContext,
    offset: u16,
) !vxfw.SubSurface {
    _ = self;
    const max_width = ctx.max.size().width;
    const max_height = ctx.max.size().height - 2;
    const panel_width = switch (offset) {
        0 => max_width / 6,
        1 => max_width - (max_width / 6) - (max_width / 3),
        2 => max_width / 3,
        else => max_width / 3,
    };
    const size: vxfw.Size = .{ .height = max_height, .width = panel_width };

    const left_ctx = vxfw.DrawContext{
        .arena = ctx.arena,
        .cell_size = ctx.cell_size,
        .max = .{
            .height = ctx.max.height,
            .width = panel_width,
        },
        .min = size,
    };

    const parent: vxfw.Border = .{
        .child = widgetComp,
        .labels = &[_]vxfw.Border.BorderLabel{
            .{
                .text = title,
                .alignment = .top_center,
            },
            .{
                .text = "permissions",
                .alignment = .bottom_center,
            },
        },
    };
    const parent_surface = try parent.widget().draw(left_ctx);

    const panel_offset = switch (offset) {
        0 => 0,
        1 => (max_width / 6),
        2 => max_width - (max_width / 3),
        else => max_width,
    };
    return .{ .origin = .{ .row = 0, .col = panel_offset }, .surface = parent_surface };
}

fn drawFn(ptr: *anyopaque, ctx: vxfw.DrawContext) std.mem.Allocator.Error!vxfw.Surface {
    const self: *screen = @ptrCast(@alignCast(ptr));

    self.children[0] = try self.getPanel("parent", self.dirView.widget(), ctx, 0);
    self.children[1] = try self.getPanel("pwd", self.left_header.widget(), ctx, 1);
    self.children[2] = try self.getPanel("preview", self.left_header.widget(), ctx, 2);

    return .{
        .size = ctx.max.size(),
        .widget = self.widget(),
        .buffer = &.{},
        .children = &self.children,
    };
}
