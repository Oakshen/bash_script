#!/usr/bin/env bash
set -euo pipefail

CONFIG_PATH="/etc/sing-box/config.json"
INSTALL_URL="https://sing-box.app/install.sh"

if [[ "${EUID}" -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "[错误] 缺少命令: $1"
    exit 1
  fi
}

urldecode() {
  local url_encoded="${1//+/ }"
  printf '%b' "${url_encoded//%/\\x}"
}

parse_vless_uri() {
  local uri="$1"

  if [[ ! "$uri" =~ ^vless:// ]]; then
    echo "[错误] 无效的 VLESS URI，必须以 vless:// 开头"
    exit 1
  fi

  local stripped="${uri#vless://}"
  local fragment=""
  if [[ "$stripped" == *"#"* ]]; then
    fragment="$(urldecode "${stripped##*#}")"
    stripped="${stripped%%#*}"
  fi

  local userinfo_host="${stripped%%\?*}"
  local query=""
  if [[ "$stripped" == *"?"* ]]; then
    query="${stripped#*\?}"
  fi

  VLESS_UUID="${userinfo_host%%@*}"
  local host_port="${userinfo_host#*@}"
  VLESS_SERVER="${host_port%%:*}"
  VLESS_PORT="${host_port##*:}"
  VLESS_NAME="${fragment:-proxy}"

  VLESS_TYPE="tcp"
  VLESS_SECURITY="none"
  VLESS_SNI=""
  VLESS_FP=""
  VLESS_PBK=""
  VLESS_SID=""
  VLESS_FLOW=""
  VLESS_PATH=""
  VLESS_HOST=""
  VLESS_SERVICE_NAME=""

  IFS='&' read -ra params <<< "$query"
  for param in "${params[@]}"; do
    local key="${param%%=*}"
    local val
    val="$(urldecode "${param#*=}")"
    case "$key" in
      type)         VLESS_TYPE="$val" ;;
      security)     VLESS_SECURITY="$val" ;;
      sni)          VLESS_SNI="$val" ;;
      fp)           VLESS_FP="$val" ;;
      pbk)          VLESS_PBK="$val" ;;
      sid)          VLESS_SID="$val" ;;
      flow)         VLESS_FLOW="$val" ;;
      path)         VLESS_PATH="$val" ;;
      host)         VLESS_HOST="$val" ;;
      serviceName)  VLESS_SERVICE_NAME="$val" ;;
    esac
  done
}

build_outbound_json() {
  local tls_block=""
  local transport_block=""
  local flow_line=""

  if [[ -n "$VLESS_FLOW" ]]; then
    flow_line="$(printf '      "flow": "%s",\n' "$VLESS_FLOW")"
  fi

  if [[ "$VLESS_SECURITY" == "reality" ]]; then
    tls_block=$(cat <<TLSEOF
      "tls": {
        "enabled": true,
        "server_name": "${VLESS_SNI}",
        "utls": {
          "enabled": true,
          "fingerprint": "${VLESS_FP:-chrome}"
        },
        "reality": {
          "enabled": true,
          "public_key": "${VLESS_PBK}",
          "short_id": "${VLESS_SID}"
        }
      }
TLSEOF
)
  elif [[ "$VLESS_SECURITY" == "tls" ]]; then
    tls_block=$(cat <<TLSEOF
      "tls": {
        "enabled": true,
        "server_name": "${VLESS_SNI}"${VLESS_FP:+,
        "utls": {
          "enabled": true,
          "fingerprint": "${VLESS_FP}"
        }}
      }
TLSEOF
)
  fi

  if [[ "$VLESS_TYPE" == "ws" ]]; then
    transport_block=$(cat <<TREOF
      "transport": {
        "type": "ws",
        "path": "${VLESS_PATH:-/}"${VLESS_HOST:+,
        "headers": {
          "Host": "${VLESS_HOST}"
        }}
      }
TREOF
)
  elif [[ "$VLESS_TYPE" == "grpc" ]]; then
    transport_block=$(cat <<TREOF
      "transport": {
        "type": "grpc",
        "service_name": "${VLESS_SERVICE_NAME}"
      }
TREOF
)
  fi

  local trailing_parts=""
  [[ -n "$tls_block" ]] && trailing_parts="${trailing_parts},\n${tls_block}"
  [[ -n "$transport_block" ]] && trailing_parts="${trailing_parts},\n${transport_block}"

  printf '    {
      "type": "vless",
      "tag": "proxy",
      "server": "%s",
      "server_port": %s,
      "uuid": "%s",\n%s%b
    }' \
    "$VLESS_SERVER" "$VLESS_PORT" "$VLESS_UUID" \
    "$flow_line" "$trailing_parts"
}

