# ABSTRACT: Client for Tic-Tac-Toe (AKA X's and O's, Naughts and Crosses, 3,3,3-game)

use MUGS::Core;
use MUGS::Client::Genre::MNKGame;


#| Client side of Tic-Tac-Toe game
class MUGS::Client::Game::TicTacToe is MUGS::Client::Genre::MNKGame {
    method game-type() { 'tic-tac-toe' }
}


# Register this class as a valid client
MUGS::Client::Game::TicTacToe.register;
