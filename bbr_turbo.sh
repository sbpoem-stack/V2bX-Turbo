#!/usr/bin/env bash
# ==============================================================================
#  BBR Turbo Optimizer for High-Performance Proxy & VPN Servers (V2bX / Sing-box / Xray)
#  专为 V2bX 等跨国代理后端设计的极速 TCP/UDP 拥塞控制与全栈内核极限调优脚本
# ==============================================================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
PLAIN='\033[0m'
BOLD='\033[1m'

# 检查 root 权限
[[ $EUID -ne 0 ]] && echo -e "${RED}[错误] 请使用 root 权限运行此脚本！(sudo -i)${PLAIN}" && exit 1

# 检测系统架构与发行版
ARCH=$(uname -m)
KERNEL_VER=$(uname -r)

if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_NAME=$ID
    OS_VER=$VERSION_ID
elif [ -f /etc/debian_version ]; then
    OS_NAME="debian"
elif [ -f /etc/redhat-release ]; then
    OS_NAME="centos"
else
    OS_NAME="unknown"
fi

# 检查命令行参数直接执行
if [[ "$1" == "4" || "$1" == "--apply" || "$1" == "apply" ]]; then
    apply_sysctl_tuning
    exit 0
elif [[ "$1" == "2" || "$1" == "--enable" || "$1" == "enable" ]]; then
    enable_native_bbr
    exit 0
fi

show_banner() {
    clear
    echo -e "${CYAN}====================================================================${PLAIN}"
    echo -e "${BOLD}${PURPLE}          V2bX / High-Throughput Server BBR Turbo Extreme           ${PLAIN}"
    echo -e "${CYAN}====================================================================${PLAIN}"
    echo -e "${BLUE} 当前系统: ${PLAIN}${OS_NAME} | ${BLUE}CPU架构: ${PLAIN}${ARCH} | ${BLUE}内核版本: ${PLAIN}${KERNEL_VER}"
    echo -e "${BLUE} 当前拥塞控制: ${PLAIN}$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo '未知') | ${BLUE}队列算法: ${PLAIN}$(sysctl -n net.core.default_qdisc 2>/dev/null || echo '未知')"
    echo -e "${CYAN}--------------------------------------------------------------------${PLAIN}"
    if [[ "${ARCH}" == "aarch64" || "${ARCH}" == "arm64" ]]; then
        echo -e "${YELLOW} [ARM64 提示] 已识别为 ARM 架构（如 Oracle ARM、AWS Graviton 等）${PLAIN}"
        echo -e "${GREEN}  1. [ARM64 专属] 升级官方最新 6.x 现代内核 + 极限网络栈调优${PLAIN}"
    else
        echo -e "${GREEN}  1. [推荐] 原生 BBRv3 / XanMod 极速内核 + 极限网络栈调优 (x86_64)${PLAIN}"
    fi
    echo -e "${GREEN}  2. [免换内核] 原生 BBR + BDP 64MB 大窗口与极限调优 (即刻生效)${PLAIN}"
    echo -e "${GREEN}  3. [恶劣网络] 安装 BBRplus / 魔改 BBR (仅限 x86_64)${PLAIN}"
    echo -e "${GREEN}  4. [网络调优] 单独应用 V2bX 极速 Sysctl & Ulimit 调优参数${PLAIN}"
    echo -e "${GREEN}  5. [状态检测] 查看当前 TCP/UDP 缓冲区、BBR 与网络状态${PLAIN}"
    echo -e "${GREEN}  6. [恢复默认] 还原系统网络默认配置${PLAIN}"
    echo -e "${GREEN}  0. 退出脚本${PLAIN}"
    echo -e "${CYAN}====================================================================${PLAIN}"
}

