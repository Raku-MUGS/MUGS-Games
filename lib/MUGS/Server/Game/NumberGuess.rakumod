# ABSTRACT: Server class for number-guess game

use MUGS::Core;
use MUGS::Server::Genre::Guessing;


#| Server side of number guessing game
class MUGS::Server::Game::NumberGuess is MUGS::Server::Genre::Guessing {
    has UInt $.num = (self.config<min> .. self.config<max>).pick;

    method game-type() { 'number-guess' }
    method game-desc() { 'High/low number guessing' }

    method config-form() {
        my @form := callsame;

        @form.push:
            { field           => 'min',
              section         => 'Challenge',
              desc            => 'Minimum possible number',
              type            => UInt,
              default         => 1,
              visible-locally => True,
            },
            { field           => 'max',
              section         => 'Challenge',
              desc            => 'Maximum possible number',
              type            => UInt,
              default         => 100,
              visible-locally => True,
              validate        => { .<max> >= .<min> },
            };

        @form
    }

    method initial-state(::?CLASS:D:) {
        my ($min, $max) = %.config< min max >;
        { :$min, :$max, |callsame }
    }

    method ensure-guess-valid(::?CLASS:D: $guess) {
        my ($min, $max) = %.config< min max >;
        X::MUGS::Request::AdHoc.new(message => "Guess is not a natural number").throw
            unless $guess && $guess ~~ UInt;
        X::MUGS::Request::AdHoc.new(message => "Guess is out of range $min..$max").throw
            unless $min <= $guess <= $max;
    }

    method process-guess(::?CLASS:D: :$character, :$guess) {
        given $guess {
            when * < $!num { $.misses++; { :result(Less) } }
            when * > $!num { $.misses++; { :result(More) } }
            default        { self.set-winloss(Win); { :result(Same) } }
        }
    }
}


# Register this class as a valid server class
MUGS::Server::Game::NumberGuess.register;
