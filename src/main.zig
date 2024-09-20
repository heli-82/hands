const std = @import("std");
const card = @import("card.zig");
const rank = @import("rank.zig");

const Arraylist = std.ArrayList;
const Allocator = std.mem.Allocator;
var gpa = std.heap.GeneralPurposeAllocator(.{ .verbose_log = false }){};
const alloc = gpa.allocator();

const stdin = std.io.getStdIn().reader();
const stdout = std.io.getStdOut().writer();

const Card = card.Card;

const allSuits = card.allSuits;
const allValues = card.allValues;
const Value = card.Value;
const SortOrder = card.SortOrder;

pub fn generate_deck() !Arraylist(Card) {
    const RndGen = std.Random.DefaultPrng;
    const time = std.time;
    var rng = RndGen.init(@as(u64, @abs(time.timestamp())));

    var deck = Arraylist(Card).init(alloc);

    for (allSuits) |s| {
        for (allValues) |v| {
            const c = Card{ .suit = s, .value = v };
            try deck.append(c);
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

pub fn main() !void {
	const SortType = enum{Value, Suit};
    var deck = try generate_deck();
    defer deck.deinit();
    var hand = Arraylist(Card).init(alloc);
    defer hand.deinit();

	try stdout.print("\x1b[3;35mCommands:\n - play [*indexes]\n - discard [*indexes]\n - set_value_sort\n - set_suit_sort\n\x1b[0m", .{});

    var discards: u8 = 4;
    var hands: u8 = 4;
    var total: i32 = 0;
	var sort_type: SortType = SortType.Value;

    try draw(&hand, &deck, 8);
    std.mem.sort(Card, hand.items, SortOrder.Value, Card.compare);

    while (hands > 0) {
        try stdout.print("Your hand:\n", .{});
        for (0.., hand.items) |i, c| {
            try stdout.print("{d}: {}\n", .{ i, c });
        }

        const Act = enum(u8) { Play = 1, Discard = 2, SetSuitSort = 3, SetValueSort = 4, Nothing = 5 };

		try stdout.print("\x1b[0;33m > ",.{});
        var line: [64]u8 = undefined;
        const size = try stdin.read(&line);
        const player_act = std.mem.trim(u8, line[0..size], "\n");
        var separated_act = std.mem.split(u8, player_act, " ");
		try stdout.print("\x1b[0m",.{});


        var selected_cards = Arraylist(Card).init(alloc);
        defer selected_cards.deinit();
        var action: Act = undefined;
        const act = separated_act.next() orelse "";
        if (std.mem.eql(u8, act, "play")) {
            action = Act.Play;
        } else if (std.mem.eql(u8, act, "discard")) {
            action = Act.Discard;
        } else if (std.mem.eql(u8, act, "set_suit_sort")) {
			sort_type = SortType.Suit;
            action = Act.SetSuitSort;
        } else if (std.mem.eql(u8, act, "set_value_sort")) {
			sort_type = SortType.Value;
            action = Act.SetValueSort;
        } else {
			action = Act.Nothing;
		}

        switch (action) {
            .SetValueSort => {
                std.mem.sort(Card, hand.items, SortOrder.Value, Card.compare);
                continue;
            },
            .SetSuitSort => {
                std.mem.sort(Card, hand.items, SortOrder.Suit, Card.compare);
                continue;
            },
            else => {},
        }

        var to_select = Arraylist(u8).init(alloc);
        defer to_select.deinit();

        while (separated_act.next()) |x| {
            const select_index = std.fmt.parseInt(u8, x, 10) catch {
                std.debug.print("oh no, parse error :(\n", .{});
                continue;
            };
            if (select_index < hand.items.len) {
                try to_select.append(select_index);
            }
        }

        if (to_select.items.len > 5) continue;

        std.mem.sort(u8, to_select.items, {}, std.sort.desc(u8));
        for (to_select.items) |idx| {
            if (idx < hand.items.len) {
                try selected_cards.append(hand.orderedRemove(idx));
            }
        }

        switch (action) {
            .Play => {
                total += rank.get_result(selected_cards.items);
                try draw(&hand, &deck, @intCast(@max(0, 8 - hand.items.len)));
                hands -= 1;
				switch (sort_type){
					SortType.Value => std.mem.sort(Card, hand.items, SortOrder.Value, Card.compare),
					SortType.Suit => std.mem.sort(Card, hand.items, SortOrder.Suit, Card.compare),
				}
            },
            .Discard => {
                try draw(&hand, &deck, @intCast(@max(0, 8 - hand.items.len)));
                discards -= 1;
				switch (sort_type){
					SortType.Value => std.mem.sort(Card, hand.items, SortOrder.Value, Card.compare),
					SortType.Suit => std.mem.sort(Card, hand.items, SortOrder.Suit, Card.compare),
				}
            },
            else => {},
        }

        try stdout.print("\x1b[1;34mtotal: {}\n\x1b[0m", .{total});
        // std.debug.print("{}, {}, {}\n", .{ hand.items.len, action, selected_cards });
    }
}
