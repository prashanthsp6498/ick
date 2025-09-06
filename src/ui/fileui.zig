const std = @import("std");
const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;

const file_ui = @This();

text: []const u8,
idx: usize,
wrap_lines: bool = true,
isSelected: bool = false,
style: vaxis.Style = .{ .bg = .{ .rgb = [3]u8{ 69, 159, 161 } } },

pub fn widget(self: *file_ui) vxfw.Widget {
    return .{
        .userdata = self,
        .drawFn = file_ui.typeErasedDrawFn,
    };
}

pub fn select(self: *file_ui) void {
    self.isSelected = true;
}

pub fn deSelect(self: *file_ui) void {
    self.isSelected = false;
}

fn typeErasedDrawFn(ptr: *anyopaque, ctx: vxfw.DrawContext) std.mem.Allocator.Error!vxfw.Surface {
    const self: *file_ui = @ptrCast(@alignCast(ptr));

    const text_widget: vxfw.Text = .{
        .text = self.text,
        .softwrap = self.wrap_lines,
        .style = if (self.isSelected) self.style else .{},
        .text_align = .left,
    };

    const text_surf: vxfw.SubSurface = .{
        .origin = .{ .row = 0, .col = 1 },
        .surface = try text_widget.draw(ctx.withConstraints(
            ctx.min,
            if (self.wrap_lines)
                .{ .width = ctx.min.width -| 6, .height = ctx.max.height }
            else
                .{ .width = if (ctx.max.width) |w| w - 6 else null, .height = ctx.max.height },
        )),
    };

    const children = try ctx.arena.alloc(vxfw.SubSurface, 1);
    children[0] = text_surf;

    return .{
        .size = .{
            .width = 6 + text_surf.surface.size.width,
            .height = text_surf.surface.size.height,
        },
        .widget = self.widget(),
        .buffer = &.{},
        .children = children,
    };
}
