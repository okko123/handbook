## Ubuntu静默安装
### 使用debconf处理安装预配置，使用debconfig-show + 包名查出预配置项
1. 已slapd包为例（必须先安装slapd），可以看出slapd/password1 和 slapd/password2需要用户填入密码
   ```shell
      abc@test:~$ sudo debconf-show slapd
   * slapd/password1: (password omitted)
     slapd/internal/adminpw: (password omitted)
     slapd/internal/generated_adminpw: (password omitted)
   * slapd/password2: (password omitted)
     slapd/unsafe_selfwrite_acl:
     slapd/dump_database_destdir: /var/backups/slapd-VERSION
     slapd/no_configuration: false
     slapd/purge_database: false
     slapd/backend: MDB
     slapd/invalid_config: true
     shared/organization: nodomain
     slapd/move_old_database: true
     slapd/dump_database: when needed
     slapd/password_mismatch:
     slapd/domain: nodomain
     slapd/upgrade_slapcat_failure:
     slapd/ppolicy_schema_needs_update: abort installation
   ```
2. 在自动化脚本里，用debconf-set-selections设置然后安装，每个配置项格式为  {包名} {配置项key} {配置项类型} {配置项value}
   ```shell
   root@test:~# declare -x LDAP_PASS="12345678"
   cat <<EOF | debconf-set-selections  
   slapd slapd/password1 password ${LDAP_PASS} 
   slapd slapd/password2 password ${LDAP_PASS} 
   LDAP_PRESEED 
   ```