class ispconfig_postfix::outbound_relay (
  $outbound_relay_host  = params_lookup( 'outbound_relay_host' ),
  $outbound_relay_port  = params_lookup( 'outbound_relay_port' ),
  $outbound_relay_user  = params_lookup( 'outbound_relay_user' ),
  $outbound_relay_pass  = params_lookup( 'outbound_relay_pass' ),
  $outbound_relay_auth  = params_lookup( 'outbound_relay_auth' ),
  $outbound_relay_hash  = params_lookup( 'outbound_relay_hash' )
) inherits ispconfig_postfix::params {

  if $::operatingsystem != 'Ubuntu' {
    fail('Only Ubuntu distros are supported')
  }

  if ($host == '' ) or ($port == '') or (!is_integer($port)) {
    fail('host and port are mandatory params. Port must be integer')
  }

  if $auth {
    if ($user == '') or ($pass == '') {
      fail('if auth is true, user and pass are mandatory')
    }
  }

  if $host !~ /[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$/ {
    $relay_host = "[${host}]:${port}"
  } else {
    $relay_host = "${host}:${port}"
  }

  if $auth {
    file {$pass_hash :
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0600',
      content => inline_template('<%= @host -%> <%= @user -%>:<%= @pass -%>'),
    }

    exec {'postmap_sasl_password':
      command     => "postmap hash:${pass_hash}",
      refreshonly => true,
      subscribe   => File[$pass_hash],
      notify      => Exec['postfix-reload'],
      path        => $::path,
    }

    postfix::postconf {
      'postconf_sasl_auth_enable':
        cmd => 'smtp_sasl_auth_enable = yes';
      'postconf_sasl_security_options':
        cmd => 'smtp_sasl_security_options = ';
      'postconf_sasl_password_maps':
        cmd => "smtp_sasl_password_maps = hash:${pass_hash}"
    }
  }

  postfix::postconf { 'postconf_relayhost':
    cmd => "relayhost = ${relay_host}";
  }

  exec {'postfix-reload':
    command     => 'postfix reload',
    refreshonly => true
  }

}
