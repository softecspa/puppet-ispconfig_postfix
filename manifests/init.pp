class ispconfig_postfix (
  $additional_packages    = params_lookup( 'additional_packages' ),
  $root_dir               = params_lookup( 'root_dir' ),
  $ssl_dir                = params_lookup( 'ssl_dir' ),
  $maincf                 = params_lookup( 'maincf' ),
  $localhostnames         = params_lookup( 'localhostnames' ),
  $ssl                    = params_lookup( 'ssl' ),
  $ssl_passphrase         = params_lookup( 'ssl_passphrase' ),
  $spool_dir              = params_lookup( 'spool_dir' ),
  $uid                    = params_lookup( 'uid' ),
  $gid                    = params_lookup( 'gid' ),
  $saslauthd_package      = params_lookup( 'saslauthd_package' ),
  $root_alias             = params_lookup( 'root_alias' ),
  $wwwdata_alias          = params_lookup( 'wwwdata_alias' ),
  $virtusertable          = params_lookup( 'virtusertable' ),
  $virtusertabledb        = params_lookup( 'virtusertabledb' ),
  $logrotate_olddir_owner = params_lookup( 'logrotate_olddir_owner' ),
  $logrotate_olddir_group = params_lookup( 'logrotate_olddir_group' ),
  $logrotate_olddir_mode  = params_lookup( 'logrotate_olddir_mode' ),
  $logrotate_create_owner = params_lookup( 'logrotate_create_owner' ),
  $logrotate_create_group = params_lookup( 'logrotate_create_group' ),
  $logrotate_create_mode  = params_lookup( 'logrotate_create_mode' ),
) inherits ispconfig_postfix::params {

  package {$ispconfig_postfix::additional_packages:
    ensure  => present
  } ->

  group { 'postfix':
    ensure  => 'present',
    gid     => $ispconfig_postfix::gid,
    system  => true
  } ->

  user { 'postfix':
    ensure  => present,
    home    => $spool_dir,
    shell   => '/bin/false',
    system  => true,
    groups  => 'sasl',
    uid     => $ispconfig_postfix::uid,
    gid     => $ispconfig_postfix::gid,
  } ->

  class {'postfix':}

  file { $localhostnames:
    ensure  => present,
    mode    => '0644',
    owner   => root,
    group   => root,
    require => Package[$postfix::package]
  }

  file { "${localhostnames}-puppet":
    ensure  => present,
    mode    => 644,
    owner   => root,
    group   => root,
    content => template('ispconfig_postfix/local-host-names-puppet.erb'),
    require => Package[$postfix::package],
    notify  => Service[$postfix::service],
  }

  augeas { 'mailname':
    context => '/files/etc/mailname',
    changes => "set hostname '${::fqdn}'",
    notify  => Service[$postfix::service],
  }

  file {$ispconfig_postfix::virtusertable:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    require => Package[$postfix::package],
  } ->

  exec {'virtusertable':
    command => "postmap ${ispconfig_postfix::virtusertable}",
    path    => $::path,
    creates => $ispconfig_postfix::virtusertabledb,
    cwd     => $ispconfig_postfix::root_dir,
    notify  => Service[$postfix::service]
  }

  class {'postfix::aliases':
    maps  => {
      'root'        => $ispconfig_postfix::root_alias,
      'www-data'    => $ispconfig_postfix::wwwdata_alias,
      'postmaster'  => 'root'
    }
  }

  $postconf = {
    'smtpd_banner'                      => {value => '$myhostname ESMTP $mail_name (Ubuntu)'},
    'biff'                              => {value => 'no'},
    'append_dot_mydomain'               => {value => 'no'},
    'readme_directory'                  => {value => 'no'},
    'inet_protocols'                    => {value => 'ipv4'},
    'smtpd_recipient_restrictions'      => {value => 'permit_sasl_authenticated,permit_mynetworks,reject_unauth_destination'},
    'home_mailbox'                      => {value => 'Maildir/'},
    'mailbox_command'                   => {value => ''},
    'myorigin'                          => {value => '/etc/mailname'},
    'mydestination'                     => {value => '/etc/postfix/local-host-names, /etc/postfix/local-host-names-puppet'},
    'mydomain'                          => {value => "${cluster}.${clusterdomain}"},
    'smtpd_sasl_local_domain'           => {value => ''},
    'smtpd_sasl_auth_enable'            => {value => 'yes'},
    'smtpd_sasl_security_options'       => {value => 'noanonymous'},
    'smtpd_use_tls'                     => {value => 'yes'},
    'broken_sasl_auth_clients'          => {value => 'yes'},
    'smtpd_sasl_authenticated_header'   => {value => 'yes'},
    'smtpd_tls_session_cache_database'  => {value => 'btree:${data_directory}/smtpd_scache'},
    'smtp_tls_session_cache_database'   => {value => 'btree:${data_directory}/smtp_scache'},
    'alias_maps'                        => {value => 'hash:/etc/aliases'},
    'alias_database'                    => {value => 'hash:/etc/aliases'},
    'mynetworks'                        => {value => '127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128'},
    'mailbox_size_limit'                => {value => '0'},
    'recipient_delimiter'               => {value => '+'},
    'inet_interfaces'                   => {value => 'all'},
    'mailbox_command'                   => {value => ''},
  }
  create_resources('postfix::postconf',$postconf,{require => Package[$postfix::package], notify => Service[$postfix::service]})

  file_line {'virtual_maps':
    path    => $ispconfig_postfix::maincf,
    line    => "virtual_maps = hash:${ispconfig_postfix::virtusertable}",
    match   => '^virtual_maps',
    require => Package[$postfix::package],
    notify  => Service[$postfix::service]
  }

  file_line {'comment_myhostname':
    ensure  => absent,
    path    => $ispconfig_postfix::maincf,
    line    => "myhostname = $::fqdn",
    match   => '^myhostname',
    require => Package[$postfix::package],
    notify  => Service[$postfix::service]
  }

  class {'ispconfig_postfix::saslauthd':
    require => Class['postfix']
  }


  if $ispconfig_postfix::ssl {
    class {'ispconfig_postfix::ssl':
      ssl_dir     => $ispconfig_postfix::ssl_dir,
      passphrase  => $ispconfig_postfix::ssl_passphrase,
      require     => Package['postfix']
    }
  }

  class {'softec_postfix::logrotate':
    olddir_owner  => $ispconfig_postfix::logrotate_olddir_owner,
    olddir_group  => $ispconfig_postfix::logrotate_olddir_group,
    olddir_mode   => $ispconfig_postfix::logrotate_olddir_mode,
    create_owner  => $ispconfig_postfix::logrotate_create_owner,
    create_group  => $ispconfig_postfix::logrotate_create_group,
    create_mode   => $ispconfig_postfix::logrotate_create_mode,
  }
}
