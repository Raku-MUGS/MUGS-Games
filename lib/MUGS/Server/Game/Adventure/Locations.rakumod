# ABSTRACT: Parser for adventure map definition files

# use Grammar::Tracer;

use RPG::Base::Location;
use RPG::Base::AreaMap;


#| Grammar of locations file used to build an AreaMap
grammar MUGS::Server::Game::Adventure::Locations {
    token ws          { <!ww> \h* }
    rule  TOP         { <location>* }
    rule  location    { <header> <description> }
    token header      { <title> <exit>* <thing>* \n }
    token title       { ^^ '--' \h+ <name> \n }
    token name        { <-[ \n { } ]>+ }
    token exit        { ^^ '>' \h+ <direction> \h+ '-' \h+ <name> <options>? \n }
    token direction   { \w+ }
    token thing       { ^^ '|' \h+ <name> <options>? \n }
    regex description { ^^ [. <!before ^^ '-- '>]+ \n }
    rule  options     { '{' <option> *%% ',' '}' }
    token option      { ':' <negated>? <flag> | <key> \h* '=' \h* <value> }
    token negated     { '!' }
    token flag        { \w+ }
    token key         { \w+ }
    token value       { <-[ , } \n ]>+ }
}


#| Parser for adventure maps
class MUGS::Server::Game::Adventure::MapParser {
    #| Parse the textual locations file into a map
    method parse-locations-file(IO() $file, :@items,
                                :$map-name, :$valid-map-name) is export {
        # XXXX: Better error messages plz, kthx
        my $parsed = MUGS::Server::Game::Adventure::Locations.parsefile($file)
            or die "Could not parse locations file '$file'";
        self.process-parsed-locations(:source($file), :$parsed, :@items,
                                      :$map-name, :$valid-map-name);
    }

    #| Process a Locations parse tree into an AreaMap definition
    method process-parsed-locations(:$source, :$parsed, :@items,
                                    :$map-name, :$valid-map-name) {
        #| Process options into a data structure
        sub process-options($options) {
            my %options = do with $options {
                .<option>.map: {
                    .<flag> ?? (~.<flag> => !.<negated>)
                            !! (~.<key>  => val(~.<value> .trim))
                }
            }
        }

        # Create a new AreaMap to hold the parsed locations
        my $map = RPG::Base::AreaMap.new(name => $map-name);

        # Track unresolved exits (e.g. going to other maps)
        my @unresolved;

        # Create Location objects for each location parsed
        for $parsed<location> {
            my $name = ~.<header><title><name> .trim;
            my $desc = ~.<description> .trim;
            $map.add-location: RPG::Base::Location.new(:$name, :$desc);
        }

        # Stitch locations into a map, adding items where requested
        for $parsed<location> -> $loc {
            my $location = $map.locations-named(~$loc<header><title><name> .trim)[0];

            # Add items
            for $loc<header><thing> -> $thing {
                # Find the item by name in the @items list
                my $name = ~$thing<name> .trim;
                my $item = @items.first(*.name eq $name)
                    or die "Unknown item '$name' in '$location.name()'";

                # If there are options (even if empty), clone with changes
                if $thing<options> -> $options {
                    my %options = $item.options, process-options($options);
                    $item .= clone(:%options);
                }

                # Add the (possibly freshly cloned) item to this location
                $location.add-thing($item);
            }

            # Stitch together the exits
            for $loc<header><exit> -> $exit {
                # Determine direction and destination name
                my $dest = ~$exit<name> .trim;
                my $dir  = ~$exit<direction> .lc;

                # Check if exit goes to a different map; if so, delay stitch
                my %options = process-options($exit<options>);
                if %options<map> -> $target {
                    die "Invalid map target '$target' for exit '$dir' from '$location.name()'"
                        unless $target ~~ $valid-map-name;

                    @unresolved.push: hash(:$source, :$map, :$location,
                                           :$dir, :$dest, :%options);
                }
                # ... otherwise, find the destination within the map and connect to it
                else {
                    my $loc2 = $map.locations-named($dest)[0]
                        or die "Unknown destination '$dest' for exit '$dir' from '$location.name()'";

                    self.add-exit($location, $loc2, $dir, %options);
                }
            }
        }

        $map, @unresolved
    }

    #| Check whether exit is blocked, and if so use programmatic exit;
    #| otherwise, just exit directly to the target location
    method add-exit($loc1, $loc2, $dir, %options) {
        my $block = %options<blocker>;
        my $exit  = $block ?? self.make-blocker-code($loc1, $loc2, $dir, $block)
                           !! $loc2;
        $loc1.add-exit($dir => $exit);
    }

    method make-blocker-code($loc1, $loc2, $dir, $block) {
        # Blocker may be in either location
        my $item =  $loc1.contents.first(*.name eq $block)
                 // $loc2.contents.first(*.name eq $block);
        die "Unknown blocker '$block' for exit '$dir' from '$loc1.name()'"
            unless $item;

        # Create programmatic exit closure
        sub blocker(:$direction, :$location, *%) {
            X::RPG::Base::Location::Blocked.new(:$direction, :$location, :$block).throw
                if $item.options<locked>;
            $loc2
        }
    }
}
