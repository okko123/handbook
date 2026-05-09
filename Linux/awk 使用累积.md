### awk 使用累积

- 以“|”作为切分符号，只打印第9位内容，并且以=切分，把=号后的数字大于5000的日志打印出来
```bash
# 
awk -F'|' 'split($9, arr, "=") && arr[2] > 5000 {print $9}' 日志文件名

# 打印行号和内容：
awk -F'|' 'split($9, arr, "=") && arr[2] > 5000 {print NR": "$0}' 日志文件名

# 统计符合条件的行数：
awk -F'|' 'split($9, arr, "=") && arr[2] > 5000 {count++} END {print count}' 日志文件名
```