# 1. 应用高通量网络参数 (针对长肥网络 BDP、UDP/QUIC、高并发)
apply_sysctl_tuning() {
    echo -e "${YELLOW}[*] 正在备份当前 sysctl 配置到 /etc/sysctl.conf.bak ...${PLAIN}"
    cp -f /etc/sysctl.conf /etc/sysctl.conf.bak 2>/dev/null

    echo -e "${YELLOW}[*] 正在写入针对 V2bX (跨国长肥网络/高并发/UDP-QUIC) 的极致调优配置...${PLAIN}"
    cat > /etc/sysctl.d/99-v2bx-bbr-turbo.conf << 'EOF'
# ===================================================================
#  V2bX & High-Speed Proxy Kernel Network Optimization (x86_64 & ARM64)
# ===================================================================

# 1. 队列调度与拥塞控制 (使用 fq 与 BBR)
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr

# 2. 突破套接字读写缓冲区限制 (针对 200ms+ 跨国千兆长肥管道优化，最大 64MB 缓存)
net.core.rmem_default = 262144
net.core.wmem_default = 262144
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.optmem_max = 2048576

# 3. TCP 窗口自适应调优 (min, default, max)
# 4KB 最小, 1MB 默认, 64MB 最大窗口，彻底喂饱 1G~10Gbps 国际大带宽
net.ipv4.tcp_rmem = 4096 1048576 67108864
net.ipv4.tcp_wmem = 4096 1048576 67108864

# 4. UDP 接收与发送缓冲调优 (专为 Hysteria 2 / TUIC / QUIC 丢包重传优化)
net.ipv4.udp_rmem_min = 16384
net.ipv4.udp_wmem_min = 16384

# 5. 网络队列及网卡处理能力增强
net.core.netdev_max_backlog = 100000
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 3240000
net.ipv4.tcp_max_tw_buckets = 2000000

# 6. TCP 连接状态与握手极速优化
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_notsent_lowat = 16384
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_autocorking = 0
net.ipv4.tcp_adv_win_scale = 1

# 7. TCP KeepAlive 保持长连接健康度
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_intvl = 15
net.ipv4.tcp_keepalive_probes = 5

# 8. MTU 探测与 SACK/DSACK 容错 (避免跨国链路黑洞丢包)
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_dsack = 1
net.ipv4.tcp_fack = 1
net.ipv4.tcp_window_scaling = 1

# 9. 内存管理与防御配置
vm.swappiness = 10
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5
fs.file-max = 2097152
EOF

    # 启用配置
    sysctl --system >/dev/null 2>&1 || sysctl -p /etc/sysctl.d/99-v2bx-bbr-turbo.conf >/dev/null 2>&1
    echo -e "${GREEN}[✓] Sysctl 网络栈参数调优已写入并生效！${PLAIN}"

    # 优化系统文件句柄限制 (nofile)
    echo -e "${YELLOW}[*] 正在优化系统级文件句柄 limits.conf ...${PLAIN}"
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

    # Systemd 默认限制优化
    if [ -d /etc/systemd/system.conf.d ]; then
        mkdir -p /etc/systemd/system.conf.d
    fi
    cat > /etc/systemd/system.conf.d/99-v2bx-limits.conf 2>/dev/null << 'EOF'
[Manager]
DefaultLimitNOFILE=1048576
DefaultLimitNPROC=524288
EOF
    systemctl daemon-reexec 2>/dev/null || true

    echo -e "${GREEN}[✓] 系统文件描述符限制 (Ulimit) 已扩展至 1,048,576！${PLAIN}"
}

# 2. 原生 BBR 开启
enable_native_bbr() {
    echo -e "${YELLOW}[*] 检查内核是否支持原生 BBR...${PLAIN}"
    modprobe tcp_bbr 2>/dev/null
    apply_sysctl_tuning
    echo -e "${GREEN}[✓] 原生 BBR 极限优化方案已完成部署！${PLAIN}"
    echo -e "${CYAN}当前生效算法: ${PLAIN}$(sysctl -n net.ipv4.tcp_congestion_control)"
    echo -e "${CYAN}当前生效队列: ${PLAIN}$(sysctl -n net.core.default_qdisc)"
}

