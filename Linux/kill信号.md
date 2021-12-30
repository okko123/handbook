### kill信号
> kill -l, 查看信号量

可不少啊！但这些信号中只有第 9 种信号(SIGKILL)才可以无条件的终止进程，其他信号进程都有权利忽略。并且这么多的信号中常用的也不多，下面我们解释几个常用信号的含义。

代号
名称	内容
1      
SIGHUP	启动被终止的程序，可让该进程重新读取自己的配置文件，类似重新启动。
2	SIGINT	相当于用键盘输入 [ctrl]-c 来中断一个程序的进行。
9	SIGKILL	代表强制中断一个程序的进行，如果该程序进行到一半，那么尚未完成的部分可能会有“半产品”产生，类似 vim会有 .filename.swp 保留下来。
15	SIGTERM	以正常的方式来终止该程序。由于是正常的终止，所以后续的动作会将他完成。不过，如果该程序已经发生问题，就是无法使用正常的方法终止时，输入这个 signal 也是没有用的。
19	SIGSTOP	相当于用键盘输入 [ctrl]-z 来暂停一个程序的进行。
上表仅是常见的信号，更多的信号信息请自行通过 man 7 signal 了解。一般来说，只要记住 "1, 9, 15" 这三个信号的意义就可以了。



Exit Codes With Special Meanings

Table E-1. Reserved Exit Codes

Exit Code Number	Meaning	Example	Comments
1	Catchall for general errors	let "var1 = 1/0"	Miscellaneous errors, such as "divide by zero" and other impermissible operations
2	Misuse of shell builtins (according to Bash documentation)	empty_function() {}	Missing keyword or command, or permission problem (and diff return code on a failed binary file comparison).
126	Command invoked cannot execute	/dev/null	Permission problem or command is not an executable
127	"command not found"	illegal_command	Possible problem with $PATH or a typo
128	Invalid argument to exit	exit 3.14159	exit takes only integer args in the range 0 - 255 (see first footnote)
128+n	Fatal error signal "n"	kill -9 $PPID of script	$? returns 137 (128 + 9)
130	Script terminated by Control-C	Ctl-C	Control-C is fatal error signal 2, (130 = 128 + 2, see above)
255*	Exit status out of range	exit -1	exit takes only integer args in the range 0 - 255