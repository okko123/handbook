https://wiki.ubuntu.com/Kernel/Systemtap
安装systemtap
sudo apt-get install -y systemtap gcc
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C8CAB6595FDFF622
codename=$(lsb_release -c | awk  '{print $2}')
sudo tee /etc/apt/sources.list.d/ddebs.list << EOF
deb http://ddebs.ubuntu.com/ ${codename}      main restricted universe multiverse
deb http://ddebs.ubuntu.com/ ${codename}-security main restricted universe multiverse
deb http://ddebs.ubuntu.com/ ${codename}-updates  main restricted universe multiverse
deb http://ddebs.ubuntu.com/ ${codename}-proposed main restricted universe multiverse
EOF

sudo apt-get update
sudo apt-get install linux-image-$(uname -r)-dbgsym

syn_qlen = @cast($sk, "struct inet_connection_sock")->icsk_accept_queue->listen_opt->qlen;

5.1 stap命令
stap [OPTIONS] FILENAME [ARGUMENTS]
stap [OPTIONS] - [ARGUMENTS]
stap [OPTIONS] –e SCRIPT [ARGUMENTS]

比较常用和有用的参数：
-e SCRIPT               Run given script.
-l PROBE                List matching probes.
-L PROBE                List matching probes and local variables.
-g                      guru mode 
-D NM=VAL               emit macro definition into generated C code
-o FILE                 send script output to file, instead of stdout.
-x PID                  sets target() to PID

探测点语法：
kernel.function(PATTERN)
kernel.function(PATTERN).call
kernel.function(PATTERN).return
kernel.function(PATTERN).return.maxactive(VALUE)
kernel.function(PATTERN).inline
kernel.function(PATTERN).label(LPATTERN)
module(MPATTERN).function(PATTERN)
module(MPATTERN).function(PATTERN).call
module(MPATTERN).function(PATTERN).return.maxactive(VALUE)
module(MPATTERN).function(PATTERN).inline
kernel.statement(PATTERN)
kernel.statement(ADDRESS).absolute
module(MPATTERN).statement(PATTERN)
process(PROCESSPATH).function(PATTERN)
process(PROCESSPATH).function(PATTERN).call
process(PROCESSPATH).function(PATTERN).return
process(PROCESSPATH).function(PATTERN).inline
process(PROCESSPATH).statement(PATTERN)

7.3 输出调用堆栈

用户态探测点堆栈：print_ubacktrace()、sprint_ubacktrace()

内核态探测点堆栈：print_backtrace()、sprint_backtrace()


---
## 参考信息
- [通过实例快速入门Systemtap](https://www.codedump.info/post/20200128-systemtap-by-example/)