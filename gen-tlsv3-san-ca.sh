#!/usr/bin/env bash
# Generate self-signed SAN CA Domain Name (by openssl extension v3_req)
# @author Jack Liu ljq@Github
# Description:
#   Quick self-signed CA certificates are used for local development testing.
# 
# Statement:
# this script tool from the visa book is only used to facilitate developers
# to build development and testing environment, prohibited for other purposes!
#
# Browser security policy changes(As of the date: 2021-03-11):
# 1.Security Changes in Chrome 58: Common Name Support Dropped. Using SAN instead.
# 2.Chrome certificates are limited to a maximum of 398 days.

# script version
CLI_VERSION="1.0.0"

# color sign
GREEN_COLOR="\033[32m"
CYAN_COLOR="\033[36m"
YELLOW_COLOR="\033[43;37m"
RED_COLOR="\033[31m"
GREEN_BG_COLOR="\033[47;42m"
CYAN_BG_COLOR="\033[47;46m"
RES="\033[0m"

# --------------------------- functions -----------------------------------

# etc conf
function etc_cnf(){
    item=$1
    section="CNF"
    cnf_file="./custom.cnf"
    if [ ! -f "$cnf_file" ]; then
        return 0
    fi
    cnf_options=`awk -F '=' '/'$section'/{a=1}a==1&&$1~/'${item}'/{print $2;exit}' ${cnf_file}`
    cnf_options=${cnf_options//\"/}
    echo ${cnf_options}
}

# san.conf file init
function san_cnf_init(){
    argv_domain_name=$1
    # check san conf
    SAN_CNF_FILE="san.cnf"
    if [ -f "{SAN_CNF_FILE}" ]; then
        return true
    fi

# create defautl san.cnf(Warning: EOF Monopolize a line)
cat > san.cnf << EOF
[req]
default_bits = 4096
default_md = sha256
distinguished_name = req_distinguished_name
req_extensions = v3_req

[req_distinguished_name]clear

[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${argv_domain_name}
IP.1 = 127.0.0.1
EOF

}

# nginx vhost tpl
function nginx_vhost_tpl(){
    argv_san_tls_absolute_path=$1
    argv_host_suffix=$2

cat << EOF
server {
    listen 443;
    server_name www.${host_suffix};

    ssl on;
    # File format (.crt|.pem)
    # ssl_certificate ${argv_san_tls_absolute_path}/${argv_host_suffix}.pem;
    ssl_certificate ${argv_san_tls_absolute_path}/${argv_host_suffix}.crt;
    ssl_certificate_key ${argv_san_tls_absolute_path}/${argv_host_suffix}.key;
    keepalive_timeout 100;

    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    root /home/wwwroot;
}
EOF
}

# --------------------------- task exec -----------------------------------

# wildcard doamin name
DOMAIN_NAME=$(etc_cnf "DOMAIN_NAME")

# The valid max 398 days
VALID_DAYS=$(etc_cnf "VALID_DAYS")

# Serial Numbers by datetime
SET_SERIAL=$(date "+%Y%m%d%H%M%S")

# TLS files generate default current path:
SAN_TLS_PATH=$(etc_cnf "SAN_TLS_PATH")
san_tls_absolute_path=$(pwd)/${SAN_TLS_PATH}

# host_suffix
host_suffix=${DOMAIN_NAME//\*\./}

# Default SUBJECT info
subject_c=$(etc_cnf "SUBJECT.C")
subject_st=$(etc_cnf "SUBJECT.ST")
subject_l=$(etc_cnf "SUBJECT.L")
subject_o=$(etc_cnf "SUBJECT.O")
subject_ou=$(etc_cnf "SUBJECT.OU")
SUBJECT="/C=${subject_c}/ST=${subject_st}/L=${subject_l}/O=${subject_o}/OU=${subject_ou}/CN=${DOMAIN_NAME}/emailAddress=dev-test@${host_suffix}"

# help info
help_info="[usage]: [-h | -help | --help] [-v | -V | --version]"

# Current date
now_date=$(date "+%Y-%m-%d")

# help
case $1 in
    "-v"|"-V"|"--version"|"-version")
        echo -e "${CYAN_COLOR}TLS v3 SAN ca script version：${CLI_VERSION}.${RES}"
        exit
        ;;  
    "-h"|"-help"|"--help") 
        echo -e "${YELLOW_COLOR}${help_info}${RES}"
        exit
        ;;
esac

echo -e "${CYAN_BG_COLOR}------------------- [ Task is starting... ] -----------------------${RES}"

# san.cnf init
san_cnf_init "${DOMAIN_NAME}"

if [ ! -d "./${SAN_TLS_PATH}" ]; then
    mkdir -p ./${SAN_TLS_PATH}
    echo -e "create dir: ./${SAN_TLS_PATH}\n"
fi

# Generate ROOT CA
# Since the issuance of the certificate (no password) :
# 1.Generate the root certificate key
openssl genrsa -out ca.key 4096
# 2.Generate self-signed root certificate
openssl req -new -x509 \
    -days ${VALID_DAYS} \
    -key ca.key \
    -out ca.crt \
    -subj "$SUBJECT"

# V3 Certificate issuance
# 1.Generate Certificate Key
openssl genrsa -out server.key 4096

# 2.CSR generation using SHA256 algorithm to avoid browser weak password error
openssl req -new \
    -sha256 \
    -key server.key \
    -out server.csr \
    -subj "$SUBJECT" \
    -config san.cnf

# 3.Check CSR information
v3_csr_verify=$(openssl req -text -in server.csr | grep "X509v3 Subject Alternative Name")
if [[ "$v3_csr_verify" != "" ]] ; then
    echo -e "${GREEN_COLOR}CSR X509v3 is verified.${RES}\n"
else
    echo -e "${RED_COLOR}CSR X509v3 is not exsit. Please check that the V3 extension module is enabled.${RES}\n"
    exit
fi


# 4.Use the root certificate to sign the certificate as CSR and generate a new certificate server.crt
#   Remark: Here, the serial parameter is globally unique.
#           Certificates with the same serial value on the same device will conflict
openssl x509 -req \
    -days ${VALID_DAYS} \
    -in server.csr \
    -CA ca.crt \
    -CAkey ca.key \
    -set_serial ${SET_SERIAL} \
    -out server.crt \
    -sha256 \
    -extfile san.cnf \
    -extensions v3_req

# 5.Check to see if the CRT certificate is included
v3_crt_verify=$(openssl x509 -text -in server.crt | grep "X509v3 Subject Alternative Name")
if [[ "$v3_crt_verify" != "" ]] ; then
    echo -e "${GREEN_COLOR}CRT X509v3 is verified.${RES}\n"
else
    echo -e "${RED_COLOR}CRT X509v3 is not exsit. Please check that the v3 extension module is enabled.${RES}\n"
    exit
fi

# Copy & rename & bak & move host_suffix files
cp server.key ${host_suffix}.key
cp server.crt ${host_suffix}.crt
cp ca.crt ${host_suffix}_ca.crt
mv ${host_suffix}.key ${san_tls_absolute_path}
mv ${host_suffix}.crt ${san_tls_absolute_path}
mv ${host_suffix}_ca.crt ${san_tls_absolute_path}

# Move process files to ./dev-tls-process/[date]/
if [ ! -d "./${SAN_TLS_PATH}-process/${now_date}" ]; then
    mkdir -p "./${SAN_TLS_PATH}-process/${now_date}"
    echo -e "create dir: ./${SAN_TLS_PATH}-process/${now_date}\n"
fi
mv ca.key ./${SAN_TLS_PATH}-process/${now_date}/ca.key
mv ca.crt ./${SAN_TLS_PATH}-process/${now_date}/ca.crt
mv server.key ./${SAN_TLS_PATH}-process/${now_date}/server.key
mv server.crt ./${SAN_TLS_PATH}-process/${now_date}/server.crt
mv server.csr ./${SAN_TLS_PATH}-process/${now_date}/server.csr

# Convert .crt to .pem
openssl x509 \
    -in ${san_tls_absolute_path}/${host_suffix}.crt \
    -out ${san_tls_absolute_path}/${host_suffix}.pem \
    -outform PEM

# Nginx vhost server deploy example:
nginx_tpl_conf=$(nginx_vhost_tpl "${san_tls_absolute_path}" "${host_suffix}")

echo -e "${CYAN_BG_COLOR}----- [ Validity of Certificate info ] ---------------${RES}"
dates=$(openssl x509 -in ./${SAN_TLS_PATH}/${host_suffix}.crt -noout -dates)
dates=${dates//notBefore=/Start Datetime\: }
dates=${dates//notAfter=/Expire Datetime\: }
serial_subj=$(openssl x509 -in ./${SAN_TLS_PATH}/${host_suffix}.crt -noout -serial -subject)
echo -e "${serial_subj}\n"
echo -e "${CYAN_COLOR}${dates}${RES}\n"
echo -e "${GREEN_COLOR}The certificate generation completed !${RES}\n"

# generate nginx vhost example .conf
echo "${nginx_tpl_conf}" > ${san_tls_absolute_path}/vhost_${host_suffix}.conf

echo -e "${CYAN_BG_COLOR}----- [ Deployment instructions (Template: Nginx vhost example) ] ----${RES}\n"
echo -e "${CYAN_COLOR}${nginx_tpl_conf}${RES}\n"
echo -e "${CYAN_BG_COLOR}----- [  Client CA import install file ] ----${RES}"
echo -e "${CYAN_COLOR}[Client CA import install file]: ./${SAN_TLS_PATH}/${host_suffix}_ca.crt${RES}\n"
echo -e "${YELLOW_COLOR}The client imports the CA root certificate and sets to add trust.${RES}\n\n"

echo -e "${CYAN_BG_COLOR}------------------- [ Task is completed ] --------------------------${RES}"
exit
