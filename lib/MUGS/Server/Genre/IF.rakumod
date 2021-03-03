# ABSTRACT: General server for IF (Interactive Fiction) games

use MUGS::Core;
use MUGS::Identity;
use MUGS::Server::Genre::TurnBased;


#| Server side of IF (Interactive Fiction) games
class MUGS::Server::Genre::IF is MUGS::Server::Genre::TurnBased {
    method genre-tags() { (|callsame, 'interactive-fiction') }

    method parsing-context(::?CLASS:D: :$character!)                  { ... }
    method process-unparsed-input(::?CLASS:D: :$character!, :$input!) { ... }

    method valid-action-types() { < nop unparsed-input > }

    method ensure-action-valid(::?CLASS:D: MUGS::Character:D :$character!, :$action!) {
        callsame;

        if $action<type> eq 'unparsed-input' {
            my $input = $action<input>;
            X::MUGS::Request::MissingData.new(:field<input>).throw
                unless $input;
            X::MUGS::Request::InvalidDataType.new(:field<input>, :type(Str)).throw
                unless $input ~~ Str;
            X::MUGS::Request::AdHoc.new(message => 'Input is empty').throw
                unless $input.trim;
        }
    }

    method process-action-unparsed-input(::?CLASS:D: MUGS::Character:D :$character!, :$action!) {
        $.turns++;
        my $context = self.parsing-context(:$character);
        self.process-unparsed-input(:$context, :$character,
                                    :input($action<input>));
    }
}
