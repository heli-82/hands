const std = @import("std");
const card = @import("card.zig");

var gpa = std.heap.GeneralPurposeAllocator(.{ .verbose_log = false }){};
const alloc = gpa.allocator();

const Card = card.Card;
const SortOrder = card.SortOrder;
const Value = card.Value;

const straight_flush = .{ 100, 8 };
const four = .{ 60, 7 };
const full_house = .{ 40, 4 };
const flush = .{ 35, 4 };
const straight = .{ 30, 4 };
const three = .{ 30, 4 };
const two_pair = .{ 20, 3 };
const pair = .{ 10, 2 };
const high = .{ 5, 1 };

fn is_flush(hand: []const Card) bool {
    if (hand.len < 5) {
        return false;
    }

    for (1..hand.len) |i| {
        if (hand[i].suit != hand[i - 1].suit) {
            return false;
        }
    }

    return true;
}

fn is_straight(hand: []Card) bool {
    std.mem.sort(Card, hand, SortOrder.Value, Card.compare);

    if (hand.len < 5) {
        return false;
    }

    for (1..hand.len) |i| {
        if (@intFromEnum(hand[i].value) != @intFromEnum(hand[i - 1].value) + 1) {
            return false;
        }
    }

    return true;
}

const CountAndValue = struct { u8, u8 };
fn compare(_: void, a: CountAndValue, b: CountAndValue) bool {
    if (a[0] <= b[0]) {
        return false;
    } else if (a[0] == b[0]) {
        if (a[1] <= b[1]) {
            return false;
        }
    }
    return true;
}
fn count_by_value(hand: []const Card) [5]CountAndValue {
    var value_map = std.AutoHashMap(Value, u8).init(alloc);
    defer value_map.deinit();

    for (hand) |c| {
        if (value_map.contains(c.value)) {
            value_map.getPtr(c.value).?.* += 1;
        } else {
            value_map.put(c.value, 1) catch continue;
        }
    }

    var count: [5]CountAndValue = .{CountAndValue{ 0, 0 }} ** 5;
    var i: u8 = 0;
	var iterator = value_map.iterator();
    while (iterator.next()) |iter| {
        const value: u8 = switch (iter.key_ptr.*) {
            .two => 2,
            .three => 3,
            .four => 4,
            .five => 5,
            .six => 6,
            .seven => 7,
            .eight => 8,
            .nine => 9,
            .ten, .jack, .queen, .king => 10,
            .ace => 11,
        };
        const quantity = iter.value_ptr.*;

        count[i] = CountAndValue{ quantity, value };
        i += 1;
    }

    std.mem.sort(CountAndValue, &count, {}, compare);

    return count;
}

pub fn get_result(hand: []Card) i32 {
    const count = count_by_value(hand);
    var sum: i32 = 0;
    for (count) |p| {
        sum += p[1];
    }

    const chips_and_mult: struct{i32, i32}, const active_cards: i32 = blk: {
        if (is_straight(hand) and is_flush(hand)) {
            break :blk .{ straight_flush, sum };
        } else if (count[0][0] == 4) {
            break :blk .{ four, count[0][1] * 4 };
        } else if (count[0][0] == 3 and count[1][0] == 2) {
            break :blk .{ full_house, count[0][1] * 3 + count[1][1] * 2 };
        } else if (is_flush(hand)) {
            break :blk .{ flush, sum };
        } else if (is_straight(hand)) {
            break :blk .{ straight, sum };
        } else if (count[0][0] == 3) {
            break :blk .{ three, count[0][1] * 3 };
        } else if (count[0][0] == 2 and count[1][0] == 2) {
            break :blk .{ two_pair, count[0][1] * 2 + count[1][1] * 2 };
        } else if (count[0][0] == 2) {
            break :blk .{ pair, count[0][1] * 2 };
        } else {
            break :blk .{ high, count[0][1] };
        }
    };

    return (chips_and_mult[0] + active_cards) * chips_and_mult[1];
}
