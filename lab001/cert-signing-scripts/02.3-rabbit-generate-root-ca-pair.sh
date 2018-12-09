#!/bin/bash
# generate ROOT_CA
 . vars.inc
rm -rf $ROOT_CA_DIR
mkdir -p $ROOT_CA_DIR/{certs,crl,newcerts,private}
chmod 0700 $ROOT_CA_DIR/private
touch $ROOT_CA_DIR/index.txt
echo 1000 > $ROOT_CA_DIR/serial

{
cat <<EOF
[ ca ]
default_ca = CA_default

[ CA_default ]
dir               = $ROOT_CA_DIR
certs             = \$dir/certs
crl_dir           = \$dir/crl
new_certs_dir     = \$dir/newcerts
database          = \$dir/index.txt
serial            = \$dir/serial
RANDFILE          = \$dir/private/.rand
private_key       = \$dir/private/ca.key.pem
certificate       = \$dir/certs/ca.cert.pem
crlnumber         = \$dir/crlnumber
crl               = \$dir/crl/ca.crl.pem
crl_extensions    = crl_ext
default_crl_days  = 30
default_md        = sha256
name_opt          = ca_default
cert_opt          = ca_default
default_days      = 375
preserve          = no
policy            = policy_strict

[ policy_strict ]
countryName             = match
stateOrProvinceName     = match
organizationName        = match
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ policy_loose ]
countryName             = optional
stateOrProvinceName     = optional
localityName            = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

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
0.organizationName              = Organization Name
organizationalUnitName          = Organizational Unit Name
commonName                      = Common Name
emailAddress                    = Email Address
countryName_default             = GB
stateOrProvinceName_default     = FAKECA
localityName_default            = SLOUGH
0.organizationName_default      = SESHSNET
organizationalUnitName_default  = SSLS
emailAddress_default            = root@mysql-001.vassilevski.com

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

[ crl_ext ]
authorityKeyIdentifier=keyid:always

[ ocsp ]
basicConstraints = CA:FALSE
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, digitalSignature
extendedKeyUsage = critical, OCSPSigning
EOF
} > $ROOT_CA_CONF

openssl genrsa -aes256 -passout pass:$ROOT_CA_PASS -out $ROOT_CA_KEY 4096
chmod 0400 $ROOT_CA_KEY
openssl req -config $ROOT_CA_CONF -key $ROOT_CA_KEY -new -x509 -days 7300 -sha256 -extensions v3_ca -subj $ROOT_CA_SUBJ  -passin pass:$ROOT_CA_PASS -out $ROOT_CA_CERT
chmod 0444 -out $ROOT_CA_CERT
openssl x509 -noout -text -in $ROOT_CA_CERT
