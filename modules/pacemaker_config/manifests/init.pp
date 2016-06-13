class pacemaker_config {
   require pg94_setup

   Exec {
      path       => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
      user       => 'root',
      group      => 'root',
      logoutput  => 'on_failure',
   }

   exec { 'pcs_auth':
      command => 'pcs cluster auth node01 node02 -u hacluster -p CHANGEME --force',
      unless  => 'test -f /tmp/cluster_status',
      require => [ Exec['drbd_umount'], Class['pg94_setup'] ],
   }

   exec { 'pcs_setup':
      command => 'pcs cluster setup --name pg94_cluster node01 node02',
      creates => '/etc/corosync/corosync.conf',
      require => Exec['pcs_auth'],
   }

   exec { 'pcs_start':
      command => 'pcs cluster start --all',
      unless  => 'test -f /tmp/cluster_status',
      require => Exec['pcs_setup'],
   }

   exec { 'pcs_enable':
      command => 'pcs cluster enable --all',
      unless  => 'test -f /tmp/cluster_status',
      require => Exec['pcs_start'],
   }

   exec { 'pcs_stonith':
      command => 'pcs property set stonith-enabled=false',
      unless  => 'test -f /tmp/cluster_status',
      require => Exec['pcs_enable'],
   }

   exec { 'pcs_quorum':
      command => 'pcs property set no-quorum-policy=ignore',
      unless  => 'test -f /tmp/cluster_status',
      require => Exec['pcs_stonith'],
   }

   exec { 'pcs_sticky':
      command => 'pcs resource defaults resource-stickiness=200',
      unless  => 'test -f /tmp/cluster_status',
      require => Exec['pcs_quorum'],
   }

   exec { 'pcs_drbd1':
      command => 'pcs resource create p_drbd_pg94 ocf:linbit:drbd drbd_resource=r0 op monitor interval=29s',
      unless  => 'test -f /tmp/cluster_status',
      cwd => '/vagrant',
      require => Exec['pcs_sticky'],
   }

   exec { 'pcs_drbd2':
      command => '/usr/sbin/pcs resource master ms_drbd_pg94 p_drbd_pg94 master-max=1 master-node-max=1 clone-max=2 clone-node-max=1 notify=true',
      unless  => 'test -f /tmp/cluster_status',
      cwd => '/vagrant',
      require => Exec['pcs_drbd1'],
   }

   exec { 'pcs_v_ip':
      command => '/usr/sbin/pcs resource create v_ip ocf:heartbeat:IPaddr2 ip=192.168.56.10 cidr_netmask=32 op monitor interval=30s',
      unless  => 'test -f /tmp/cluster_status',
      require => Exec['pcs_drbd2'],
   }

   exec { 'pcs_fs':
      command => '/usr/sbin/pcs resource create p_fs_pg94 Filesystem device="/dev/drbd0" directory="/var/lib/pg94_drbd" fstype="ext4"',
      unless  => 'test -f /tmp/cluster_status',
      require => Exec['pcs_v_ip'],
   }

   exec { 'pcs_pg94':
      command => '/usr/sbin/pcs resource create p_pg94 ocf:heartbeat:pgsql pgctl="/usr/pgsql-9.4/bin/pg_ctl" psql="/usr/pgsql-9.4/bin/psql" pgdata="/var/lib/pg94_drbd/data" config="/var/lib/pg94_drbd/data/postgresql.conf" op monitor interval=30s timeout=30s',
      unless  => 'test -f /tmp/cluster_status',
      require => Exec['pcs_fs'],
   }

   exec { 'pcs_group':
      command => '/usr/sbin/pcs resource group add g_pg94 p_fs_pg94 v_ip p_pg94',
      unless  => 'test -f /tmp/cluster_status',
      require => Exec['pcs_pg94'],
   }

   exec { 'pcs_coloc':
      command => '/usr/sbin/pcs constraint colocation add ms_drbd_pg94 g_pg94 INFINITY with-rsc-role=Master',
      unless  => 'test -f /tmp/cluster_status',
      require => Exec['pcs_group'],
   }

   exec { 'pcs_order':
      command => '/usr/sbin/pcs constraint order promote ms_drbd_pg94 then start g_pg94',
      unless  => 'test -f /tmp/cluster_status',
      require => Exec['pcs_coloc'],
   }

   $str="cluster built"
   file { '/tmp/cluster_status':
      content => $str,
      require => Exec['pcs_order'],
   }

}
