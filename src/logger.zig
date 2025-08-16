const std = @import("std");
const exe_options = @import("exe_options");

const log_file_name = "debug.log";

pub const Logger = struct {
    file: ?std.fs.File,
    writer: ?std.fs.File.Writer,

    pub fn init() !Logger {
        if (!exe_options.debug_build) {
            return .{
                .file = null,
                .writer = null,
            };
        }
        var file = std.fs.cwd().openFile(log_file_name, .{ .mode = .read_write }) catch |er|
            switch (er) {
                std.fs.File.OpenError.FileNotFound => try std.fs.cwd().createFile(log_file_name, .{ .truncate = false }),
                else => @panic("failed to create log file"),
            };

        try file.seekFromEnd(0);
        file.writer().print("\n New Run; build_type: {s}\n\n", .{if (exe_options.debug_build) "Debug" else "Release"}) catch {};
        return Logger{
            .file = file,
            .writer = file.writer(),
        };
    }

    pub fn info(self: *Logger, comptime fmt: []const u8, args: anytype) void {
        if (!exe_options.debug_build)
            return;
        self.writer.?.print("INF :: " ++ fmt ++ "\n", args) catch {};
    }

    pub fn debug(self: *Logger, comptime fmt: []const u8, args: anytype) void {
        if (!exe_options.debug_build)
            return;
        self.writer.?.print("DBG :: " ++ fmt ++ "\n", args) catch {};
    }

    pub fn warning(self: *Logger, comptime fmt: []const u8, args: anytype) void {
        if (!exe_options.debug_build)
            return;
        self.writer.?.print("WAR :: " ++ fmt ++ "\n", args) catch {};
    }

    pub fn err(self: *Logger, comptime fmt: []const u8, args: anytype) void {
        if (!exe_options.debug_build)
            return;
        self.writer.?.print("ERR :: " ++ fmt ++ "\n", args) catch {};
    }

    pub fn deinit(self: *Logger) void {
        self.file.?.close();
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

    end_pos = try logger.file.getEndPos();
    logger.info("This is error test", .{});
    std.debug.assert(end_pos != try logger.file.getEndPos());
}
