const std = @import("std");
const RNDGEN = std.rand.DefaultPrng;
const print = std.debug.print;
const eql = std.mem.eql;

const MESSAGEDASH: []const u8 = "-------------------------------------------------";

const suits = [_][]const u8{ "Clubs", "Diamonds", "Hearts", "Spades" };
const card_types = [_][]const u8{ "Ace", "2", "3", "4", "5", "6", "7", "8", "9", "10", "Jack", "Queen", "King" };

const UserInputError = error{
    TooLong,
    TooShort,
};

const Card = struct {
    suit: []const u8,
    type: []const u8,
    value: u8,
    shown: bool,
};

const Deck = struct {
    number_of_decks: u8,
    current_card_index: u32,
    cards: []Card,
    prng: std.Random.DefaultPrng,

    pub fn init(allocator: std.mem.Allocator, number_of_decks: u8, prng: std.Random.DefaultPrng) !Deck {
        var cards = try allocator.alloc(Card, 52 * number_of_decks);
        var index: usize = 0;
        var i: usize = 0;

        while (i < number_of_decks) : (i += 1) {
            for (suits) |suit| {
                for (card_types) |c_type| {
                    const c_value = if (eql(u8, "Ace", c_type))
                        1
                    else if (eql(u8, "Jack", c_type) or eql(u8, "Queen", c_type) or eql(u8, "King", c_type))
                        10
                    else
                        try std.fmt.parseInt(u8, c_type, 10);
                    cards[index] = Card{
                        .suit = suit,
                        .type = c_type,
                        .value = c_value,
                        .shown = false,
                    };
                    index += 1;
                }
            }
        }

        // for (cards, 0..) |card, z| {
        //     std.debug.print("Card {d}: {s}, {s}\n", .{ z + 1, card.suit, card.type });
        // }

        return Deck{ .cards = cards, .current_card_index = 0, .number_of_decks = number_of_decks, .prng = prng };
    }

    pub fn deinit(self: *Deck, allocator: std.mem.Allocator) void {
        allocator.free(self.cards);
    }

    pub fn shuffle(self: *Deck) void {

        // var rnd = RNDGEN.init(0);
        var i = self.cards.len;
        while (i > 1) {
            i -= 1;
            const j = self.prng.random().int(u32) % i;
            // const j = rnd.random().int(u32) % i;
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
    money: u32,
    hand: Hand,

    pub fn init(name: []const u8, money: u32) Player {
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

    pub fn get_hand_total(self: *Player) u32 {
        var hand_total: u32 = 0;
        var ace_count: u8 = 0;

        for (self.hand.cards[0..self.hand.current_card_index]) |card| {
            if (card) |c| {
                if (c.value == 1) {
                    ace_count += 1;
                } else {
                    hand_total += c.value;
                }
            }
        }
        if (ace_count == 0) {
            return hand_total;
        }

        var i: u8 = 0;
        while (i < ace_count) : (i += 1) {
            if (hand_total + 11 < 21) {
                hand_total += 11;
            } else {
                hand_total += 1;
            }
        }
        return hand_total;
    }

    pub fn print_hand(self: *Player) void {
        // Check for cards in the players hand
        if (self.hand.current_card_index == 0) {
            print("\nNo Cards in hand\n", .{});
        } else {
            std.debug.print("\n{s} has cards:\n", .{self.name});
            // Loop through each card and its index
            // print out the index and its card
            // sum of the value of the cards in his hand while accounts for if there is an ace or not
            for (self.hand.cards[0..self.hand.current_card_index], 0..) |card, i| {
                if (card) |c| {
                    std.debug.print("{d}: {s} of {s}\n", .{ i + 1, c.type, c.suit });
                } else {
                    std.debug.print("{d}: No card\n", .{i});
                }
            }
            print("{s} hand total: {d}\n\n", .{ self.name, get_hand_total(self) });
        }
    }

    pub fn print_second_card(self: *Player) void {
        // Check for cards in the players hand
        if (self.hand.current_card_index == 0) {
            print("\nNo Cards in hand\n", .{});
        } else {
            std.debug.print("\n{s} has cards:\n", .{self.name});
            // Loop through each card and its index
            // print out the index and its card
            // sum of the value of the cards in his hand while accounts for if there is an ace or not
            for (self.hand.cards[0..self.hand.current_card_index], 0..) |card, i| {
                if (card) |c| {
                    if (i == 0) {
                        print("{d}: ?\n", .{i + 1});
                    } else {
                        print("{d}: {s} of {s}\n", .{ i + 1, c.type, c.suit });
                    }
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

    // Uncomment this next line if you need to debug the cards so their orders are fixed each round
    // const prng = std.Random.DefaultPrng(0);

    // Comment this line out if you need to remove the randome seed for the random number generator
    const prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });

    const num_decks: u8 = 2;
    var deck = try Deck.init(allocator, num_decks, prng);
    deck.shuffle();

    const game = true;
    var game_menu = true;

    while (game) {
        while (game_menu) {
            try stdout.print("\n\n{s}\nWelcome to Blackjack\n{s}\nStart - (s) Exit - (e)\n\n", .{ MESSAGEDASH, MESSAGEDASH });

            const usr_input = ask_user_str(3, allocator);

            if (usr_input) |start_game| {
                if (eql(u8, "s", start_game[0 .. start_game.len - 1])) {
                    print("\n{s}\nInitialzing Game!\n{s}\n", .{ MESSAGEDASH, MESSAGEDASH });
                    game_menu = false;
                } else if (eql(u8, "e", start_game[0 .. start_game.len - 1])) {
                    print("\nExiting the game. Goodbye.\n\n", .{});
                    std.process.exit(200);
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
        }
        print("What is your name?\n", .{});
        const player_name = try ask_user_str(30, allocator);

        print("\nHow much money would you like to put in your wallet?\n", .{});
        const player_wallet = try ask_user_int(10, allocator);

        var player1 = Player.init(player_name[0 .. player_name.len - 1], player_wallet);
        var dealer = Player.init("Dealer", 1_000_000_000);
        print("\nGame Start\n\n", .{});

        while (player1.money > 0) {
            print("Money: {d}", .{player1.money});
            print("\nWhat would you like to bet?\n$5 - (1)  $10 - (2)  $25 - (3)  $100 - (4)  Custom - (5)\n", .{});
            const bet_decision = try ask_user_int(20, allocator);
            var bet_amt: u32 = switch (bet_decision) {
                1 => blk: {
                    const r: u32 = 5;
                    if (r > player1.money) {
                        print("\nYou don't have enough money to make that bet\n", .{});
                        continue;
                    }
                    print("\nYou've bet: $5\n", .{});
                    break :blk r;
                },
                2 => blk: {
                    const r: u32 = 10;
                    if (r > player1.money) {
                        print("\nYou don't have enough money to make that bet\n", .{});
                        continue;
                    }
                    print("\nYou've bet: $10\n", .{});
                    break :blk r;
                },
                3 => blk: {
                    const r: u32 = 25;
                    if (r > player1.money) {
                        print("\nYou don't have enough money to make that bet\n", .{});
                        continue;
                    }
                    print("\nYou've bet: $25\n", .{});
                    break :blk r;
                },
                4 => blk: {
                    const r: u32 = 100;
                    if (r > player1.money) {
                        print("\nYou don't have enough money to make that bet\n", .{});
                        continue;
                    }
                    print("\nYou've bet: $100\n", .{});
                    break :blk r;
                },
                5 => blk: {
                    print("What would you like to bet?\n", .{});
                    const r: u32 = try ask_user_int(30, allocator);
                    if (r > player1.money) {
                        print("\nYou don't have enough money to make that bet\n", .{});
                        continue;
                    }
                    print("\nYou've bet: {d}\n", .{bet_decision});
                    break :blk r;
                },
                else => blk: {
                    print("\nNot a valid input\n", .{});
                    const r: u32 = 0;
                    break :blk r;
                },
            };
            dealer.draw_card(&deck);
            dealer.draw_card(&deck);
            dealer.print_second_card();

            player1.draw_card(&deck);
            player1.draw_card(&deck);
            player1.print_hand();
            player1.money -= bet_amt;

            var surrender = false;

            while (player1.get_hand_total() < 22) {
                //TODO add the ability to split a hand
                print("\nWhat would you like to do?\nHit - (1)  Double Down - (2)  Stand - (3)  Surrender - (4)\n", .{});

                // Get user action
                const action = try ask_user_int(20, allocator);
                switch (action) {
                    1 => {
                        print("You've choosen to hit.\n", .{});
                        player1.draw_card(&deck);
                        dealer.print_second_card();
                        player1.print_hand();
                    },
                    2 => {
                        if (bet_amt > player1.money) {
                            print("You don't have enough money to double down\n\n", .{});
                            continue;
                        }
                        player1.money -= bet_amt;
                        bet_amt = bet_amt * 2;
                        print("You've double downed\nYour new bet is ${d}\n", .{bet_amt});
                        player1.draw_card(&deck);
                        dealer.print_second_card();
                        player1.print_hand();
                        break;
                    },
                    3 => {
                        print("You've choosen to stand\n", .{});
                        break;
                    },
                    4 => {
                        print("\nYou've choosen to Surrender", .{});
                        surrender = true;
                        break;
                    },
                    else => {
                        print("\nNot a valid input", .{});
                    },
                }
            }

            if (surrender) {
                player1.money += bet_amt / 2;
                player1.clear_hand();
                dealer.clear_hand();
                continue;
            }

            const p_hand_total: u32 = player1.get_hand_total();

            // If the player busts after breaking out of his turn
            // They immediately lose all bets made on that hand and the players round ends
            if (p_hand_total > 21) {
                print("You've bust\n\n", .{});
                player1.money -= bet_amt;
                player1.clear_hand();
                dealer.clear_hand();
                continue;
            }

            print("\n{s}\nDealer is taking his turn\n{s}\n", .{ MESSAGEDASH, MESSAGEDASH });
            dealer.print_hand();

            // If the player doesn't bust then the dealer starts his turn
            while (dealer.get_hand_total() < 22) {
                std.time.sleep(2_000_000_000);
                const d_hand_total: u32 = dealer.get_hand_total();
                if (d_hand_total <= 16) {
                    print("Dealer hits\n", .{});
                    dealer.draw_card(&deck);
                    dealer.print_hand();
                } else {
                    break;
                }
            }

            const d_hand_total: u32 = dealer.get_hand_total();

            if (d_hand_total > 21) {
                print("Dealer busts, you win!\n\n", .{});
                player1.money += bet_amt * 2;
                player1.clear_hand();
                dealer.clear_hand();
                continue;
            }

            if (p_hand_total > d_hand_total) {
                print("You've won!\n\n", .{});
                player1.money += bet_amt * 2;
                player1.clear_hand();
                dealer.clear_hand();
                continue;
            } else if (p_hand_total == d_hand_total) {
                print("Push\n\n", .{});
                player1.money += bet_amt;
                player1.clear_hand();
                dealer.clear_hand();
                continue;
            } else {
                print("You've lost\n\n", .{});
                player1.money -= bet_amt;
                player1.clear_hand();
                dealer.clear_hand();
                continue;
            }
        }
    }
    deck.deinit(allocator);
}
