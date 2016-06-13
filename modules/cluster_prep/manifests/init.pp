class cluster_prep {

   $install1 = [ 'kmod-drbd84', 'drbd84-utils', 'corosync', 'pacemaker', 'pcs' ]
   $install2 = [ 'postgresql94-server']

   exec { 'se_permissive':
      command => '/usr/sbin/setenforce 0',
   }~>

   package { 'ntp':
      ensure  => present,
   } ~>

   service { 'ntpd':
      ensure => running,
      enable => true,
   } ~>

   package { $install1:
      ensure  => present,
      require => Service["ntpd"]
   }~>

   service { 'pcsd':
      ensure => running,
      enable => true,
   } ~>

   exec { 'hacluster_pw':
      command => '/usr/bin/echo CHANGEME | passwd --stdin hacluster',
      user    => 'root',
   }~>

   package { $install2:
      ensure => present,
   }
}
