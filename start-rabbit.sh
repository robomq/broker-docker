#!/bin/bash
# ------------------------------------------------------------------
# [Author] Yi Lin <yi.lin@robomq.io>
# [Date  ] 2017.09.10
#          Start-up script for rabbitmq
# ------------------------------------------------------------------

set -eu

global_vars(){
    # environment variables
    RABBITMQ_USE_LONGNAME=${RABBITMQ_USE_LONGNAME:-}
    BROKER_LOG_LEVEL=${BROKER_LOG_LEVEL:-}
    RABBITMQ_VM_MEMORY_HIGH_WATERMARK=${RABBITMQ_VM_MEMORY_HIGH_WATERMARK:-}
    RABBITMQ_HIPE_COMPILE=${RABBITMQ_HIPE_COMPILE:-}
    DEFAULT_VHOST=${DEFAULT_VHOST:-}
    DEFAULT_USER=${DEFAULT_USER:-}
    DEFAULT_PASSWORD=${DEFAULT_PASSWORD:-}
    HEAD_NODE=${HEAD_NODE:-}
    # backward compatability
    WEB_MANAGE_UI=${WEB_MANAGE_UI:-${MANAGE:-}}
    RABBITMQ_ERLANG_COOKIE=${RABBITMQ_ERLANG_COOKIE:-${ERLANG_COOKIE:-}}
    RAM_NODE=${RAM_NODE:-${RAM:-}}

    # flags
    FORCE_RABBITMQ_USE_LONGNAME=false
    USE_EXISTING_MNESIA_VOLUME=false
    USE_EXISTING_RABBITMQ_CONFIG=false
    USE_EXISTING_ENABLED_PLUGINS=false
    USE_EXISTING_ERLANG_COOKIE=false
    THIS_IS_HEAD_NODE=false
    BROKER_CREATED_FIRST_TIME=false

    # helper for DEFAULT_PASSWORD
    PASS=

    # directory and files
    VOLUME=/var/lib/rabbitmq/
    COOKIE_FILE=${VOLUME}.erlang.cookie
    CONFIG_FILE=/etc/rabbitmq/rabbitmq.config
    PLUGIN_FILE=/etc/rabbitmq/enabled_plugins
    DUMMY_FILE=/etc/rabbitmq_was_started_before

    # backward compatability
    if [[ "$RAM_NODE" == "1" ]]; then
        RAM_NODE=true
    fi
    if [[ "$WEB_MANAGE_UI" == "0" ]]; then
        WEB_MANAGE_UI=false
    fi
}

pre_start_up () {
    # If long & short hostnames are not the same, use long hostname
    if [[ "$(hostname)" != "$(hostname -s)" && "$RABBITMQ_USE_LONGNAME" != "true" ]]; then
        local envfile=${RABBITMQ_CONF_ENV_FILE:-"/etc/rabbitmq/rabbitmq-env.conf"}
        if ! grep "RABBITMQ_USE_LONGNAME=true" "$envfile" >& /dev/null; then
            export RABBITMQ_USE_LONGNAME=true
            FORCE_RABBITMQ_USE_LONGNAME=true
        fi
    fi

    # test if container mounts mnesia volume with existing config
    if [[ -f "${VOLUME}mnesia/rabbit@${HOSTNAME}/cluster_nodes.config" ]]; then
        USE_EXISTING_MNESIA_VOLUME=true
    fi

    # test if rabbbitmq.config exists
    if [[ -f "$CONFIG_FILE" ]]; then
        USE_EXISTING_RABBITMQ_CONFIG=true
    fi

    # test if enabled_plugins exists
    if [[ -f "$PLUGIN_FILE" ]]; then
        USE_EXISTING_ENABLED_PLUGINS=true
    fi

    # test if erlang cookie exists
    if [[ -f "$COOKIE_FILE" ]]; then
        USE_EXISTING_ERLANG_COOKIE=true
    fi

    # test if this is head node
    if [[ -z "$HEAD_NODE" || "$HEAD_NODE" == "$HOSTNAME" ]]; then
        THIS_IS_HEAD_NODE=true
    fi

    # use a dummy file to indicate whether broker is just created
    if [[ ! -f "$DUMMY_FILE" ]]; then
        BROKER_CREATED_FIRST_TIME=true
        first_time_init
    fi
}

