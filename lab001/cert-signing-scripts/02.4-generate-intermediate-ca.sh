#!/bin/bash
 . vars.inc
# generate INTERMEDIATE_CA
rm -rf $INTERMED_CA_DIR
mkdir -p $INTERMED_CA_DIR/{certs,crl,csr,newcerts,private}
chmod 0700 $INTERMED_CA_DIR/private
touch $INTERMED_CA_DIR/index.txt
echo 1000 > $INTERMED_CA_DIR/serial
echo 1000 > $INTERMED_CA_DIR/crlnumber
{
cat <<EOF
[ ca ]
default_ca = CA_default

[ CA_default ]
dir               = $INTERMED_CA_DIR
certs             = \$dir/certs
crl_dir           = \$dir/crl
new_certs_dir     = \$dir/newcerts
database          = \$dir/index.txt
serial            = \$dir/serial
RANDFILE          = \$dir/private/.rand
private_key       = \$dir/private/intermediate.key.pem
certificate       = \$dir/certs/intermediate.cert.pem
crlnumber         = \$dir/crlnumber
crl               = \$dir/crl/intermediate.crl.pem
crl_extensions    = crl_ext
default_crl_days  = 30
default_md        = sha256
name_opt          = ca_default
cert_opt          = ca_default
default_days      = 375
preserve          = no
policy            = policy_loose

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
stateOrProvinceName_default     = England
localityName_default            = England
0.organizationName_default      = Alice Ltd
organizationalUnitName_default  = Paragno
emailAddress_default            = root@localhost

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
} > $INTERMED_CA_CONF

openssl genrsa -aes256 -passout pass:$INTERMED_CA_PASS -out $INTERMED_CA_KEY 4096
chmod 0400 $INTERMED_CA_KEY
openssl req -config $INTERMED_CA_CONF  -subj $INTERMED_CA_SUBJ  -new -sha256 -key $INTERMED_CA_KEY   -out $INTERMED_CA_CSR -passin pass:$INTERMED_CA_PASS
openssl ca -batch -config $ROOT_CA_CONF -extensions v3_intermediate_ca -days 365 -notext -md sha256 -passin pass:$ROOT_CA_PASS -in $INTERMED_CA_CSR -out $INTERMED_CA_CERT
chmod 0444 $INTERMED_CA_CERT
openssl x509 -noout -text -in $INTERMED_CA_CERT
openssl verify -CAfile $ROOT_CA_CERT $INTERMED_CA_CERT
cat $INTERMED_CA_CERT  $ROOT_CA_CERT > $INTERMED_CA_CHAIN
chmod 0444 $INTERMED_CA_CHAIN
