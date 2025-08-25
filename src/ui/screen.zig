const std = @import("std");
const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;
const files = @import("../core/core.zig");
const cwd = std.fs.cwd();

pub const ScreenSize = struct { left_width: u16, middle_width: u16, right_width: u16 };

pub const ViewScreen = struct {
    main_split: vxfw.SplitView,
    right_split: vxfw.SplitView,
    left_header: vxfw.Text,
    right_header: vxfw.Text,
    middle_header: vxfw.Text,
    children: [3]vxfw.SubSurface = undefined,
    allocator: std.mem.Allocator,

    pub fn widget(self: *ViewScreen) vxfw.Widget {
        return .{
            .userdata = self,
            .eventHandler = ViewScreen.eventHandler,
            .drawFn = ViewScreen.drawFn,
        };
    }

    fn eventHandler(ptr: *anyopaque, ctx: *vxfw.EventContext, event: vxfw.Event) anyerror!void {
        const self: *ViewScreen = @ptrCast(@alignCast(ptr));
        switch (event) {
            .init => {
                // Middle <-> Right
                self.right_split.lhs = self.middle_header.widget();
                self.right_split.rhs = self.right_header.widget();

                // Left <-> Middle <-> Right
                self.main_split.lhs = self.left_header.widget();
                self.main_split.rhs = self.right_split.widget();
            },
            .key_press => |key| {
                if (key.matches('c', .{ .ctrl = true }) or key.matches('q', .{})) {
                    ctx.quit = true;
                    return;
                }
            },
            else => {},
        }
    }

    fn drawFn(ptr: *anyopaque, ctx: vxfw.DrawContext) std.mem.Allocator.Error!vxfw.Surface {
        const self: *ViewScreen = @ptrCast(@alignCast(ptr));
        //const surf = try self.main_split.widget().draw(ctx);
        const total_width = ctx.max.size().width;
        const total_height = ctx.max.size().height - 2;
        const panel = total_width / 3;

        const size:vxfw.Size = .{ .height = total_height, .width = panel };
        const left_ctx = vxfw.DrawContext{ .arena = ctx.arena, .cell_size = ctx.cell_size, .max = .{ .height = ctx.max.height, .width = panel }, .min = size };
        const middle_ctx = left_ctx;
        const right_ctx = left_ctx;

        const parent: vxfw.Border = .{ .child = self.left_header.widget(),  .labels = &[_]vxfw.Border.BorderLabel{ .{ .text = "parent", .alignment = .top_center}, .{ .text = "permissions", .alignment = .bottom_center}}};
        const parent_surface = try parent.widget().draw(left_ctx);

        const pwd: vxfw.Border = .{ .child = self.left_header.widget(),  .labels = &[_]vxfw.Border.BorderLabel{ .{ .text = "pwd", .alignment = .top_center}}};
        const pwd_surface = try pwd.widget().draw(middle_ctx);

        const preview: vxfw.Border = .{ .child = self.left_header.widget(),  .labels = &[_]vxfw.Border.BorderLabel{ .{ .text = "preview", .alignment = .top_center}}};
        const preview_surface = try preview.widget().draw(right_ctx);


        const left_panel = 0;
        const middle_panel = left_panel + panel;
        const right_panel = total_width - (middle_panel);
        self.children[0] = .{ .origin = .{ .row = 0, .col = left_panel }, .surface = parent_surface };
        self.children[1] = .{ .origin = .{ .row = 0, .col = middle_panel }, .surface = pwd_surface };
        self.children[2] = .{ .origin = .{ .row = 0, .col = right_panel }, .surface = preview_surface };

        return .{ .size = ctx.max.size(), .widget = self.widget(), .buffer = &.{}, .children = &self.children };
    }
};

pub const Scroll = struct {
    height: u16 = 0,
    max_height: u8,
    content_height: u16,
    files: *files.folderStructure,
    middle_scroll: u16 = 0,

    pub fn initscroll(height: u16, file_struct: *files.folderStructure) Scroll {
        return .{
            .height = height,
            .files = file_struct,
            .max_height = 0,
            .content_height = 0,
        };
    }

    pub fn makescroll(self: *Scroll, middle_scroll: u16, middle_panel: vaxis.Window) !void {
        self.content_height = @as(u16, @intCast(self.files.curr.len + 3));
        const max_scroll = if (self.content_height > self.height) self.content_height - self.height else 0;

        if (middle_scroll > max_scroll) {
            self.middle_scroll = max_scroll;
        } else {
            self.middle_scroll = middle_scroll;
        }

        var i: u16 = 3;
        var file_index: usize = self.middle_scroll;

        while (file_index < self.files.curr.len and i < self.height) {
            _ = middle_panel.printSegment(.{ .text = self.files.curr[file_index] }, .{ .row_offset = i, .col_offset = 3 });
            i += 1;
            file_index += 1;
        }
    }
};

pub fn keybindings(key: vaxis.Key, scroll_offset: *u16, vx: *vaxis.Vaxis) !bool {
    if (key.matches('c', .{ .ctrl = true }) or key.matches('q', .{})) {
        return true;
    } else if (key.matches('l', .{ .ctrl = true })) {
        vx.queueRefresh();
    } else if (key.matches('j', .{})) {
        scroll_offset.* += 1;
    } else if (key.matches('k', .{})) {
        if (scroll_offset.* > 0) {
            scroll_offset.* -= 1;
        }
    } else if (key.matches('g', .{ .shift = true })) {
        if (scroll_offset.* > 0) {
            scroll_offset.* = 0;
        }
    }

    return false;
}
