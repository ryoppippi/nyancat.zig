const std = @import("std");
const utils = @import("utils.zig");
const content = @embedFile("assets/frames.json");

const output_char = "  ";
const defualt_term_info = [2]u8{ 60, 60 };

pub fn main() anyerror!void {
    var writer = std.io.getStdOut().writer();
    const print = writer.print;

    var allocator = std.heap.page_allocator;
    var p = std.json.Parser.init(allocator, false);
    defer p.deinit();
    var data = (p.parse(content) catch unreachable).root;

    var term_info: [2]u8 = utils.getTermSize(allocator, "/tmp/.stty.nyan") catch defualt_term_info;
    const term_width = term_info[1] / output_char.len;
    const term_height = term_info[0];

    const frame_row = data.Array.items[0].Array.items.len;
    const frame_col = frame_row;

    const min_row = if (frame_row > term_height) (frame_row - term_height) / 2 else 0;
    const max_row = if (frame_row > term_height) min_row + term_height else frame_row;

    const min_col = if (frame_col > term_width) (frame_col - term_width) / 2 else 0;
    const max_col = if (frame_col > term_width) min_col + term_width else frame_col;

    try print("{s}", .{NEW_SCREEN});
    var kk: i32 = 0;

    while (true) {
        kk += 1;
        for (data.Array.items) |frames| {
            for (frames.Array.items[min_row..max_row]) |row| {
                for (row.String[min_col..max_col]) |char| {
                    try print("{s}", .{convertColors(char)});
                } else {
                    try print("{s}", .{NEW_LINE});
                }
            }
            try print("{s}", .{CLEAR_SCREEN});
            try print("{s}", .{EXIT_SCREEN});
            std.time.sleep(60 * std.time.ns_per_ms);
        }
    }
}

const ESC = "\x1b";
const NEW_SCREEN = ESC ++ "\u{67}" ++ ESC ++ "[?47h";
const CLEAR_SCREEN = ESC ++ "[H";
const EXIT_SCREEN = ESC ++ "[?47l" ++ ESC ++ "\u{70}";
const NEW_LINE = ESC ++ "[m" ++ "\n";

fn convertColors(s: u8) []const u8 {
    return switch (s) {
        '+' => ESC ++ "[48;5;226m" ++ output_char,
        '@' => ESC ++ "[48;5;223m" ++ output_char,
        ',' => ESC ++ "[48;5;17m" ++ output_char,
        '-' => ESC ++ "[48;5;205m" ++ output_char,
        '#' => ESC ++ "[48;5;82m" ++ output_char,
        '.' => ESC ++ "[48;5;15m" ++ output_char,
        '$' => ESC ++ "[48;5;219m" ++ output_char,
        '%' => ESC ++ "[48;5;217m" ++ output_char,
        ';' => ESC ++ "[48;5;99m" ++ output_char,
        '&' => ESC ++ "[48;5;214m" ++ output_char,
        '=' => ESC ++ "[48;5;39m" ++ output_char,
        '\'' => ESC ++ "[48;5;0m" ++ output_char,
        '>' => ESC ++ "[48;5;196m" ++ output_char,
        '*' => ESC ++ "[48;5;245m" ++ output_char,
        else => unreachable,
    };
}

test "a" {
    comptime var writer = std.io.getStdOut().writer();
    try writer.print("{s}", .{convertColors('*')});
    try writer.print("{s}", .{convertColors('%')});
    try writer.print("{s}", .{convertColors(' ')});
    try writer.print("\n", .{});
}
