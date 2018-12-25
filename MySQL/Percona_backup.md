

https://www.percona.com/downloads/XtraBackup/Percona-XtraBackup-2.4.12/binary/tarball/percona-xtrabackup-2.4.12-Linux-x86_64.libgcrypt145.tar.gz


percona-xtrabackup-8.0.4
This version of Percona XtraBackup can only perform backups and restores against MySQL 8.0 and Percona Server 8.0

yum install perl-Digest-MD5 -y


/usr/local/percona-xtrabackup-2.4.12-Linux-x86_64/bin/xtrabackup \
--defaults-file=/usr/local/mysql-5.6.38/my.cnf \
--backup \
--slave-info \
--compress \
--stream=tar \
--parallel=4 ./ > /data/test.tar.gz