echo "======================================"
echo "  sing-box 一键安装 & 全代理配置脚本"
echo "======================================"
echo ""

read -rp "请输入 VLESS 分享链接 (vless://...): " VLESS_INPUT

if [[ -z "$VLESS_INPUT" ]]; then
  echo "[错误] VLESS 链接不能为空"
  exit 1
fi

parse_vless_uri "$VLESS_INPUT"

echo ""
echo "--- 解析结果 ---"
echo "  节点名称: ${VLESS_NAME}"
echo "  服务器:   ${VLESS_SERVER}"
echo "  端口:     ${VLESS_PORT}"
echo "  UUID:     ${VLESS_UUID}"
echo "  传输协议: ${VLESS_TYPE}"
echo "  安全类型: ${VLESS_SECURITY}"
[[ -n "$VLESS_SNI" ]] && echo "  SNI:      ${VLESS_SNI}"
[[ -n "$VLESS_FP" ]] && echo "  指纹:     ${VLESS_FP}"
[[ -n "$VLESS_FLOW" ]] && echo "  Flow:     ${VLESS_FLOW}"
[[ "$VLESS_SECURITY" == "reality" ]] && echo "  公钥:     ${VLESS_PBK}" && echo "  Short ID: ${VLESS_SID}"
echo "----------------"
echo ""

read -rp "确认以上信息无误？(Y/n): " CONFIRM
CONFIRM="${CONFIRM:-Y}"
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo "已取消。"
  exit 0
fi

OUTBOUND_JSON="$(build_outbound_json)"

echo ""
echo "[1/6] 检查基础依赖..."
need_cmd curl

if ! command -v sing-box >/dev/null 2>&1; then
  echo "[2/6] 安装 sing-box..."
  curl -fsSL "${INSTALL_URL}" | ${SUDO} sh
else
  echo "[2/6] sing-box 已安装，跳过安装"
fi

echo "[3/6] 检查 sing-box 版本..."
sing-box version

echo "[4/6] 写入全代理配置到 ${CONFIG_PATH}..."
${SUDO} mkdir -p /etc/sing-box

${SUDO} tee "${CONFIG_PATH}" >/dev/null <<JSONEOF
{
  "log": {
    "level": "info",
    "timestamp": true
  },
  "dns": {
    "servers": [
      {
        "tag": "dns-remote",
        "type": "udp",
        "server": "8.8.8.8",
        "server_port": 53,
        "detour": "proxy"
      }
    ],
    "final": "dns-remote",
    "independent_cache": true
  },
  "inbounds": [
    {
      "type": "tun",
      "tag": "tun-in",
      "interface_name": "tun0",
      "address": [
        "172.19.0.1/30"
      ],
      "auto_route": true,
      "strict_route": true,
      "stack": "system",
      "sniff": true
    },
    {
      "type": "mixed",
      "tag": "mixed-in",
      "listen": "127.0.0.1",
      "listen_port": 2080
    }
  ],
  "outbounds": [
${OUTBOUND_JSON},
    {
      "type": "direct",
      "tag": "direct"
    }
  ],
  "route": {
    "rules": [
      {
        "protocol": "dns",
        "action": "hijack-dns"
      },
      {
        "ip_is_private": true,
        "outbound": "direct"
      }
    ],
    "final": "proxy",
    "auto_detect_interface": true
  }
}
JSONEOF

echo "[5/6] 校验配置文件..."
sing-box check -c "${CONFIG_PATH}"

echo "[6/6] 重启并检查服务状态..."
${SUDO} systemctl restart sing-box
${SUDO} systemctl --no-pager --full status sing-box | sed -n '1,20p'

echo ""
echo "[附加] 测试出口 IP..."
curl -fsSL --max-time 10 https://www.icanhazip.com || true

echo ""
echo "完成！当前为全代理模式，所有流量走 proxy 出站。"
