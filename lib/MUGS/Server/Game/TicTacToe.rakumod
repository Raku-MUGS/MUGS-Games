# ABSTRACT: Server for Tic-Tac-Toe (AKA X's and O's, Naughts and Crosses, 3,3,3-game)

use MUGS::Core;
use MUGS::Server::Genre::MNKGame;


#| Server side of Tic-Tac-Toe game
class MUGS::Server::Game::TicTacToe is MUGS::Server::Genre::MNKGame {
    method game-type()     { 'tic-tac-toe' }
    method game-desc()     { "Tic-Tac-Toe, Naughts and Crosses, or X's and O's" }
    method default-width() { 3 }
}


# Register this class as a valid server class
MUGS::Server::Game::TicTacToe.register;
