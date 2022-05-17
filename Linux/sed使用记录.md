sed删除匹配行到最后的行。

sed '/^abc/,$d' file
解释：,$d的作用是删除匹配到的行到末行的行的所有数据。

删除匹配行和匹配行后的2行
sed '/muahao/,+2d' file

删除指定行
sed '/xxx/d' filename

删除第N~M行
sed -i 'N,Md' filename # file的[N,M]行都被删除

每行末尾添加回车
sed '/$/a\\n' test.txt

在文件末尾添加eof
sed '$a\eof' test.txt