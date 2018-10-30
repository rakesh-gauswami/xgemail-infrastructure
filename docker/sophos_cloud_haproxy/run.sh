#!/usr/bin/env bash

export haproxy_file="${HOME}/g/nova/haproxy/haproxy.cfg"
export addendum_file="././config/xgemail_addendum_haproxy.cfg"
{
    pattern="hub-backend[[:space:]]if[[:space:]]mail_context"
    replacement="mail-backend if mail_context"

    grep -q ${pattern} ${haproxy_file}

    if [ $? -eq 0 ]; then
        # modify existing routing to mail-backend
        gawk -i inplace '{ gsub( "'"${pattern}"'", "'"${replacement}"'" ); }; { print }' ${haproxy_file}

        # add mail-backend
        cat ${addendum_file} >> ${haproxy_file}

        # restart nova proxy, make sure mail-service is up
        docker restart nova_proxy_1
    fi

} || exit 1
