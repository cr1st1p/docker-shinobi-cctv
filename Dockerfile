FROM ubuntu:bionic-20200112

ENV     LC_ALL=C.UTF-8     LANG=C.UTF-8     APP_UPDATE=manual     APP_BRANCH=dev     APP_PORT=8080

EXPOSE 8080


VOLUME /opt/shinobi/videos

SHELL ["/bin/bash", "-c"] 
RUN set -e \
    ; mkdir -p \
        /config \
        /opt/shinobi \
        /customAutoLoad \
    ; true

COPY docker-entrypoint.sh /opt/shinobi/
COPY pm2Shinobi.yml /opt/shinobi/
COPY /tools/modifyJson.js /opt/shinobi/tools
RUN set -e \
    ; apt-get update -qq \
    ; DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends --no-install-suggests -yqq -o Dpkg::Options::=--force-unsafe-io \
        gnupg2 apt-transport-https ca-certificates \
    ; [ command -v curl >/dev/null 2>/dev/null ] || DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends --no-install-suggests -yqq -o Dpkg::Options::=--force-unsafe-io \
        curl \
    ; curl -s 'https://deb.nodesource.com/gpgkey/nodesource.gpg.key' | apt-key add - \
    ; echo 'deb https://deb.nodesource.com/node_11.x bionic main' > /etc/apt/sources.list.d/nodesource.list \
    ; apt-get update -qq \
    ; DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends --no-install-suggests -yqq -o Dpkg::Options::=--force-unsafe-io \
        nodejs \
    ; DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends --no-install-suggests -yqq -o Dpkg::Options::=--force-unsafe-io \
        jq mysql-client \
    ; DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends --no-install-suggests -yqq -o Dpkg::Options::=--force-unsafe-io \
        python make \
    ; DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends --no-install-suggests -yqq -o Dpkg::Options::=--force-unsafe-io \
        git \
    ; ld=$(pwd) \
    ; cd "/opt/shinobi" \
    ; git clone "https://gitlab.com/Shinobi-Systems/Shinobi.git" "existing-dir.tmp" \
    ; mv 'existing-dir.tmp/.git' "." \
    ; rm -rf "existing-dir.tmp/" \
    ; git reset --hard HEAD \
    ; git checkout -b dev \
    ; ld=$(pwd) \
    ; cd "/opt/shinobi" \
    ; npm i npm@latest -g \
    ; npm install pm2 -g  \
    ; npm install jsonfile \
    ; npm install edit-json-file \
    ; npm install ffbinaries  \
    ; npm install --unsafe-perm \
    ; npm audit fix --force \
    ; cd "$ld" \
    ; ln -s /config/conf.json "/opt/shinobi/conf.json" \
    ; ln -s /config/super.json "/opt/shinobi/super.json" \
    ; chmod -f +x /opt/shinobi/*.sh \
    ; DEBIAN_FRONTEND=noninteractive apt-get purge -y -o Dpkg::Options::=--force-unsafe-io \
        command-not-found command-not-found-data man-db manpages python3-commandnotfound python3-update-manager update-manager-core \
    ; apt-get purge -y --auto-remove \
    ; apt-get clean -q \
    ; rm -f /etc/dpkg/dpkg.cfg.d/02apt-speedup || true \
    ; rm -rf /var/lib/apt/lists/* \
    ; rm -rf /root/.cache \
    ; rm -rf /root/.npm \
    ; rm -rf /root/.ffbinaries-cache \
    ; true

CMD ["pm2-docker", "pm2Shinobi.yml"]
WORKDIR /opt/shinobi
ENTRYPOINT ["/opt/shinobi/docker-entrypoint.sh"]
