# ABSTRACT: General client for Interactive Fiction games

use MUGS::Core;
use MUGS::Client::Genre::TurnBased;


#| Client side of Interactive Fiction games
class MUGS::Client::Genre::IF is MUGS::Client::Genre::TurnBased {
    # XXXX: For now, just always pass through the unparsed input
    method valid-turn($turn) { True }

    method submit-turn($turn, &on-success?) {
        self.send-unparsed-input($turn, &on-success)
    }

    method send-unparsed-input(Str:D $input, &on-success?) {
        self.action-promise(hash(:type<unparsed-input>, :$input), &on-success);
    }
}
