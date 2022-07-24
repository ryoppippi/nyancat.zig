const std = @import("std");
const builtin = @import("builtin");
const fmt = std.fmt;
const os = std.os;
const mem = std.mem;
const ArrayList = std.ArrayList;

var return_array = mem.zeroes([2]u8);

pub fn getTermSize(allocator: std.mem.Allocator, filename: []const u8) ![2]u8 {
    var tokens = std.mem.split(u8, "stty size", " ");
    var args: [10][20:0]u8 = undefined;
    var args_ptrs: [10:null]?[*:0]u8 = undefined;

    // Copy each string "token" into the storage array and save a pointer to it.
    var i: usize = 0;
    while (tokens.next()) |tok| {
        std.mem.copy(u8, &args[i], tok);
        args[i][tok.len] = 0; // add sentinel 0
        args_ptrs[i] = &args[i];
        i += 1;
    }
    args_ptrs[i] = null; // add sentinel null

    const fork_pid = try std.os.fork();

    // Who am I?
    if (fork_pid == 0) { // We are the child.

        // make file
        const file = try std.fs.cwd().createFile(filename, .{ .read = true });
        defer file.close();

        _ = try std.os.dup2(file.handle, 1);

        // Make a null environment of the correct type.
        const env = [_:null]?[*:0]u8{null};

        // Execute command, replacing child process!
        const result = std.os.execvpeZ(args_ptrs[0].?, &args_ptrs, &env);

        // If we make it this far, the exec() call has failed!
        // try stdout.print(" {}\n", .{result});
        std.log.info("{}", .{result});
        return return_array;
    } else { // We are the parent.

        const wait_result = await async std.os.waitpid(fork_pid, 0);

        if (wait_result.status != 0) {
            // try stdout.print("Command returned {}.\n", .{wait_result.status});
        }
        const file = try std.fs.cwd().openFile(filename, .{});
        defer file.close();
        const contents = file.reader().readAllAlloc(allocator, 30) catch unreachable;
        defer allocator.free(contents);

        i = 0;

        tokens = std.mem.split(u8, contents, " ");

        while (tokens.next()) |tok| {
            for (tok) |c| {
                if (i >= 2) break;
                const num = fmt.charToDigit(c, 10) catch {
                    continue;
                };
                return_array[i] *= 10;
                return_array[i] += num;
            }
            i += 1;
        }
        for (return_array) |a| {
            if (a == 0) return error.CannnotGetTermSize;
        }
        return return_array;
    }
}

test "get term size" {
    const test_allocator = std.testing.allocator;
    const re = try getTermSize(test_allocator, "/tmp/.stty.nyan");
    std.debug.print("\n", .{});
    for (re) |r| {
        std.debug.print("{}\n", .{r});
    }
}

pub fn main() !void {
    const test_allocator = std.testing.allocator;
    const re = try getTermSize(test_allocator, "/tmp/.stty.nyan");
    std.debug.print("\n", .{});
    for (re) |r| {
        std.debug.print("{}\n", .{r});
    }
}

pub const is_windows = builtin.os.tag == .windows;

pub const w32 = if (is_windows) struct {
    const WINAPI = std.os.windows.WINAPI;
    const DWORD = std.os.windows.DWORD;
    const ENABLE_VIRTUAL_TERMINAL_PROCESSING = 0x0004;
    const STD_ERROR_HANDLE = @bitCast(DWORD, @as(i32, -12));
    extern "kernel32" fn GetStdHandle(id: DWORD) callconv(WINAPI) ?*anyopaque;
    extern "kernel32" fn GetConsoleMode(console: ?*anyopaque, out_mode: *DWORD) callconv(WINAPI) u32;
    extern "kernel32" fn SetConsoleMode(console: ?*anyopaque, mode: DWORD) callconv(WINAPI) u32;
} else undefined;

var w32_handle: ?*anyopaque = undefined;
var w32_mode: if (is_windows) w32.DWORD else void = undefined;

pub fn term_init() void {
    if (builtin.os.tag == .windows) {
        w32_handle = w32.GetStdHandle(w32.STD_ERROR_HANDLE);
        if (w32.GetConsoleMode(w32_handle, &w32_mode) != 0) {
            w32_mode |= w32.ENABLE_VIRTUAL_TERMINAL_PROCESSING;
            w32_mode = w32.SetConsoleMode(w32_handle, w32_mode);
        }
    }
}

pub fn term_finish() void {
    if (builtin.os.tag == .windows) {
        _ = w32.SetConsoleMode(w32_handle, w32_mode);
    }
}
