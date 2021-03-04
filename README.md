[![Actions Status](https://github.com/Raku-MUGS/MUGS-Games/workflows/test/badge.svg)](https://github.com/Raku-MUGS/MUGS-Games/actions)

NAME
====

MUGS-Games - Free-as-in-speech game implementations for MUGS (Multi-User Gaming Services)

SYNOPSIS
========

```raku
use MUGS::Games;
```

DESCRIPTION
===========

**NOTE: See the [top-level MUGS repo](https://github.com/Raku-MUGS/MUGS) for more info.**

MUGS-Games is a collection of free-as-in-speech client and server game and genre implementations for MUGS (Multi-User Gaming Services). Note that these implementations do NOT have user interfaces; they only implement abstract game logic, request/response protocols, and so forth. This is sufficient for automated testing and implementation of game bots, but if you want to play them as an end user, you'll need to install the appropriate MUGS-UI-* for the user interface you prefer.

This Proof-of-Concept release only includes simple turn-based guessing and interactive fiction games. The underlying framework in [MUGS-Core](https://github.com/Raku-MUGS/MUGS-Core) has been tested with 2D arcade games as well, but these are not yet ready for public release. Future releases will include many more games and genres.

ROADMAP
=======

MUGS is still in its infancy, at the beginning of a long and hopefully very enjoyable journey. There is a [draft roadmap for the first few major releases](https://github.com/Raku-MUGS/MUGS/tree/main/docs/todo/release-roadmap.md) but I don't plan to do it all myself -- I'm looking for contributions of all sorts to help make it a reality.

CONTRIBUTING
============

Please do! :-)

In all seriousness, check out [the CONTRIBUTING doc](docs/CONTRIBUTING.md) (identical in each repo) for details on how to contribute, as well as [the Coding Standards doc](https://github.com/Raku-MUGS/MUGS/tree/main/docs/design/coding-standards.md) for guidelines/standards/rules that apply to code contributions in particular.

The MUGS project has a matching GitHub org, [Raku-MUGS](https://github.com/Raku-MUGS), where you will find all related repositories and issue trackers, as well as formal meta-discussion.

More informal discussion can be found on IRC in [Freenode #mugs](ircs://chat.freenode.net:6697/mugs).

AUTHOR
======

Geoffrey Broadwell <gjb@sonic.net> (japhb on GitHub and Freenode)

COPYRIGHT AND LICENSE
=====================

Copyright 2021 Geoffrey Broadwell

MUGS is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

