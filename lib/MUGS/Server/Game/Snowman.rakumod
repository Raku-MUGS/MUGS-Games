# ABSTRACT: Server class for Snowman word guessing game

use MUGS::Core;
use MUGS::Server::Genre::Guessing;


#| Server side of Snowman word guessing game
class MUGS::Server::Game::Snowman is MUGS::Server::Genre::Guessing {
    has IO::Path $.wordlist     = '/usr/share/dict/words'.IO;
    has          @.words        = $!wordlist.words.grep(/^ <[a..z]>+ $/);

    has UInt:D   $!max-length   = (self.config<difficulty> || 1) + 2;
    has UInt:D   $!min-length   = self.config<progressive> ?? 3 !! $!max-length;
    has UInt:D   $!start-length = $!min-length;
    has UInt:D   $!cur-length   = $!start-length;
    has Str      $!word;

    has WinLoss  @.round-results;


    method game-type() { 'snowman' }
    method game-desc() { 'Letter-by-letter word guessing' }

    method config-form() {
        my @form := callsame;

        @form.push:
            { field           => 'difficulty',
              section         => 'Challenge',
              desc            => 'Difficulty (affects word length)',
              type            => UInt,
              default         => 5,
              visible-locally => True,
            },
            { field           => 'progressive',
              section         => 'Challenge',
              desc            => 'Progressive mode (multiple rounds, changing word length)',
              type            => Bool,
              default         => False,
              visible-locally => True,
            },
            { field           => 'penalize-loss',
              section         => 'Challenge',
              desc            => 'Penalize losses in progressive mode',
              type            => Bool,
              default         => False,
              visible-locally => True,
            };

        @form
    }

    method start-game(::?CLASS:D:) {
        callsame;
        self.start-round;
    }

    method start-round(::?CLASS:D:) {
        @.tried  = Empty;
        $.misses = 0;
        @!round-results.push: Undecided;

        self.update-cur-length;
        self.pick-new-word;
    }

    method update-cur-length(::?CLASS:D:) {
        my $prev-round = @!round-results[*-2] // Undecided;
        my $penalty    = self.config<penalize-loss> * ($!cur-length > $!min-length) * -1;

        $!cur-length  += $prev-round == Loss ?? $penalty !! $prev-round == Win;
    }

    method pick-new-word(::?CLASS:D:) {
        $!word = @!words.grep(*.chars == $!cur-length).pick;
    }

    method ensure-guess-valid(::?CLASS:D: $guess) {
        X::MUGS::Request::AdHoc.new(message => "Guess is not a single character string").throw
            unless $guess && $guess ~~ Str && $guess.chars == 1;
    }

    method partial(::?CLASS:D:) {
        $!word.comb.map({ $_ ∈ @.tried ?? $_ !! '_' }).join
    }

    method process-guess(::?CLASS:D: :$character, :$guess) {
        my $correct = $guess ∈ $!word.comb;
        $.misses   += !$correct;

        self.maybe-end-round;

        hash(:$correct)
    }

    method maybe-end-round(::?CLASS:D:) {
        if self.round-result -> $winloss {
            @!round-results[*-1] = $winloss;

            if $!cur-length == $!max-length {
                if $winloss == Win
                || !self.config<progressive> {
                    self.set-winloss($winloss);
                }
                else {
                    self.start-round;
                }
            }
        }
    }

    method round-result(::?CLASS:D:) {
        $.partial eq $!word ?? Win       !!
        $.misses  >= 6      ?? Loss      !!
                               Undecided
    }

    method game-status(::?CLASS:D: $action-result) {
        hash(|callsame, :length($!word.chars), :$.partial, :@!round-results);
    }
}


# Register this class as a valid server class
MUGS::Server::Game::Snowman.register;
