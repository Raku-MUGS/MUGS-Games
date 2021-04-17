# ABSTRACT: Server for particle effect tech test

use MUGS::Core;
use MUGS::Server::Genre::Test;


#| Server side of PFX tech test "game"
class MUGS::Server::Game::PFX is MUGS::Server::Genre::Test {
    method game-type() { 'pfx' }
    method game-desc() { 'Test "game" that generates particle effects' }

    method valid-action-types() { < nop pause > }

    method ensure-action-valid(::?CLASS:D: MUGS::Character:D :$character!, :$action!) {
        callsame;
    }

    method process-action-pause(::?CLASS:D: MUGS::Character:D :$character!, :$action!) {
        self.set-gamestate($.gamestate == Paused ?? InProgress !! Paused);
        Empty
    }

    method state-info() {
        hash()
    }

    method start-game() {
        callsame;

        start react whenever Supply.interval(.1) {
            done if $.gamestate >= Finished;

            my %update := self.state-info;
            for self.participants -> (:$character, :$session, :$instance) {
                $session.push-game-update(:game-id($.id), :$character, :%update);
            }
        }
    }
}


# Register this class as a valid server class
MUGS::Server::Game::PFX.register;
