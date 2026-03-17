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

## 快速开始

方式一：直接在线下载并执行（快速）

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Oakshen/bash_script/main/setup-omz.sh)
```

方式二：克隆仓库后执行（便于管理多个脚本）

```bash
git clone https://github.com/<your-username>/bash_script.git
cd bash_script
chmod +x setup-omz.sh
./setup-omz.sh
```

执行完成后：

```bash
exec zsh
```

首次进入会自动触发 `powerlevel10k` 配置向导，也可手动执行：

```bash
p10k configure
```

## 未来计划

- `tailscale` 一键 `DERP` 搭建脚本
- 更多 Linux/macOS 初始化与运维自动化脚本

## 使用说明与风险提示

- 脚本会修改以下内容，请先确认可接受：
  - 默认 Shell（`chsh -s`）
  - `~/.zshrc`（会自动备份为 `~/.zshrc.bak.<timestamp>`）
- 建议在新机器或测试环境先运行，确认行为符合预期后再用于生产环境。

## 目录结构（当前）

```text
.
├── README.md
└── setup-omz.sh
```
