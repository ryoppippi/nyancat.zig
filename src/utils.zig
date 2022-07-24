const std = @import("std");
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
