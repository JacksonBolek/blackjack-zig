const std = @import("std");
const RNDGEN = std.rand.DefaultPrng;
const print = std.debug.print;
const eql = std.mem.eql;

const suits = [_][]const u8{ "clubs", "diamonds", "hearts", "spades" };
const card_types = [_][]const u8{ "Ace", "2", "3", "4", "5", "6", "7", "8", "9", "10", "Jack", "Queen", "King" };

const UserInputError = error{
    TooLong,
    TooShort,
};

const Card = struct {
    suit: []const u8,
    type: []const u8,
    shown: bool,
};

const Deck = struct {
    number_of_decks: u8,
    current_card_index: u32,
    cards: []Card,

    pub fn init(allocator: std.mem.Allocator, number_of_decks: u8) !Deck {
        var cards = try allocator.alloc(Card, 52 * number_of_decks);
        var index: usize = 0;
        var i: usize = 0;

        while (i < number_of_decks) : (i += 1) {
            for (suits) |suit| {
                for (card_types) |c_type| {
                    cards[index] = Card{
                        .suit = suit,
                        .type = c_type,
                        .shown = false,
                    };
                    index += 1;
                }
            }
        }

        // for (cards, 0..) |card, z| {
        //     std.debug.print("Card {d}: {s}, {s}\n", .{ z + 1, card.suit, card.type });
        // }

        return Deck{
            .cards = cards,
            .current_card_index = 0,
            .number_of_decks = number_of_decks,
        };
    }

    pub fn deinit(self: *Deck, allocator: std.mem.Allocator) void {
        allocator.free(self.cards);
    }

    pub fn shuffle(self: *Deck) void {
        var rnd = RNDGEN.init(0);
        var i = self.cards.len;
        while (i > 1) {
            i -= 1;
            const j = rnd.random().int(u32) % i;
            const temp = self.cards[i];
            self.cards[i] = self.cards[j];
            self.cards[j] = temp;
        }
    }

    pub fn draw_card(self: *Deck) *Card {
        if (self.current_card_index == self.cards.len) {
            self.shuffle();
            self.current_card_index = 0;
        }
        self.current_card_index += 1;
        return &self.cards[self.current_card_index - 1];
    }
};

const Hand = struct {
    cards: [13]?*Card,
    current_card_index: u8,

    pub fn init() Hand {
        const cards: [13]*Card = undefined;
        return Hand{
            .cards = cards,
            .current_card_index = 0,
        };
    }
};

const Player = struct {
    name: []const u8,
    money: u64,
    hand: Hand,

    pub fn init(name: []const u8, money: u64) Player {
        return Player{
            .name = name,
            .money = money,
            .hand = Hand.init(),
        };
    }

    pub fn draw_card(self: *Player, deck: *Deck) void {
        self.hand.cards[self.hand.current_card_index] = deck.draw_card();
        self.hand.current_card_index += 1;
    }

    pub fn clear_hand(self: *Player) void {
        for (self.hand.cards, 0..) |_, i| {
            self.hand.cards[i] = null;
        }
        self.hand.current_card_index = 0;
    }

    pub fn print_hand(self: *Player) void {
        if (self.hand.current_card_index == 0) {
            print("\nNo Cards in hand\n", .{});
        } else {
            std.debug.print("\n{s} has cards:\n", .{self.name});
            for (self.hand.cards[0..self.hand.current_card_index], 0..) |card, i| {
                if (card) |c| {
                    std.debug.print("{d}: {s} of {s}\n", .{ i + 1, c.type, c.suit });
                } else {
                    std.debug.print("{d}: No card\n", .{i});
                }
            }
        }
    }
};

pub fn ask_user_str(input_len: usize, allocator: std.mem.Allocator) ![]const u8 {
    const stdin = std.io.getStdIn();

    var buffer = try allocator.alloc(u8, input_len);
    defer allocator.free(buffer);

    const length = try stdin.read(buffer);

    if (length == buffer.len) {
        return UserInputError.TooLong;
    }

    // We have to add a 0 to the end of the string or else we cannot print it out
    // std.mem.trimRight does not add a 0 so we must do that ourselves
    const trimmed_length = std.mem.trimRight(u8, buffer[0..length], "\n").len;

    var clean_input = try allocator.alloc(u8, trimmed_length + 1);
    std.mem.copyForwards(u8, clean_input[0..trimmed_length], buffer[0..trimmed_length]);
    clean_input[trimmed_length] = 0;

    return clean_input;
}

pub fn ask_user_int(input_len: usize, allocator: std.mem.Allocator) !u32 {
    const usr_input = try ask_user_str(input_len, allocator);

    return std.fmt.parseInt(u32, usr_input[0 .. usr_input.len - 1], 10);
}

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        _ = gpa.deinit();
    }

    var deck = try Deck.init(allocator, 1);
    deck.shuffle();

    const game = true;
    var game_menu = true;

    while (game) {
        while (game_menu) {
            try stdout.print("\n\nWelcome to Blackjack\nStart - (s) Exit - (e)\n\n", .{});

            const usr_input = ask_user_str(3, allocator);

            if (usr_input) |start_game| {
                if (eql(u8, "s", start_game[0 .. start_game.len - 1])) {
                    print("Initialzing Game!\n\n", .{});
                    game_menu = false;
                } else if (eql(u8, "e", start_game[0 .. start_game.len - 1])) {
                    //TODO Implement closing the program on exit (e)
                    print("Exit the game", .{});
                } else {
                    print("\nNot a valid selection", .{});
                }
            } else |err| {
                switch (err) {
                    UserInputError.TooLong => {
                        print("Input too long", .{});
                    },
                    else => {
                        print("An error occured: {}", .{err});
                    },
                }
            }
            print("What is your name - ", .{});
            const player_name = try ask_user_str(30, allocator);

            print("\nHow much money would you like to put in your wallet?\n", .{});
            const player_wallet = try ask_user_int(10, allocator);

            const player1 = Player.init(player_name[0 .. player_name.len - 1], player_wallet);
            _ = player1;

            print("You are in the game loop", .{});
        }
    }
    deck.deinit(allocator);
}
