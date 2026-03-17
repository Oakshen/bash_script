#!/bin/bash

# ============================================
#  Oh My ZSH 一键自动配置脚本
#  适用于全新设备快速搭建 ZSH 开发环境
# ============================================

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ---- 检测操作系统 & 包管理器 ----
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        if ! command -v brew &>/dev/null; then
            info "检测到 macOS，正在安装 Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        PKG_INSTALL="brew install"
        PKG_UPDATE="brew update"
    elif [[ -f /etc/debian_version ]]; then
        OS="debian"
        PKG_INSTALL="sudo apt install -y"
        PKG_UPDATE="sudo apt update"
    elif [[ -f /etc/redhat-release ]]; then
        OS="redhat"
        PKG_INSTALL="sudo yum install -y"
        PKG_UPDATE="sudo yum update -y"
    else
        error "不支持的操作系统，请手动安装。"
    fi
    info "检测到操作系统: $OS"
}

# ---- 0. 更新包索引 & 安装基础依赖 (curl, git, wget) ----
install_prerequisites() {
    # 新机器包索引可能为空，始终先更新一次
    info "正在更新包管理器索引..."
    $PKG_UPDATE

    info "正在检查基础依赖..."
    DEPS_TO_INSTALL=""

    for cmd in curl git wget; do
        if ! command -v "$cmd" &>/dev/null; then
            warn "$cmd 未安装，将自动安装。"
            DEPS_TO_INSTALL="$DEPS_TO_INSTALL $cmd"
        else
            info "$cmd 已就绪。"
        fi
    done

    if [[ -n "$DEPS_TO_INSTALL" ]]; then
        info "正在安装基础依赖:$DEPS_TO_INSTALL ..."
        $PKG_INSTALL $DEPS_TO_INSTALL
        info "基础依赖安装完成。"
    fi
}

# ---- 1. 安装 ZSH ----
install_zsh() {
    if command -v zsh &>/dev/null; then
        info "ZSH 已安装，跳过。($(zsh --version))"
    else
        info "正在安装 ZSH..."
        $PKG_INSTALL zsh
        info "ZSH 安装完成。"
    fi
}

# ---- 2. 设置 ZSH 为默认 Shell ----
set_default_shell() {
    if [[ "$SHELL" == *"zsh"* ]]; then
        info "ZSH 已是默认 Shell，跳过。"
    else
        info "正在将 ZSH 设置为默认 Shell..."
        # 确保 zsh 在 /etc/shells 中
        ZSH_PATH=$(which zsh)
        if ! grep -q "$ZSH_PATH" /etc/shells; then
            echo "$ZSH_PATH" | sudo tee -a /etc/shells
        fi
        chsh -s "$ZSH_PATH"
        info "默认 Shell 已切换为 ZSH（重新登录后生效）。"
    fi
}

# ---- 3. 安装 Oh My ZSH ----
install_oh_my_zsh() {
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        info "Oh My ZSH 已安装，跳过。"
    else
        info "正在安装 Oh My ZSH..."
        # 使用国际源，--unattended 表示非交互模式
        sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        info "Oh My ZSH 安装完成。"
    fi
}

# ---- 4. 安装 Powerlevel10k 主题 ----
install_p10k() {
    P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    if [[ -d "$P10K_DIR" ]]; then
        info "Powerlevel10k 主题已安装，跳过。"
    else
        info "正在安装 Powerlevel10k 主题..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
        info "Powerlevel10k 安装完成。"
    fi
}

# ---- 5. 安装插件 ----
install_plugins() {
    CUSTOM_PLUGINS_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"

    # zsh-autosuggestions：命令自动提示
    if [[ -d "$CUSTOM_PLUGINS_DIR/zsh-autosuggestions" ]]; then
        info "zsh-autosuggestions 已安装，跳过。"
    else
        info "正在安装 zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions "$CUSTOM_PLUGINS_DIR/zsh-autosuggestions"
        info "zsh-autosuggestions 安装完成。"
    fi

    # zsh-syntax-highlighting：语法高亮
    if [[ -d "$CUSTOM_PLUGINS_DIR/zsh-syntax-highlighting" ]]; then
        info "zsh-syntax-highlighting 已安装，跳过。"
    else
        info "正在安装 zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$CUSTOM_PLUGINS_DIR/zsh-syntax-highlighting"
        info "zsh-syntax-highlighting 安装完成。"
    fi
}

# ---- 6. 配置 .zshrc ----
configure_zshrc() {
    ZSHRC="$HOME/.zshrc"

    if [[ ! -f "$ZSHRC" ]]; then
        warn ".zshrc 不存在，Oh My ZSH 应该已创建它。"
        return
    fi

    info "正在配置 .zshrc..."

    # 备份原始配置
    cp "$ZSHRC" "$ZSHRC.bak.$(date +%Y%m%d%H%M%S)"
    info "已备份原 .zshrc"

    # 设置主题为 powerlevel10k
    if grep -q '^ZSH_THEME=' "$ZSHRC"; then
        sed -i.tmp 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$ZSHRC"
        rm -f "$ZSHRC.tmp"
        info "主题已设置为 powerlevel10k。"
    else
        echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' >> "$ZSHRC"
    fi

    # 设置插件列表
    if grep -q '^plugins=' "$ZSHRC"; then
        sed -i.tmp 's/^plugins=.*/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' "$ZSHRC"
        rm -f "$ZSHRC.tmp"
        info "插件列表已更新。"
    else
        echo 'plugins=(git zsh-autosuggestions zsh-syntax-highlighting)' >> "$ZSHRC"
    fi

    info ".zshrc 配置完成。"
}

# ---- 主流程 ----
main() {
    echo ""
    echo "============================================"
    echo "   Oh My ZSH 一键配置脚本"
    echo "============================================"
    echo ""

    detect_os
    install_prerequisites
    install_zsh
    set_default_shell
    install_oh_my_zsh
    install_p10k
    install_plugins
    configure_zshrc

    echo ""
    echo "============================================"
    info " 全部安装配置完成！"
    echo "============================================"
    echo ""
    info "后续步骤："
    echo "  1. 重新打开终端（或执行 exec zsh）使配置生效"
    echo "  2. 首次进入会自动启动 Powerlevel10k 配置向导"
    echo "     也可手动执行: p10k configure"
    echo ""
}

main "$@"
