#!/usr/bin/env bash

export haproxy_file="${HOME}/g/nova/haproxy/haproxy.cfg"
export addendum_file="././config/xgemail_addendum_haproxy.cfg"
{
    # modify existing routing to mail-backend
    edited=$(sed 's/hub-backend if mail_context/mail-backend if mail_context/' ${haproxy_file})

    if [[ ${edited} == 0 ]]; then
        # add mail-backend
        cat ${addendum_file} >> ${haproxy_file}

        # restart nova proxy, make sure mail-service is up
        docker restart nova_proxy_1
    fi;

} || exit 1
