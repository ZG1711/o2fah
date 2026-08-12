# O2FAH

一款运行于 HarmonyOS 的双因素认证 (2FA) 令牌管理应用，基于 Stage 模型和 ArkTS 构建。

## 功能特性

- **TOTP / HOTP 双协议** — 支持 RFC 6238 (基于时间) 和 RFC 4226 (基于计数器) 一次性密码
- **多算法兼容** — SHA-1 / SHA-256 / SHA-512，6 位或 8 位验证码
- **扫码添加** — 相机扫码或相册识别二维码，一键导入令牌
- **手动输入** — 支持 Base32 密钥录入，可调整算法、位数、周期等高级参数
- **分类标签** — 自定义彩色标签，拖拽排序，按标签筛选令牌
- **生物识别锁定** — 调用系统指纹 / 面部识别保护令牌数据
- **加密备份** — 密码加密导出 `.o2fah` 文件，导入时支持合并去重
- **拖拽排序** — 长按卡片拖动排序，触觉反馈，松手自动保存
- **深色模式** — 完整浅色 / 深色配色方案，可跟随系统自动切换
- **纯本地存储** — 设备端加密存储，无网络传输，无云同步

## 技术栈

| 分层 | 技术                                       |
|---|------------------------------------------|
| 平台 | HarmonyOS 6.1.0 · Stage 模型 · API 23      |
| 语言 | ArkTS (严格模式)                             |
| 构建 | hvigor                                   |
| 二维码识别 | 鸿蒙SDK，ScanBarcode模块                      |
| 安全 | @ohos.biometrics · @ohos.security.crypto |

## 快速开始

### 环境要求

- DevEco Studio（最新稳定版）
- HarmonyOS 6.1 SDK

### 构建

```bash
# 增量构建（默认）
hvigorw assembleHap

# 或在 DevEco Studio 中：构建 > 构建 HAP
```

### 运行

连接真机或模拟器后：

```bash
hdc install -r build/default/outputs/default/FAH-default-signed.hap
```

或在 DevEco Studio 中点击 **运行** 按钮。

### 签名配置

项目使用 HarmonyOS 应用签名，配置文件位于 `build-profile.json5` 的 `signingConfigs` 节点。

**调试签名（自动生成）：**

DevEco Studio 首次打开项目时会自动创建调试签名，无需手动配置。签名文件默认存放在：

```
~/.ohos/config/
├── default_O2FAH_xxx.cer    # 调试证书
├── default_O2FAH_xxx.p12    # 密钥库文件
└── default_O2FAH_xxx.p7b    # Profile 文件
```

**发布签名（手动配置）：**

1. 在 DevEco Studio 中打开 **文件 > 项目结构 > Signing Configs**
2. 填写发布证书（`.cer`）、密钥库（`.p12`）及对应密码
3. 配置对应的发布 Profile（`.p7b`）
4. 将 `build-profile.json5` 中 `signingConfigs` 指向发布签名材料

**真机运行须知：**

- 推送到真机需要完成上述签名配置
- 若因签名问题导致安装失败，请在 DevEco Studio 中手动配置签名后重试
- 模拟器运行时使用调试签名即可

## 项目结构

```
O2FAH/
├── AppScope/           # 应用级配置 (app.json5)
├── FAH/                # 主模块 (entry)
│   ├── src/main/ets/   # ArkTS 源码
│   ├── src/main/resources/  # 资源文件、SVG 图标
│   └── build-profile.json5
├── hvigor/             # 构建插件与钩子
└── build-profile.json5 # 根构建配置
```

## 许可

MIT 许可。详见 [LICENSE](LICENSE)。
