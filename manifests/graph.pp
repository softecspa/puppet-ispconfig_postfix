class ispconfig_postfix::graph {

  file { "/var/www/cluster.${cluster}.$clusterdomain/web/mailstat.php":
    ensure  => present,
    content => template("ispconfig_postfix/mailstat.php.erb"),
    owner   => 'root',
    group   => 'www-data',
    mode    => 440,
  }

}
