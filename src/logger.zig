const std = @import("std");
const exe_options = @import("exe_options");
const open_error = std.fs.File.OpenError;

const log_file_name = "debug.log";

var file: ?std.fs.File = null;

pub fn init() void {
    _ = std.log.scoped(.ick);
    const cwd = std.fs.cwd();
    file = cwd.openFile(log_file_name, .{ .mode = .read_write }) catch |er|
        switch (er) {
            open_error.FileNotFound => cwd.createFile(log_file_name, .{ .truncate = false }) catch return,
            else => @panic("failed to create log file"),
        };

    if (file) |f| {
        f.seekFromEnd(0) catch return;
        f.writer().print("\n\n=========================================\n\n", .{}) catch return;
    }
}

pub fn deinit() void {
    file.?.writer().print("\n\n=========================================\n\n", .{}) catch return;
    file.?.close();
}

pub fn logFn(
    comptime message_level: std.log.Level,
    comptime scope: @TypeOf(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    const level_txt = comptime message_level.asText();
    const prefix2 = if (scope == .default) "(ick): " else "(" ++ @tagName(scope) ++ "): ";

    if (file) |f| {
        const writer = f.writer();
        std.debug.lockStdErr();
        defer std.debug.unlockStdErr();
        nosuspend {
            writer.print(level_txt ++ prefix2 ++ format ++ "\n", args) catch return;
        }
    }
}
