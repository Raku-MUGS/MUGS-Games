# ABSTRACT: General client for board games

use MUGS::Core;
use MUGS::Client::Genre::TurnBased;


#| Client side of board games
class MUGS::Client::Genre::BoardGame is MUGS::Client::Genre::TurnBased {
    method submit-turn(Str:D $move, &on-success?) {
        self.action-promise(hash(:type<move>, :$move), &on-success);
    }
}
