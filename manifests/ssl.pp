class ispconfig_postfix::ssl (
  $ssl_dir,
  $passphrase,
){

  Exec{
    notify  => Service[$postfix::service]
  }

  file { $ssl_dir :
    ensure  => directory,
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    require => Package['postfix'],
  } ->

  file { "${ssl_dir}/ssl.puppet":
    ensure  => present,
    mode    => '0644',
    owner   => root,
    group   => root,
    content => template('ispconfig_postfix/ssl.puppet.erb'),
  } ->

  exec { 'genrsa':
    command => "openssl genrsa -rand /etc/hosts -out ${ssl_dir}/smtpd.key 1024",
    path    => $::path,
    onlyif  => "test ! -s ${ssl_dir}/smtpd.key",
    require => Package['postfix'],
  } ->

  exec { 'smtpdcsr':
    command => "cat ${ssl_dir}/ssl.puppet | openssl req -new -key ${ssl_dir}/smtpd.key -out ${ssl_dir}/smtpd.csr",
    path    => $::path,
    onlyif  => ["test ! -s ${ssl_dir}/smtpd.csr"],
  } ->

  exec { 'smtpdcrt':
    command => "openssl x509 -req -days 3650 -in ${ssl_dir}/smtpd.csr -signkey ${ssl_dir}/smtpd.key -out ${ssl_dir}/smtpd.crt",
    path    => $::path,
    onlyif  => ["test ! -s ${ssl_dir}/smtpd.crt"],
  } ->

  exec { 'unencrypt':
    command => "openssl rsa -in ${ssl_dir}/smtpd.key -out ${ssl_dir}/smtpd.key.unencrypted",
    path    => $::path,
    onlyif  => ["test ! -s ${ssl_dir}/cacert.pem"],
  } ->

  exec { 'movekey':
    command => "mv -f ${ssl_dir}/smtpd.key.unencrypted ${ssl_dir}/smtpd.key",
    path    => $::path,
    onlyif  => ["test -s ${ssl_dir}/smtpd.key.unencrypted"],
  } ->

  file { "${ssl_dir}/smtpd.key":
    owner => 'root',
    group => 'root',
    mode  => '0600'
  } ->

  exec { 'pem':
    command => "cat ${ssl_dir}/ssl.puppet | openssl req -new -x509 -extensions v3_ca -keyout ${ssl_dir}/cakey.pem -out ${ssl_dir}/cacert.pem -days 3650 -passout pass:${passphrase}",
    path    => $::path,
    onlyif  => ["test ! -s ${ssl_dir}/cacert.pem"],
  }

  $postconf = {
    'smtpd_tls_cert_file'             => {value => '/etc/postfix/ssl/smtpd.crt'},
    'smtpd_tls_key_file'              => {value => '/etc/postfix/ssl/smtpd.key'},
    'smtpd_tls_CAfile'                => {value => '/etc/postfix/ssl/cacert.pem'},
    'smtpd_tls_auth_only'             => {value => 'no'},
    'smtp_use_tls'                    => {value => 'yes'},
    'smtp_tls_note_starttls_offer'    => {value => 'yes'},
    'smtpd_tls_loglevel'              => {value => '1'},
    'smtpd_tls_received_header'       => {value => 'yes'},
    'smtpd_tls_session_cache_timeout' => {value => '3600s'},
    'tls_random_source'               => {value => 'dev:/dev/urandom'},
  }

  create_resources('postfix::postconf',$postconf,{require => Package[$postfix::package], notify => Service[$postfix::service]})

}
