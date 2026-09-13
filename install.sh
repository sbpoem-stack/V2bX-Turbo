#!/usr/bin/env bash
# ==============================================================================
#  V2bX-Turbo High-Performance Proxy Management System (x86_64 & ARM64)
# ==============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
PLAIN='\033[0m'
BOLD='\033[1m'

[[ $EUID -ne 0 ]] && echo -e "${RED}[ERROR] Please run this script as root! (sudo -i)${PLAIN}" && exit 1

ARCH=$(uname -m)
case "${ARCH}" in
    x86_64|amd64)
        BIN_ARCH="linux-64"
        ;;
    aarch64|arm64)
        BIN_ARCH="linux-arm64-v8a"
        ;;
    armv7l|armv7)
        BIN_ARCH="linux-arm32-v7a"
        ;;
    s390x)
        BIN_ARCH="linux-s390x"
        ;;
    *)
        echo -e "${RED}[ERROR] Unsupported CPU architecture: ${ARCH}${PLAIN}"
        exit 1
        ;;
esac

INSTALL_DIR="/usr/local/V2bX"
CONFIG_DIR="/etc/V2bX"
SERVICE_FILE="/etc/systemd/system/V2bX.service"

show_menu() {
    clear
    echo -e "${CYAN}====================================================================${PLAIN}"
    echo -e "${BOLD}${PURPLE}             V2bX-Turbo 高性能定制版 一键管理系统            ${PLAIN}"
    echo -e "${CYAN}====================================================================${PLAIN}"
    echo -e "${BLUE} 系统架构: ${PLAIN}${ARCH} (${BIN_ARCH}) | ${BLUE}服务状态: ${PLAIN}$(get_status)"
    echo -e "${CYAN}--------------------------------------------------------------------${PLAIN}"
    echo -e "${GREEN}  1. 安装 / 升级 V2bX-Turbo (自动应用 BBR 极限网络加速)${PLAIN}"
    echo -e "${GREEN}  2. 智能对接面板配置 (输入面板信息后自动探测补全)${PLAIN}"
    echo -e "${GREEN}  3. 启动 V2bX-Turbo 服务${PLAIN}"
    echo -e "${GREEN}  4. 停止 V2bX-Turbo 服务${PLAIN}"
    echo -e "${GREEN}  5. 重启 V2bX-Turbo 服务${PLAIN}"
    echo -e "${GREEN}  6. 查看 实时运行日志${PLAIN}"
    echo -e "${GREEN}  7. 开启 / 检查 BBR Turbo 极限网络加速${PLAIN}"
    echo -e "${GREEN}  8. 实时性能健康监控 (CPU / 内存 / 并发连接)${PLAIN}"
    echo -e "${GREEN}  9. 卸载 V2bX-Turbo${PLAIN}"
    echo -e "${GREEN}  0. 退出管理菜单${PLAIN}"
    echo -e "${CYAN}====================================================================${PLAIN}"
}

get_status() {
    if systemctl is-active --quiet V2bX; then
        echo -e "${GREEN}运行中 (Running)${PLAIN}"
    else
        echo -e "${RED}已停止 (Stopped)${PLAIN}"
    fi
}

