const std = @import("std");
const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;
const files = @import("../core/core.zig");
const cwd = std.fs.cwd();

pub const ScreenSize = struct {
    left_width: u16,
    middle_width: u16,
    right_width: u16,
};

const FileUI = struct {
    text: []const u8,
    idx: usize,
    wrap_lines: bool = true,
    isSelected: bool = false,

    pub fn widget(self: *FileUI) vxfw.Widget {
        return .{
            .userdata = self,
            .drawFn = FileUI.typeErasedDrawFn,
        };
    }

    pub fn select(self: *FileUI) void {
        self.isSelected = true;
    }

    pub fn deSelect(self: *FileUI) void {
        self.isSelected = false;
    }

    fn typeErasedDrawFn(ptr: *anyopaque, ctx: vxfw.DrawContext) std.mem.Allocator.Error!vxfw.Surface {
        const self: *FileUI = @ptrCast(@alignCast(ptr));

        const idx_text = try std.fmt.allocPrint(ctx.arena, "{d: >4}", .{self.idx});
        const style: vaxis.Style = .{ .bg = .{ .rgb = [3]u8{ 10, 20, 30 } } };

        const idx_widget: vxfw.Text = .{ .text = idx_text, .style = if (self.isSelected) style else .{} };

        const idx_surf: vxfw.SubSurface = .{
            .origin = .{ .row = 0, .col = 0 },
            .surface = try idx_widget.draw(ctx.withConstraints(
                .{ .width = 1, .height = 1 },
                .{ .width = 4, .height = 1 },
            )),
        };

        const text_widget: vxfw.Text = .{
            .text = self.text,
            .softwrap = self.wrap_lines,
            .style = if (self.isSelected) style else .{},
        };

        const text_surf: vxfw.SubSurface = .{
            .origin = .{ .row = 0, .col = 6 },
            .surface = try text_widget.draw(ctx.withConstraints(
                ctx.min,
                if (self.wrap_lines)
                    .{ .width = ctx.min.width -| 6, .height = ctx.max.height }
                else
                    .{ .width = if (ctx.max.width) |w| w - 6 else null, .height = ctx.max.height },
            )),
        };

        const children = try ctx.arena.alloc(vxfw.SubSurface, 2);
        children[0] = idx_surf;
        children[1] = text_surf;

        return .{
            .size = .{
                .width = 6 + text_surf.surface.size.width,
                .height = @max(idx_surf.surface.size.height, text_surf.surface.size.height),
            },
            .widget = self.widget(),
            .buffer = &.{},
            .children = children,
        };
    }
};

pub const DirView = struct {
    scroll_bars: vxfw.ScrollBars,
    files: std.ArrayList(FileUI),
    current_select: usize = 0,

    pub fn init(allocator: std.mem.Allocator) !*DirView {
        const data = try allocator.create(DirView);
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
            .files = std.ArrayList(FileUI).init(allocator),
        };

        for (0..40) |i| {
            try data.*.files.append(.{
                .text = "File Name",
                .idx = i,
            });
        }

        data.*.files.items[data.current_select].select();

        return data;
    }

    pub fn scrollDown(self: *DirView) void {
        if (self.current_select + 1 < self.files.items.len) {
            self.current_select = self.current_select + 1;
            _ = self.scroll_bars.scroll_view.scroll.linesDown(1);
        }
    }

    pub fn scrollUp(self: *DirView) void {
        const next: i32 = @intCast(self.current_select);
        if (next - 1 >= 0) {
            self.current_select = self.current_select - 1;
            _ = self.scroll_bars.scroll_view.scroll.linesUp(1);
        }
    }

    fn widgetBuilder(ptr: *const anyopaque, idx: usize, _: usize) ?vxfw.Widget {
        const self: *const DirView = @ptrCast(@alignCast(ptr));
        if (idx >= self.files.items.len) return null;

        return self.files.items[idx].widget();
    }

    pub fn widget(self: *DirView) vxfw.Widget {
        return .{
            .userdata = self,
            .eventHandler = eventHandler,
            .drawFn = drawFn,
        };
    }

    pub fn eventHandler(userdata: *anyopaque, ctx: *vxfw.EventContext, event: vxfw.Event) !void {
        const self: *DirView = @ptrCast(@alignCast(userdata));

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
        const self: *DirView = @ptrCast(@alignCast(userdata));
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
};

pub const ViewScreen = struct {
    main_split: vxfw.SplitView,
    right_split: vxfw.SplitView,
    left_header: vxfw.Text,
    right_header: vxfw.Text,
    middle_header: vxfw.Text,
    children: [3]vxfw.SubSurface = undefined,
    allocator: std.mem.Allocator,
    dirView: *DirView,

    pub fn init(allocator: std.mem.Allocator) void {
        return .{
            .left_header = .{ .text = "Root" },
            .right_header = .{ .text = "child" },
            .middle_header = .{ .text = "curr" },
            .allocator = allocator,
        };
    }

    pub fn widget(self: *ViewScreen) vxfw.Widget {
        return .{
            .userdata = self,
            .eventHandler = ViewScreen.eventHandler,
            .drawFn = ViewScreen.drawFn,
        };
    }

    fn eventHandler(ptr: *anyopaque, ctx: *vxfw.EventContext, event: vxfw.Event) anyerror!void {
        const self: *ViewScreen = @ptrCast(@alignCast(ptr));
        // _ = self;
        switch (event) {
            .init => {},
            .key_press => |key| {
                if (key.matches('c', .{ .ctrl = true }) or key.matches('q', .{})) {
                    ctx.quit = true;
                    return;
                } else {
                    try DirView.eventHandler(self.dirView, ctx, event);
                }
            },
            else => {},
        }
    }

    inline fn getPanel(self: *ViewScreen, title: []const u8, widgetComp: vxfw.Widget, ctx: vxfw.DrawContext, offset: u16) !vxfw.SubSurface {
        _ = self;
        const max_width = ctx.max.size().width;
        const max_height = ctx.max.size().height - 2;
        const panel_width = max_width / 3;
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
        const panel_offset = panel_width * offset;
        return .{ .origin = .{ .row = 0, .col = panel_offset }, .surface = parent_surface };
    }

    fn drawFn(ptr: *anyopaque, ctx: vxfw.DrawContext) std.mem.Allocator.Error!vxfw.Surface {
        const self: *ViewScreen = @ptrCast(@alignCast(ptr));

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
};
