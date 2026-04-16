# bash_script

用于存放个人常用的自动化 Bash 脚本，便于在新环境快速初始化与复用。

## 当前脚本

### `setup-omz.sh`

一键配置 `Zsh + Oh My Zsh + Powerlevel10k` 开发环境。

功能包含：

- 自动识别系统：`macOS` / `Debian` / `RedHat`
- 自动安装基础依赖：`curl`、`git`、`wget`
- 安装并设置 `zsh` 为默认 Shell
- 安装 `Oh My Zsh`
- 安装 `powerlevel10k` 主题
- 安装插件：
  - `zsh-autosuggestions`
  - `zsh-syntax-highlighting`
- 自动备份并更新 `~/.zshrc`

**快速使用：**

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Oakshen/bash_script/main/setup-omz.sh)
```

执行完成后运行 `exec zsh`，首次进入会自动触发 `powerlevel10k` 配置向导。

---

### `sing-box-oneclick.sh`

交互式 [sing-box](https://sing-box.sagernet.org/) 一键安装与配置脚本，**全代理模式**，适合在 Linux 服务器上快速部署透明代理。

功能包含：

- 交互式输入 VLESS 分享链接（`vless://...`），自动解析节点信息，无需手动编辑配置文件
- 支持传输协议：`tcp`、`ws`、`grpc`
- 支持安全类型：`reality`、`tls`、`none`
- 自动生成 **全代理模式** 配置（所有流量走代理，仅私有 IP 直连）
- 自动安装 sing-box、写入配置、校验、重启服务
- 完成后测试出口 IP 确认代理生效

**快速使用：**

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Oakshen/bash_script/main/sing-box-oneclick.sh)
```

脚本会提示输入 VLESS 节点链接，例如：

```
vless://uuid@host:port?type=tcp&security=reality&pbk=...&fp=chrome&sni=...&sid=...#节点名称
```

确认解析信息无误后，脚本将自动完成安装与配置。

> **系统要求：** Linux（使用 `systemd` 管理服务），需要 `sudo` 权限。

---

## 克隆仓库

```bash
git clone https://github.com/Oakshen/bash_script.git
cd bash_script
chmod +x *.sh
```

## 未来计划

- `tailscale` 一键 `DERP` 搭建脚本
- 更多 Linux/macOS 初始化与运维自动化脚本

## 使用说明与风险提示

- 脚本会修改系统配置，建议在新机器或测试环境先验证行为后再用于生产环境
- `sing-box-oneclick.sh` 会写入 `/etc/sing-box/config.json` 并重启 `sing-box` 服务
- `setup-omz.sh` 会修改默认 Shell 及 `~/.zshrc`（自动备份为 `~/.zshrc.bak.<timestamp>`）

## 目录结构

```text
.
├── README.md
├── setup-omz.sh
└── sing-box-oneclick.sh
```
