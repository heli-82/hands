const std = @import("std");

pub const Suit = enum(u2) {
    spades,
    hearts,
    clubs,
    diamonds,
};
pub const Value = enum(u8) {
    two = 2,
    three = 3,
    four = 4,
    five = 5,
    six = 6,
    seven = 7,
    eight = 8,
    nine = 9,
    ten = 10,
    jack = 11,
    queen = 12,
    king = 13,
    ace = 14,
};

pub const allValues = [_]Value{ .two, .three, .four, .five, .six, .seven, .eight, .nine, .ten, .jack, .queen, .king, .ace };
pub const allSuits = [_]Suit{
    .spades,
    .hearts,
    .clubs,
    .diamonds,
};

pub const SortOrder = enum { Value, Suit };
pub const Card = struct {
    suit: Suit,
    value: Value,

    pub fn format(
        self: Card,
        comptime options: []const u8,
        fmt: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = options;
        _ = fmt;
        try writer.print("{s} of {s}", .{ @tagName(self.value), @tagName(self.suit) });
    }

    pub fn compare(order: SortOrder, a: Card, b: Card) bool {
        switch (order) {
            SortOrder.Suit => {
                if (a.suit == b.suit) return @intFromEnum(a.value) < @intFromEnum(b.value);
                return @intFromEnum(a.suit) < @intFromEnum(b.suit);
            },
            SortOrder.Value => {
                if (a.value == b.value) return @intFromEnum(a.suit) < @intFromEnum(b.suit);
                return @intFromEnum(a.value) < @intFromEnum(b.value);
            },
        }
    }
};
