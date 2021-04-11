# ABSTRACT: Command parser for IF adventure game

# use Grammar::Tracer;

my %abbr = northwest => 'nw', north => 'n', northeast => 'ne',
                west =>  'w',                    east =>  'e',
           southwest => 'sw', south => 's', southeast => 'se';
my %long = %abbr.invert;


#| Context for parsing (room exits, visible items, etc.)
class MUGS::Server::Game::Adventure::CommandParser::Context {
    # These should be compiled from a combination of character state (such as
    # inventory) and location information (such as exits and visible items)
    has @.items;
    has @.exits;
}


#| A single player command
grammar MUGS::Server::Game::Adventure::CommandParser {
    rule TOP { ^ <command> $ }

    proto rule command          {*}
    rule command:sym<quit>      { [ 'q' | <sym> ] }
    rule command:sym<inventory> { [ 'i' | <sym> ] }
    rule command:sym<look>      { <sym> }
    rule command:sym<lock>      { <sym> <thing=@($*ctx.items)> }
    rule command:sym<unlock>    { <sym> <thing=@($*ctx.items)> }
    rule command:sym<go>        { <sym>?
                                  [
                                  | <exit=@($*ctx.exits)>
                                  | <short=@(%abbr{$*ctx.exits}.grep(?*))>
                                  ] }
}


#| Actions for CommandParser grammar
class MUGS::Server::Game::Adventure::CommandParser::Actions {
    method TOP($/)                    { make $<command>.made }
    method command:sym<quit>($/)      { make 'quit' }
    method command:sym<inventory>($/) { make 'inventory' }
    method command:sym<look>($/)      { make 'look' }
    method command:sym<lock>($/)      { make ('lock',   ~$<thing>) }
    method command:sym<unlock>($/)    { make ('unlock', ~$<thing>) }
    method command:sym<go>($/)        { $<exit> ?? make ('go', ~$<exit>)
                                                !! make ('go', %long{~$<short>}) }
}
