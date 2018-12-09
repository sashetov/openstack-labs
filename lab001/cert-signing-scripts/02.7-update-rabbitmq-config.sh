#!/bin/bash
. vars.inc
{
cat <<EOF
[
  {rabbit, [
    {ssl_listeners, [5671]},
    {ssl_options, [
      {cacertfile,"$INTERMED_CA_CERT"},
      {certfile,"$RABBIT_CA_CERT"},
      {keyfile,"$RABBIT_KEY"},
      {verify,verify_peer},
      {versions,['tlsv1.2','tlsv1.1',tlsv1]},
      {fail_if_no_peer_cert,false}
    ]}
  ]}
].
EOF
} > $RABBIT_CONF

systemctl restart rabbitmq-server.service
