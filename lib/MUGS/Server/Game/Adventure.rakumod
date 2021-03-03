# ABSTRACT: Server for IF adventure games

use MUGS::Core;
use MUGS::Message;
use MUGS::Server::Genre::IF;
use MUGS::Server::Game::Adventure::Loader;
use MUGS::Server::Game::Adventure::CommandParser;

use RPG::Base;
use RPG::Base::Container;
use RPG::Base::Location;
use RPG::Base::Creature;
use RPG::Base::AreaMap;



#| An character wrapped in game-specific extras
class MUGS::Server::Game::Adventure::CharacterInstance is RPG::Base::Creature {
    has MUGS::Character:D $.character is required;

    #| Reflect character's screen name
    method name(::?CLASS:D:) {
        $.character.screen-name
    }

    #| Things visible to this instance
    method visible-things(::?CLASS:D:) {
        my @things = $.container.contents.grep(* !=== self)
    }

    #| Things known to this instance (inventory and visible objects)
    method known-things(::?CLASS:D:) {
        my @things = |@.contents, |self.visible-things
    }

    #| Find a known thing by its name
    method known-thing-named(::?CLASS:D: Str:D $name) {
        self.known-things.first(*.name.fc eq $name.fc)
    }
}

# Alias for brevity
constant \CharacterInstance = MUGS::Server::Game::Adventure::CharacterInstance;


#| Server side of IF adventure game
class MUGS::Server::Game::Adventure is MUGS::Server::Genre::IF {
    has Str                 $!name;
    has Str                 $!intro;
    has RPG::Base::AreaMap  %!maps;
    has RPG::Base::Location $!start;

    method game-type() { 'adventure' }
    method game-desc() { 'Interactive Fiction style adventuring' }

    method config-form() {
        my @form := callsame;

        @form.push:
            { field           => 'scenario',
              section         => 'Mission',
              desc            => 'Scenario to play',
              type            => Str,
              default         => 'new-path',
              visible-locally => True,
              validate        => {
                    MUGS::Server::Game::Adventure::Loader.scenario-exists(.<scenario>)
                },
            };

        @form
    }


    ### GAME CREATION

    submethod TWEAK() {
        self.load-adventure;
    }

    method load-adventure() {
        my $scenario-name = %.config<scenario>;
        my $loader = MUGS::Server::Game::Adventure::Loader.new(:$scenario-name);
        my $loaded = $loader.load-scenario;

        ($!name, $!intro, $!start) = $loaded<title intro start>;
        %!maps                    := $loaded<maps>;
    }


    ### CHARACTER JOINS

    method wrap-character(MUGS::Character:D $character) {
        my $instance = CharacterInstance.new(:$character);
        $!start.add-thing($instance);
        $instance
    }

    method initial-state(::?CLASS:D: MUGS::Character:D :$character) {
        my $instance = self.instance-for-character($character);
        my $details  = self.location-details($instance.container);
        { :pre-title($!name), :pre-message($!intro), :location($details), |callsame }
    }


    ### ENGINE HELPERS

    #| Throw a generic failure exception, indicating why an action failed
    method fail(Str:D $message) {
        X::MUGS::Request::AdHoc.new(:$message).throw;
    }

    #| Collect visible information about a Location
    method location-details(RPG::Base::Location:D $location) {
        my @exits      = $location.exits.keys.sort;
        my @things     = $location.contents.grep(* !~~ CharacterInstance).map(*.name);
        my @characters = $location.contents.grep(*  ~~ CharacterInstance).map(*.name);

        {
            name        => $location.name,
            description => $location.desc,
            :@exits,
            :@things,
            :@characters,
        }
    }


    ### CHARACTER ACTIONS

    #| Move character to a new location
    method move-character(CharacterInstance:D $instance, Str:D $dir) {
        CATCH {
            when X::RPG::Base::Location::Blocked {
                self.fail("Cannot go $dir because you are blocked by the $_.block.lc().");
            }
            default { .rethrow }
        }

        $instance.container.move-thing($dir => $instance);
    }

    #| Look at a creature's inventory
    method inventory(RPG::Base::Creature:D $creature) {
        { inventory => $creature.contents.map(*.name) }
    }

    #| Attempt to lock a thing
    method lock-thing(MUGS::Server::Game::Adventure::Thing:D $thing) {
        my $name = $thing.name.lc;
        when $thing.options<locked> {
            self.fail("The $name was already locked.")
        }
        when $thing.options<locked>.defined {
            $thing.options<locked> = True;
            { message => "The $name is now locked." }
        }
        default {
            self.fail("The $name does not have a lock.")
        }
    }

    #| Attempt to unlock a thing
    method unlock-thing(MUGS::Server::Game::Adventure::Thing:D $thing) {
        my $name = $thing.name.lc;
        when $thing.options<locked> {
            $thing.options<locked> = False;
            { message => "The $name is now unlocked." }
        }
        when $thing.options<locked>.defined {
            self.fail("The $name was not locked.")
        }
        default {
            self.fail("The $name does not have a lock.")
        }
    }

    ### COMMAND PARSING/PROCESSING

    #| Compute a parsing context for this character at the current game state
    method parsing-context(::?CLASS:D: MUGS::Character:D :$character!) {
        my $instance = self.instance-for-character($character);
        my @exits    = $instance.container.exits.keys;
        my @items    = $instance.known-things.map(*.name.fc);

        MUGS::Server::Game::Adventure::CommandParser::Context.new(:@exits, :@items)
    }

    #| Parse a single command in a given context
    method parse-command(Str:D $input, $*ctx) {
        my $actions = MUGS::Server::Game::Adventure::CommandParser::Actions;
        MUGS::Server::Game::Adventure::CommandParser.parse($input.fc, :$actions);
    }

    #| Process the parsed player command
    method process-player-command(CharacterInstance:D $instance, Str:D $command, @args) {
        given $command {
            when 'quit'      { self.set-gamestate(Finished); {} }
            when 'go'        { self.move-character($instance, @args[0]); {} }
            when 'inventory' { self.inventory($instance) }
            when 'look'      { {} }
            when 'lock'      { self.lock-thing(  $instance.known-thing-named(@args[0])) }
            when 'unlock'    { self.unlock-thing($instance.known-thing-named(@args[0])) }
            default          { self.fail("I can't handle that command yet.") }
        }
    }

    #| Validate and parse the input, and respond with a game update
    method process-unparsed-input(::?CLASS:D: MUGS::Character:D :$character!,
                                  Str:D :$input!, :$context) {
        # XXXX: Need a better exception class
        my $parsed = self.parse-command($input, $context)
            or X::MUGS::Request::AdHoc.new(:message('Could not parse your input')).throw;

        my ($command, @args) = |$parsed.made;
        my $instance  = self.instance-for-character($character);
        my %result   := self.process-player-command($instance, $command, @args);
        ++$.turns;

        %result<location> = self.location-details($instance.container);

        %result
    }
}


# Register this class as a valid server class
MUGS::Server::Game::Adventure.register;
