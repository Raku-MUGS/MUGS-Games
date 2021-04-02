# ABSTRACT: General server for board games played on a rectangular board

use MUGS::Core;
use MUGS::Server::Genre::BoardGame;


# NOTE: By convention in the code below, x/y are 0-based and col/row are 1-based


#| Server side of rectangular board games
class MUGS::Server::Genre::RectangularBoard is MUGS::Server::Genre::BoardGame {
    has UInt:D $.width  = self.default-width;   #= Number of files/columns
    has UInt:D $.height = self.default-height;  #= Number of ranks/rows

    method genre-tags() { (|callsame, 'rectangular') }

    method default-width()  { ... }
    method default-height() { self.default-width }

    method initialize-board() {
        my (@cells, @contents);

        for ^$.height -> $y {
            for ^$.width -> $x {
                @cells[   $y][$x] = self.make-cell($x+1, $y+1);
                @contents[$y][$x] = Nil;
            }
        }

        $.board = { :@cells, :@contents };
    }

    method make-cell(UInt:D $col, UInt:D $row) {
        my $cell-name = self.cell-name($col, $row);
        %( :$col, :$row, :$cell-name )
    }

    method cell-name(UInt:D $col, UInt:D $row) {
        my $col-name = $.width > 26 ?? "$col," !! ('a'..'z')[$col - 1];
        $col-name ~ $row
    }

    method at-cell(UInt:D $col, UInt:D $row) {
        $.board<contents>[$row-1][$col-1]
    }

    method set-cell(UInt:D $col, UInt:D $row, $contents) {
        $.board<contents>[$row-1][$col-1] = $contents;
    }

    method parse-move($move) {
        if    $move ~~ /^(\d+) ',' (\d+)$/ -> $/ { (+$0, +$1) }
        elsif $move ~~ /^(<[a..z]>)(\d+)$/ -> $/ { ((~$0).ord - 96, +$1) }
        else  { self.unparseable-move($move) }
    }

    method ensure-move-valid($move) {
        my ($col, $row) = self.parse-move($move);
        self.ensure-location-valid($move, $col, $row);
    }

    method ensure-location-valid($move, $col, $row) {
        self.invalid-board-location($move, ($col, $row))
            unless 1 <= $col <= $.width
                && 1 <= $row <= $.height;
    }

    method game-status(::?CLASS:D: $action-result) {
        hash(|callsame, :board($.board<contents>));
    }
}
