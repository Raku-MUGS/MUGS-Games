# ABSTRACT: General server for turn-based games

use MUGS::Core;
use MUGS::Server;


#| Server side of turn-based games
class MUGS::Server::Genre::TurnBased is MUGS::Server::Game {
    has UInt:D            $.turns      is rw = 0;
    has MUGS::Character:D @.play-order;

    method genre-tags() { (|callsame, 'turn-based') }

    method add-character(::?CLASS:D: MUGS::Character:D :$character!,
                         MUGS::Server::Session:D :$session!) {
        callsame;
        @!play-order.push($character);
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
        self.next-character;
    }

    method game-status(::?CLASS:D: $action-result) {
        my $next           = @.play-order[0];
        my $next-character = $next ?? $next.screen-name !! '';

        hash(|callsame, :$!turns, :$next-character)
    }
}