install_v2bx() {
    echo -e "${YELLOW}[*] 正在安装基础依赖组件 (curl, wget, tar, jq)...${PLAIN}"
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update && apt-get install -y curl wget tar jq ca-certificates unzip
    elif command -v yum >/dev/null 2>&1; then
        yum install -y curl wget tar jq ca-certificates unzip
    fi

    echo -e "${YELLOW}[*] 正在创建安装目录...${PLAIN}"
    mkdir -p "${INSTALL_DIR}" "${CONFIG_DIR}"

    echo -e "${YELLOW}[*] 正在获取最新核心程序 (${BIN_ARCH})...${PLAIN}"
    DOWNLOAD_URL="https://github.com/wyx2685/V2bX/releases/latest/download/V2bX-${BIN_ARCH}.zip"
    
    if ! wget -O /tmp/V2bX.zip "${DOWNLOAD_URL}"; then
        echo -e "${YELLOW}[!] 正在尝试备用镜像源...${PLAIN}"
        wget -O /tmp/V2bX.zip "https://ghproxy.net/${DOWNLOAD_URL}"
    fi

    if [ ! -f /tmp/V2bX.zip ]; then
        echo -e "${RED}[ERROR] 下载核心程序失败，请检查网络连接！${PLAIN}"
        return 1
    fi

    echo -e "${YELLOW}[*] 解压并安装程序...${PLAIN}"
    unzip -o /tmp/V2bX.zip -d "${INSTALL_DIR}"
    chmod +x "${INSTALL_DIR}/V2bX"
    ln -sf "${INSTALL_DIR}/V2bX" /usr/bin/v2bx
    ln -sf "${INSTALL_DIR}/V2bX" /usr/bin/V2bX
    rm -f /tmp/V2bX.zip

    # 写入 systemd 服务
    echo -e "${YELLOW}[*] 注册 Systemd 系统服务...${PLAIN}"
    cat > "${SERVICE_FILE}" << EOF
[Unit]
Description=V2bX-Turbo High-Performance Proxy Service
After=network.target nss-lookup.target

[Service]
Type=simple
User=root
WorkingDirectory=${INSTALL_DIR}
ExecStart=${INSTALL_DIR}/V2bX server -c ${CONFIG_DIR}/config.json
Restart=on-failure
RestartSec=5s
LimitNOFILE=1048576
LimitNPROC=524288

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable V2bX >/dev/null 2>&1

    # 自动执行 BBR 极限调优
    echo -e "${GREEN}[*] 正在为系统自动注入 BBR Turbo 极限网络参数...${PLAIN}"
    timeout 2 modprobe tcp_bbr >/dev/null 2>&1 || true
    cat > /etc/sysctl.d/99-v2bx-bbr-turbo.conf << 'EOF'
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.core.rmem_default = 262144
net.core.wmem_default = 262144
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.optmem_max = 2048576
net.ipv4.tcp_rmem = 4096 1048576 67108864
net.ipv4.tcp_wmem = 4096 1048576 67108864
net.ipv4.udp_rmem_min = 16384
net.ipv4.udp_wmem_min = 16384
net.core.netdev_max_backlog = 100000
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 3240000
net.ipv4.tcp_max_tw_buckets = 2000000
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_notsent_lowat = 16384
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_window_scaling = 1
fs.file-max = 2097152
EOF
    timeout 3 sysctl -p /etc/sysctl.d/99-v2bx-bbr-turbo.conf >/dev/null 2>&1 || true

    cat > /etc/security/limits.d/99-v2bx-limits.conf << 'EOF'
* soft nofile 1048576
* hard nofile 1048576
* soft nproc 524288
* hard nproc 524288
root soft nofile 1048576
root hard nofile 1048576
root soft nproc 524288
root hard nproc 524288
EOF
    echo -e "${GREEN}[OK] BBR Turbo 极限网络参数已成功注入！${PLAIN}"

    # 引导智能配置向导
    if [ ! -f "${CONFIG_DIR}/config.json" ]; then
        config_wizard
    else
        echo -e "${GREEN}[OK] 检测到已有配置文件: ${CONFIG_DIR}/config.json，保持不变。${PLAIN}"
    fi

    systemctl restart V2bX >/dev/null 2>&1 || true
    echo -e "${GREEN}====================================================================${PLAIN}"
    echo -e "${GREEN}   [OK] V2bX-Turbo 极速定制版已成功安装并启动！${PLAIN}"
    echo -e "${CYAN}   - 配置文件路径: ${CONFIG_DIR}/config.json${PLAIN}"
    echo -e "${CYAN}   - 常用快捷命令: ${GREEN}v2bx${CYAN} (管理菜单) / ${GREEN}v2bx log${CYAN} (实时日志)${PLAIN}"
    echo -e "${GREEN}====================================================================${PLAIN}"
}

