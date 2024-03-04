ARG mugs_version=latest
FROM mugs-core:$mugs_version
ARG mugs_version

LABEL org.opencontainers.image.source=https://github.com/Raku-MUGS/MUGS-Games

USER raku:raku

WORKDIR /home/raku/MUGS/MUGS-Games
COPY . .

RUN zef install --deps-only . \
 && zef install --/test . \
 && rm -rf /home/raku/.zef /tmp/.zef
