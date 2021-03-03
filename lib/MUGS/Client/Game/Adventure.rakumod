# ABSTRACT: Client for IF adventure games

use MUGS::Core;
use MUGS::Client::Genre::IF;


#| Client side of IF adventure game
class MUGS::Client::Game::Adventure is MUGS::Client::Genre::IF {
    method game-type() { 'adventure' }
}


# Register this class as a valid client
MUGS::Client::Game::Adventure.register;
