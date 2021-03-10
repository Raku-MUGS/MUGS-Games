# ABSTRACT: General server for simple guessing games

use MUGS::Core;
use MUGS::Server::Genre::TurnBased;


#| Server side of guessing game
class MUGS::Server::Genre::Guessing is MUGS::Server::Genre::TurnBased {
    has UInt:D $.misses is rw = 0;
    has        @.tried;

    method genre-tags() { (|callsame, 'guessing') }

    method ensure-guess-valid(::?CLASS:D: $guess)            { ... }
    method process-guess(::?CLASS:D: :$character!, :$guess!) { ... }

    method valid-action-types() { < nop guess > }

    method ensure-action-valid(::?CLASS:D: MUGS::Character:D :$character!, :$action!) {
        callsame;

        if $action<type> eq 'guess' {
            X::MUGS::Request::MissingData.new(:field<guess>).throw
                unless $action<guess>.defined;

            self.ensure-guess-valid($action<guess>);

            X::MUGS::Request::AdHoc.new(message => "Guess has already been tried.").throw
                if $action<guess> ∈ @.tried;
        }
    }

    method process-action-guess(::?CLASS:D: MUGS::Character:D :$character!, :$action!) {
        $.turns++;
        @!tried.push($action<guess>);
        self.process-guess(:$character, :guess($action<guess>))
    }

    method game-status(::?CLASS:D: $action-result) {
        hash(|callsame, :$.misses, :@.tried);
    }
}
