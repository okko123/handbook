学习 **eBPF（extended Berkeley Packet Filter）** 是进入云原生、系统性能、网络安全和可观测性领域的关键技术路径。eBPF 允许你在**不修改内核源码、不加载内核模块**的前提下，安全高效地运行沙箱程序于 Linux 内核中。

以下是 **2025 年最新、系统化、由浅入深的学习路线**，适合开发者、SRE、安全工程师和系统爱好者：

---

## 🧭 一、学习前准备：基础要求

| 领域 | 掌握程度 |
|------|--------|
| **Linux 系统基础** | 熟悉进程、网络、文件系统、系统调用（如 `strace`, `lsof`） |
| **C 语言** | 能读懂指针、结构体、内存管理（eBPF 内核态程序用 C 编写） |
| **Python / Go（可选）** | 用户态程序常用（如 BCC 工具链） |
| **网络基础** | 了解 TCP/IP、socket、iptables 等 |

> ✅ 如果你是 Kubernetes 或可观测性用户（如用过 DeepFlow、Pixie），你已经具备场景理解优势。

---

## 📚 二、官方权威资源（必读）

### 1. **《What is eBPF?》—— eBPF 官网**
- 网站：https://ebpf.io
- 内容：eBPF 原理、架构图、用例、项目生态
- 特别推荐：[eBPF Illustrated](https://ebpf.io/what-is-ebpf/) 动画讲解

### 2. **《BPF Performance Tools》—— Brendan Gregg**
- 作者：Netflix 首席性能工程师，eBPF 推广者
- 内容：**60+ 实战工具**（如 `biolatency`, `tcpconnect`）原理与使用
- 书籍 + 视频：https://www.brendangregg.com/bpf.html
- ✅ **强烈建议作为第一本实战书**

---

## 🛠️ 三、动手实践：从工具到开发

### 阶段 1️⃣：先会用 → 使用现有 eBPF 工具

| 工具 | 用途 | 学习目标 |
|------|------|--------|
| **bpftrace** | 快速编写单行脚本追踪系统行为 | `bpftrace -e 'tracepoint:syscalls:sys_enter_open { printf("%s %s\n", comm, str(args->filename)); }'` |
| **BCC (BPF Compiler Collection)** | 提供 `opensnoop`, `execsnoop`, `tcptop` 等高级工具 | 理解“内核态采集 + 用户态展示”模式 |
| **kubectl trace** | 在 K8s 中运行 bpftrace | 云原生场景落地 |

✅ 安装体验：
```bash
# Ubuntu/Debian
sudo apt install bpfcc-tools linux-headers-$(uname -r)

# 运行一个经典工具：监控文件打开
sudo opensnoop-bpfcc
```

> 💡 目标：能用 `execsnoop` 抓到异常进程，用 `tcplife` 分析连接延迟。

---

### 阶段 2️⃣：学原理 → 理解 eBPF 核心机制

重点掌握以下概念：

| 概念 | 说明 |
|------|------|
| **eBPF 程序类型** | XDP（网络入口）、TC（流量控制）、Tracepoint、kprobe/uprobe、LSM（安全）等 |
| **Map（数据结构）** | 内核态 ↔ 用户态通信桥梁（如 hash、array、ringbuf） |
| **Verifier** | 内核验证器，确保 eBPF 程序安全（无死循环、内存越界） |
| **Tail Call / BTF** | 高级特性：程序跳转、类型信息（避免 struct 硬编码） |

📚 推荐资料：
- [eBPF Internals](https://github.com/xdp-project/xdp-tutorial)（XDP 教程，但原理通用）
- [Linux Kernel Documentation on BPF](https://www.kernel.org/doc/html/latest/bpf/)

---

### 阶段 3️⃣：写代码 → 开发自己的 eBPF 程序

#### 推荐开发框架（按难度排序）：

| 框架 | 语言 | 特点 | 适用场景 |
|------|------|------|--------|
| **libbpf + C** | C | 官方推荐，轻量，需手动处理 BTF | 生产级工具（如 DeepFlow Agent） |
| **BCC** | Python/C++ | 自动化重写，易上手 | 快速原型、脚本 |
| **Go + Cilium ebpf** | Go | 纯 Go 开发，类型安全 | 云原生集成（如 Hubble、Tetragon） |
| **Rust + Aya** | Rust | 内存安全，新兴选择 | 安全敏感场景 |

#### ✅ 新手推荐路径：
1. 用 **BCC** 写一个 `hello world` 程序（监控 exec）
2. 改用 **libbpf-bootstrap**（官方模板）重构
3. 尝试用 **Cilium ebpf (Go)** 写一个网络包计数器

GitHub 模板：
- libbpf-bootstrap：https://github.com/libbpf/libbpf-bootstrap
- cilium/ebpf：https://github.com/cilium/ebpf
- aya-rs：https://github.com/aya-rs/aya

---

## 🌐 四、真实项目参考（学以致用）

| 项目 | 技术栈 | 学习价值 |
|------|--------|--------|
| **DeepFlow** | Go + eBPF | 自动埋点、协议解析、零代码可观测性 |
| **Cilium / Hubble** | Go + eBPF | CNI、网络策略、服务网格 |
| **Tetragon** | Go + eBPF | 运行时安全、进程监控 |
| **Pixie** | C++/Go + eBPF | 内存驻留调试（已归档，但代码经典） |
| **Parca** | Go + eBPF | 持续 Profiling（CPU/内存火焰图） |

> 💡 建议：**阅读 DeepFlow 或 Cilium 的 eBPF 代码**，看如何用 `kprobe` 捕获 socket 数据。

---

## 🎓 五、课程与社区

### 在线课程：
- **eBPF Summit 视频**（每年举办，免费）：https://ebpf.io/summit/
- **Linux Foundation: Introduction to eBPF**（免费入门课）
- **Udemy: eBPF and XDP Mastery**（付费，实战强）

### 社区：
- Slack：https://ebpf.io/slack （活跃开发者聚集地）
- GitHub Discussions：在 cilium/ebpf、libbpf 等仓库提问
- 中文社区：CNCF eBPF SIG（微信/QQ 群搜索“eBPF 中国”）

---

## 🗺️ 六、学习路线图（6 周计划）

| 周 | 目标 |
|----|------|
| **第 1 周** | 安装 BCC，运行 10 个工具（opensnoop, biolatency...） |
| **第 2 周** | 用 bpftrace 写 5 个自定义脚本（如监控特定 syscall） |
| **第 3 周** | 阅读《BPF Performance Tools》前 5 章 |
| **第 4 周** | 用 libbpf-bootstrap 编译并运行第一个 C 程序 |
| **第 5 周** | 用 Go + cilium/ebpf 实现一个简单的网络包计数器 |
| **第 6 周** | 贡献一个文档 PR 或复现一个开源项目 issue |

---

## ⚠️ 七、常见误区

| 误区 | 正确理解 |
|------|--------|
| “eBPF = 网络工具” | eBPF 可用于**追踪、安全、调度、存储**等全领域 |
| “必须会内核开发” | 只需理解接口，无需修改内核 |
| “只能在新内核用” | Linux 4.14+（2017）已支持核心功能，主流发行版均可 |
| “性能开销大” | 合理使用下，开销 < 1%，远低于传统探针 |

---

## ✅ 总结：行动建议

1. **今天就装 BCC**，运行 `sudo execsnoop-bpfcc`
2. **读 Brendan Gregg 的书**，边读边敲命令
3. **加入 eBPF Slack**，提问不怕小白
4. **选一个框架（推荐 Go + cilium/ebpf）**，写你的第一个 eBPF 程序

> 🌟 **记住**：eBPF 不是“未来技术”，它已经是 **Cilium、DeepFlow、Datadog、Pixie、Falco** 等产品的核心引擎。掌握它，你就站在了云原生基础设施的最前沿。