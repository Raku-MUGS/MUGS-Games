# ABSTRACT: General client for simple guessing games

use MUGS::Core;
use MUGS::Client::Genre::TurnBased;


#| Client side of guessing game
class MUGS::Client::Genre::Guessing is MUGS::Client::Genre::TurnBased {
    method valid-guess($guess)     { False }
    method canonical-guess($guess) { $guess }
    method initial-state-format()  { ... }
    method response-format()       { ... }

    method send-guess($guess, &on-success) {
        self.action-promise(self.guess-action($guess), &on-success).then: {
            if .status == Kept {
                await self.leave if .result.data<gamestate> >= Finished
            }
            else {
                .cause.rethrow
            }
        }
    }

    method guess-action($guess) {
        { :type<guess>, :guess(self.canonical-guess($guess)) }
    }

    method ensure-initial-state-valid() {
        my $base-format = :(UInt:D :$turns!,
                            :$winloss!   where { WinLoss::{$_}.defined },
                            :$gamestate! where { GameState::{$_}.defined }, *%);

        die "Invalid base initial state format; $.initial-state.raku() !~~ $base-format.raku()"
            unless $.initial-state ~~ $base-format;
        die "Invalid game-specific initial state format; $.initial-state.raku() !~~ {self.initial-state-format.raku}"
            unless $.initial-state ~~ self.initial-state-format;
    }

    method ensure-response-valid($response) {
        my $base-format = :(UInt:D :$turns!,
                            :$winloss!   where { WinLoss::{$_}.defined },
                            :$gamestate! where { GameState::{$_}.defined }, *%);

        die "Invalid base response format; $response.data.raku() !~~ $base-format.raku()"
            unless $response.data ~~ $base-format;

        # XXXX: Format of NOP response, or other response types?
        die "Invalid game-specific response format; $response.data.raku() !~~ {self.response-format.raku}"
            unless $response.data ~~ self.response-format;
    }

    method canonify-initial-state() {
        self.ensure-initial-state-valid;
        callsame;
    }

    method canonify-response($response) {
        self.ensure-response-valid($response);
        callsame;
    }
}
