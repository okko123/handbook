# 安装MHA

- 介绍
  - MHA由MHA Manager和MHA Node包组成。 
  - MHA Manager在管理服务器上运行，MHA Node在每个MySQL服务器上运行。
  - MHA Node程序不会一直运行，但在需要时（在配置检查，故障转移等）从MHA管理器程序调用。 MHA管理器和MHA节点都是用Perl编写的。
- 安装Manager节点
  - OS：CentOS 7
  - 依赖的安装包：yum install perl-DBD-MySQL perl-Config-Tiny perl-Log-Dispatch perl-Parallel-ForkManager -y
 
[MHA的官方wiki](https://github.com/yoshinorim/mha4mysql-manager/wiki)