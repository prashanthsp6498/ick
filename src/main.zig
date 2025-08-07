const std = @import("std");
const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;

const Text = struct {
    text: []u8,
    col: i17,
    row: i17,

    pub fn init(text_data: []u8, col: i17) Text {
        return .{
            .text = text_data,
            .col = col,
            .row = 5,
        };
    }

    pub fn move_up(self: *Text) void {
        if (self.row - 1 < 0) {
            return;
        }
        self.row -|= 1;
    }

    pub fn move_down(self: *Text) void {
        if (self.row + 1 > 50) {
            return;
        }
        self.row +|= 1;
    }
};

const Model = struct {
    counter: i32,
    idx: usize = 0,
    texts: std.ArrayList([]u8),
    text_texts: std.ArrayList(Text),
    allocator: std.mem.Allocator,

    pub fn widget(self: *Model) vxfw.Widget {
        return .{ .userdata = self, .eventHandler = Model.eventHandler, .drawFn = Model.drawFn };
    }

    pub fn eventHandler(userdata: *anyopaque, ctx: *vxfw.EventContext, event: vxfw.Event) anyerror!void {
        const self: *Model = @ptrCast(@alignCast(userdata));

        switch (event) {
            .key_press => |key| {
                if (key.matches('c', .{ .ctrl = true }) or key.matches('q', .{})) {
                    ctx.quit = true;
                    return;
                } else if (key.matches('h', .{})) {
                    const val: i32 = @intCast(self.idx);
                    if (val - 1 >= 0) {
                        self.idx -|= 1;
                    }
                } else if (key.matches('l', .{})) {
                    if (self.idx + 1 < self.text_texts.items.len) {
                        self.idx +|= 1;
                    }
                } else if (key.matches('j', .{})) {
                    self.text_texts.items[self.idx].move_down();
                } else if (key.matches('k', .{})) {
                    self.text_texts.items[self.idx].move_up();
                } else if (key.matches('e', .{})) {
                    var col: i17 = 0;
                    const offset: i17 = 3;
                    for (self.text_texts.items) |i| {
                        col +|= @intCast(i.text.len);
                        col +|= offset;
                    }
                    try self.text_texts.append(Text.init(try std.fmt.allocPrint(self.allocator, "This is {d} line", .{self.counter}), col));
                }
            },
            else => {},
        }

        ctx.consumeAndRedraw();
    }

    pub fn drawFn(userdata: *anyopaque, ctx: vxfw.DrawContext) std.mem.Allocator.Error!vxfw.Surface {
        const self: *Model = @ptrCast(@alignCast(userdata));

        const text = try std.fmt.allocPrint(ctx.arena, "current index : {d}", .{self.idx});
        const text_w: vxfw.Text = .{ .text = text };

        const text_subSurface: vxfw.SubSurface = .{ .origin = .{ .col = 0, .row = 0 }, .surface = try text_w.draw(ctx) };
        const childrens = try ctx.arena.alloc(vxfw.SubSurface, 1 + self.text_texts.items.len);

        childrens[0] = text_subSurface;

        var idx: usize = 1;

        for (self.text_texts.items) |i| {
            const tt: vxfw.Text = .{ .text = i.text };
            const t: vxfw.SubSurface = .{ .origin = .{ .col = i.col, .row = i.row }, .surface = try tt.draw(ctx) };
            childrens[idx] = t;
            idx +|= 1;
        }

        return .{ .size = ctx.max.size(), .widget = self.widget(), .buffer = &.{}, .children = childrens };
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
        for (model.texts.items) |i| {
            allocator.free(i);
        }

        for (model.text_texts.items) |i| {
            allocator.free(i.text);
        }
        model.texts.deinit();
        model.text_texts.deinit();
        allocator.destroy(model);
    }

    model.* = .{
        .counter = 10,
        .texts = std.ArrayList([]u8).init(allocator),
        .text_texts = std.ArrayList(Text).init(allocator),
        .allocator = allocator,
    };

    try app.run(model.widget(), .{});
    std.debug.print("asfasf", .{});
}
