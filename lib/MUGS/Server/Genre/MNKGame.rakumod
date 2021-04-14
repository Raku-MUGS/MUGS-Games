# ABSTRACT: General server for M,N,K games (https://en.wikipedia.org/wiki/M,n,k-game)

use MUGS::Core;
use MUGS::Server::Genre::RectangularBoard;

#| Server side of M,N,K games
class MUGS::Server::Genre::MNKGame is MUGS::Server::Genre::RectangularBoard {
    has UInt:D $.k       = self.default-k;  #= Number in a row to win
    has Bool:D $.exact-k = False;           #= Whether win must have exact length K

    my constant @directions =
        ('ul', -1, -1), ('u', 0, -1), ('ur', +1, -1),
        ( 'l', -1,  0),               ( 'r', +1,  0),
        ('dl', -1, +1), ('d', 0, +1), ('dr', +1, +1);

    method genre-tags() { (|callsame, 'mnk-game') }
    method default-k()  { min(self.width, self.height) }

    method config-form() {
        my $form = callsame;
        self.change-config-default(:$form, :field('min-players'),   :default(2));
        self.change-config-default(:$form, :field('max-players'),   :default(2));
        self.change-config-default(:$form, :field('start-players'), :default(2));
        self.change-config-default(:$form, :field('allow-joins-after-start'), :default(False));
        $form
    }

    # Set the starting board contents to empty in all cells
    method setup-starting-layout() {
        for @($.board<contents>) -> @row {
            @row[$_] = '' for ^@row;
        }
    }

    method ensure-move-valid($move) {
        callsame;

        my ($col, $row) = self.parse-move($move);
        self.invalid-move($move, 'Cell already occupied.') if self.at-cell($col, $row);
    }

    method process-move(:$character, :$move) {
        my ($col, $row) = self.parse-move($move);
        self.set-cell($col, $row, $character.screen-name);

        if self.is-win-at($col, $row) {
            self.set-winloss(Win,  $character);
            self.set-winloss(Loss, $_) for @.play-order.tail;
            self.set-gamestate(Finished);
        }
        elsif self.board-full {
            self.set-winloss(Tie,  $_) for @.play-order;
            self.set-gamestate(Finished);
        }

        ()
    }

    method is-win-at(UInt:D $col, UInt:D $row,
                     $character = self.at-cell($col, $row)) {
        # Count length of runs of same character's pieces in each direction
        my %count;
        for @directions -> ($dir, $dx, $dy) {
            %count{$dir} = 0;
            my $c = $col + $dx;
            my $r = $row + $dy;
            while 1 <= $c <= $.width && 1 <= $r <= $.height {
                last unless $character eq self.at-cell($c, $r);
                %count{$dir}++;
                $c += $dx;
                $r += $dy;
            }
        }

        # Add counts in each opposite pair of directions (plus center) to check
        # for winning length (either exact or "at least")
        if $.exact-k {
            (%count<u>  + %count<d>  + 1 == $.k) ||
            (%count<l>  + %count<r>  + 1 == $.k) ||
            (%count<ul> + %count<dr> + 1 == $.k) ||
            (%count<dl> + %count<ur> + 1 == $.k)
        }
        else {
            (%count<u>  + %count<d>  + 1 >= $.k) ||
            (%count<l>  + %count<r>  + 1 >= $.k) ||
            (%count<ul> + %count<dr> + 1 >= $.k) ||
            (%count<dl> + %count<ur> + 1 >= $.k)
        }
    }

    method board-full() {
        for 1..$.height -> $row {
            for 1..$.width -> $col {
                return False unless self.at-cell($col, $row);
            }
        }

        True
    }
}