# initialing container when it starts up for the first time
first_time_init (){
    # cookie file content overrides RABBITMQ_ERLANG_COOKIE
    if [[ "$USE_EXISTING_ERLANG_COOKIE" == "false" && -n "$RABBITMQ_ERLANG_COOKIE" ]]; then
        echo "$RABBITMQ_ERLANG_COOKIE" > "$COOKIE_FILE"
    fi
    # cookie file does not exist if cookie file not mounted and RABBITMQ_ERLANG_COOKIE not set
    if [[ -f "$COOKIE_FILE" ]]; then
        chmod 400 "$COOKIE_FILE"
    fi

    # ensure rabbitmq write access is set on mounted volume
    chown -R rabbitmq:rabbitmq "$VOLUME"

    # enabled_plugins file content overrides WEB_MANAGE_UI
    if [[ "$USE_EXISTING_ENABLED_PLUGINS" == "false" ]]; then
        local plugins='rabbitmq_auth_backend_ldap,rabbitmq_jms_topic_exchange,rabbitmq_management_agent,rabbitmq_mqtt'
        # enable web management ui by default
        if [[ "$WEB_MANAGE_UI" != "false" ]]; then
            plugins="${plugins},rabbitmq_management"
        fi
        echo "[${plugins}]."  > "$PLUGIN_FILE"
    fi
    chown rabbitmq:rabbitmq "$PLUGIN_FILE"

    # turn off startup_log and get log to console
    sed -i 's#> "$RABBITMQ_LOG_BASE/startup_log" 2> "$RABBITMQ_LOG_BASE/startup_err"##' /usr/sbin/rabbitmq-server
    sed -i '/--background --no-close/! s#--background#--background --no-close#' /etc/init.d/rabbitmq-server

    # rabbitmq.config file content overrides environment variables
    if [[ "$USE_EXISTING_RABBITMQ_CONFIG" == "false" ]]; then
        create_rabbitmq_config
    fi
    chown rabbitmq:rabbitmq "$CONFIG_FILE"
}

# create rabbitmq.config based on DEFAULT_USER/PASSWORD/VHOST and BROKER_LOG_LEVEL
create_rabbitmq_config () {
    # sanity checks for values
    case "$BROKER_LOG_LEVEL" in
        debug|info|warning|error|none) LEVEL="$BROKER_LOG_LEVEL";;
        *) LEVEL="info";;
    esac
    if [[ ! "$RABBITMQ_VM_MEMORY_HIGH_WATERMARK" =~ 0\.[0-9]+ ]]; then
        RABBITMQ_VM_MEMORY_HIGH_WATERMARK="0.8"
    fi
    if [[ "$RABBITMQ_HIPE_COMPILE" != "true" ]]; then
        RABBITMQ_HIPE_COMPILE=false
    fi

    local default_section=
    # default user/pass/vhost applies only to head node fresh start
    if [[ "$THIS_IS_HEAD_NODE" == "true" && "$USE_EXISTING_MNESIA_VOLUME" == "false" ]]; then
        DEFAULT_VHOST=${DEFAULT_VHOST:-"/"}
        DEFAULT_USER=${DEFAULT_USER:-"admin"}
        if [[ -z "$DEFAULT_PASSWORD" ]]; then
            local uuid=$(cat /proc/sys/kernel/random/uuid)
            PASS=${uuid##*-}
        fi

        default_section=$(cat <<EOF
        {default_vhost, <<"$DEFAULT_VHOST">>},
        {default_user, <<"$DEFAULT_USER">>},
        {default_pass, <<"${DEFAULT_PASSWORD:-$PASS}">>},
        {default_permissions, [<<".*">>, <<".*">>, <<".*">>]},
EOF
        )
    fi

    # use preconfigured setting
    cat > "$CONFIG_FILE" <<EOF
[
  {mnesia, [{dump_log_write_threshold, 1000}]},
  {rabbit, [
$default_section
        {vm_memory_high_watermark, $RABBITMQ_VM_MEMORY_HIGH_WATERMARK},
        {hipe_compile, $RABBITMQ_HIPE_COMPILE},
        {cluster_partition_handling, autoheal},
        {collect_statistics_interval, 10000},
        {handshake_timeout, 120000},
        {ssl_handshake_timeout, 60000},
        {disk_free_limit, 100000000},
        {log_levels, [{connection, $LEVEL}]},
        {tcp_listeners, [{"0.0.0.0", 5672}]}
  ]}
].
EOF
}

join_cluster() { 
     if [[ "$THIS_IS_HEAD_NODE" == "true" ]]; then
        return 0;
    fi
    # join_cluster in two cases: 1. fresh start; OR 2. does not know head node   
    if [[ "$USE_EXISTING_MNESIA_VOLUME" == "true" ]]; then
        # handle specail case of a persistent broker changing head node
        if rabbitmqctl cluster_status | grep  "@${HEAD_NODE}[],']" >& /dev/null ;then
            return 0;
        fi
    fi
    # Join head node of the cluster. 
    rabbitmqctl stop_app
    if [[ "$RAM_NODE" == "true" ]]; then
        rabbitmqctl join_cluster "rabbit@${HEAD_NODE}" --ram
    else 
        rabbitmqctl join_cluster "rabbit@${HEAD_NODE}"
    fi
    rabbitmqctl start_app
}

