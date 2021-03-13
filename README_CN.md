### 自动生成本地自签名SAN域名证书工具

* 原生OpenSSL生成自签名SAN CA域名(V3签名)
* 截至最新版本 Chrome 89.0.4389.90 (x86_64) 版本测试通过。
* 作者: Jack Liu ljq@Github
* 声明:
    - 本脚本工具仅供开发人员搭建开发和测试环境，禁止用于其他目的!
    - 浏览器安全策略变更(截止日期:2021-03-11):
        - 1.Chrome 58的安全改变:普通名称支持被删除。使用SAN。
        - 2.Chrome证书安全策略被限制为最多398天，超过标记不安全。

[English](https://github.com/ljq/gen-tlsv3-san-ca)

**检查开启扩展支持模块：v3_req:**
**(签发完毕后建议恢复关闭)**
```
req_extensions = v3_req # The extensions to add to a certificate request
```

**custom.cnf:**

```
# [严正声明]
# 该脚本仅用于开发人员的本地Dev开发和Test测试环境测试，禁止用于其他用途!

[CNF]
# 通配符域名
DOMAIN_NAME="*.wdft.com"

# 浏览器安全策略更改(截至日期:2021-03-11):
# 1.Chrome 58版本开始的安全改变:普通名称支持被删除。使用SAN标记替代。
# 2.Chrome证书被限制为最多398天。

# 有效的398天(天数范围必须小于或等于398天)
VALID_DAYS=398

# TLS文件生成默认当前路径:
SAN_TLS_PATH="tls-ca"

# Default SUBJECT info: SUBJECT=/C=/ST=/L=/O=/OU=/CN=/emailAddress=
# C =>国家名称(2位首字母简写)
# ST =>状态名
# L =>城市名称
# O =>组织名称
# OU =>组织单位

SUBJECT.C=CN
SUBJECT.ST=Shanghai
SUBJECT.L=Shanghai
SUBJECT.O=Localhost
SUBJECT.OU=IT-DEV
```

#### CA生成文件目录结构示例：

主域名**wdft.com**为例：

```
├── custom.cnf              # 脚本自定义配置文件
├── tls-ca                  # 自签证书生成目录 
│   ├── vhost_wdft.com.conf # Nginx vhost demo
│   ├── wdft.com_ca.crt     # 客户端根证书(导入或安装，添加信任)
│   ├── wdft.com.crt        # 服务器密钥对(.crt)
│   ├── wdft.com.key        # 服务器密钥对私钥(.key)
│   └── wdft.com.pem        # 服务器密钥对(.pem)
│
├── tls-ca-process         # 流程文件，用于备份和诊断
│   └── 2021-03-13
│       ├── ca.crt
│       ├── ca.key
│       ├── server.crt
│       ├── server.csr
│       └── server.key
│
├── gen-tlsv3-san-ca.sh
└── san.cnf                 # SAN: 此文件首次自动生成
```

#### 客户端:导入并安装根CA文件
* 下载 [主域名]_ca.crt文件,将crt文件导入并安装
* 客户端证书添加信任。