class ispconfig_postfix::ssl (
  $ssl_dir,
  $passphrase,
){

  file { $ssl_dir :
    ensure  => directory,
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    require => Package["postfix"],
    #before  => [ Exec["postfix-restart"], Exec["saslauthd-start"] ]
  } ->

  file { "${ssl_dir}/ssl.puppet":
    ensure  => present,
    mode    => '0644',
    owner   => root,
    group   => root,
    content => template("ispconfig_postfix/ssl.puppet.erb"),
  } ->

  exec { 'genrsa':
    command => "openssl genrsa -rand /etc/hosts -out ${ssl_dir}/smtpd.key 1024",
    path    => $::path,
    onlyif  => "test ! -s ${ssl_dir}/smtpd.key",
    require => Package["postfix"],
    #before  => [ Exec["postfix-restart"], Exec["saslauthd-start"] ]
  } ->

  exec { "smtpdcsr":
    command => "cat ${ssl_dir}/ssl.puppet | openssl req -new -key ${ssl_dir}/smtpd.key -out ${ssl_dir}/smtpd.csr",
    path    => $::path,
    onlyif  => ["test ! -s ${ssl_dir}/smtpd.csr"],
    #before  => [ Exec["postfix-restart"], Exec["saslauthd-start"] ]
  } ->

  exec { "smtpdcrt":
    command => "openssl x509 -req -days 3650 -in ${ssl_dir}/smtpd.csr -signkey ${ssl_dir}/smtpd.key -out ${ssl_dir}/smtpd.crt",
    path    => $::path,
    onlyif  => ["test ! -s ${ssl_dir}/smtpd.crt"],
    #before  => [ Exec["postfix-restart"], Exec["saslauthd-start"] ]
  } ->

  exec { "unencrypt":
    command => "openssl rsa -in ${ssl_dir}/smtpd.key -out ${ssl_dir}/smtpd.key.unencrypted",
    path    => $::path,
    onlyif  => ["test ! -s ${ssl_dir}/cacert.pem"],
    #before  => [ Exec["postfix-restart"], Exec["saslauthd-start"] ]
  } ->

  exec { "movekey":
    command => "mv -f ${ssl_dir}/smtpd.key.unencrypted ${ssl_dir}/smtpd.key",
    path    => $::path,
    onlyif  => ["test -s ${ssl_dir}/smtpd.key.unencrypted"],
    #before  => [ Exec["postfix-restart"], Exec["saslauthd-start"] ]
  } ->

  file { "${ssl_dir}/smtpd.key":
    owner => 'root',
    group => 'root',
    mode  => '0600'
  } ->

  exec { "pem":
    command => "cat ${ssl_dir}/ssl.puppet | openssl req -new -x509 -extensions v3_ca -keyout ${ssl_dir}/cakey.pem -out ${ssl_dir}/cacert.pem -days 3650 -passout pass:${passphrase}",
    path    => $::path,
    onlyif  => ["test ! -s ${ssl_dir}/cacert.pem"],
    #before  => [ Exec["postfix-restart"], Exec["saslauthd-start"] ]
  }

}