auto_detect_node() {
    local host="$1"
    local key="$2"
    local id="$3"
    
    echo -e "${YELLOW}[*] 正在连接面板 API 智能探测节点信息...${PLAIN}"
    
    local types=("vless" "v2ray" "shadowsocks" "trojan" "hysteria2" "hysteria" "tuic")
    local detected_type=""

    for t in "${types[@]}"; do
        resp=$(curl -s -m 4 "${host}/api/v1/server/UniProxy/config?node_id=${id}&node_type=${t}&token=${key}" -H "Token: ${key}" 2>/dev/null)
        if echo "$resp" | grep -q '"server_port"\|"port"\|"tls"\|"network"\|"routes"'; then
            detected_type="$t"
            echo -e "${GREEN}[OK] 智能识别成功！节点协议类型为: ${BOLD}${CYAN}${t}${PLAIN}"
            break
        elif echo "$resp" | grep -q "Invalid token"; then
            echo -e "${RED}[ERROR] 通信密钥 (Token) 错误，面板拒绝访问！${PLAIN}"
            break
        fi
    done

    if [ -z "$detected_type" ]; then
        echo -e "${YELLOW}[!] 面板未能返回明确协议标识，自动启用通用高性能模式 (v2ray/vless)。${PLAIN}"
        detected_type="v2ray"
    fi

    echo "$detected_type"
}

config_wizard() {
    # 确保安装目录与配置目录存在
    mkdir -p "${CONFIG_DIR}" "${INSTALL_DIR}"

    # 如果尚未安装核心程序，自动先执行安装
    if [ ! -f "${INSTALL_DIR}/V2bX" ]; then
        echo -e "${YELLOW}[*] 检测到系统尚未安装 V2bX-Turbo，正在为您自动预安装核心程序...${PLAIN}"
        install_v2bx
        return
    fi

    echo -e "\n${BOLD}${PURPLE}====================================================================${PLAIN}"
    echo -e "${BOLD}${PURPLE}                 智能节点对接配置向导                               ${PLAIN}"
    echo -e "${BOLD}${PURPLE}====================================================================${PLAIN}"

    echo -e "\n${CYAN}[1/3] 请输入面板网址 (例如: https://api.paopao.cx):${PLAIN}"
    read -r api_host
    api_host=${api_host:-"https://api.paopao.cx"}
    api_host="${api_host%/}"

    echo -e "\n${CYAN}[2/3] 请输入面板通信密钥 (API Key / Token):${PLAIN}"
    read -r api_key

    echo -e "\n${CYAN}[3/3] 请输入节点 ID (Node ID，数字):${PLAIN}"
    read -r node_id
    node_id=${node_id:-59}

    # 自动探测并补全信息
    node_type=$(auto_detect_node "${api_host}" "${api_key}" "${node_id}")
    core_type="sing"

    echo -e "${YELLOW}[*] 正在自动生成全套极限优化配置文件...${PLAIN}"
    mkdir -p "${CONFIG_DIR}"
    cat > "${CONFIG_DIR}/config.json" << EOF
{
  "Log": {
    "Level": "info",
    "Output": ""
  },
  "Cores": [
    {
      "Type": "${core_type}",
      "Log": {
        "Level": "info",
        "Timestamp": true
      }
    }
  ],
  "Nodes": [
    {
      "Core": "${core_type}",
      "ApiHost": "${api_host}",
      "ApiKey": "${api_key}",
      "NodeID": ${node_id},
      "NodeType": "${node_type}",
      "Timeout": 30,
      "ListenIP": "0.0.0.0",
      "SendIP": "0.0.0.0",
      "TCPFastOpen": true,
      "SniffEnabled": true
    }
  ]
}
EOF
    echo -e "${GREEN}[OK] 配置文件已成功生成: ${CONFIG_DIR}/config.json${PLAIN}"
    echo -e "${YELLOW}[*] 正在重启并验证 V2bX-Turbo 服务...${PLAIN}"
    systemctl restart V2bX >/dev/null 2>&1 || true
    sleep 2
    if systemctl is-active --quiet V2bX; then
        echo -e "${GREEN}====================================================================${PLAIN}"
        echo -e "${GREEN}   [OK] V2bX-Turbo 节点已成功上线并全速运行！${PLAIN}"
        echo -e "${CYAN}   - 协议类型: ${BOLD}${node_type}${PLAIN} | 核心: ${BOLD}sing-box (BBR Turbo 加速)${PLAIN}"
        echo -e "${GREEN}====================================================================${PLAIN}"
    else
        echo -e "${RED}[ERROR] 节点启动异常，请使用 v2bx log 查看具体日志。${PLAIN}"
    fi
}

