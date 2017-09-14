FROM ubuntu:17.04
MAINTAINER Yi Lin <yi.lin@robomq.com>

# perequisites: logroate, socat for rabbitmq
RUN set -ex; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        gnupg2 \
        dirmngr \
        logrotate \
        socat \
    ; \
    rm -rf /var/lib/apt/lists/*

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -r rabbitmq && useradd -r -d /var/lib/rabbitmq -m -g rabbitmq rabbitmq

# install Erlang
RUN set -ex; \
# pin erlang version to prevent future upgrade
    echo "Package: erlang*\nPin: version 1:19.2.1+dfsg-2ubuntu1\nPin-Priority: 1000" \
            > /etc/apt/preferences.d/erlang; \
    apt-get update; \
# "erlang-base-hipe" is optional (and only supported on a few arches)
# so, only install it if it's available for our current arch
    if apt-cache show erlang-base-hipe 2>/dev/null | grep -q 'Package: erlang-base-hipe'; then \
        apt-get install -y --no-install-recommends \
            erlang-base-hipe=1:19.* \
        ; \
    fi; \
# we start with "erlang-base-hipe" because it and "erlang-base" (non-hipe) are exclusive
    apt-get install -y --no-install-recommends \
        erlang-asn1 \
        erlang-crypto \
        erlang-eldap \
        erlang-inets \
        erlang-mnesia \
        erlang-nox=1:19.* \
        erlang-os-mon \
        erlang-public-key \
        erlang-ssl \
        erlang-xmerl \
    ; \
    rm -rf /var/lib/apt/lists/*

# get logs to stdout
ENV RABBITMQ_LOGS=- RABBITMQ_SASL_LOGS=-

RUN set -ex; \
    key='0A9AF2115F4687BD29803A206B73A36E6026DFCA'; \
    export GNUPGHOME="$(mktemp -d)"; \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
    gpg --export "$key" > /etc/apt/trusted.gpg.d/rabbitmq.gpg; \
    rm -rf "$GNUPGHOME"; \
    apt-key list

RUN echo 'deb http://www.rabbitmq.com/debian testing main' > /etc/apt/sources.list.d/rabbitmq.list

# install Rabbitmq
ENV RABBITMQ_VERSION 3.6.12
ENV RABBITMQ_DEBIAN_VERSION 3.6.12-1

RUN apt-get update && apt-get install -y --no-install-recommends \
        rabbitmq-server=$RABBITMQ_DEBIAN_VERSION \
    && rm -rf /var/lib/apt/lists/*

COPY start-rabbit.sh /usr/local/bin/

# white label web management UI
COPY robomqlogo.png favicon.ico /
RUN set -ex; \
    apt-get update && apt-get install -y --no-install-recommends \
        unzip zip; \

    unzip /usr/lib/rabbitmq/lib/rabbitmq_server-3.6.12/plugins/rabbitmq_management-3.6.12.ez; \

    # make changes
    # icons
    mv favicon.ico rabbitmq_management-3.6.12/priv/www/favicon.ico; \
    mv robomqlogo.png rabbitmq_management-3.6.12/priv/www/img/robomqlogo.png; \
    # title
    sed -i 's/RabbitMQ Management/RoboMQ Management/' rabbitmq_management-3.6.12/priv/www/index.html; \
    # colors
    sed -i 's/#FF8C00/#188bcd/' rabbitmq_management-3.6.12/priv/www/css/main.css; \
    sed -i 's/#F60/#188bcd/' rabbitmq_management-3.6.12/priv/www/css/main.css; \
    sed -i 's/#f88/#188bcd/' rabbitmq_management-3.6.12/priv/www/css/main.css; \
    # autocomplete for security
    sed -i 's/name="password"/name="password" autocomplete="off"/' rabbitmq_management-3.6.12/priv/www/js/tmpl/login.ejs; \
    # replace logo
    sed -i '/rabbitmqlogo.png/ s/rabbitmqlogo.png/robomqlogo.png/' rabbitmq_management-3.6.12/priv/www/js/tmpl/login.ejs; \
    sed -i '/rabbitmqlogo.png/ s/rabbitmqlogo.png/robomqlogo.png/' rabbitmq_management-3.6.12/priv/www/js/tmpl/layout.ejs; \
    sed -i '/robomqlogo.png/ s/width="204" height="37"/width="180" height="45"/' rabbitmq_management-3.6.12/priv/www/js/tmpl/login.ejs; \
    sed -i '/robomqlogo.png/ s/width="204" height="37"/width="180" height="45"/' rabbitmq_management-3.6.12/priv/www/js/tmpl/layout.ejs; \

    zip /usr/lib/rabbitmq/lib/rabbitmq_server-3.6.12/plugins/rabbitmq_management-3.6.12.ez -r rabbitmq_management-3.6.12/*; \
    rm -rf rabbitmq_management-3.6.12; \

    apt-get purge --auto-remove -y unzip zip; \
    rm -rf /var/lib/apt/lists/*


VOLUME ["/var/lib/rabbitmq/"]

EXPOSE 5671 5672 15671 15672 1883 8883 4369 25672

CMD start-rabbit.sh
