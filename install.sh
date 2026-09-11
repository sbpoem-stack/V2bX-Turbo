#!/usr/bin/env bash
# ==============================================================================
#  V2bX-Turbo Extreme Installer & Manager (x86_64 & ARM64)
#  专为 V2bX 高性能节点设计的极速安装、面板对接与 BBR 极限加速一键脚本
# ==============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
PLAIN='\033[0m'
BOLD='\033[1m'

# 确保在管道运行 (curl | bash) 时正确接管终端键盘输入
if [ -c /dev/tty ]; then
    exec < /dev/tty 2>/dev/null || true
fi

[[ $EUID -ne 0 ]] && echo -e "${RED}[错误] 请使用 root 权限运行此脚本！(sudo -i)${PLAIN}" && exit 1

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
        echo -e "${RED}[错误] 暂不支持当前系统架构: ${ARCH}${PLAIN}"
        exit 1
        ;;
esac

GITHUB_RAW="https://raw.githubusercontent.com/sbpoem-stack/V2bX-Turbo/main"
CDN_RAW="https://fastly.jsdelivr.net/gh/sbpoem-stack/V2bX-Turbo@main"

INSTALL_DIR="/usr/local/V2bX"
CONFIG_DIR="/etc/V2bX"
SERVICE_FILE="/etc/systemd/system/V2bX.service"

show_menu() {
    clear
    echo -e "${CYAN}====================================================================${PLAIN}"
    echo -e "${BOLD}${PURPLE}          🚀 V2bX-Turbo 高性能定制版 一键管理脚本            ${PLAIN}"
    echo -e "${CYAN}====================================================================${PLAIN}"
    echo -e "${BLUE} 系统架构: ${PLAIN}${ARCH} (${BIN_ARCH}) | ${BLUE}服务状态: ${PLAIN}$(get_status)"
    echo -e "${CYAN}--------------------------------------------------------------------${PLAIN}"
    echo -e "${GREEN} 1. ⚡ 安装 / 升级 V2bX-Turbo (自动应用 BBR 极限网络调优)${PLAIN}"
    echo -e "${GREEN} 2. 📝 生成 / 修改 节点对接配置 (Xboard / V2board / SSPanel)${PLAIN}"
    echo -e "${GREEN} 3. 🚀 启动 V2bX-Turbo${PLAIN}"
    echo -e "${GREEN} 4. 🛑 停止 V2bX-Turbo${PLAIN}"
    echo -e "${GREEN} 5. 🔄 重启 V2bX-Turbo${PLAIN}"
    echo -e "${GREEN} 6. 📜 查看 运行实时日志${PLAIN}"
    echo -e "${GREEN} 7. 🏎️ 开启 / 检测 BBR Turbo 极限网络加速${PLAIN}"
    echo -e "${GREEN} 8. 📊 实时性能监控 (CPU / 内存 / 并发连接 / 错误捕获)${PLAIN}"
    echo -e "${GREEN} 9. ❌ 卸载 V2bX-Turbo${PLAIN}"
    echo -e "${GREEN} 0. 退出脚本${PLAIN}"
    echo -e "${CYAN}====================================================================${PLAIN}"
}

get_status() {
    if systemctl is-active --quiet V2bX; then
        echo -e "${GREEN}正在运行 (Running)${PLAIN}"
    else
        echo -e "${RED}未运行 (Stopped)${PLAIN}"
    fi
}

