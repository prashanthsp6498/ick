const std = @import("std");
const vaxis = @import("vaxis");
const vxfw = vaxis.vxfw;
const cwd = std.fs.cwd();
const logger = @import("logger").Logger;

const folderStructure = struct {
    curr: [][]const u8,

    parent: ?*folderStructure,
    child: ?*folderStructure,
};

pub const File = struct {
    root_path: []const u8 = ".",
    curr_path: []u8 = "",
    child_path: []u8 = "",
    allocator: std.mem.Allocator,

    pub const handler = struct {
        getRootFile: [][]const u8,
        getCurrFile: [][]const u8,
        getChildFile: [][]const u8,
        folderSize: u8,
        allocator: std.mem.Allocator,

        pub fn deinit(self: *handler) void {
            for (self.getRootFile) |file| {
                self.allocator.free(file);
            }

            self.allocator.free(self.getRootFile);
            self.allocator.free(self.getCurrFile);
            self.allocator.free(self.getChildFile);
        }
    };

    pub fn init(allocator: std.mem.Allocator) File {
        return .{
            .allocator = allocator,
        };
    }

    pub fn getContent(self: *File) !handler {
        return .{
            .getRootFile = try self.getRootDir(),
            .getCurrFile = try self.getCurrDir(),
            .getChildFile = try self.getChildDir(),
            .folderSize = try self.getFolderSize(),
            .allocator = self.allocator,
        };
    }

    fn getFolderSize(self: *const File) !u8 {
        var dir = try std.fs.cwd().openDir(self.root_path, .{ .iterate = true });
        defer dir.close();

        var total_size: u8 = 0;

        var it = dir.iterate();
        while (try it.next()) |entry| {
            _ = entry.name;
            total_size += 1;
        }

        return total_size;
    }

    fn getRootDir(self: *const File) ![][]const u8 {
        var dir = try std.fs.cwd().openDir(self.root_path, .{ .iterate = true });
        defer dir.close();

        var files = std.ArrayList([]const u8).init(self.allocator);
        defer files.deinit();

        var it = dir.iterate();

        while (try it.next()) |entry| {
            const file = try self.allocator.dupe(u8, entry.name);
            try files.append(file);
        }

        return files.toOwnedSlice();
    }

    fn getCurrDir(self: *const File) ![][]const u8 {
        var dir = try std.fs.cwd().openDir(self.root_path, .{ .iterate = true });
        defer dir.close();

        var files = std.ArrayList([]const u8).init(self.allocator);
        defer files.deinit();

        var it = dir.iterate();
        while (try it.next()) |entry| {
            try files.append(entry.name);
        }

        return files.toOwnedSlice();
    }

    fn getChildDir(self: *const File) ![][]const u8 {
        var dir = try std.fs.cwd().openDir(self.root_path, .{ .iterate = true });
        defer dir.close();

        var files = std.ArrayList([]const u8).init(self.allocator);
        defer files.deinit();

        var it = dir.iterate();
        while (try it.next()) |entry| {
            try files.append(entry.name);
        }

        return files.toOwnedSlice();
    }
};

//
test "file test" {
    var gap = std.heap.DebugAllocator(.{}){};
    defer _ = gap.deinit();
    const allocator = gap.allocator();
    var file = File.init(allocator);
    const contents = file.getContent();
    defer contents.deinit();
    //const size = try contents.folderSize;

    const get_files = try contents.getRootFile;
    for (get_files) |get_file| {
        std.debug.print("{s}", .{get_file});
    }
    //std.debug.print("{s}", .{size});
}
