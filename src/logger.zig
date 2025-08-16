const std = @import("std");

const log_file_name = "debug.log";

pub const Logger = struct {
    file: std.fs.File,
    writer: std.fs.File.Writer,

    pub fn init() !Logger {
        var file = std.fs.cwd().openFile(log_file_name, .{ .mode = .read_write }) catch |er|
            switch (er) {
                std.fs.File.OpenError.FileNotFound => try std.fs.cwd().createFile(log_file_name, .{ .truncate = false }),
                else => @panic("failed to create log file"),
            };

        try file.seekFromEnd(0); file.writer().print("\n New Run \n\n", .{}) catch {}; return Logger{ .file = file,
            .writer = file.writer(),
        };
    }

    pub fn debug(self: *Logger, comptime fmt: []const u8, args: anytype) void {
        self.writer.print("debug   :: " ++ fmt ++ "\n", args) catch {};
    }

    pub fn warning(self: *Logger, comptime fmt: []const u8, args: anytype) void {
        self.writer.print("warning :: " ++ fmt ++ "\n", args) catch {};
    }

    pub fn err(self: *Logger, comptime fmt: []const u8, args: anytype) void {
        self.writer.print("error   :: " ++ fmt ++ "\n", args) catch {};
    }

    pub fn deinit(self: *Logger) void {
        self.file.close();
    }
};

test "test file creation and logging" {
    var logger = try Logger.init();
    defer logger.deinit();

    var end_pos = try logger.file.getEndPos();
    logger.debug("This is debug test", .{});
    std.debug.assert(end_pos != try logger.file.getEndPos());

    end_pos = try logger.file.getEndPos();
    logger.warning("This is warning test", .{});
    std.debug.assert(end_pos != try logger.file.getEndPos());

    end_pos = try logger.file.getEndPos();
    logger.err("This is error test", .{});
    std.debug.assert(end_pos != try logger.file.getEndPos());
}
