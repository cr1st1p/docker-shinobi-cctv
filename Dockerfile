FROM ubuntu:22.04

ENV     LC_ALL=C.UTF-8     LANG=C.UTF-8     APP_UPDATE=manual     APP_BRANCH=dev     APP_PORT=8080

EXPOSE 8080


VOLUME /home/Shinobi/videos
VOLUME /home/Shinobi/libs/customAutoload
VOLUME /config

SHELL [ "/bin/bash" , "-c" ]
RUN set -e \
    ; mkdir -p \
        /config \
        /home/Shinobi \
        /customAutoLoad \
    ; true

COPY docker-entrypoint.sh /home/Shinobi/
COPY /tools/modifyJson.js /home/Shinobi/tools
RUN set -e \
    ; apt-get update -qq \
    ; DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends --no-install-suggests -yqq -o Dpkg::Options::=--force-unsafe-io \
        gnupg2 apt-transport-https ca-certificates \
    ; [ command -v curl >/dev/null 2>/dev/null ] || DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends --no-install-suggests -yqq -o Dpkg::Options::=--force-unsafe-io \
        curl \
    ; curl -s 'https://deb.nodesource.com/gpgkey/nodesource.gpg.key' | apt-key add - \
    ; echo 'deb https://deb.nodesource.com/node_16.x kinetic main' > /etc/apt/sources.list.d/nodesource.list \
    ; apt-get update -qq \
    ; DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends --no-install-suggests -yqq -o Dpkg::Options::=--force-unsafe-io \
        nodejs \
    ; DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends --no-install-suggests -yqq -o Dpkg::Options::=--force-unsafe-io \
        jq mysql-client \
    ; DEBIAN_FRONTEND=noninteractive apt-get install  -yqq -o Dpkg::Options::=--force-unsafe-io \
        ffmpeg \
    ; DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends --no-install-suggests -yqq -o Dpkg::Options::=--force-unsafe-io \
        python3 make git \
    ; DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends --no-install-suggests -yqq -o Dpkg::Options::=--force-unsafe-io \
        git \
    ; ld=$(pwd) \
    ; cd "/home/Shinobi" \
    ; git clone "https://gitlab.com/Shinobi-Systems/Shinobi.git" "existing-dir.tmp" \
    ; mv 'existing-dir.tmp/.git' "." \
    ; rm -rf "existing-dir.tmp/" \
    ; git reset --hard HEAD \
    ; git checkout -b dev \
    ; ld=$(pwd) \
    ; cd "/home/Shinobi" \
    ; npm i npm@latest -g \
    ; npm install --unsafe-perm \
    ; npm install pm2 -g  \
    ; cd "$ld" \
    ; ln -s /config/conf.json "/home/Shinobi/conf.json" \
    ; ln -s /config/super.json "/home/Shinobi/super.json" \
    ; chmod -f +x /home/Shinobi/*.sh \
    ; chmod 777 /home/Shinobi/plugins \
    ; function apt_purge_packages() { \
        local pkgToRemoveList="" \
    ;   for pkgToRemove in "$@"; do \
          if dpkg --status "$pkgToRemove" &> /dev/null; then \
            pkgToRemoveList="$pkgToRemoveList $pkgToRemove" ; \
          fi ; \
        done  \
    ;   if [ -n "$pkgToRemoveList" ]; then \
          DEBIAN_FRONTEND=noninteractive apt-get purge -y -o Dpkg::Options::=--force-unsafe-io \
            $pkgToRemoveList \
        ; fi \
    ; } \
    ; apt_purge_packages command-not-found command-not-found-data man-db manpages python3-commandnotfound python3-update-manager update-manager-core \
    ; apt-get purge -y --auto-remove \
    ; apt-get clean -q \
    ; rm -f /etc/dpkg/dpkg.cfg.d/02apt-speedup || true \
    ; rm -rf /var/lib/apt/lists/* \
    ; rm -rf /root/.cache \
    ; rm -rf /root/.npm \
    ; rm -rf /root/.ffbinaries-cache \
    ; true

CMD ["pm2-docker", "Docker/pm2.yml"]
WORKDIR /home/Shinobi
ENTRYPOINT ["/home/Shinobi/docker-entrypoint.sh"]
