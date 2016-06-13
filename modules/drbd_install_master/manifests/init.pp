class drbd_install_master {
   require cluster_prep

   Exec {
      path       => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      user       => 'root',
      group      => 'root',
      logoutput  => 'on_failure',
   }

   file { '/var/lib/pg94_drbd':
      ensure     => 'directory',
      owner      => 'postgres',
      group      => 'postgres',
      require    => Class['cluster_prep'],
   }

   file { '/etc/drbd.conf':
      source     => 'puppet:///modules/cluster_prep/drbd.conf',
      require    => File['/var/lib/pg94_drbd'],
   }

   exec { 'drbd_create':
      command    => 'echo "yes" | /usr/sbin/drbdadm create-md r0',
      unless     => "drbdadm cstate r0 | egrep -q '^(Sync|Connected|WFConnection|StandAlone|Verify)'",
      require    => File['/etc/drbd.conf'],
   }

   service { 'drbd':
      ensure     => running,
      enable     => false,
      require    => Exec['drbd_create'],
   }

   exec { 'drbd_primary':
      command    => 'drbdsetup /dev/drbd0 primary --overwrite-data-of-peer',
      unless     => "drbdadm role r0 |egrep -q '^Primary'",
      require    => Service['drbd'],
      notify     => Exec['drbd_mkfs'],
   }

   exec { 'drbd_mkfs':
      command     => 'mkfs -t ext4 /dev/drbd0',
      user        => 'root',
      before      => Exec['drbd_mount'],
      refreshonly => 'true',
   }

   exec { 'drbd_mount':
      command     => 'mount /dev/drbd0 /var/lib/pg94_drbd',
      unless      => 'test -d /var/lib/pg94_drbd/data/mysql',
      require     => [ Service['drbd'], Exec['drbd_mkfs'] ],
      before      => File['/var/lib/pg94_drbd/data'],
   }

   file { '/var/lib/pg94_drbd/data':
      ensure => 'directory',
      owner => 'postgres',
      group => 'postgres',
      require => Exec['drbd_mount'],
   }
}
