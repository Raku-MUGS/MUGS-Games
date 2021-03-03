# ABSTRACT: Loader for adventure scenario definitions

use MUGS::Core;
use MUGS::Message;
use MUGS::Util::File;
use MUGS::Server::Game::Adventure::Locations;

use RPG::Base::Thing;


#| A Thing with options (flags and key-value pairs)
class MUGS::Server::Game::Adventure::Thing is RPG::Base::Thing {
    has %.options;
}


#| Scenario file has invalid format
class X::MUGS::Server::Game::Adventure::Loader::InvalidFormat is X::MUGS {
    has Str:D $type     is required;
    has Str:D $filename is required;
    has Str:D $reason   is required;

    method message() { "$type.tclc() file '$filename' has an invalid format: $reason" }
}


#| Required scenario file is missing
class X::MUGS::Server::Game::Adventure::Loader::MissingFile is X::MUGS {
    has Str:D $type     is required;
    has Str:D $filename is required;

    method message() { "$type.tclc() file '$filename' is missing or unreadable" }
}


#| Adventure scenario loading methods
class MUGS::Server::Game::Adventure::Loader {
    has Str:D $.scenario-name is required;


    submethod TWEAK() {
        X::MUGS::Message::InvalidEntity.new(:type<scenario>, :id($!scenario-name)).throw
            unless self.scenario-exists($!scenario-name);
    }

    method scenario-exists(Str:D $scenario-name) {
        $scenario-name ~~ /^ <.ident> ['-' <.ident>]* $/
        && self.scenario-resource-file($scenario-name, 'spec.yaml').IO.r;
    }

    method ensure-valid-spec($spec, Str:D $filename) {
        # Helper subs
        my sub invalid-format($reason) {
            my $type = 'adventure scenario spec';
            X::MUGS::Server::Game::Adventure::Loader::InvalidFormat
                .new(:$type, :$filename, :$reason).throw;
        }

        my sub expect-value-type(%hash, $key, $value-type, $desc) {
            invalid-format("$desc is missing or empty")
                unless %hash{$key};
            invalid-format("$desc is not a $value-type.^name()")
                unless %hash{$key} ~~ $value-type;
        }

        # Top level is a key-value map
        invalid-format('top level is not a key-value map')
            unless $spec.defined && $spec ~~ Associative;

        # Top level string-valued keys are all present
        expect-value-type($spec, $_, Str, "top level '$_' entry")
            for < title intro-file item-file start-map start-location >;

        # map-files is a key-value map containing (resource name) strings
        expect-value-type($spec, 'map-files', Associative, "top level 'map-files' entry");
        expect-value-type($spec<map-files>, $_, Str, "map-files '$_' entry")
            for $spec<map-files>.keys;

        # start-map actually exists in map-files hash
        invalid-format('start-map value is not a key in map-files')
            unless $spec<map-files>{$spec<start-map>}:exists;
    }

    method ensure-resources-exist(%spec) {
        # Helper sub
        my sub check-resource-file($file, $desc) {
            my $resource = self.scenario-resource-file($file);
            my $filename = ~$resource;
            X::MUGS::Server::Game::Adventure::Loader::MissingFile
                .new(:type($desc), :$filename).throw
                unless $resource.IO.r;
        }

        # Singleton files exist
        check-resource-file(%spec{$_ ~ '-file'}, "adventure scenario $_")
            for < intro item >;

        # Map files exist
        for %spec<map-files>.kv -> $moniker, $file {
            check-resource-file($file, "adventure scenario map '$moniker'");
        }
    }

    multi method scenario-resource-file(Str:D $scenario-name,
                                        Str:D $relative-filename) {
        my $resource-path = "game/adventure/$scenario-name/$relative-filename";
        %?RESOURCES{$resource-path} || "resources/$resource-path"
    }

    multi method scenario-resource-file(::?CLASS:D: Str:D $relative-filename) {
        my $resource-path = "game/adventure/$!scenario-name/$relative-filename";
        %?RESOURCES{$resource-path} || "resources/$resource-path"
    }

    method stitch-unresolved(::?CLASS:D: $parser, %maps, @unresolved) {
        # Helper sub
        my sub invalid-target($filename, $reason) {
            my $type = 'adventure scenario map';
            X::MUGS::Server::Game::Adventurer::Loader::InvalidFormat
                .new(:$type, :$filename, :$reason).new.throw;
        }

        for @unresolved {
            my $loc-name = .<location>.name;
            my $target   = %maps{.<options><map>};
            unless $target {
                my $reason = "location '$loc-name' exit '$_<dir>' target map '$_<options><map>' is unknown";
                invalid-target(.<source>, $reason);
            }

            my $dest = $target.locations-named(.<dest>)[0];
            unless $dest {
                my $reason = "location '$loc-name' exit '$_<dir>' destination '$_<dest> does not exist in map '$_<options><map>'";
                invalid-target(.<source>, $reason);
            }

            $parser.add-exit(.<location>, $dest, .<dir>, .<options>);
        }
    }

    method load-scenario(::?CLASS:D:) {
        # Load the adventure scenario spec and check it is basically usable
        my $spec-file = self.scenario-resource-file('spec.yaml');
        my $spec = load-yaml-file('adventure scenario spec', $spec-file);
        self.ensure-valid-spec($spec, ~$spec-file);
        self.ensure-resources-exist($spec);

        # Load the intro
        my $intro-file = self.scenario-resource-file($spec<intro-file>);
        my $intro = slurp $intro-file;

        # Load the item list
        my $item-file = self.scenario-resource-file($spec<item-file>);
        my $items = load-yaml-file('adventure scenario item', $item-file, :all);
        my @items = $items.map: { MUGS::Server::Game::Adventure::Thing.new(|$_) };

        # Load the maps
        my $parser         = MUGS::Server::Game::Adventure::MapParser;
        my $valid-map-name = $spec<map-files>;

        my RPG::Base::AreaMap %maps;
        my @unresolved;

        for $spec<map-files>.kv -> $moniker, $file {
            my $map-file = self.scenario-resource-file($file);
            my ($map, $unresolved)
                = $parser.parse-locations-file($map-file, :map-name($moniker),
                                               :@items, :$valid-map-name);
            %maps{$moniker} = $map;
            @unresolved.append: $unresolved.map: { hash(:$map-file, |$_) };
        }
        self.stitch-unresolved($parser, %maps, @unresolved);

        # Determine title and start location (and make sure it exists)
        my $title = $spec<title>;
        my $start = %maps{$spec<start-map>}.locations-named($spec<start-location>)[0];
        unless $start {
            my $type   = 'adventure scenario spec';
            my $reason = "start-location '$spec<start-location>' is not a valid location in start-map '$spec<start-map>'";
            X::MUGS::Server::Game::Adventure::Loader::InvalidFormat
                .new(:$type, :filename(~$spec-file), :$reason).throw;
        }

        # Return loaded scenario definitions
        { :$title, :$intro, :@items, :%maps, :$start }
    }
}
