const std = @import("std");
const Arraylist = std.ArrayList;
const Allocator = std.mem.Allocator;
var gpa = std.heap.GeneralPurposeAllocator(.{ .verbose_log = false }){};
const alloc = gpa.allocator();

const Suit = enum(u2) {
    spades,
    hearts,
    clubs,
    diamonds,
};

const Value = enum(u8) {
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

const allValues = [_]Value{ .two, .three, .four, .five, .six, .seven, .eight, .nine, .ten, .jack, .queen, .king, .ace };
const allSuits = [_]Suit{
    .spades,
    .hearts,
    .clubs,
    .diamonds,
};

const Card = struct {
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
};

pub fn generate_deck() error{OutOfMemory}!Arraylist(Card) {
    const RndGen = std.Random.DefaultPrng;
    const time = std.time;
    var rng = RndGen.init(@as(u64, @abs(time.timestamp())));

    var deck = Arraylist(Card).init(alloc);

    for (allSuits) |s| {
        for (allValues) |v| {
            const card = Card{ .suit = s, .value = v };
            try deck.append(card);
        }
    }

    rng.random().shuffle(Card, deck.items);

    return deck;
}

pub fn main() !void {
    const deck = try generate_deck();
    defer deck.deinit();
    
    for (deck.items) |card| {
        std.debug.print("{}\n", .{card});
    }
}
