const std = @import("std");
const writer = std.io.getStdOut().writer();
const utils = @import("utils.zig");
const content = @embedFile("assets/frames.json");

const output_char = "  ";
const default_term_info = if (utils.is_windows) [2]u32{ 24, 80 } else [2]u32{ 60, 60 };

pub fn main() anyerror!void {
    utils.term_init();
    defer utils.term_finish();

    var allocator = std.heap.page_allocator;
    var p = std.json.Parser.init(allocator, false);
    defer p.deinit();
    var data = (p.parse(content) catch unreachable).root;

    var term_info: [2]u32 = if (utils.is_windows) default_term_info else utils.getTermSize(allocator, "/tmp/.stty.nyan") catch default_term_info;
    const term_width = term_info[1] / output_char.len;
    const term_height = term_info[0];

    const frame_row = data.Array.items[0].Array.items.len;
    const frame_col = frame_row;

    const min_row = if (frame_row > term_height) (frame_row - term_height) / 2 else 0;
    const max_row = if (frame_row > term_height) min_row +| term_height else frame_row;

    const min_col = if (frame_col > term_width) (frame_col - term_width) / 2 else 0;
    const max_col = if (frame_col > term_width) min_col +| term_width else frame_col;

    try writer.print("{s}", .{NEW_SCREEN});

    while (true) {
        for (data.Array.items) |frames| {
            for (frames.Array.items[min_row..max_row]) |row| {
                for (row.String[min_col..max_col]) |char| {
                    try writer.print("{s}", .{convertColors(char)});
                } else {
                    try writer.print("{s}", .{NEW_LINE});
                }
            }
            try writer.print("{s}", .{CLEAR_SCREEN});
            try writer.print("{s}", .{EXIT_SCREEN});
            std.time.sleep(60 * std.time.ns_per_ms);
        }
    }
}

const ESC = "\x1b";
const NEW_SCREEN = ESC ++ "\u{67}" ++ ESC ++ "[0;0H" ++ ESC ++ "[2J" ++ ESC ++ "[?47h";
const CLEAR_SCREEN = ESC ++ "[H";
const EXIT_SCREEN = ESC ++ "[?47l" ++ ESC ++ "\u{70}";
const NEW_LINE = ESC ++ "[m" ++ "\n";

fn convertColors(s: u8) []const u8 {
    return switch (s) {
        // zig fmt: off
        '+'  => makeTermString(226),
        '@'  => makeTermString(223),
        ','  => makeTermString(17),
        '-'  => makeTermString(205),
        '#'  => makeTermString(82),
        '.'  => makeTermString(15),
        '$'  => makeTermString(219),
        '%'  => makeTermString(217),
        ';'  => makeTermString(99),
        '&'  => makeTermString(214),
        '='  => makeTermString(39),
        '\'' => makeTermString(0),
        '>'  => makeTermString(196),
        '*'  => makeTermString(245),
        else => unreachable,
        // zig fmt: on
    };
}

fn makeTermString(comptime s: u32) []const u8 {
    return std.fmt.comptimePrint(ESC ++ "[48;5;{}m" ++ output_char, .{s});
}
