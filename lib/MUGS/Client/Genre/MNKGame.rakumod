# ABSTRACT: General client for M,N,K games (https://en.wikipedia.org/wiki/M,n,k-game)

use MUGS::Core;
use MUGS::Client::Genre::BoardGame;


#| Client side of M,N,K games
class MUGS::Client::Genre::MNKGame is MUGS::Client::Genre::BoardGame {
    method valid-turn($turn) {
        # XXXX: Validate
        True
    }
}
