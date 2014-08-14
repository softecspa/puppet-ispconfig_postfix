class ispconfig_postfix::params {

  $additional_packages = [
    'libsasl2-2',
    'libsasl2-modules',
    'procmail'
  ]
  $root_dir             = '/etc/postfix'
  $ssl_dir              = "${root_dir}/ssl"
  $localhostnames       = "${root_dir}/local-host-names"
  $ssl                  = true
  $ssl_passphrase       = $::postfix_ssl_passphrase
  $spool_dir            = '/var/spool/postfix'
  $uid                  = $::local_postfix_uid ? {
    undef   => '3001',
    default => $::local_postfix_uid
  }

  $gid                  = $::local_postfix_gid ? {
    undef   => '3001',
    default => $::local_postfix_gid
  }
  $root_alias           = $::notifyemail
  $wwwdata_alias        = $::notifyemail
  $virtusertable        = "${root_dir}/virtusertable"
  $virtusertabledb      = "${root_dir}/virtusertable.db"

  $saslauthd_service    = 'saslauthd'
  $saslauthd_package    = 'sasl2-bin'
  $saslauthd_default    = '/etc/default/saslauthd'
  $saslauthd_work_dir   = "${spool_dir}/var/run/saslauthd"
  $saslauthd_conf_dir   = "${root_dir}/sasl"
}
