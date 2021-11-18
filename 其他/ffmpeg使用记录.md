## ffmpeg使用记录

- FFmpeg 命令的典型语法是：
  > ffmpeg [全局选项] {[输入文件选项] -i 输入_url_地址} ... {[输出文件选项] 输出_url_地址} ...
- 获取音频/视频文件信息
  > ffmpeg -i video.mp4
  > ffmpeg -i video.mp4 -hide_banner #隐藏ffmpeg的信息
- x265转码
  > ffmpeg -i HDCTV.ts -c:v libx265 HDCTV.mkv
- 获取所有流（包括音频，字幕流），默认的情况下ffmpeg只保留1路的音频
  > ffmpeg -i HDCTV.ts -c:v libx265 -c:a copy -c:s copy  -map 0 HDCTV.mkv
- 接合或合并多个视频部分到一个
  > FFmpeg 也可以接合多个视频部分，并创建一个单个视频文件。创建包含你想接合文件的准确的路径的 join.txt。所有的文件都应该是相同的格式（相同的编码格式）。所有文件的路径应该逐个列出，像下面。
  ```txt
  file /home/sk/myvideos/part1.mp4
  file /home/sk/myvideos/part2.mp4
  file /home/sk/myvideos/part3.mp4
  file /home/sk/myvideos/part4.mp4
  ```
  > 现在，接合所有文件，使用命令：
  
  > ffmpeg -f concat -i join.txt -c copy output.mp4
如果你得到一些像下面的错误；

  > [concat @ 0x555fed174cc0] Unsafe file name '/path/to/mp4' join.txt: Operation not permitted
添加 -safe 0 :

  > $ ffmpeg -f concat -safe 0 -i join.txt -c copy output.mp4
  
  > 上面的命令将接合 part1.mp4、part2.mp4、part3.mp4 和 part4.mp4 文件到一个称为 output.mp4 的单个文件中。
- 使用intel核显加速转码-QSV，首先需要编译ffmpeg源码，支持QSV硬件加速
  > /opt/ffmpeg/bin/ffmpeg -hwaccel qsv -c:v h264_qsv -i input.mp4 -crf 22 -c:v hevc_qsv  -c:a copy -c:s copy  -map 0 output.mkv
---
### 参考连接
- [给新手的 20 多个 FFmpeg 命令示例](https://zhuanlan.zhihu.com/p/67878761)
- ["Intel Quick Sync Video" is the marketing name for a set of hardware features available inside many Intel GPUs.](https://trac.ffmpeg.org/wiki/Hardware/QuickSync)
- [Ubuntu20.04 ffmpeg添加 Intel核显QSV加速支持](https://zhuanlan.zhihu.com/p/372361709)