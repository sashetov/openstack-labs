class packstack::glance::ceilometer ()
{
    $kombu_ssl_ca_certs = hiera('CONFIG_AMQP_SSL_CACERT_FILE', undef)
    $kombu_ssl_keyfile = hiera('CONFIG_GLANCE_SSL_KEY', undef)
    $kombu_ssl_certfile = hiera('CONFIG_GLANCE_SSL_CERT', undef)

    if $kombu_ssl_keyfile {
      $files_to_set_owner = [ $kombu_ssl_keyfile, $kombu_ssl_certfile ]
      file { $files_to_set_owner:
        owner   => 'glance',
        group   => 'glance',
        require => Class['::glance::notify::rabbitmq'],
        notify  => Service['glance-api'],
      }
    }
    class { '::glance::notify::rabbitmq':
      rabbit_host                  => hiera('CONFIG_AMQP_HOST_URL'),
      rabbit_notification_exchange => 'glance',
      rabbit_notification_topic    => 'notifications',
      rabbit_port                  => hiera('CONFIG_AMQP_CLIENTS_PORT'),
      rabbit_use_ssl               => hiera('CONFIG_AMQP_SSL_ENABLED'),
      rabbit_userid                => hiera('CONFIG_AMQP_AUTH_USER'),
      rabbit_password              => hiera('CONFIG_AMQP_AUTH_PASSWORD'),
      kombu_ssl_ca_certs           => $kombu_ssl_ca_certs,
      kombu_ssl_keyfile            => $kombu_ssl_keyfile,
      kombu_ssl_certfile           => $kombu_ssl_certfile,
      notification_driver          => 'messagingv2',
    }
}