# log startup summary info
log_startup_summary() {
    printf "\n"
    printf "==========================================================================\n"
    # log if ram node
    if [[ "$RAM_NODE" == "true" ]]; then
        local ram=" as a ram node"
    fi
    printf "Broker rabbit@$HOSTNAME is running${ram:-}. Supports AMQP/MQTT by default.\n"
    # log if using exsting config/data/cookie
    if [[ "$USE_EXISTING_RABBITMQ_CONFIG" == "true" ]]; then
        printf " * Use broker settings from existing file ${CONFIG_FILE}\n"
    fi
    if [[ "$USE_EXISTING_ENABLED_PLUGINS" == "true" ]]; then
        printf " * Use broker settings from existing file ${PLUGIN_FILE}\n"
    fi
    if [[ "$USE_EXISTING_MNESIA_VOLUME" == "true" ]]; then
        printf " * Use previously saved data and settings from volume /var/lib/rabbitmq/\n"
    fi
    local cookie=$(cat $COOKIE_FILE)
    if [[ "$USE_EXISTING_ERLANG_COOKIE" == "true"  ]]; then
        printf " * Use erlang cookie saved in file ${COOKIE_FILE}\n"
        if [[ -n "$RABBITMQ_ERLANG_COOKIE" && "$cookie" != "$RABBITMQ_ERLANG_COOKIE" ]]; then
            printf "WARN: .erlang.cookie file content does not match RABBITMQ_ERLANG_COOKIE.\n"
        fi
    fi
    # RABBITMQ_USE_LONGNAME should be set but is not
    if [[ "$FORCE_RABBITMQ_USE_LONGNAME" == "true"  ]]; then
        printf "WARN: you use long hostname but RABBITMQ_USE_LONGNAME!=true.\n"
        printf "WARN: run \"export RABBITMQ_USE_LONGNAME=true\" before using rabbitmqctl.\n"
    fi
    # log if join cluster
    if [[ "$THIS_IS_HEAD_NODE" == "false" ]]; then
        printf "Success: Join cluster with HEAD_NODE: rabbit@$HEAD_NODE\n"
    fi
    # log default user/pass/vhost only when head node does a completely fresh startup
    if [[ "$THIS_IS_HEAD_NODE" == "true"  && "$BROKER_CREATED_FIRST_TIME" == "true"  \
        && "$USE_EXISTING_RABBITMQ_CONFIG" == "false"  && "$USE_EXISTING_MNESIA_VOLUME" == "false" ]]; then
        printf "\n"
        printf "\tDefault Vhost    : %s\n" "$DEFAULT_VHOST"
        printf "\tDefault User     : %s\n" "$DEFAULT_USER"
        # password protection: logs system generated default password only
        PASS=${PASS:-"<your-password>"}
        printf "\tDefault Password : %s\n" "$PASS"
        # cookie protection: logs system generated erlang cookie only
        if [[ "$USE_EXISTING_ERLANG_COOKIE" == "false" && -z "$RABBITMQ_ERLANG_COOKIE" ]]; then
            printf "\tERLANG_COOKIE    : %s\n" $cookie
        fi
        printf "\n"
        if [[ -z "$DEFAULT_PASSWORD" ]]; then
            printf "Please update system generated default password by this command:\n"
            if [[ "$FORCE_RABBITMQ_USE_LONGNAME" == "true" ]]; then
                local longname="env RABBITMQ_USE_LONGNAME=true "
            fi
            printf "\$ docker exec <container> rabbitmqctl ${longname:-}change_password $DEFAULT_USER <password>\n"
        fi
        local credential="with ${DEFAULT_USER}:${PASS} "
    fi
    # log web management UI access info
    if grep "\brabbitmq_management\b" "$PLUGIN_FILE" >& /dev/null ; then
        printf "Web Management UI can be accessed ${credential:-}from:\n"
        printf "\t\thttp://<broker-host>:<ui-port>/\n"
        printf "To get <ui-port>, run: \$ docker port <container> 15672 | cut -d : -f 2\n"
    else
        printf "Web Management UI is disabled and cannot be accessed from this node.\n"
    fi
    printf "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n"
    rabbitmqctl cluster_status
    printf "==========================================================================\n"
}

post_start_up() {
    # create dummy indication file only if all is well
    if [[ "$BROKER_CREATED_FIRST_TIME" == "true" ]]; then
        touch "$DUMMY_FILE"
    fi

    # keep this process running and tail logs
    tail -F /var/log/rabbitmq/* 2>/dev/null
}

main () {
    global_vars
    pre_start_up
    # start rabbitmq server as daemon
    /etc/init.d/rabbitmq-server start
    join_cluster
    log_startup_summary
    post_start_up
}

main
