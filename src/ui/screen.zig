const std = @import("std");
const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;
const files = @import("../core/core.zig");
const cwd = std.fs.cwd();

pub const ScreenSize = struct { left_width: u16, middle_width: u16, right_width: u16 };

pub const Screen_ = struct {
    win: vaxis.Window,
    screenSize: ScreenSize,

    const color_idx: u8 = 140;
    const style: vaxis.Style = .{
        .fg = .{ .index = color_idx },
    };

    pub fn initscreen(win: vaxis.Window, screenSize: ScreenSize) Screen_ {
        return .{
            .win = win,
            .screenSize = screenSize,
        };
    }

    pub fn getScreenSizes(win: vaxis.Window) ScreenSize {
        const left_width = win.width / 4;
        const right_width = win.width / 4;
        const middle_width = win.width - left_width - right_width;
        return .{ .left_width = left_width, .right_width = right_width, .middle_width = middle_width };
    }

    pub fn createWindows(self: *Screen_) !vaxis.Window {
        const left_panel = self.createLeftPanel(self.win, self.screenSize);
        _ = left_panel.printSegment(.{ .text = "Root Folder" }, .{ .row_offset = 0, .col_offset = 1 });

        const right_panel = self.createRightPanel(self.win, self.screenSize);
        _ = right_panel.printSegment(.{ .text = "Child Folder" }, .{ .row_offset = 0, .col_offset = 1 });

        const middle_panel = self.createMiddlePanel(self.win, self.screenSize);
        _ = middle_panel.printSegment(.{ .text = "Current Folder" }, .{ .row_offset = 0, .col_offset = 1 });

        return middle_panel;
    }

    fn createLeftPanel(self: *const Screen_, win: vaxis.Window, sizes: ScreenSize) vaxis.Window {
        _ = self;
        return win.child(.{
            .x_off = 0,
            .y_off = 0,
            .width = sizes.left_width,
            .height = win.height,
            .border = .{
                .where = .all,
                .style = style,
            },
        });
    }

    fn createMiddlePanel(self: *const Screen_, win: vaxis.Window, sizes: ScreenSize) vaxis.Window {
        _ = self;
        return win.child(.{
            .x_off = sizes.left_width,
            .y_off = 0,
            .width = sizes.middle_width,
            .height = win.height,
            .border = .{
                .where = .all,
                .style = style,
            },
        });
    }

    fn createRightPanel(self: *const Screen_, win: vaxis.Window, sizes: ScreenSize) vaxis.Window {
        _ = self;
        return win.child(.{
            .x_off = sizes.left_width + sizes.middle_width,
            .y_off = 0,
            .width = sizes.right_width,
            .height = win.height,
            .border = .{
                .where = .all,
                .style = style,
            },
        });
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
