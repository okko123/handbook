### aync-profiler 工具使用
- 使用的jdk版本: 8.261
- asprof版本: 4.4

### 1. 抓取 30 秒的 CPU 性能，并输出为暗黑模式火焰图
```bash
./asprof -d 30 -f ./cpu_flame.html <PID>
./asprof -d 30 -f cpu.html 503897
```
### 2. 抓取 30 秒的内存分配（Allocation）并生成火焰图
```bash
./asprof -e alloc -d 30 -f ./alloc_flame.html <PID>
```
### 针对常见 Java 问题的排查套路
- 场景 A：CPU 被占满（CPU 100%）
  - 采样模式： ./asprof -e cpu -d time_second -f cpu_flame.html <PID>
  - 看图重点： 寻找那些占了总宽度 30% 以上 的绿/黄色 Java 块。
  - 排查目标：
    - 如果平顶山是 java.util.regex.Pattern，说明系统内有高频且低效的正则表达式匹配。
    - 如果平顶山是 Jackson、Fastjson 或 Gson 的方法，说明系统在进行高频、大体积的 JSON 序列化/反序列化。
    - 如果平顶山是 java.util.HashMap.get，多半是多线程并发下发生了 HashMap 环形链表死循环，或者是 Hash 冲突太严重。

- 场景 B：接口响应慢，但 CPU 并不忙
  - 采样模式： ./asprof -e wall（墙钟时间模式）-d time_second -f wall.html <PID>
  - 看图重点： 在这个模式下，不仅会记录正在计算的代码，还会记录正在“等锁”或“等网络/磁盘”的代码。
  - 排查目标：
    - 看看有没有极宽的方块卡在 socketRead0 或 socketWrite0 上，这代表外部依赖接口（如第三方 API、数据库、Redis）响应极慢。
    - 看看有没有极宽的方块卡在 unsafe.park 或 Object.wait 上，这代表高并发下线程在疯狂争抢同一把锁。

- 场景 C：频繁发生 GC 卡顿
  - 采样模式： ./asprof -e alloc（内存分配模式）-d time_second -f alloc.html <PID>
  - 看图重点： 查看哪些类（如 byte[]、String、或你自定义的 DTO）的分配宽度最大。
  - 排查目标：
    - 找出在哪个业务方法中，正在以恐怖的速度产生大批量的临时对象，导致 JVM 堆内存迅速被塞满并触发垃圾回收。