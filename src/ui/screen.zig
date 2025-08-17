const std = @import("std");
const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;
const cwd = std.fs.cwd();

pub const ScreenSize = struct { left_width: u16, middle_width: u16, right_width: u16 };

pub const Screen_ = struct {
    root_dir_name: []const u8,
    curr_dir_name: []const u8,
    child_dir_name: []const u8,

    const color_idx: u8 = 140;
    const style: vaxis.Style = .{
        .fg = .{ .index = color_idx },
    };

    pub fn getScreenSizes(self: *const Screen_, win: vaxis.Window) ScreenSize {
        _ = self;
        const left_width = win.width / 4;
        const right_width = win.width / 4;
        const middle_width = win.width - left_width - right_width;
        return .{ .left_width = left_width, .right_width = right_width, .middle_width = middle_width };
    }

    pub fn createLeftPanel(self: *const Screen_, win: vaxis.Window, sizes: ScreenSize) vaxis.Window {
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

    pub fn createMiddlePanel(self: *const Screen_, win: vaxis.Window, sizes: ScreenSize) vaxis.Window {
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

    pub fn createRightPanel(self: *const Screen_, win: vaxis.Window, sizes: ScreenSize) vaxis.Window {
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