install_v2bx() {
    echo -e "${YELLOW}[*] 正在安装基础依赖组件 (curl, wget, tar, jq)...${PLAIN}"
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update && apt-get install -y curl wget tar jq ca-certificates
    elif command -v yum >/dev/null 2>&1; then
        yum install -y curl wget tar jq ca-certificates
    fi

    echo -e "${YELLOW}[*] 正在创建工作目录...${PLAIN}"
    mkdir -p "${INSTALL_DIR}" "${CONFIG_DIR}"

    echo -e "${YELLOW}[*] 正在获取最新 V2bX 核心程序 (${BIN_ARCH})...${PLAIN}"
    DOWNLOAD_URL="https://github.com/wyx2685/V2bX/releases/latest/download/V2bX-${BIN_ARCH}.zip"
    
    if ! wget -O /tmp/V2bX.zip "${DOWNLOAD_URL}"; then
        echo -e "${YELLOW}[!] 正在尝试备用下载源...${PLAIN}"
        wget -O /tmp/V2bX.zip "https://ghproxy.net/${DOWNLOAD_URL}"
    fi

    if [ ! -f /tmp/V2bX.zip ]; then
        echo -e "${RED}[错误] 下载核心程序失败，请检查网络！${PLAIN}"
        return 1
    fi

    echo -e "${YELLOW}[*] 解压并安装程序...${PLAIN}"
    if command -v unzip >/dev/null 2>&1; then
        unzip -o /tmp/V2bX.zip -d "${INSTALL_DIR}"
    else
        apt-get install -y unzip 2>/dev/null || yum install -y unzip 2>/dev/null
        unzip -o /tmp/V2bX.zip -d "${INSTALL_DIR}"
    fi
    chmod +x "${INSTALL_DIR}/V2bX"
    ln -sf "${INSTALL_DIR}/V2bX" /usr/bin/v2bx
    ln -sf "${INSTALL_DIR}/V2bX" /usr/bin/V2bX
    rm -f /tmp/V2bX.zip

    # 下载 BBR Turbo 脚本至本地
    curl -fsSL "https://raw.githubusercontent.com/sbpoem-stack/bbr-turbo/main/bbr_turbo.sh" -o "${INSTALL_DIR}/bbr_turbo.sh" 2>/dev/null
    chmod +x "${INSTALL_DIR}/bbr_turbo.sh" 2>/dev/null

    # 写入 systemd 服务单元
    echo -e "${YELLOW}[*] 配置 Systemd 守护进程...${PLAIN}"
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

    # 自动执行 BBR 极限调优 (直接静默注入，带超时防卡死保护)
    echo -e "${GREEN}[*] 正在为服务器自动注入 BBR Turbo 极限网络参数...${PLAIN}"
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
    echo -e "${GREEN}[✓] BBR Turbo 极限网络参数已成功注入！${PLAIN}"

    # 检查默认配置是否存在
    if [ ! -f "${CONFIG_DIR}/config.json" ]; then
        if [ -f "${INSTALL_DIR}/config.json" ]; then
            cp -f "${INSTALL_DIR}/config.json" "${CONFIG_DIR}/config.json"
        fi
        echo -e "${YELLOW}[*] 首次安装，正在引导生成基础配置文件...${PLAIN}"
        config_wizard
    else
        echo -e "${GREEN}[✓] 检测到已有配置文件: ${CONFIG_DIR}/config.json，保持不变。${PLAIN}"
    fi

    systemctl restart V2bX >/dev/null 2>&1 || true
    echo -e "${GREEN}====================================================================${PLAIN}"
    echo -e "${GREEN}   🎉 V2bX-Turbo 极速定制版已成功安装并启动！${PLAIN}"
    echo -e "${CYAN}   - 配置文件路径: ${CONFIG_DIR}/config.json${PLAIN}"
    echo -e "${CYAN}   - 常用快捷命令: ${GREEN}v2bx${CYAN} (打开菜单) / ${GREEN}v2bx log${CYAN} (查看日志)${PLAIN}"
    echo -e "${GREEN}====================================================================${PLAIN}"
}

