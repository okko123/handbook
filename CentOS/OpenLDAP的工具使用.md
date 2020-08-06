## 添加访问规则
cat > add_access.ldif <<EOF
dn: olcDatabase={1}mdb,cn=config
add: olcAccess
olcAccess: to * by self write by * read
EOF
ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f add_access.ldif

## 删除访问规则（全部删除）
cat > del_access.ldif <<EOF
dn: olcDatabase={1}mdb,cn=config
changetype: modify
delete: olcAccess
EOF
ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f del_access.ldif

## 查询
ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b cn=config dn