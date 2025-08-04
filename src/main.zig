const std = @import("std");
const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;

const Model = struct {
    counter: i32,
    texts: std.ArrayList([]u8),
    allocator: std.mem.Allocator,

    pub fn widget(self: *Model) vxfw.Widget {
        return .{
            .userdata = self,
            .eventHandler = Model.eventHandler,
            .drawFn = Model.drawFn
        };
    }

    pub fn eventHandler(userdata: *anyopaque, ctx: *vxfw.EventContext, event: vxfw.Event) anyerror!void {
        const self: *Model = @ptrCast(@alignCast(userdata));

        switch(event) {
            .key_press => |key| {
                if (key.matches('c', .{ .ctrl = true }) or key.matches('q', .{})) {
                    ctx.quit = true;
                    return;
                } else if (key.matches('h', .{})) {
                    self.counter = self.counter + 1;
                } else if (key.matches('l', .{})) {
                    self.counter = self.counter - 1;
                } else if (key.matches('j', .{})) {
                    if (self.counter + 10 < 100) {
                    self.counter = self.counter + 10;
                    }
                } else if (key.matches('k', .{})) {
                    if (self.counter - 10 > 10) {
                    self.counter = self.counter - 10;
                    }
                } else if (key.matches('e', .{})) {
                    try self.texts.append(try std.fmt.allocPrint(self.allocator, "This is {d} line", .{self.counter}));
                }
            },
            else => {},
        }

        ctx.consumeAndRedraw();
    }

    pub fn drawFn(userdata: *anyopaque, ctx: vxfw.DrawContext) std.mem.Allocator.Error!vxfw.Surface {
        const self: *Model = @ptrCast(@alignCast(userdata));

        const text = try std.fmt.allocPrint(ctx.arena, "Total text count is: {d}", .{self.texts.items.len});
        const text_w: vxfw.Text = .{.text = text};

        const text_subSurface: vxfw.SubSurface = .{.origin = .{.col = 0, .row = 0}, .surface = try text_w.draw(ctx)};
        const childrens = try ctx.arena.alloc(vxfw.SubSurface, 1 + self.texts.items.len);

        childrens[0] = text_subSurface;

        var idx: usize = 1;
        var last_len: usize = 0; 
        const offset: usize = 1;

        for(self.texts.items) |te| {
            const prev_sub_surface: vxfw.SubSurface = childrens[idx - 1];
            const tt: vxfw.Text = .{.text = te};
            var t: vxfw.SubSurface = undefined;
            if (idx == 1) {
                t = .{ .origin = .{ .col = 0, .row = prev_sub_surface.origin.row + 1}, .surface = try tt.draw(ctx)};
                last_len = last_len + te.len;
            } else {
                t = .{ .origin = .{ .col = @intCast(last_len + offset), .row = prev_sub_surface.origin.row + 1}, .surface = try tt.draw(ctx)};
                last_len = last_len + te.len + offset;
            }
            childrens[idx] = t;
            idx = idx + 1;
        }

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
    defer {
        for(model.texts.items) |i| {
            allocator.free(i);
        }
        model.texts.deinit();
        allocator.destroy(model);
    }

    model.* = .{
        .counter = 10,
        .texts = std.ArrayList([]u8).init(allocator),
        .allocator = allocator,
    };

    try app.run(model.widget(), .{});
}

