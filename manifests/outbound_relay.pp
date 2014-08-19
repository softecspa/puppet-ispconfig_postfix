class ispconfig_postfix::outbound_relay (
  $outbound_relay_host        = params_lookup( 'outbound_relay_host' ),
  $outbound_relay_port        = params_lookup( 'outbound_relay_port' ),
  $outbound_relay_user        = params_lookup( 'outbound_relay_user' ),
  $outbound_relay_pass        = params_lookup( 'outbound_relay_pass' ),
  $outbound_relay_auth        = params_lookup( 'outbound_relay_auth' ),
  $outbound_relay_hash_file   = params_lookup( 'outbound_relay_hash_file' ),
) inherits ispconfig_postfix::params {

  if $::operatingsystem != 'Ubuntu' {
    fail('Only Ubuntu distros are supported')
  }

  if ($ispconfig_postfix::outbound_relay::outbound_relay_host == '' ) or ($ispconfig_postfix::outbound_relay::outbound_relay_port == '') or (!is_integer($ispconfig_postfix::outbound_relay::outbound_relay_port)) {
    fail('host and port are mandatory params. Port must be integer')
  }

  if $ispconfig_postfix::outbound_relay::outbound_relay_auth {
    if ($ispconfig_postfix::outbound_relay::outbound_relay_user == '') or ($ispconfig_postfix::outbound_relay::outbound_relay_pass == '') {
      fail('if auth is true, user and pass are mandatory')
    }
  }

  if $ispconfig_postfix::outbound_relay::outbound_relay_host !~ /[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ispconfig_postfix::outbound_relay::outbound_relay_/ {
    $relay_host = "[${ispconfig_postfix::outbound_relay::outbound_relay_host}]:${ispconfig_postfix::outbound_relay::outbound_relay_port}"
  } else {
    $relay_host = "${ispconfig_postfix::outbound_relay::outbound_relay_host}:${ispconfig_postfix::outbound_relay::outbound_relay_port}"
  }

  if $ispconfig_postfix::outbound_relay::outbound_relay_auth {
    file {$ispconfig_postfix::outbound_relay::outbound_relay_hash_file :
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0600',
      content => inline_template('<%= @outbound_relay_host -%> <%= @outbound_relay_user -%>:<%= @outbound_relay_pass -%>'),
    }

    exec {'postmap_sasl_password':
      command     => "postmap hash:${ispconfig_postfix::outbound_relay::outbound_relay_hash_file}",
      refreshonly => true,
      subscribe   => File[$ispconfig_postfix::outbound_relay::outbound_relay_hash_file],
      notify      => Service['postfix'],
      require     => Package['postfix'],
      path        => $::path,
    }

    $auth_conf = {
      'smtp_sasl_auth_enable'       => {value => 'yes'},
      'smtp_sasl_security_options'  => {value => ''},
      'smtp_sasl_password_maps'     => {value => "hash:${ispconfig_postfix::outbound_relay::outbound_relay_hash_file}"},
    }

    create_resources('postfix::postconf',$auth_conf,{require => Package['postfix'], notify => Service['postfix']})
  }

  postfix::postconf { 'relayhost':
    value   => $ispconfig_postfix::outbound_relay::outbound_relay_host,
    require => Package['postfix'],
    notify  => Service['postfix']
  }

}
