# ABSTRACT: Free-as-in-speech game implementations for MUGS

unit class MUGS::Games:auth<zef:japhb>:ver<0.1.4>;


=begin pod

=head1 NAME

MUGS-Games - Free-as-in-speech game implementations for MUGS (Multi-User Gaming Services)

=head1 SYNOPSIS

  # Setting up a simple MUGS-Games development environment
  mkdir MUGS
  cd MUGS
  git clone git@github.com:Raku-MUGS/MUGS-Core.git
  git clone git@github.com:Raku-MUGS/MUGS-Games.git
  cd MUGS-Core
  zef install --exclude="pq:ver<5>:from<native>" .
  mugs-admin create-universe
  cd ../MUGS-Games
  zef install --deps-only .


=head1 DESCRIPTION

B<NOTE: See the L<top-level MUGS repo|https://github.com/Raku-MUGS/MUGS> for more info.>

MUGS-Games is a collection of free-as-in-speech client and server game and
genre implementations for MUGS (Multi-User Gaming Services).  Note that these
implementations do NOT have user interfaces; they only implement abstract game
logic, request/response protocols, and so forth.  This is sufficient for
automated testing and implementation of game bots, but if you want to play
them as an end user, you'll need to install the appropriate MUGS-UI-* for the
user interface you prefer.

This Proof-of-Concept release only includes simple turn-based guessing and
interactive fiction games.  The underlying framework in
L<MUGS-Core|https://github.com/Raku-MUGS/MUGS-Core>
has been tested with 2D arcade games as well, but these are not yet ready for
public release.  Future releases will include many more games and genres.


=head1 ROADMAP

MUGS is still in its infancy, at the beginning of a long and hopefully very
enjoyable journey.  There is a
L<draft roadmap for the first few major releases|https://github.com/Raku-MUGS/MUGS/tree/main/docs/todo/release-roadmap.md>
but I don't plan to do it all myself -- I'm looking for contributions of all
sorts to help make it a reality.


=head1 CONTRIBUTING

Please do!  :-)

In all seriousness, check out L<the CONTRIBUTING doc|docs/CONTRIBUTING.md>
(identical in each repo) for details on how to contribute, as well as
L<the Coding Standards doc|https://github.com/Raku-MUGS/MUGS/tree/main/docs/design/coding-standards.md>
for guidelines/standards/rules that apply to code contributions in particular.

The MUGS project has a matching GitHub org,
L<Raku-MUGS|https://github.com/Raku-MUGS>, where you will find all related
repositories and issue trackers, as well as formal meta-discussion.

More informal discussion can be found on IRC in
L<Libera.Chat #mugs|ircs://irc.libera.chat:6697/mugs>.


=head1 AUTHOR

Geoffrey Broadwell <gjb@sonic.net> (japhb on GitHub and Libera.Chat)


=head1 COPYRIGHT AND LICENSE

Copyright 2021-2024 Geoffrey Broadwell

MUGS is free software; you can redistribute it and/or modify it under the
Artistic License 2.0.

=end pod
