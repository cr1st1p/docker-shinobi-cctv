#! /usr/bin/env bash
set -e

#set -x

# We assume:
# - external mysql db
# - mysql db and user were created externally
# - configuration files are provided externally (kubernetes configmaps)
# - 


BASEDIR=/home/Shinobi

bail() {
    echo "$@"
    exit 1
}


setup_custom_auto_load() {
    # link customAutoLoad
    ln -s "/customAutoLoad" "${BASEDIR}/libs/" || true
    chmod -R 777 "${BASEDIR}/libs/customAutoLoad"
}

update_code_if_asked_for() {
    # Update Shinobi to latest version on container start?
    if [ "$APP_UPDATE" != "auto" ]; then
        return 0
    fi
    echo "Checking for Shinobi updates ..."
    git checkout "${APP_BRANCH}"
    git reset --hard
    git pull
    npm install --unsafe-perm
    npm audit fix --force
}


check_configuration_files_exists() {
    [ -f "$BASEDIR/conf.json" ] || bail "Missing configuration file conf.json"
    [ -f "$BASEDIR/super.json" ] || bail "Missing configuration file super.json"
}

ensure_plugin_motion_config_is_present() {
    if [ -f /config/plugins-motion/conf.json ]; then
        ln -sf /config/plugins-motion/conf.json  ${BASEDIR}/plugins/motion/conf.json
    fi

    if [ ! -f ${BASEDIR}/plugins/motion/conf.json ]; then
        echo "Create default config file ${BASEDIR}/plugins/motion/conf.json ..."
        cp ${BASEDIR}/plugins/motion/conf.sample.json ${BASEDIR}/plugins/motion/conf.json
    fi
}

read_mysql_credentials() {
    mysql_host=$(jq -r '.db.host' < "$BASEDIR/conf.json")
    mysql_user=$(jq -r '.db.user' < "$BASEDIR/conf.json")
    mysql_pass=$(jq -r '.db.password' < "$BASEDIR/conf.json")
    mysql_db=$(jq -r '.db.database' < "$BASEDIR/conf.json")
}

wait_for_mysql() {

    # Waiting for connection to MariaDB server
    echo -n "Waiting for connection to mysql server on $mysql_host ."
    while ! mysqladmin ping -h "$mysql_host" -u "$mysql_user" --password="$mysql_pass"; do
        sleep 1
        echo -n "."
    done
    echo " established."
}

create_db_tables() {
    # Create db tables if they do not exists
    echo "Create database schema if it does not exists ..."
    
    # don't bail if it doesn't work.
    # I don't like this at all, but there is an ALTER TABLE ... ADD COLUMN .. that has no safety guards to check if column exists
    grep -E -v '^(CREATE DATABASE IF NOT EXISTS|USE .ccio.)' "${BASEDIR}/sql/framework.sql" | mysql -h "$mysql_host" -u "$mysql_user" --password="$mysql_pass" "$mysql_db" || true
}


fix_user_node_uid_gid() {
    # Change the uid/gid of the node user
    if [ -n "${GID}" ]; then
        if [ -n "${UID}" ]; then
            echo " - Set the uid:gid of the node user to ${UID}:${GID}"
            groupmod -g "$GID" node && usermod -u "$UID" -g "$GID" node
        fi
    fi
}

download_custom_autoload_samples() {
    if [ -n "${DOWNLOAD_CUSTOMAUTOLOAD_SAMPLES}" ]; then
        node tools/downloadCustomAutoLoadModule.js "${DOWNLOAD_CUSTOMAUTOLOAD_SAMPLES}"
    fi
}


# === main
cd "$BASEDIR" # let's be sure about this
# configuration files will be provided by upper layers
check_configuration_files_exists
setup_custom_auto_load
update_code_if_asked_for
#ensure_plugin_motion_config_is_present
read_mysql_credentials
wait_for_mysql
create_db_tables
fix_user_node_uid_gid
#download_custom_autoload_samples

# Execute Command
echo "Starting Shinobi ..."
exec "$@"