# 3. 升级最新 6.x 内核 (针对 ARM64 / x86_64)
install_fast_kernel() {
    if [[ "${ARCH}" == "aarch64" || "${ARCH}" == "arm64" ]]; then
        echo -e "${YELLOW}[*] 检测到 ARM64 架构，正在配置官方 Linux 6.x 现代内核...${PLAIN}"
        if [[ "${OS_NAME}" == "ubuntu" ]]; then
            apt-get update && apt-get install -y linux-generic-hwe-$(lsb_release -rs 2>/dev/null || echo "22.04")
        elif [[ "${OS_NAME}" == "debian" ]]; then
            apt-get update && apt-get install -y -t $(lsb_release -cs)-backports linux-image-arm64 linux-headers-arm64 2>/dev/null || apt-get install -y linux-image-arm64
        elif [[ "${OS_NAME}" == "centos" || "${OS_NAME}" == "almalinux" || "${OS_NAME}" == "rocky" ]]; then
            yum install -y kernel kernel-headers
        fi
        apply_sysctl_tuning
        echo -e "${GREEN}====================================================================${PLAIN}"
        echo -e "${GREEN}   🎉 ARM64 现代内核与极速网络调优已完成配置！${PLAIN}"
        echo -e "${YELLOW}   建议重启服务器使新内核与 BBR 生效。${PLAIN}"
        echo -e "${GREEN}====================================================================${PLAIN}"
        read -rp "是否立即重启服务器？[y/N]: " reboot_choice
        if [[ "$reboot_choice" =~ ^[Yy]$ ]]; then
            reboot
        fi
        return 0
    fi

    # x86_64 XanMod (BBRv3)
    echo -e "${YELLOW}[*] 正在准备安装 XanMod 极速内核 (集成官方最新 BBRv3)...${PLAIN}"
    if [[ "${OS_NAME}" != "debian" && "${OS_NAME}" != "ubuntu" ]]; then
        echo -e "${RED}[错误] XanMod 官方源主要支持 Debian / Ubuntu x86_64 系统。${PLAIN}"
        return 1
    fi

    echo -e "${YELLOW}[*] 检测 CPU 微架构层级 (x86-64-v1 ~ v3)...${PLAIN}"
    XANMOD_PKG="linux-xanmod-x64v3"
    if ! grep -q "avx2" /proc/cpuinfo; then
        XANMOD_PKG="linux-xanmod-x64v2"
        if ! grep -q "sse4_2" /proc/cpuinfo; then
            XANMOD_PKG="linux-xanmod"
        fi
    fi
    echo -e "${GREEN}[✓] 匹配到最适合您 CPU 的内核版本: ${XANMOD_PKG}${PLAIN}"

    echo -e "${YELLOW}[*] 正在添加 XanMod 官方 GPG 密钥与软件源...${PLAIN}"
    apt-get update && apt-get install -y wget curl gnupg lsb-release ca-certificates
    wget -qO - https://dl.xanmod.org/archive.key | gpg --dearmor -o /etc/apt/keyrings/xanmod-archive-keyring.gpg --yes
    echo 'deb [signed-by=/etc/apt/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | tee /etc/apt/sources.list.d/xanmod-release.list

    apt-get update
    echo -e "${YELLOW}[*] 正在安装 ${XANMOD_PKG} ...${PLAIN}"
    apt-get install -y "${XANMOD_PKG}"

    # 应用 sysctl 调优
    apply_sysctl_tuning

    echo -e "${GREEN}====================================================================${PLAIN}"
    echo -e "${GREEN}   🎉 XanMod (BBRv3) 内核安装完成！${PLAIN}"
    echo -e "${YELLOW}   注意: 重启服务器后系统将自动运行 BBRv3 极致加速模式！${PLAIN}"
    echo -e "${GREEN}====================================================================${PLAIN}"
    read -rp "是否立即重启服务器？[y/N]: " reboot_choice
    if [[ "$reboot_choice" =~ ^[Yy]$ ]]; then
        reboot
    fi
}

