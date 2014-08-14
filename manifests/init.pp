class ispconfig_postfix (
  $additional_packages  = params_lookup( 'additional_packages' ),
  $root_dir             = params_lookup( 'root_dir' ),
  $ssl_dir              = params_lookup( 'ssl_dir' ),
  $localhostnames       = params_lookup( 'localhostnames' ),
  $ssl                  = params_lookup( 'ssl' ),
  $ssl_passphrase       = params_lookup( 'ssl_passphrase' ),
  $spool_dir            = params_lookup( 'spool_dir' ),
  $uid                  = params_lookup( 'uid' ),
  $gid                  = params_lookup( 'gid' ),
  $saslauthd_package    = params_lookup( 'saslauthd_package' ),
  $root_alias           = params_lookup( 'root_alias' ),
  $wwwdata_alias        = params_lookup( 'wwwdata_alias' ),
  $virtusertable        = params_lookup( 'virtusertable' ),
  $virtusertabledb      = params_lookup( 'virtusertabledb' ),
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
  }

  file { $localhostnames:
    ensure  => present,
    mode    => '0644',
    owner   => root,
    group   => root,
    require => Package["postfix"],
    #before  => [ Exec["postfix-restart"], Exec["saslauthd-start"] ]
  }

  file { "${localhostnames}-puppet":
    ensure  => present,
    mode    => 644,
    owner   => root,
    group   => root,
    content => template("ispconfig_postfix/local-host-names-puppet.erb"),
    require => Package['postfix'],
    #before  => Exec['postfix-restart'],
  }

  augeas { 'mailname':
    context => "/files/etc/mailname",
    changes => "set hostname '${::fqdn}'",
  }

  file {$ispconfig_postfix::virtusertable:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0444'
  } ->

  exec {'virtusertable':
    command => "postmap ${ispconfig_postfix::virtusertable}",
    path    => $::path,
    creates => $ispconfig_postfix::virtusertabledb,
    cwd     => $ispconfig_postfix::root_dir,
  }

  class {'postfix':
    template  => 'ispconfig_postfix/main.cf.erb'
  } ->
  class {'postfix::aliases':
    maps  => {
      'root'      => $ispconfig_postfix::root_alias,
      'www-data'  => $ispconfig_postfix::wwwdata_alias,
    }
  }
  include ispconfig_postfix::saslauthd
  if $ispconfig_postfix::ssl {
    class {'ispconfig_postfix::ssl':
      ssl_dir     => $ispconfig_postfix::ssl_dir,
      passphrase  => $ispconfig_postfix::ssl_passphrase
    }
  }

  User['postfix'] ->
  Class['postfix'] ->
  Class['ispconfig_postfix::saslauthd']
}
