#vagrant Postgres 9.4 drbd pacemaker centos7 on virtualbox

# Simple Description

As with the Mysql variant, still working to make it a generic build.
At present it will create the cluster and start everything,
but it is fixed to the ip's defined.  

### Simple 2-Node Mysql cluster on Centos7
Built with Vagrant and virtualbox
and incorporating Puppet, DRBD, Postgres 9.4, Pacemaker & Corosync  
Base box is a minimal Centos7

## Defaults ip addresses:  
virtual_ip - 192.168.56.10
node01     - 192.168.56.11
node02     - 192.168.56.12
