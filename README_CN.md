### 自动生成本地自签名SAN域名证书工具

###### 注意事项：此工具禁止用于非法用途，否则产生的一切法律责任等后果均由使用者本人承担！

- 原生OpenSSL生成自签名SAN CA域名(V3签名)，**在Linux、MacOS系统下签发测试通过。**
  用于一键快速生成开发和测试场景证书，内部平台授权和私有DevOps平台搭建。
- 系统测试环境(截至2023.08.18最新版本)：
  - Chrome 版本: 116.0.5845.96 (Official Build) (x86_64) 版本测试通过。
  - macOS 版本 13.4.1(c)
  - Windows 版本: Windows 11 (22H2)
  - Linux 内核发行版: Ubuntu 22.04 LTS（代号 Jammy Jellyfish）
- 作者: Jack Liu ljq@Github
- 声明:
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

#### 客户端:导入并安装根CA文件（导入自签证书颁发机构设为信任）

- 下载 [主域名]\_ca.crt文件,将crt文件导入并安装
- macOS: 客户端证书添加信任
- Windows: 证书存储 -> 将所有的证书都放入下列存储 -> 受信任的根证书颁发机构

**注意事项**：

- 如果是Windows系统环境下，安装时证书存储类型，请选择“受信任的根证书颁发机构”。因为默认根据证书类型自动选择证书存储，并不会存储和归类到根证书颁发机构，需要手动选择安装到根证书颁发机构。
- 补充说明：基于系统、浏览器版本和缓存机制差异，如未生效，可尝试重启浏览器验证是否生效。如问题仍然存在，参考:
  [ \[issue: 1\] ](https://github.com/ljq/gen-tlsv3-san-ca/issues/1)

#### 火狐浏览器导入根证书颁发机构注意事项

###### 因火狐浏览器的安全策略机制设计，需要从浏览器证书管理导入自签证书到证书颁发机构才能被浏览器信任，操作方式如下：

![firefox-tls.png](https://github.com/ljq/gen-tlsv3-san-ca/blob/main/images/firefox-tls.png)

#### 测试用例

![tls-01.png](https://github.com/ljq/gen-tlsv3-san-ca/blob/main/images/tls-01.png)
![tls-02.png](https://github.com/ljq/gen-tlsv3-san-ca/blob/main/images/tls-02.png)
![tls-03.png](https://github.com/ljq/gen-tlsv3-san-ca/blob/main/images/tls-03.png)
![tls-04.png](https://github.com/ljq/gen-tlsv3-san-ca/blob/main/images/tls-04.png)
