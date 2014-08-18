class ispconfig_postfix::saslauthd (
  $saslauthd_package    = params_lookup( 'saslauthd_package' ),
  $saslauthd_service    = params_lookup( 'saslauthd_service' ),
  $saslauthd_defaul     = params_lookup( 'saslauthd_default' ),
  $saslauthd_work_dir   = params_lookup( 'saslauthd_work_dir' ),
  $saslauthd_conf_dir   = params_lookup( 'saslauthd_conf_dir' ),
) inherits ispconfig_postfix::params{

  package { 'saslauthd':
    ensure  => present,
    name    => $ispconfig_postfix::saslauthd::saslauthd_package,
  } ->


  augeas { 'default_saslauthd':
    context => "/files/${ispconfig_postfix::saslauthd::saslauthd_default}",
    changes => [
      'set START "yes"',
      "set OPTIONS '\"-c -m ${ispconfig_postfix::saslauthd::saslauthd_work_dir}\"'",
      'set NAME "saslauthd"',
      'set MECHANISMS "pam"',
      'set THREADS "5"',
      'set MECH_OPTIONS ""',
    ],
    notify  => Service[$ispconfig_postfix::saslauthd::saslauthd_service]
  } ->

  exec { "mkdir_sasl_work":
    command => "mkdir -p ${ispconfig_postfix::saslauthd::saslauthd_work_dir}",
    creates => $ispconfig_postfix::saslauthd::saslauthd_work_dir,
    path    => $::path
  } ->

  file { $ispconfig_postfix::saslauthd::saslauthd_work_dir:
    ensure  => directory,
    owner   => 'root',
    group  => 'sasl',
    mode    => '0710'
  } ->

  file {"${saslauthd_conf_dir}/smtpd.conf":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    source  => 'puppet:///modules/ispconfig_postfix/sasl/smtpd.conf',
  } ->

  service {$ispconfig_postfix::saslauthd::saslauthd_service:
    ensure  => running,
    enable  => true,
    hasstatus => false,
    status    => "pidof ${ispconfig_postfix::saslauthd::saslauthd_service}"
  }



}
