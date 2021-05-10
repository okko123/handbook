import sys
import os
import ldap
import ldap.modlist
import sqlite3

os.environ['LDAPNOINIT']='0'

# Set debugging level
#ldap.set_option(ldap.OPT_DEBUG_LEVEL,255)
ldapmodule_trace_level = 0
ldapmodule_trace_file = sys.stderr

ldap._trace_level = ldapmodule_trace_level
ldapserver = 'ldap://192.168.1.1'

def readuserinfo():
    l = ldap.initialize(ldapserver, trace_level=ldapmodule_trace_level, trace_file=ldapmodule_trace_file)
    l.protocol_version=ldap.VERSION3

    # Try an explicit anon bind to provoke failure
    l.simple_bind_s('','')
    res = l.search_s("ou=研发部,ou=科技中心,dc=abc,dc=cn", ldap.SCOPE_SUBTREE, "objectclass=*",["cn", "mail", "uidNumber"])

    for cn in res:
        if len(cn[1]) > 0:
            ou = cn[0].split(',', 2)
            username = cn[1]['cn'][0].decode('UTF-8')
            mail = cn[1]['mail'][0].decode('UTF-8')
            uidNumber = cn[1]['uidNumber'][0].decode('UTF-8')
            print(username, mail, uidNumber, ou[1])
    l.unbind_s()

def adduser(username, userid, mail, groupname=''):
    l = ldap.initialize(ldapserver)
    l.protocol_version = ldap.VERSION3

    # Bind/authenticate with a user with apropriate rights to add objects
    l.simple_bind("cn=admin,dc=abc,dc=cn", "123456")

    if (groupname == ''):
        dn = "cn={0}, ou=研发部, ou=科技中心, dc=abc, dc=cn".format(username)
    else:
        dn = "cn={0}, ou={1}, ou=研发部, ou=科技中心, dc=abc, dc=cn".format(username, groupname)

    attrs = {}
    attrs['objectclass'] = [
        b'inetOrgPerson',
        b'organizationalPerson',
        b'person',
        b'posixAccount',
        b'shadowAccount',
        b'top'
    ]
    attrs['cn'] = username.encode()
    attrs['sn'] = username.encode()
    attrs['uidNumber'] = userid.encode()
    attrs['gidNumber'] = userid.encode()
    attrs['homeDirectory'] = ("/home/" + username).encode()
    attrs['uid'] = username.encode()
    attrs['userPassword'] = b'123456'
    attrs['mail'] = mail.encode()

    ldif = ldap.modlist.addModlist(attrs)
    print(ldif, dn)

    l.add_s(dn,ldif)

    # add memberof
    groupdn = 'cn={},ou=groups,dc=abc,dc=cn'.format(groupname)
    mod_attrs = [(
        ldap.MOD_ADD,
        'uniqueMember',
        dn.encode()
        )]
    l.modify_s(groupdn, mod_attrs)
    l.unbind()

def main():
    if len(sys.argv) == 3:
        username = sys.argv[1]
        groupname = sys.argv[2]
        mail = '{}@qdama.cn'.format(username)

        con = sqlite3.connect('LDAPuser.db')
        cur = con.cursor()
        sql = "INSERT INTO user (NAME, MAIL, DEPARTMENT) VALUES ('{}','{}','{}');".format(username, mail, groupname)
        cur.execute(sql)
        con.commit()

        sql = "select id from user where name = '{}'".format(username)
        cur.execute(sql)
        userid = str(cur.fetchall()[0][0])
        con.close()
        adduser(username, userid, mail, groupname)
    else:
        usage()

def usage():
    print("{0} username department\nfor example:\npython3 {0} chenxuanxin 运维".format(sys.argv[0]))

if __name__ == "__main__":
    main()