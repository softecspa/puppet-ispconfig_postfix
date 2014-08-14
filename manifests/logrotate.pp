class ispconfig_postfix::logrotate (
  $olddir_owner,
  $olddir_group,
  $olddir_mode,
  $create_owner,
  $create_group,
  $create_mode
){

  # Logrotate configuration. Deleting entry for mail logs in rsyslog logrotate
  # configuration and create a dedicated conf file using logrotate module

  augeas { "maillog_rsyslog_delete":
    changes => [
        "rm /files/etc/logrotate.d/rsyslog/rule[file =~ regexp(\"/var/log/mail.*\")]/file[. =~ regexp(\"/var/log/mail.*\")]",
      ],
    require => [ Class["puppet"], Package["postfix"] ],
  }

  logrotate::file { "postfix":
      log          => "/var/log/mail.log /var/log/mail.err /var/log/mail.warn /var/log/mail.info",
      interval     => "weekly",
      rotation     => "4",
      options      => [ 'notifempty', 'missingok', 'compress', 'delaycompress', 'sharedscripts' ],
      archive      => true,
      olddir       => "/var/log/archives/mail/",
      olddir_owner => $olddir_owner,
      olddir_group => $olddir_group,
      olddir_mode  => $olddir_mode,
      create       => "${create_mode} ${create_owner} ${create_group}",
      postrotate   => 'reload rsyslog >/dev/null 2>&1 || true'
  }
}
