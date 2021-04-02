# ABSTRACT: General server for board games

use MUGS::Core;
use MUGS::Server::Genre::TurnBased;


### EXCEPTIONS

#| Board game move exceptions
class X::MUGS::BoardGame::Move is X::MUGS::Request {
    has $.move;

    method message() { "Unknown error processing requested move" }
}

#| Move can't be parsed as a recognizable move in this game
class X::MUGS::BoardGame::Move::Unparseable is X::MUGS::BoardGame::Move {
    method message() { "Move is unparseable" }
}

#| Move is parseable, but refers to locations not on the actual board
class X::MUGS::BoardGame::Move::InvalidLocation is X::MUGS::BoardGame::Move {
    has $.location;

    method message() { "Move refers to an invalid location" }
}

#| Move is parseable and syntactically valid, but doesn't make sense in current game state
class X::MUGS::BoardGame::Move::Invalid is X::MUGS::BoardGame::Move {
    has Str:D $.reason is required;

    method message() { "Move is invalid: $.reason" }
}



### GENRE CLASS

#| Server side of board games
class MUGS::Server::Genre::BoardGame is MUGS::Server::Genre::TurnBased {
    has $.board is rw;
    has @.moves;


    method genre-tags() { (|callsame, 'board') }

    method initialize-board()       { ... }
    method setup-starting-layout()  { ... }
    method parse-move($move)        { ... }
    method ensure-move-valid($move) { ... }
    method process-move($move)      { ... }

    method start-game() {
        self.initialize-board;
        self.setup-starting-layout;
        callsame;
    }

    method valid-action-types() { < nop move > }

    method ensure-action-valid(::?CLASS:D: MUGS::Character:D :$character!, :$action!) {
        callsame;

        if $action<type> eq 'move' {
            X::MUGS::Request::MissingData.new(:field<move>).throw
                unless $action<move>;

            self.ensure-move-valid($action<move>);
        }
    }

    method process-action-move(::?CLASS:D: MUGS::Character:D :$character!, :$action!) {
        $.turns++;
        @.moves.push($action<move>);
        self.process-move(:$character, :move($action<move>));
    }


    # Exception helpers

    method unparseable-move($move) {
        X::MUGS::BoardGame::Move::Unparseable.new(:$move).throw;
    }

    method invalid-board-location($move, $location) {
        X::MUGS::BoardGame::Move::InvalidLocation.new(:$move, :$location).throw;
    }

    method invalid-move($move, Str:D $reason) {
        X::MUGS::BoardGame::Move::Invalid.new($move, $reason).throw;
    }
}
