# Class to carry out the configuration of the mysql environment
class pg94_setup {
   require drbd_install_master

   Exec {
      path       => ['/bin', '/sbin', '/usr/bin'],
      user       => 'root',
      group      => 'root',
      logoutput  => 'on_failure',
   }

   exec { 'pg94_install':
      command    => '/usr/pgsql-9.4/bin/initdb -D /var/lib/pg94_drbd/data',
      user       => 'postgres',
      group      => 'postgres',
      unless     => 'test -f /var/lib/pg94_drbd/data/postgresql.conf',
      require    => [ Class['drbd_install_master'], File['/var/lib/pg94_drbd/data'] ],
   }

   exec { 'drbd_umount':
      command    =>'umount /var/lib/pg94_drbd',
      onlyif     => "test `pcs status | grep Masters: | awk '{print $3}'` != \"node01\"",
      require    => Exec['pg94_install']
   }
}
