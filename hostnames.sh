# update the hosts files
sudo cp /vagrant/hosts.txt /etc
sudo mv /etc/hosts.txt /etc/hosts

echo "Adding puppet repo"
sudo rpm -ivh https://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm
echo "Adding drbd repo"
sudo rpm -ivh http://elrepo.org/elrepo-release-7.0-2.el7.elrepo.noarch.rpm
echo "Adding postgres repo"
sudo rpm -ivh https://download.postgresql.org/pub/repos/yum/9.4/redhat/rhel-7-x86_64/pgdg-centos94-9.4-2.noarch.rpm
echo "installing puppet"
sudo yum install -y puppet
