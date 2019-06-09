OpenStack部署的记录，基于Rocky版本
基于CentOS7系统进行安装


====
# Enable the OpenStack repository(Version Rocky)
```bash
yum install centos-release-openstack-rocky
```
## Upgrade the Packages on all nodes
```bash
yum upgrade

yum install python-openstackclient openstack-selinux

openstack-glance-api.service
openstack-glance-registry.service


export OS_USERNAME=admin
export OS_PASSWORD=ADMIN_PASS
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
```


# keystone
## 创建数据库
cat > keystone.sql <<EOF
CREATE DATABASE keystone;
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' \
IDENTIFIED BY 'KEYSTONE_DBPASS';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' \
IDENTIFIED BY 'KEYSTONE_DBPASS';
EOF

mysql -u root -p -e "source keystone.sql"

yum install openstack-keystone httpd mod_wsgi -y
cat > /etc/keystone/keystone.conf <<'EOF'
EOF

su -s /bin/sh -c "keystone-manage db_sync" keystone
keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
keystone-manage credential_setup --keystone-user keystone --keystone-group keystone
keystone-manage bootstrap --bootstrap-password ADMIN_PASS \
  --bootstrap-admin-url http://controller:5000/v3/ \
  --bootstrap-internal-url http://controller:5000/v3/ \
  --bootstrap-public-url http://controller:5000/v3/ \
  --bootstrap-region-id RegionOne

sed -i 's/#Server/cServerName controller/g' /etc/httpd/conf/httpd.conf
ln -s /usr/share/keystone/wsgi-keystone.conf /etc/httpd/conf.d/
systemctl enable httpd.service
systemctl start httpd.service

cat > admin.sh <<EOF
export OS_USERNAME=admin
export OS_PASSWORD=ADMIN_PASS
export OS_PROJECT_NAME=admin
export OS_USER_DOMAIN_NAME=Default
export OS_PROJECT_DOMAIN_NAME=Default
export OS_AUTH_URL=http://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
EOF

openstack domain create --description "An Example Domain" example
openstack project create --domain default \
  --description "Service Project" service
openstack project create --domain default \
  --description "Demo Project" myproject
openstack user create --domain default \
  --password-prompt myuser
openstack role create myrole
openstack role add --project myproject --user myuser myrole

## Verify operation
echo "Verify operation"