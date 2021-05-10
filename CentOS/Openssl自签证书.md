## 使用openssl生成自签证书
### 创建CA的配置文件，配置CA证书的有效时间10年
* centos下，ca.cnf 文件路径为/etc/pki/tls/openssl.cnf。
* 使用默认/etc/pki/tls/openssl.cnf配置文件，需要执行sed -i '|# copy_extensions|copy_extensions|g' /etc/pki/tls/openssl.cnf启用SubjectAltName。
```bash
cat > ca.cnf << EOF
[ ca ]
default_ca = ROOT_CA

[ ROOT_CA ]
new_certs_dir   = ./out/newcerts
certificate     = ./out/root.crt
database        = ./out/index.txt
private_key     = ./out/root.key.pem
serial          = ./out/serial
unique_subject  = no
default_days    = 3700
default_md      = sha256
policy          = policy_loose
x509_extensions = ca_extensions
copy_extensions = copy

[ policy_loose ]
countryName             = optional
stateOrProvinceName     = optional
localityName            = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ ca_extensions ]
basicConstraints = CA:false
nsComment = "OpenSSL Generated Server Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always
keyUsage = digitalSignature,keyEncipherment
extendedKeyUsage = serverAuth

[ req ]
default_bits        = 2048
distinguished_name  = req_distinguished_name
string_mask         = utf8only
default_md          = sha256
x509_extensions     = v3_ca

[ req_distinguished_name ]
countryName                     = Country Name (2 letter code)
stateOrProvinceName             = State or Province Name
localityName                    = Locality Name
organizationName                = Organization Name
organizationalUnitName          = Organizational Unit Name
commonName                      = Common Name
emailAddress                    = Email Address

countryName_default             = CN
stateOrProvinceName_default     = Guangdong
localityName_default            = Guangzhou
organizationName_default        = Fishdrowned
organizationalUnitName_default  =
emailAddress_default            =

[ v3_ca ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ v3_intermediate_ca ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true, pathlen:0
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ usr_cert ]
basicConstraints = CA:FALSE
nsCertType = client, email
nsComment = "OpenSSL Generated Client Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth, emailProtection

[ server_cert ]
basicConstraints = CA:FALSE
nsCertType = server
nsComment = "OpenSSL Generated Server Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer:always
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth

[ ocsp ]
basicConstraints = CA:FALSE
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, digitalSignature
extendedKeyUsage = critical, OCSPSigning
EOF
```
### 生成CA证书
```bash
#创建临时目录
if [ -d out ];then
    rm -rf out
fi

mkdir out
pushd out
mkdir newcerts
touch index.txt
echo "unique_subject = no" > index.txt.attr
echo 1000 > serial
popd

#Generate root cert along with root key
openssl genrsa -out out/ca.key.pem

#Generate Certificate Signing Request
openssl req -config ca.cnf \
-key out/ca.key.pem \
-new \
-x509 \
-out out/ca.crt \
-subj "/C=CN/ST=Guangdong/L=Guangzhou/O=Your Organization/CN=Your Organization ROOT CA"
```
### 生成自签证书
```bash
DOMAIN="abc_com"
DIR="out"
#Generate cert key
openssl genrsa -out "${DIR}/${DOMAIN}.key.pem" 2048

#Certificate Signing Request
openssl req -new -out "${DIR}/${DOMAIN}.csr.pem" \
-key out/${DOMAIN}.key.pem \
-reqexts SAN \
-config <(cat ca.cnf \
<(printf "[SAN]\nsubjectAltName=DNS:image.abc.com, DNS:www.abc.com, DNS:m.abc.com")) \
-subj "/C=CN/ST=Guangdong/L=Guangzhou/O=Your Organization/CN=abc.com"

# Issue certificate
openssl ca -config ./ca.cnf -batch -notext \
-in "${DIR}/${DOMAIN}.csr.pem" \
-out "${DIR}/${DOMAIN}.crt" \
-cert ./out/ca.crt \
-keyfile ./out/ca.key.pem
```