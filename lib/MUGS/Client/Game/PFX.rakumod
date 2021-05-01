# ABSTRACT: Client for streaming particle effect updates

use MUGS::Core;
use MUGS::Client::Genre::Test;


#| Client side of PFX tech test "game"
class MUGS::Client::Game::PFX is MUGS::Client::Genre::Test {
    method game-type() { 'pfx' }

    method send-pause-request(&on-success?) {
        self.action-promise: hash(:type<pause>), &on-success;
    }
}


# Register this class as a valid client
MUGS::Client::Game::PFX.register;
