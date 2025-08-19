const std = @import("std");
const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;
const cwd = std.fs.cwd();
const logger = @import("logger").Logger;

pub const folderStructure = struct {
    curr: [][]const u8,
    parent: ?*folderStructure,
    child: ?*folderStructure,
    allocator: std.mem.Allocator,
};

pub const File = struct {
    path: []const u8 = "/home/hexa",
    allocator: std.mem.Allocator,

    pub fn init(alloc: std.mem.Allocator) File {
        return .{
            .allocator = alloc,
        };
    }
    pub fn deinit(self: *folderStructure) void {
        for (self.curr) |file| {
            self.allocator.free(file);
        }
        self.allocator.free(self.curr);
    }

    pub fn currDir(self: *const File) !folderStructure {
        var open = try std.fs.openDirAbsolute(self.path, .{ .iterate = true });
        defer open.close();
        var it = open.iterate();

        var folders = std.ArrayList([]const u8).init(self.allocator);

        while (try it.next()) |entry| {
            const file = try self.allocator.dupe(u8, entry.name);
            try folders.append(file);
        }

        return folderStructure{ .curr = try folders.toOwnedSlice(), .parent = undefined, .child = undefined, .allocator = self.allocator };
    }
};