# 4. 安装 BBRPlus (增加架构安全检查，防止 ARM 变砖)
install_bbrplus() {
    if [[ "${ARCH}" == "aarch64" || "${ARCH}" == "arm64" ]]; then
        echo -e "${RED}[安全拦截] 当前为 ARM64 架构！第三方 BBRPlus 脚本包含大量 x86 内核包，安装会导致 ARM 机器失联/变砖！${PLAIN}"
        echo -e "${GREEN}[建议] ARM64 机器请选择 菜单 1 或 菜单 2（原生 BBR + 64MB 极限调优），稳定性与速度最强！${PLAIN}"
        echo -e "\n按任意键返回菜单..."
        read -n 1 -s -r
        return 1
    fi
    echo -e "${YELLOW}[*] 正在调用高丢包恶劣链路专用 BBRplus / 暴力 BBR 脚本...${PLAIN}"
    wget -N --no-check-certificate "https://github.com/cx9208/Linux-NetSpeed/raw/master/tcp.sh" && chmod +x tcp.sh && ./tcp.sh
}

# 5. 查看当前状态
check_status() {
    echo -e "${CYAN}======================= 当前系统网络加速状态 =======================${PLAIN}"
    echo -e "${BLUE}内核版本:${PLAIN} $(uname -r)"
    echo -e "${BLUE}TCP 拥塞控制算法:${PLAIN} $(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)"
    echo -e "${BLUE}队列调度算法 (qdisc):${PLAIN} $(sysctl -n net.core.default_qdisc 2>/dev/null)"
    echo -e "${BLUE}TCP 读缓冲区 (tcp_rmem):${PLAIN} $(sysctl -n net.ipv4.tcp_rmem 2>/dev/null)"
    echo -e "${BLUE}TCP 写缓冲区 (tcp_wmem):${PLAIN} $(sysctl -n net.ipv4.tcp_wmem 2>/dev/null)"
    echo -e "${BLUE}系统最大打开文件数 (file-max):${PLAIN} $(sysctl -n fs.file-max 2>/dev/null)"
    echo -e "${BLUE}当前会话 Ulimit 限制:${PLAIN} $(ulimit -n)"
    echo -e "${BLUE}BBR 内核模块加载状态:${PLAIN} $(lsmod | grep bbr || echo '内置/未加载')"
    echo -e "${CYAN}====================================================================${PLAIN}"
    echo -e "\n按任意键返回菜单..."
    read -n 1 -s -r
}

# 6. 还原默认
restore_defaults() {
    echo -e "${YELLOW}[*] 正在清理 V2bX BBR Turbo 配置文件...${PLAIN}"
    rm -f /etc/sysctl.d/99-v2bx-bbr-turbo.conf
    rm -f /etc/security/limits.d/99-v2bx-limits.conf
    rm -f /etc/systemd/system.conf.d/99-v2bx-limits.conf
    if [ -f /etc/sysctl.conf.bak ]; then
        cp -f /etc/sysctl.conf.bak /etc/sysctl.conf
    fi
    sysctl --system >/dev/null 2>&1 || sysctl -p >/dev/null 2>&1
    echo -e "${GREEN}[✓] 系统网络参数已还原为默认值！${PLAIN}"
    echo -e "\n按任意键返回菜单..."
    read -n 1 -s -r
}

# 主菜单循环
while true; do
    show_banner
    read -rp "请输入选项编号 [0-6]: " choice
    case "${choice}" in
        1)
            install_fast_kernel
            break
            ;;
        2)
            enable_native_bbr
            echo -e "\n按任意键返回菜单..."
            read -n 1 -s -r
            ;;
        3)
            install_bbrplus
            break
            ;;
        4)
            apply_sysctl_tuning
            echo -e "\n按任意键返回菜单..."
            read -n 1 -s -r
            ;;
        5)
            check_status
            ;;
        6)
            restore_defaults
            ;;
        0)
            echo -e "${GREEN}感谢使用，再见！${PLAIN}"
            exit 0
            ;;
        *)
            echo -e "${RED}[错误] 无效选项，请重新输入！${PLAIN}"
            sleep 1
            ;;
    esac
done
