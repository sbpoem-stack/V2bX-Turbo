#!/usr/bin/env bash
# ==============================================================================
#  V2bX-Turbo Performance & Health Monitor
#  持续监控 V2bX 服务的 CPU、内存、网络连接、UDP丢包与运行日志
# ==============================================================================

INTERVAL=3 # 采样间隔(秒)
LOG_FILE="/tmp/v2bx_monitor.log"

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
PLAIN='\033[0m'
BOLD='\033[1m'

echo -e "${CYAN}====================================================================${PLAIN}"
echo -e "${BOLD}${GREEN}        🚀 V2bX-Turbo 实时性能与健康监控探针 (持续采样中)        ${PLAIN}"
echo -e "${CYAN}====================================================================${PLAIN}"
echo -e "${YELLOW}提示: 按 Ctrl+C 可随时停止监控。监控摘要将同步写入 ${LOG_FILE}${PLAIN}\n"

# 表头输出
printf "%-10s | %-8s | %-12s | %-10s | %-10s | %-12s | %-10s\n" \
    "时间" "CPU(%)" "内存(RSS)" "内存(%)" "TCP并发" "TIME_WAIT" "UDP接收错误"
echo "----------------------------------------------------------------------------------------"

# 循环采集
while true; do
    TIMESTAMP=$(date "+%H:%M:%S")
    
    # 获取 V2bX 进程 PID
    PID=$(pgrep -f "/usr/local/V2bX/V2bX server" | head -n 1)
    
    if [ -z "$PID" ]; then
        printf "%-10s | ${RED}%-8s | %-12s | %-10s | %-10s | %-12s | %-10s${PLAIN}\n" \
            "${TIMESTAMP}" "未运行" "--" "--" "--" "--" "--"
        sleep ${INTERVAL}
        continue
    fi

    # 获取 CPU 与内存
    CPU_MEM=$(ps -p ${PID} -o %cpu,%mem,rss --no-headers 2>/dev/null)
    CPU=$(echo ${CPU_MEM} | awk '{print $1}')
    MEM_PERCENT=$(echo ${CPU_MEM} | awk '{print $2}')
    MEM_RSS_KB=$(echo ${CPU_MEM} | awk '{print $3}')
    MEM_RSS_MB=$(awk "BEGIN {printf \"%.1fMB\", ${MEM_RSS_KB}/1024}")

    # 统计 TCP 并发数与 TIME_WAIT
    TCP_ESTAB=$(ss -ant | grep -c ESTAB 2>/dev/null || echo "0")
    TCP_TW=$(ss -ant | grep -c TIME-WAIT 2>/dev/null || echo "0")

    # 统计 UDP 接收丢包与溢出
    UDP_ERR=$(grep -i "Udp:" /proc/net/snmp 2>/dev/null | tail -n 1 | awk '{print $4+$6+$7}' || echo "0")

    # 彩色阈值警报
    CPU_DISPLAY="${CPU}%"
    if (( $(echo "${CPU} > 80.0" | bc -l 2>/dev/null || [ "${CPU%.*}" -gt 80 ]) )); then
        CPU_DISPLAY="${RED}${CPU}%${PLAIN}"
    fi

    printf "%-10s | %-8s | %-12s | %-10s | %-10s | %-12s | %-10s\n" \
        "${TIMESTAMP}" "${CPU_DISPLAY}" "${MEM_RSS_MB}" "${MEM_PERCENT}%" "${TCP_ESTAB}" "${TCP_TW}" "${UDP_ERR}"

    # 记录结构化日志
    echo "[${TIMESTAMP}] PID:${PID} CPU:${CPU}% MEM:${MEM_RSS_MB}(${MEM_PERCENT}%) TCP_ESTAB:${TCP_ESTAB} TCP_TW:${TCP_TW} UDP_ERR:${UDP_ERR}" >> "${LOG_FILE}"

    # 检查最新错误日志
    RECENT_ERR=$(journalctl -u V2bX.service --since "3 seconds ago" -p err..emerg --no-pager 2>/dev/null)
    if [ -n "$RECENT_ERR" ]; then
        echo -e "${RED}[异常捕获] 发现错误日志:${PLAIN}\n${RECENT_ERR}"
    fi

    sleep ${INTERVAL}
done
