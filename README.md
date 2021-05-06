### Auto generate self-signed SAN domain name certificate tool

* Native OpenSSL generates self signed SAN CA domain name (V3 signature).
  **In Linux, MacOS system issued the test passed.**
  Generate self-signed SAN CA Domain Name (TLS v3). For a key quickly fast generate development and test environment certificates, internal platform authorization and private DevOps platform build.
* Up to latest version chrome 89.0.4389.90 (x86_64) test passed.
* By Jack Liu ljq@Github
* Statement:
    - This script tool is only for developers to build development and test environment, not for other purposes!
    - Browser security policy change (deadline: March 11, 2021)
        * 1. Security change of chrome 58: common name support is deleted. Use San.
        * 2. Chrome certificate is limited to 398 days,more days than this are marked as unsafe.

[简体中文](https://github.com/ljq/gen-tlsv3-san-ca/blob/main/README_CN.md)

**Check the open extension support module: v3_req:**
(It is recommended to resume the closure after the issuance.)
```
req_extensions = v3_req # The extensions to add to a certificate request
```

**custom.cnf:**
```
# [Solemn Statement]
# This script is only for use in the developer's local development test environment, 
# and is not allowed to be used for other purposes!

[CNF]
# wildcard doamin name
DOMAIN_NAME="*.wdft.com" 

# Browser security policy changes(By a date: 2021-03-11):
# 1.Security Changes in Chrome 58 Version: Common Name Support Dropped. Using SAN instead.
# 2.Chrome certificates are limited to a maximum of 398 days.
# The valid 398 days(The days range must be less than or equal to 398 days)
VALID_DAYS=398

# TLS files generate default current path:
SAN_TLS_PATH="tls-ca"

# Default SUBJECT info: SUBJECT=/C=/ST=/L=/O=/OU=/CN=/emailAddress=
# C  => Country Name(Two acronyms)
# ST => State Name
# L  => City Name
# O  => Organization Name
# OU => Organization Unit Name

SUBJECT.C=CN
SUBJECT.ST=Shanghai
SUBJECT.L=Shanghai
SUBJECT.O=Localhost
SUBJECT.OU=IT-DEV

```

#### Example of CA file generated file directory structure:：

By the domain name **wdft.com** as an example：

```
├── custom.cnf              # Script custom configuration file
├── tls-ca                  # Self-signed certificate generation directory
│ ├── vhost_wdft.com.conf   # Nginx vhost demo
│ ├── wdft.com_ca.crt       # Client root certificate (import or install,add trust)
│ ├── wdft.com.crt          # Server key pair (.crt)
│ ├── wdft.com.key          # Server key pair private key (.key)
│ └── wdft.com.pem          # Server key pair (.pem)
│
├── tls-ca-process          # Process file, used for backup and diagnosis
│ └── 2021-03-13
│ ├── ca.crt
│ ├── ca.key
│ ├── server.crt
│ ├── server.csr
│ └── server.key
│
├── gen-tlsv3-san-ca.sh      # SAN: This file is automatically generated for the first time
└── san.cnf
```

#### Client: Import and Install root CA file
* Download the [domain name]_ca.crt file and import and install,
* Client certificate management add the trust.

#### The test case

![tls-01.png](https://github.com/ljq/gen-tlsv3-san-ca/blob/main/images/tls-01.png)
![tls-02.png](https://github.com/ljq/gen-tlsv3-san-ca/blob/main/images/tls-02.png)
![tls-03.png](https://github.com/ljq/gen-tlsv3-san-ca/blob/main/images/tls-03.png)
![tls-04.png](https://github.com/ljq/gen-tlsv3-san-ca/blob/main/images/tls-04.png)
