## docker笔记
docker官方文档中指出：

By default, each container's access to the host machine's CPU cycles is unlimited. You can set various constraints to limit a given container's access to the host machine's CPU cycles. Most users use and configure the default CFS scheduler. In Docker 1.13 and higher, you can also configure the realtime scheduler.
意思是默认情况下不会对容器所使用的CPU进行任何的限制。限制方案有两种，一种是将容器设置为普通进程，通过CFS调度类进行限制（默认方案），另一种是将容器设置为实时进程，通过实时调度类进行限制，我们这里仅考虑默认方案，即通过CFS调度类实现对容器CPU的限制。（我们下面的分析默认了进程只进行CPU操作，没有睡眠、IO等操作，换句话说，进程的生命周期中一直在就绪队列中排队，要么在用CPU，要么在等CPU）

docker通过docker run指令来决定容器对CPU的使用量，共有五个参数：(官方链接)


--cpuset-cpus:指定容器只能跑在那些core上，这个没啥好说的
--cpuset-shares：指定容器中进程的shares值
shares值即CFS中每个进程的(准确的说是调度实体)权重(weight/load)，普通进程(区别于实时进程，实时进程使用实时调度类、普通进程使用CFS调度类，Linux的调度我将在后续文章中分析)的shares值是根据其静态优先级优先级计算而来(优先级分为静态、动态、普通、实时优先级，优先级是linux调度中的重要概念，其计算过程非常复杂，我将在后续文章中分析优先级的计算,在这里你只需要知道普通进程的静态、动态、普通相同)，一般普通进程的静态优先级为120，其对应的shares值为1024(至于为什么是1024又是一个复杂的问题，我将在后续文章中分析)。docker的--cpuset-shares参数就直接指定了容器中进程的shares值，默认也是1024。

shares的大小决定了在一个CFS调度周期中，进程占用的比例，比如进程A的shares是1024，B的shares是512，假设调度周期为3秒，那么A将只用2秒，B将使用1秒，再次注意，这A使用这1秒的过程中除非其主动释放CPU，否则将一直占据，因为这是在一个调度周期，当然调度周期不会这么大，那么CFS的调度周期有多大呢？这个问题问得好！

CFS的调度周期是有默认值的，你可以通过:

cat /proc/sys/kernel/sched_latency_ns
查看.当然调度周期绝对不是一个固定值,其实是基于该值和就绪队列大小计算而来,具体计算方法请期待我后面的文章.

到这里你应该已经明白了,加入调度周期是10ms,就绪队列中有3个进程,他们的shares分别是1024,1024,2048.那么他们将这个调度周期中分别执行2.5ms,2.5ms,5ms.这就是单纯设置--cpuset-shares带来效果,效果就是容器将根据自己shares来瓜分CPU.

读到这里我相信你已经想放弃了,因为这些你都懂,我既没有深度的分析CFS,是的,CFS非常复杂,但这不是我们此文的目的,在这里你只需要知道:CFS提出了shares的概念,CFS保证了每个进程根据shares来瓜分CPU.CFS更为核心是决定在内核发出调度命令时,该调度那个进程去执行,我们在这里不需要知道这么多,如果你想知道请持续关注我的专栏后续的系列文章.

到这里你还没有看到docker对于CPU的限制,因为这都是CFS的内容,dockers仅仅设置了shares而已,如果系统中只有一个容器,那么shares无论怎么设置,容器都将占100%的CPU,因为shares仅仅是一个权重而已,那么你想限制容器,就要用下面的参数:

--cpus-period:调度周期,这里的调度周期和CFS调度周期是两个概念,为了区分,我们称之为重分配周期,默认是100ms

--cpus-quota:占用周期,其表示在在一个重分配周期中,容器最多可以占用的CPU时间,注意,这个是可以大于重分配周期,因为系统可能有多个CPU,也就说--cpus-quota的最大值是core数×重分配周期,默认值是-1,即不做限制

--cpus:是1.13版本的新特性,他是为了简化设置而出现的,如--cpus=1.5,也就是以为着--cpus-period值为100ms,--cpus-quota值为150ms

那么重分配周期和占用周期怎么来限制CPU使用呢,你需要知道他们是通过Cgroup的cpu子系统来控制的,cpu子系统则是通过CFS来实现的，当然，绝对不是一开始设计的CFS，因为最初的CFS仅仅是使用shares来限制.是Google在实现cgroup时,对CFS进行了扩展,提出了"CPU bandwidth control for CFS",论文在这里.简单说就是添加了重分配周期和占用周,当进程在一个重分配周期中获得CPU时间达到占用周期时,将不再被调度,直到下一个重分配周期.

到这里我不知道你乱了没有,我们用例子来解释:

我现在有两个进程(或者说容器),其配置如下(单核!):

进程A shares=1024 --cpus-period=100ms --cpus-quota=50ms

进程B shares=1024 --cpus-period=100ms --cpus-quota=20ms

假设CFS调度周期为10ms,其就绪队列中仅有此2进程,那么过程为:

t=0时刻,距离重分配周期还有100ms,就绪队列中有A和B,A在该分配周期中还有50ms,B有20ms

A先执行5ms(10*1024/(1024+1024))

B执行5ms

此时t=10ms,距离重分配周期还有90ms,就绪队列中有A和B,A在该分配周期中还有45ms,B有15ms

A执行5ms B执行5ms

...

此时t=40ms,距离重分配周期还有60ms,A,B都执行了20ms,B在此次分配周期中已经没有了时间,B被限流,踢出就绪队列,不再被调度,A此时还有30ms

A先执行10ms(10*1024/(1024)),注意此时就绪队列中只有A，独占整个CFS调度周期,且在接下来反复被选中,因为只有他一个

A先执行10ms

A先执行10ms

此时t=70ms,距离重分配周期还有30ms,A已经执行了50ms,也没有占用之间可用,限流踢出就绪队列

此时没有进程被调度,CPU空转30ms,直到重分配周期结束,又重新开始新的循环.最终我们使用top指令查看,将会得到A的CPU利用率为50%,B为20%(单核的机子!不过top指令即使是多核也是按单核算,不懂的话,后续文章,,,,,,,也不会讲)

到这里我相信你已经很懂了,CFS是如何根据这三个参数进行分配CPU的.但是你真的懂了吗?我举得你没有,不相信,你能理解这句话吗:

如果多个进程的--cpus-quota值相加小于--cpus-period(前提是这几个进程的--cpus-period相同哈),那么无论shares如何设置,进程的CPU占用率都等于quota/period
如果两个进程的--cpus-quota值相加大于--cpus-period,那么shares大的进程CPU比重等于min(shares比重,quota/period),shares小的进程CPU比重等于(1-大进程的比重)
如果你不能理解,那么说明你真的还没理解,需要我讲解吗?想看所有的后续文章吗?想知道k8s是如何利用容器的这几个参数吗?一键三连吧(B站误入)!!!!
---

- [从CFS的层面来分析docker是如何限制容器对CPU的使用的](https://zhuanlan.zhihu.com/p/83526484)