OpenStack部署的记录，基于Rocky版本
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
