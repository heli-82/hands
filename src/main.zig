const std = @import("std");
const Arraylist = std.ArrayList;
const Allocator = std.mem.Allocator;
var gpa = std.heap.GeneralPurposeAllocator(.{ .verbose_log = false }){};
var arena_alloc = std.heap.ArenaAllocator.allocator();
const alloc = gpa.allocator();

const stdin = std.io.getStdIn().reader();
const stdout = std.io.getStdOut().writer();

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

const SortOrder = enum { Value, Suit };

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

pub fn generate_deck() !Arraylist(Card) {
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

pub fn draw(hand: *Arraylist(Card), deck: *Arraylist(Card), amount: u8) !void {
    for (0..@min(amount, deck.capacity)) |_| {
        try hand.append(deck.pop());
    }
}

pub fn handle_input() !std.mem.SplitIterator(u8, std.mem.DelimiterType.sequence) {
    var line: [64]u8 = undefined;
    const size = try stdin.read(&line);
    const player_act = std.mem.trim(u8, line[0..size], "\n");
    return std.mem.split(u8, player_act, " ");
}

const scores_and_mult: []struct { i32, i32 } = {};

const Rank = struct {
    const StraightFlush = .{ 100, 8 };
    const Four = .{ 60, 7 };
    const FullHouse = .{ 40, 4 };
    const Flush = .{ 35, 5 };
    const Straight = .{ 31, 4 };
    const Three = .{ 30, 4 };
    const TwoPair = .{ 20, 3 };
    const Pair = .{ 10, 2 };
    const High = .{ 5, 1 };


};

pub fn main() !void {
    const score = Rank.get_score(Rank.Four);
    std.debug.print("{}\n", .{score});

    var deck = try generate_deck();
    defer deck.deinit();
    var hand = Arraylist(Card).init(alloc);
    defer hand.deinit();

    var discards: u8 = 4;
    var hands: u8 = 4;

    try draw(&hand, &deck, 8);
    std.mem.sort(Card, hand.items, SortOrder.Value, Card.compare);

    while (hands > 0) {
        try stdout.print("Your hand:\n", .{});
        for (0.., hand.items) |i, card| {
            try stdout.print("{d}: {}\n", .{ i, card });
        }

        // try stdout.print("{s}", .{std.mem.trim(u8, "\nHello\n", "\n")});
        const Act = enum(u8) { Play = 1, Discard = 2, SetSuitSort = 3, SetValueSort };

        var splitted_act = try handle_input();

        var action: Act = undefined;
        var selected_cards = Arraylist(Card).init(alloc);
        defer selected_cards.deinit();

        while (splitted_act.next()) |x| {
            if (action != undefined) {
                if (std.mem.eql(u8, x, "play")) {
                    action = Act.Play;
                } else if (std.mem.eql(u8, x, "discard")) {
                    action = Act.Discard;
                } else if (std.mem.eql(u8, x, "set_suit_sort")) {
                    action = Act.SetSuitSort;
                } else if (std.mem.eql(u8, x, "set_value_sort")) {
                    action = Act.SetValueSort;
                }
            } else {
                const select_index = std.fmt.parseInt(u8, x, 10) catch continue;
                if (hand.items.len > select_index) {
                    try selected_cards.append(hand.items[select_index]);
                }
            }
        }

        std.debug.print("{}, {}", .{ action, selected_cards });

        hands -= 1;
        discards -= 1;
    }
}
