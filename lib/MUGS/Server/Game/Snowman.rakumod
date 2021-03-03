# ABSTRACT: Server class for Snowman word guessing game

use MUGS::Core;
use MUGS::Server::Genre::Guessing;


#| Server side of Snowman word guessing game
class MUGS::Server::Game::Snowman is MUGS::Server::Genre::Guessing {
    has UInt     $.min-length = self.config<difficulty> + 2;
    has UInt     $.max-length = $!min-length;
    has IO::Path $.wordlist   = '/usr/share/dict/words'.IO;
    has          @.words      = $!wordlist.words;
    has Str      $.word       = @!words.grep($!min-length <= *.chars <= $!max-length)
                                       .grep(/^ <[a..z]>+ $/).pick.lc;

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
            };

        @form
    }

    method ensure-guess-valid(::?CLASS:D: $guess) {
        X::MUGS::Request::AdHoc.new(message => "Guess is not a single character string").throw
            unless $guess && $guess ~~ Str && $guess.chars == 1;
    }

    method partial(::?CLASS:D:) {
        $!word.comb.map({ $_ ∈ @.tried ?? $_ !! '_' }).join
    }

    method process-guess(::?CLASS:D: :$character, :$guess) {
        my $partial = self.partial;
        my $correct = $guess ∈ $!word.comb;
        $.misses   += !$correct;

        self.set-winloss($partial eq $!word ?? Win       !!
                         $.misses >= 6      ?? Loss      !!
                                               Undecided);
        hash(:$correct)
    }

    method game-status(::?CLASS:D: $action-result) {
        hash(|callsame, :length($!word.chars), :$.partial);
    }
}


# Register this class as a valid server class
MUGS::Server::Game::Snowman.register;
