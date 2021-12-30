## Dockefile的CMD与ENTRYPOINT区别

### exec模式与shell模式
> CMD 和 ENTRYPOINT 指令都支持 exec 模式和 shell 模式的写法，所以要理解 CMD 和 ENTRYPOINT 指令的用法，就得先区分 exec 模式和 shell 模式。这两种模式主要用来指定容器中的不同进程为 1 号进程。了解 linux 的朋友应该清楚 1 号进程在系统中的重要地位。

- exec模式
  - 使用 exec 模式时，容器中的任务进程就是容器内的 1 号进程
  - exec 模式的特点是不会通过 shell 执行相关的命令，所以像 $HOME 这样的环境变量是取不到的
- shell模式
  - 使用 shell 模式时，docker 会以 /bin/sh -c "task command" 的方式执行任务命令。也就是说容器中的 1 号进程不是任务进程而是 bash 进程
### CMD 指令
- CMD 指令的目的是：为容器提供默认的执行命令。CMD 指令有三种使用方式，
  - ENTRYPOINT 提供默认的参数，CMD ["param1","param2"]
  - exec模式，CMD ["executable", "param1", "param2"]
  - shell模式，CMD command param1 param2
- 命令行参数可以覆盖CMD指令的设置，但只能是重写，却不能给CMD中的命令通过命令行传递参数
  - 例子：使用此dockerfile创建镜像，在启动容器时我们通过命令行指定参数 ps aux 覆盖默认的 top 命令
    ```bash
    cat > dockerfile <<EOF
    FROM ubuntu
    CMD ["top"]
    EOF

    # 构建镜像test:v1
    docker build . -t test:v1

    # 运行进行test:v1
    docker run --name debug --rm test:v1  ps aux
    ```
  - ![](img/docker-1.png)
    从上图可以看到，命令行上指定的 ps aux 命令覆盖了 Dockerfile 中的 CMD [ "top" ]。实际上，命令行上的命令同样会覆盖 shell 模式的 CMD 指令。
### ENTRYPOINT 指令
- ENTRYPOINT 指令的目的也是为容器指定默认执行的任务。exec 模式和 shell 模式的基本用法和 CMD 指令是一样的，下面我们介绍一些比较特殊的用法。
  - exec 模式，ENTRYPOINT ["executable", "param1", "param2"]
  - shell 模式，ENTRYPOINT command param1 param2
---
### 同时使用 CMD 和 ENTRYPOINT 的情况
> 对于 CMD 和 ENTRYPOINT 的设计而言，多数情况下它们应该是单独使用的。当然，有一个例外是 CMD 为 ENTRYPOINT 提供默认的可选参数。
- 指定 ENTRYPOINT  指令为 exec 模式时，命令行上指定的参数会作为参数添加到 ENTRYPOINT 指定命令的参数列表中。
- 指定 ENTRYPOINT  指令为 shell 模式时，会完全忽略命令行参数：

> 我们大概可以总结出下面几条规律：
  - 如果 ENTRYPOINT 使用了 shell 模式，CMD 指令会被忽略。
  - 如果 ENTRYPOINT 使用了 exec 模式，CMD 指定的内容被追加为 ENTRYPOINT 指定命令的参数。
  - 如果 ENTRYPOINT 使用了 exec 模式，CMD 也应该使用 exec 模式。
  - 真实的情况要远比这三条规律复杂，好在 docker 给出了官方的解释，如下图所示：
    |-|	No ENTRYPOINT|	ENTRYPOINT exec_entry p1_entry	|    ENTRYPOINT ["exec_entry", "p1_entry"]|
    |:-|:-|:-|:-|
    |No CMD|error, not allowed|/bin/sh -c exec_entry p1_entry|exec_entry p1_entry|
    |CMD ["exec_cmd", "p1_cmd"]|exec_cmd p1_cmd|/bin/sh -c exec_entry p1_entry|	exec_entry p1_entry exec_cmd p1_cmd|
    |CMD ["p1_cmd", "p2_cmd"]|p1_cmd p2_cmd|/bin/sh -c exec_entry p1_entry|exec_entry p1_entry p1_cmd p2_cmd|
    |CMD exec_cmd p1_cmd|/bin/sh -c exec_cmd p1_cmd|/bin/sh -c exec_entry p1_entry|exec_entry p1_entry /bin/sh -c exec_cmd p1_cmd|

---
### 参考连接
- [ENTRYPOINT的解释](https://docs.docker.com/engine/reference/builder/?spm=a2c6h.12873639.0.0.39e74a0a3c0UnH#entrypoint)
- [Dockerfile 中的 CMD 与 ENTRYPOINT](https://www.cnblogs.com/sparkdev/p/8461576.html)