run_bbr() {
    if [ -f "${INSTALL_DIR}/bbr_turbo.sh" ]; then
        bash "${INSTALL_DIR}/bbr_turbo.sh"
    else
        bash <(curl -fsSL "https://raw.githubusercontent.com/sbpoem-stack/V2bX-Turbo/main/bbr_turbo.sh")
    fi
}

uninstall_v2bx() {
    read -rp "确定要完全卸载 V2bX-Turbo 吗？[y/N]: " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        systemctl stop V2bX 2>/dev/null
        systemctl disable V2bX 2>/dev/null
        rm -rf "${INSTALL_DIR}" "${CONFIG_DIR}" "${SERVICE_FILE}" /usr/bin/v2bx /usr/bin/V2bX install.sh*
        systemctl daemon-reload
        echo -e "${GREEN}[OK] V2bX-Turbo 已彻底从服务器卸载！${PLAIN}"
    else
        echo -e "${YELLOW}已取消卸载。${PLAIN}"
    fi
}

# 命令行参数支持
case "$1" in
    start)
        systemctl start V2bX && echo -e "${GREEN}[OK] V2bX-Turbo 启动成功${PLAIN}"
        exit 0
        ;;
    stop)
        systemctl stop V2bX && echo -e "${GREEN}[OK] V2bX-Turbo 已停止${PLAIN}"
        exit 0
        ;;
    restart)
        systemctl restart V2bX && echo -e "${GREEN}[OK] V2bX-Turbo 重启成功${PLAIN}"
        exit 0
        ;;
    log)
        journalctl -u V2bX.service -e --no-pager -f
        exit 0
        ;;
    bbr)
        run_bbr
        exit 0
        ;;
esac

# 交互主菜单
while true; do
    show_menu
    read -rp "请输入选项编号 [0-9]: " opt
    case "$opt" in
        1)
            install_v2bx
            echo -e "\n按回车键返回主菜单..."
            read -r
            ;;
        2)
            config_wizard
            echo -e "\n按回车键返回主菜单..."
            read -r
            ;;
        3)
            systemctl start V2bX
            echo -e "${GREEN}[OK] 服务已启动！${PLAIN}"
            sleep 1
            ;;
        4)
            systemctl stop V2bX
            echo -e "${YELLOW}[!] 服务已停止！${PLAIN}"
            sleep 1
            ;;
        5)
            systemctl restart V2bX
            echo -e "${GREEN}[OK] 服务已重启！${PLAIN}"
            sleep 1
            ;;
        6)
            journalctl -u V2bX.service -e --no-pager -f
            ;;
        7)
            run_bbr
            ;;
        8)
            bash <(curl -fsSL "https://raw.githubusercontent.com/sbpoem-stack/V2bX-Turbo/main/monitor.sh")
            ;;
        9)
            uninstall_v2bx
            break
            ;;
        0)
            echo -e "${GREEN}感谢使用 V2bX-Turbo，再见！${PLAIN}"
            exit 0
            ;;
        *)
            echo -e "${RED}[ERROR] 无效选项: '${opt}'${PLAIN}"
            sleep 1
            ;;
    esac
done
