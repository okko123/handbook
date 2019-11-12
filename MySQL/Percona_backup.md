## Percona XtraBackup使用笔记
* percona-xtrabackup: 2.4.15
* percona-xtrabackup 8.0版本只能用于MySQL 8.0 或 Percona Server 8.0

### 安装
```bash
yum install perl-Digest-MD5 -y

MYSQL_CNF="/apps/mysql-5.6.38/conf/my-3306.cnf"
BACKUPDIR="/data/backup"
BACKUPFILE="erc-`date +%w`.tar.gz"

# 备份
innobackupex \
--defaults-file=${MYSQL_CNF} \
--backup \
--slave-info \
--user=root \
--password=password \
--no-timestamp \
--stream=tar /data/backup/workdir |gzip > ${BACKUPDIR}/${BACKUPFILE}

# 恢复
innobackupex --apply-log $BACKUPDIR
chown -R mysql.mysql $BACKUPDIR
```