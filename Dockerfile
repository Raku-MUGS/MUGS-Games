ARG mugs_version=latest
FROM mugs-core:$mugs_version
ARG mugs_version

LABEL org.opencontainers.image.source=https://github.com/Raku-MUGS/MUGS-Games

COPY . /home/raku

RUN zef install --deps-only . \
 && raku -c -Ilib bin/mugs-ws-server \
 && raku -c -Ilib bin/mugs-admin

RUN zef install .
