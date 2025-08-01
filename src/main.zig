const std = @import("std");
const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;

const Model = struct {
    counter: i32,

    pub fn widget(self: *Model) vxfw.Widget {
        return .{
            .userdata = self,
            .eventHandler = Model.eventHandler,
            .drawFn = Model.drawFn
        };
    }

    pub fn eventHandler(userdata: *anyopaque, ctx: *vxfw.EventContext, event: vxfw.Event) anyerror!void {
        _ = userdata;

        switch(event) {
            .key_press => |key| {
                if (key.matches('c', .{ .ctrl = true })) {
                    ctx.quit = true;
                    return;
                }
            },
            else => {},
        }
    }

    pub fn drawFn(userdata: *anyopaque, ctx: vxfw.DrawContext) std.mem.Allocator.Error!vxfw.Surface {
        const self: *Model = @ptrCast(@alignCast(userdata));

        const text = try std.fmt.allocPrint(ctx.arena, "Total count is: {d}", .{self.counter});
        const text_w: vxfw.Text = .{.text = text};

        const text_subSurface: vxfw.SubSurface = .{.origin = .{.col = 0, .row = 0}, .surface = try text_w.draw(ctx)};
        const childrens = try ctx.arena.alloc(vxfw.SubSurface, 1);

        childrens[0] = text_subSurface;

        return .{
            .size = ctx.max.size(),
            .widget = self.widget(),
            .buffer = &.{},
            .children = childrens
        };
    }

};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    var app = try vxfw.App.init(allocator);
    defer app.deinit();

    const model = try allocator.create(Model);
    defer allocator.destroy(model);
    model.* = .{
        .counter = 0
    };

    try app.run(model.widget(), .{});

}

