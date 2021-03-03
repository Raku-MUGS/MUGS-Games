# ABSTRACT: Client for Snowman word guessing game

use MUGS::Core;
use MUGS::Client::Genre::Guessing;


#| Client side of Snowman word guessing game
class MUGS::Client::Game::Snowman is MUGS::Client::Genre::Guessing {
    method game-type()             { 'snowman' }
    method valid-guess($guess)     { $guess ~~ /^ <:alpha> $/ }
    method canonical-guess($guess) { $guess.lc }
    method initial-state-format()  { :(UInt:D :$misses!, Str:D :$partial!,
                                       UInt:D :$length!, :@tried!, *%) }
    method response-format()       { :(UInt:D :$misses!, Str:D :$partial!,
                                       Bool :$correct, :@tried!, *%) }

    method !ensure-guesses-all-single-characters(@guesses) {
        die "List of guessed characters contains a non-string"
            if @guesses.grep(* !~~ Str);
        die "List of guessed characters contains an undefined value"
            if @guesses.grep(!*.defined);
        die "List of guessed characters contains a string with length not exactly one character"
            if @guesses.grep(*.chars != 1);
    }

    method ensure-initial-state-valid() {
        callsame;
        self!ensure-guesses-all-single-characters($.initial-state<tried>);
    }

    method ensure-response-valid($response) {
        callsame;
        self!ensure-guesses-all-single-characters($response.data<tried>);

        die "Miss count doesn't make sense"
            unless $response.data<misses> <= $response.data<turns>;
    }
}


# Register this class as a valid client
MUGS::Client::Game::Snowman.register;
