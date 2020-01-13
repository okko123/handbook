## 使用openssl生成自签证书


# Generate root cert along with root key
openssl req -config ca.conf \
    -newkey rsa:2048 -nodes -keyout out/root.key.pem \
    -new -x509 -days 7300 -out out/root.crt \
    -subj "/C=CN/ST=Guangdong/L=Guangzhou/O=Fishdrowned/CN=Fishdrowned ROOT CA"

# Generate cert key
openssl genrsa -out "out/cert.key.pem" 2048

SAN=""
for var in "$@"
do
    SAN+="DNS:*.${var},DNS:${var},"
done
SAN=${SAN:0:${#SAN}-1}



# Create CSR
openssl req -new -out "${DIR}/$1.csr.pem" \
    -key out/cert.key.pem \
    -reqexts SAN \
    -config <(cat ca.cnf \
        <(printf "[SAN]\nsubjectAltName=${SAN}")) \
    -subj "/C=CN/ST=Guangdong/L=Guangzhou/O=Fishdrowned/OU=$1/CN=*.$1"

# Issue certificate
# openssl ca -batch -config ./ca.cnf -notext -in "${DIR}/$1.csr.pem" -out "${DIR}/$1.cert.pem"
openssl ca -config ./ca.cnf -batch -notext \
    -in "${DIR}/$1.csr.pem" \
    -out "${DIR}/$1.crt" \
    -cert ./out/root.crt \
    -keyfile ./out/root.key.pem

# Chain certificate with CA
cat "${DIR}/$1.crt" ./out/root.crt > "${DIR}/$1.bundle.crt"
ln -snf "./${TIME}/$1.bundle.crt" "${BASE_DIR}/$1.bundle.crt"
ln -snf "./${TIME}/$1.crt" "${BASE_DIR}/$1.crt"
ln -snf "../cert.key.pem" "${BASE_DIR}/$1.key.pem"
ln -snf "../root.crt" "${BASE_DIR}/root.crt"