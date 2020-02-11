#! /usr/bin/env bash

# This will create an image that does NOT install also mysql
#


set -e

SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

for n in main.sh apt.sh debugging.sh nodejs.sh git.sh; do
    # shellcheck disable=SC1090
    source "${SCRIPT_PATH}/dockerfile-lib/$n"
done


DEV_MODE=
FORCE_GIT_CLONE=

SHINOBI_BASEDIR=/opt/shinobi

# ==== command line parsing
checkArg () {
    if [ -z "$2" ] || [[ "$2" == "-"* ]]; then
        echo "Expected argument for option: $1. None received"
        exit 1
    fi
}

arguments=()
while [[ $# -gt 0 ]]
do
    # split --x=y to have them separated
    [[ $1 == --*=* ]] && set -- "${1%%=*}" "${1#*=}" "${@:2}"

    case "$1" in
        --dev)
            DEV_MODE=1
            shift
            ;;
        --run-with-debug)
            RUN_WITH_DEBUG=1
            shift
            ;;
        --force-git-clone)
            FORCE_GIT_CLONE=1
            shift
            ;;
        --) # end argument parsing
            shift
            break
            ;;
        -*) # unsupported flags
            echo "Error: Unsupported flag $1" >&2
            exit 1
            ;;
        *) # preserve positional arguments
            arguments+=("$1")
            shift
            ;;
    esac    
done

# ========
start_stuff() {
    exit_run_cmd


    GEN_FROM "ubuntu:bionic-20200112"

    cat <<EOS

ENV \
    LC_ALL=C.UTF-8 \
    LANG=C.UTF-8 \
    APP_UPDATE=manual \
    APP_BRANCH=dev \
    APP_PORT=8080

EXPOSE 8080


VOLUME ${SHINOBI_BASEDIR}/videos

EOS

}



end_stuff() {
    exit_run_cmd

    cat <<'EOS'
CMD ["pm2-docker", "pm2Shinobi.yml"]
EOS
    echo "WORKDIR ${SHINOBI_BASEDIR}"
    echo "ENTRYPOINT [\"${SHINOBI_BASEDIR}/docker-entrypoint.sh\"]"

}


run_shinobi_makedirs() {
    enter_run_cmd        

    # Create additional directories for: Custom configuration, working directory, database directory, scripts
    cat << EOS
    ; mkdir -p \\
        /config \\
        ${SHINOBI_BASEDIR} \\
        /customAutoLoad \\
EOS
}

SHINOBI_REQ_PACKAGES_RUNTIME=(jq mysql-client)

# 'gyp' node modules requires: 'apt.py' (python package), make
SHINOBI_REQ_PACKAGES_BUILDTIME=(python make)

run_shinobi_install_package_dependencies() {    
    cmd_apt_min_install "${SHINOBI_REQ_PACKAGES_RUNTIME[@]}"
    cmd_apt_min_install "${SHINOBI_REQ_PACKAGES_BUILDTIME[@]}"
    return 0

    cmd_apt_min_install \
        libfreetype6-dev \
        libgnutls28-dev \
        libmp3lame-dev \
        libass-dev \
        libogg-dev \
        libtheora-dev \
        libvorbis-dev \
        libvpx-dev \
        libwebp-dev \
        libssh2-1-dev \
        libopus-dev \
        librtmp-dev \
        libx264-dev \
        libx265-dev \
        yasm


    cmd_apt_min_install \
        build-essential \
        bzip2 \
        coreutils \
        gnutls-bin \
        nasm \
        tar \
        x264


    # Install additional packages

    # SEEME: using this ffmpeg OR the ffbinaries from npm install!?!?

    cmd_apt_min_install \
        ffmpeg \
        git \
        make \
        mariadb-client \
        pkg-config \
        python \
        wget \
        tar \
        sudo \
        xz-utils
}

run_shinobi_code_clone() {
    cmd_apt_min_install git

    run_git_clone_into_existing_dir https://gitlab.com/Shinobi-Systems/Shinobi.git "$SHINOBI_BASEDIR" -b "dev"
}


run_shinobi_install_nodejs_dependencies() {
    enter_run_cmd
    cat << EOS
    ; ld=\$(pwd) \\
    ; cd "$SHINOBI_BASEDIR" \\
    ; npm i npm@latest -g \\
    ; npm install pm2 -g  \\
    ; npm install jsonfile \\
    ; npm install edit-json-file \\
    ; npm install ffbinaries  \\
    ; npm install --unsafe-perm \\
    ; npm audit fix --force \\
    ; cd "\$ld" \\
EOS

}

run_shinobi_configs_symlinks() {
    enter_run_cmd 
    cat << EOS
    ; ln -s /config/conf.json "$SHINOBI_BASEDIR/conf.json" \\
    ; ln -s /config/super.json "$SHINOBI_BASEDIR/super.json" \\
EOS
}


copy_files() {
    exit_run_cmd
    cat << EOS
COPY docker-entrypoint.sh ${SHINOBI_BASEDIR}/
COPY pm2Shinobi.yml ${SHINOBI_BASEDIR}/
COPY /tools/modifyJson.js ${SHINOBI_BASEDIR}/tools
EOS
}


run_fix_files() {
    enter_run_cmd
    echo "    ; chmod -f +x ${SHINOBI_BASEDIR}/*.sh \\"
}


run_cleanup() {
    enter_run_cmd

    # can't call that, nodejs needs ca-certificates
    #run_apt_remove_initial_packages
    run_apt_cleanups

    enter_run_cmd
    cat <<'EOS'
    ; rm -rf /root/.cache \
    ; rm -rf /root/.npm \
    ; rm -rf /root/.ffbinaries-cache \
EOS
}


# =======
start_stuff

run_shinobi_makedirs
[ -z "$DEV_MODE" ] && copy_files

run_apt_initial_minimal_installs

# repositories:
run_nodejs_add_repo

# end of adding repositories
run_apt_update
run_nodejs_install


run_shinobi_install_package_dependencies
run_shinobi_code_clone
run_shinobi_install_nodejs_dependencies
run_shinobi_configs_symlinks

[ -n "$DEV_MODE" ] && copy_files

run_fix_files


[ -z "$DEV_MODE" ] && run_cleanup


end_stuff
