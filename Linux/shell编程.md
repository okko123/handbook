## shell 编程：冒号 后面跟 等号，加号，减号，问号的意义
- 缺省值（:-）
  ```bash
  ${var:-string} 若变量var为空或者未定义,则用在命令行中用string来替换${var:-string} 否则变量var不为空时,则用变量var的值来替换${var:-string}

  $ COMPANY=
  $ printf "%s\n" "${COMPANY:-Unknown Company}"
  Unknown Company
  $ echo $COMPANY
  ```
  > 变量的实际值保持不变。
- 指定缺省值（:=）
  > 如果变量后面跟着冒号和等号，则给空变量指定一个缺省值。
    ```bash
    $ printf "%s\n" "${COMPANY:=Nightlight Inc.}"
    Nightlight Inc.
    $ printf "%s\n" "${COMPANY}"
    Nightlight Inc.

    # 变量的实际值已经改变了。 比较${var:-string}和${var:=string} 后者发现$var为空时,把string赋值给了var
    # 后者是一种赋值默认值的常见做法
    ```
- 变量是否存在检查（:?）
  > 替换规则:若变量var不为空,则用变量var的值来替换${var:?string}

  > 若变量var为空,则把string输出到标准错误中,并从脚本中退出。

  > 可利用此特性来检查是否设置了变量的值
    ```bash
    根据变量是否存在，显示不同的信息。信息不是必选的。

    printf "Company is %s\n" "${COMPANY:?Error: Company has notbeen defined—aborting}"
    ```
- 覆盖缺省值(:+)
  > \${var:+string} 规则和\${var:-string}, \${var:=string}的完全相反 即只有当var不是空的时候才替换成string,若var为空时则不替换或者说是替换成变量var的值,即空值
    ```bash
    $ COMPANY="Nightlight Inc."
    $ printf "%s\n" "${COMPANY:+Company has been overridden}"
    Company has been overridden
    ```
- 替换部分字符串（:n）
  > 如果变量后面跟着一个冒号和数字，则返回该数字开始的一个子字符串，如果后面还跟着一个冒号和数字。则第一个数字表示开始的字符，后面数字表示字符的长度。
    ```bash
    $ printf "%s\n" "${COMPANY:5}"
    light Inc.
    $ printf "%s\n" "${COMPANY:5:5}"
    light
    ```
  > 根据模板删除字串（%，#，%%，##） #删除左边,%删除右边 如果变量后面跟着井号，则返回匹配模板被删除后的字串。一个井号为最小可能性的匹配，两个井号为自大可能性的匹配。表达式返回模板右边的字符。
    ```bash
    $ COMPANY="Nightlight Inc."
    $ printf "%s\n" "${COMPANY#Ni*}"
    ghtlight Inc.
    $ printf "%s\n" "${COMPANY##Ni*}"

    $ printf "%s\n" "${COMPANY##*t}"
    Inc.
    $ printf "%s\n" "${COMPANY#*t}"
    light Inc.

    #使用百分号，表达式返回模板左边的字符
    $ printf "%s\n" "${COMPANY%t*}"
    Nightligh
    $ printf "%s\n" "${COMPANY%%t*}"
    Nigh
    ```
  > 案例: 获取文件名和后缀名
    ```bash
    $ f=file.tar.gz
    $ echo ${f##*.}
    gz
    $ echo ${f%%.*}
    file

    #假设我们定义了一个变量为：
    file=/dir1/dir2/dir3/my.file.txt

    #可以用${ }分别替换得到不同的值：
    ${file#*/}：删掉第一个 / 及其左边的字符串：dir1/dir2/dir3/my.file.txt
    ${file##*/}：删掉最后一个 /  及其左边的字符串：my.file.txt
    ${file#*.}：删掉第一个 .  及其左边的字符串：file.txt
    ${file##*.}：删掉最后一个 .  及其左边的字符串：txt
    ${file%/*}：删掉最后一个  /  及其右边的字符串：/dir1/dir2/dir3
    ${file%%/*}：删掉第一个 /  及其右边的字符串：(空值)
    ${file%.*}：删掉最后一个  .  及其右边的字符串：/dir1/dir2/dir3/my.file
    ${file%%.*}：删掉第一个  .   及其右边的字符串：/dir1/dir2/dir3/my
    ```
  >记忆的方法为： #是 去掉左边（键盘上#在 $ 的左边） %是去掉右边（键盘上% 在$ 的右边） 单一符号是最小匹配；两个符号是最大匹配
- 使用模板进行子字符串的替换（//）
  > 如果变量后只有一个斜杠，则两个斜杠中间的字符串是要被替换的字符串，而第二个斜杠后面的字符串是要替换的字符串。如果变量后面跟着两个斜杠，则所有出现在两个斜杠中间的字符都要被替换为最后一个斜杠后面的字符。
    ```bash
    $ printf "%s\n" "${COMPANY/Inc./Incorporated}"
    Nightlight Incorporated
    $ printf "You are the I in %s\n" "${COMPANY//i/I}"
    You are the I in NIghtlIght Inc.
    ```
  > 如果模板以#号开始，则匹配以模板开始的字符，如果模板以%号结尾(在centos7上测试不生效)，则匹配以模板结尾的字符。
    ```bash
    $ COMPANY="NightLight Night Lighting Inc."
    $ printf "%s\n" "$COMPANY"
    NightLight Night Lighting Inc.
    $ printf "%s" "${COMPANY//Night/NIGHT}"
    NIGHTLight NIGHT Lighting Inc.
    $ printf "%s" "${COMPANY//#Night/NIGHT}"
    NIGHTLight Night Lighting Inc.
    ```
  > 如果没有指定新的值，则匹配的字符会被删除。
    ```bash
    $ COMPANY="Nightlight Inc."
    $ printf "%s\n" "${COMPANY/light}"
    Night Inc.
    ```
  > 也可以使用范围符号。例如：删除所有字符串中的标点符号，使用范围[:punct:]。
    ```bash
    $ printf "%s" "${COMPANY//[[:punct:]]}"
    Nightlight Inc
    ```
  > 使用号或@符号替换变量会替换shell脚本中所有的参数，同样，在数组中使用号或@符号也会替换数组中的所有元素

