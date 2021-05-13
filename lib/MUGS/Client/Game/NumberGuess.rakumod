# ABSTRACT: Client for number-guess game

use MUGS::Core;
use MUGS::Client::Genre::Guessing;


#| Client side of number guessing game
class MUGS::Client::Game::NumberGuess is MUGS::Client::Genre::Guessing {
    method game-type()             { 'number-guess' }
    method valid-guess($guess)     { $guess ~~ /^ \d+ $/ }
    method canonical-guess($guess) { +$guess }
    method initial-state-format()  { :(UInt:D :$min!, UInt:D :$max!, *%) }
    method response-format()       { :(:$result where { !.defined || Order($_).defined }, *%) }

    method canonify-response($response) {
        callsame;
        $response.data<result> = Order($response.data<result>)
            if $response.data<result>.defined;
    }
}


# Register this class as a valid client
MUGS::Client::Game::NumberGuess.register;
