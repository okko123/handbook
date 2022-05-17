## 使用exifread库读取图片的Exif信息
读取Exif信息中的设备信息、时间；创建指定的目录将文件以<拍摄设备品牌>/YYYY.MM.DD/filename的方式进行归档
```python
import os
import shutil
import datetime
import exifread


def parse_ymd(s):
    year_s, mon_s, day_s = s.split(" ")[0].split(":")
    return datetime.datetime(int(year_s), int(mon_s), int(day_s)).strftime("%Y.%m.%d")

def move_file(src_path, dst_path, file):
    try:
        f_src = os.path.join(src_path, file)

        if not os.path.exists(dst_path):
            os.makedirs(dst_path, mode=0o755)

        f_dst = os.path.join(dst_path, file)
        shutil.move(f_src, f_dst)
    except Exception as e:
        print("move_file ERROR: ", e)


file_path = "/data/Photo"
src_dir = os.path.join(file_path, "Camera Uploads")
os.chdir(src_dir)

for file in os.listdir(src_dir):
#for file in ["2018-07-12 11.38.39.JPG",]:
    f = open(file, "rb")
    try:
        tags = exifread.process_file(f)
        f.close()

        if tags.get("Image Make", "0"):
            maker = tags.get("Image Make", "0").values
            image_time = tags.get("Image DateTime", "0").values
            image_time_ymd = parse_ymd(image_time)

            dst_dir = os.path.join(file_path, maker, image_time_ymd)
            move_file(src_dir, dst_dir, file)

    except Exception as e:
        print(e)
```