# ABSTRACT: General server for card games

use MUGS::Core;
use MUGS::Server::Genre::TurnBased;


#| An individual playing card
class MUGS::PlayingCard {
    has $.suit;
    has $.rank;
    has $.numeric-rank;
}


#| Server side of card games
class MUGS::Server::Genre::CardGame is MUGS::Server::Genre::TurnBased {
    has MUGS::PlayingCard:D @.unshuffled-deck;
    has MUGS::PlayingCard:D @.deck;

    method genre-tags() { (|callsame, 'card') }

    method initialize-deck() { ... }
    method deal-hands()      { ... }

    submethod TWEAK() {
        self.initialize-deck;
    }

    method shuffle-deck() {
        @.deck = @.unshuffled-deck.pick(*);
    }
}


#| A card from the standard 52- or 56-card French-suited decks supported by Unicode
class MUGS::StandardPlayingCard is MUGS::PlayingCard {
    has $.unicode;
}

#| Games that use a standard 52-card deck
role MUGS::Server::Genre::CardGame::Standard52CardDeck {
    method initialize-deck() {
        @.unshuffled-deck = Empty;
        for < ♠‭ ♡‭ ♢‭ ♣‭ >.kv -> $i, $suit {
            for < A 2 3 4 5 6 7 8 9 10 J Q K >.kv -> $j, $rank {
                my $unicode = chr(0x1F0A1 + 16 * $i + $j + ?($rank eq 'Q'|'K'));
                @.unshuffled-deck.push:
                    MUGS::StandardPlayingCard.new(:$rank, :$suit, :$unicode,
                                                  :numeric-rank($j+1));
            }
        }
    }
}
