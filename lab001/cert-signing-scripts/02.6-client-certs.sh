#!/bin/bash
 . vars.inc

openssl genrsa -aes256 -passout pass:$CLIENT_CA_PASS -out $CLIENT_KEY 2048
chmod 400 $CLIENT_KEY
openssl req -config $INTERMED_CA_CONF -key $CLIENT_KEY -subj $CLIENT_SUBJ -new -sha256 -out $CLIENT_CSR -passin pass:$INTERMED_CA_PASS
openssl ca -batch -config $INTERMED_CA_CONF -extensions usr_cert -days 375 -notext -md sha256 -passin pass:$ROOT_CA_PASS -in $CLIENT_CSR -out $CLIENT_CERT
chmod 444 $CLIENT_CERT
openssl x509 -noout -text -in $CLIENT_CERT
openssl verify -CAfile $INTERMED_CA_CHAIN $CLIENT_CERT
openssl pkcs12 -export -out $CLIENT_CERT_P12 -in $CLIENT_CERT -inkey $CLIENT_KEY -passout pass:$CLIENT_CA_PASS -passin pass:$CLIENT_CA_PASS