config_wizard() {
    echo -e "\n${BOLD}${PURPLE}--- 节点对接快速配置向导 ---${PLAIN}"
    local TTY_DEV="/dev/tty"
    if [ ! -c /dev/tty ]; then
        TTY_DEV="/dev/stdin"
    fi

    read -rp "1. 请输入面板类型 [可选: NewV2board / V2board / SSpanel / Xboard] (默认: Xboard): " api_host_type < ${TTY_DEV}
    api_host_type=${api_host_type:-"Xboard"}

    read -rp "2. 请输入面板网址 (例如: https://my-panel.com): " api_host < ${TTY_DEV}
    read -rp "3. 请输入面板通信密钥 (API Key / Token): " api_key < ${TTY_DEV}
    read -rp "4. 请输入节点 ID (Node ID，数字): " node_id < ${TTY_DEV}
    read -rp "5. 请选择核心类型 [1: sing-box (推荐) / 2: xray] (默认: 1): " core_choice < ${TTY_DEV}
    
    if [[ "$core_choice" == "2" ]]; then
        core_type="xray"
    else
        core_type="sing"
    fi

    cat > "${CONFIG_DIR}/config.json" << EOF
{
  "LogConfig": {
    "Level": "info",
    "Output": ""
  },
  "CoresConfig": {
    "Type": "${core_type}"
  },
  "NodeConfig": [
    {
      "Core": "${core_type}",
      "ApiHost": "${api_host}",
      "ApiKey": "${api_key}",
      "NodeID": ${node_id:-1},
      "NodeType": "V2ray",
      "Timeout": 30,
      "TrafficFormat": "json",
      "ApiConfig": {
        "APIHost": "${api_host}",
        "Key": "${api_key}",
        "NodeID": ${node_id:-1},
        "NodeType": "V2ray",
        "Timeout": 30,
        "RuleListPath": ""
      }
    }
  ]
}
EOF
    echo -e "${GREEN}[✓] 配置文件已生成: ${CONFIG_DIR}/config.json${PLAIN}"
}

run_bbr() {
    if [ -f "${INSTALL_DIR}/bbr_turbo.sh" ]; then
        bash "${INSTALL_DIR}/bbr_turbo.sh"
    else
        bash <(curl -fsSL "https://raw.githubusercontent.com/sbpoem-stack/bbr-turbo/main/bbr_turbo.sh")
    fi
}

uninstall_v2bx() {
    read -rp "确定要完全卸载 V2bX-Turbo 吗？[y/N]: " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        systemctl stop V2bX 2>/dev/null
        systemctl disable V2bX 2>/dev/null
        rm -rf "${INSTALL_DIR}" "${CONFIG_DIR}" "${SERVICE_FILE}" /usr/bin/v2bx /usr/bin/V2bX
        systemctl daemon-reload
        echo -e "${GREEN}[✓] V2bX-Turbo 已彻底从服务器卸载！${PLAIN}"
    else
        echo -e "${YELLOW}已取消卸载。${PLAIN}"
    fi
}

# 快捷命令行参数支持
case "$1" in
    start)
        systemctl start V2bX && echo -e "${GREEN}[✓] V2bX-Turbo 启动成功${PLAIN}"
        exit 0
        ;;
    stop)
        systemctl stop V2bX && echo -e "${GREEN}[✓] V2bX-Turbo 已停止${PLAIN}"
        exit 0
        ;;
    restart)
        systemctl restart V2bX && echo -e "${GREEN}[✓] V2bX-Turbo 重启成功${PLAIN}"
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
    read -rp "请输入选项编号 [0-8]: " opt
    case "$opt" in
        1)
            install_v2bx
            echo -e "\n按任意键返回主菜单..."
            read -n 1 -s -r
            ;;
        2)
            config_wizard
            systemctl restart V2bX
            echo -e "\n按任意键返回主菜单..."
            read -n 1 -s -r
            ;;
        3)
            systemctl start V2bX
            echo -e "${GREEN}[✓] 服务已启动！${PLAIN}"
            sleep 1
            ;;
        4)
            systemctl stop V2bX
            echo -e "${YELLOW}[!] 服务已停止！${PLAIN}"
            sleep 1
            ;;
        5)
            systemctl restart V2bX
            echo -e "${GREEN}[✓] 服务已重启！${PLAIN}"
            sleep 1
            ;;
        6)
            journalctl -u V2bX.service -e --no-pager -f
            ;;
        7)
            run_bbr
            ;;
        8)
            if [ -f "${INSTALL_DIR}/monitor.sh" ]; then
                bash "${INSTALL_DIR}/monitor.sh"
            else
                bash <(curl -fsSL "https://raw.githubusercontent.com/sbpoem-stack/V2bX-Turbo/main/monitor.sh")
            fi
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
            echo -e "${RED}[错误] 无效选项！${PLAIN}"
            sleep 1
            ;;
    esac
done
