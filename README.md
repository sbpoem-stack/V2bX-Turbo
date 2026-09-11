# 🚀 V2bX-Turbo 极速定制版 (High-Performance Proxy Backend)

<p align="center">
  <b>融合 Linux 内核 BBR Turbo 极限加速与 Sing-box / Xray 高并发调优的专属 V2bX 增强版</b>
</p>

---

## 🌟 核心优化与特性

1. **🏎️ 原生集成 BBR Turbo 极限拥塞控制与全栈内核调优**
   - 突破 64MB BDP（带宽时延积）长肥网络大窗口，彻底跑满 1G~10Gbps 国际大带宽。
   - 针对 **Hysteria 2 / TUIC v5 / QUIC** 等 UDP 协议大幅提升读写缓冲，杜绝突发丢包卡顿。
   - 自动适配 **x86_64** 与 **ARM64**（甲骨文 ARM、AWS Graviton 等）架构。

2. **🤖 智能面板 API 探测与配置全自动补全**
   - 只需输入【面板网址】、【通信密钥 Token】和【节点 ID】3 项参数。
   - 脚本自动向面板发送智能握手请求，自动识别协议类型（`vless` / `vmess` / `shadowsocks` / `trojan` / `hysteria2` / `tuic`）并自动补全所有配置。

3. **⚡ Go Runtime 运行时高并发与内存防抖调优**
   - 优化 GC 回收策略与内存分配，降低上万并发连接下的 GC 停顿与延迟抖动。
   - 默认解锁系统级 **1,048,576** 文件句柄与 65535 连接队列，告别 `too many open files` 报错。

3. **🛠️ 极速安装与管理工具箱**
   - 支持一键安装、更新、快捷菜单管理（`v2bx`、`v2bx start`、`v2bx restart`、`v2bx log`、`v2bx bbr`）。
   - 内置交互式面板对接向导（无缝对接 Xboard / V2board / SSPanel 等）。

---

## 🚀 一键安装与管理

在您的 Linux 服务器（Debian / Ubuntu / CentOS / AlmaLinux / Rocky 等）直接复制并执行：

```bash
# 🌟 一键极速安装 / 打开管理菜单
bash <(curl -fsSL https://raw.githubusercontent.com/sbpoem-stack/V2bX-Turbo/main/install.sh)
```

或使用 CDN 镜像：
```bash
bash <(curl -fsSL https://fastly.jsdelivr.net/gh/sbpoem-stack/V2bX-Turbo@main/install.sh)
```

---

## 📋 常用快捷指令

| 命令 | 描述 |
| :--- | :--- |
| `v2bx` | 打开 V2bX-Turbo 交互式管理主菜单 |
| `v2bx start` | 启动 V2bX-Turbo 后端服务 |
| `v2bx stop` | 停止 V2bX-Turbo 后端服务 |
| `v2bx restart` | 重启 V2bX-Turbo 后端服务 |
| `v2bx log` | 实时追踪查看运行日志 |
| `v2bx bbr` | 一键调优 / 切换 BBR Turbo 极限网络加速 |

---

## ⚙️ 配置文件路径

- **主配置文件**：`/etc/V2bX/config.json`
- **程序安装目录**：`/usr/local/V2bX/`
- **系统服务单元**：`/etc/systemd/system/V2bX.service`

---

## 📄 开源协议

本项目基于原版 [V2bX](https://github.com/wyx2685/V2bX) 架构优化定制，遵循 [GPL-3.0 License](LICENSE) 开源协议。
