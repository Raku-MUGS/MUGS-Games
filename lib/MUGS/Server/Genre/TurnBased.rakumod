# ABSTRACT: General server for turn-based games

use MUGS::Core;
use MUGS::Server;


#| Server side of turn-based games
class MUGS::Server::Genre::TurnBased is MUGS::Server::Game {
    has UInt:D            $.turns          is rw = 0;
    has MUGS::Character:D @.play-order;
    has MUGS::Character:D @.initial-order;

    method genre-tags() { (|callsame, 'turn-based') }

    method start-game(::?CLASS:D:) {
        self.choose-initial-play-order;
        callsame;
    }

    method choose-initial-play-order(::?CLASS:D:) {
        @!initial-order = @!play-order .= pick(*);
    }

    method add-character(::?CLASS:D: MUGS::Character:D :$character!,
                         MUGS::Server::Session:D :$session!) {
        @!play-order.push($character);
        callsame;
    }

    method remove-character(::?CLASS:D: MUGS::Character:D $character) {
        callsame;
        @!play-order = @!play-order.grep(* !=== $character);
    }

    method next-character(::?CLASS:D:) {
        @.play-order.push(@.play-order.shift) if @.play-order > 1;
    }

    method ensure-action-valid(::?CLASS:D: MUGS::Character:D :$character!, :$action!) {
        callsame;

        if @.play-order && $action<type> ne 'nop' {
            my $next = @.play-order[0];
            die "Not your turn; $next.screen-name() is next" unless $next === $character;
        }
    }

    method post-process-action(::?CLASS:D: MUGS::Character:D :$character!,
                               :$action!, :$result!) {
        if $action<type> ne 'nop' {
            self.next-character;

            my %update := self.game-status( () );
            for self.participants -> (:character($c), :$session, :$instance) {
                next if $c === $character;
                $session.push-game-update(:game-id($.id), :character($c), :%update);
            }
        }
    }

    method game-status(::?CLASS:D: $action-result) {
        my @play-order     = @.play-order\  .map(*.screen-name);
        my @initial-order  = @.initial-order.map(*.screen-name);
        my $next-character = @play-order[0] || '';

        hash(|callsame, :$!turns, :$next-character,
             :@play-order, :@initial-order)
    }
}
