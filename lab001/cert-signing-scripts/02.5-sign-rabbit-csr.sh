#!/bin/bash
 . vars.inc
openssl genrsa -aes256 -passout pass:$RABBIT_CA_PASS -out $RABBIT_KEY 2048
chmod 400 $RABBIT_KEY
openssl req -config $INTERMED_CA_CONF -key $RABBIT_KEY -subj $INTERMED_CA_SUBJ -new -sha256 -out $RABBIT_CSR -passin pass:$INTERMED_CA_PASS
openssl ca -batch -config $INTERMED_CA_CONF -extensions server_cert -days 375 -notext -md sha256 -passin pass:$ROOT_CA_PASS -in $RABBIT_CSR -out $RABBIT_CA_CERT
chmod 444 $RABBIT_CA_CERT
openssl x509 -noout -text -in $RABBIT_CA_CERT
openssl verify -CAfile $INTERMED_CA_CHAIN $RABBIT_CA_CERT
openssl pkcs12 -export -out $RABBIT_CA_CERT_P12 -in $RABBIT_CA_CERT -inkey  $RABBIT_KEY -passout pass:$RABBIT_CA_PASS -passin pass:$RABBIT_CA_PASS
