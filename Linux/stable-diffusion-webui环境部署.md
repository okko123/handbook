## sd环境部署
### 硬件配置
- Dell Precision 7920
  - Intel(R) Xeon(R) Silver 4210R CPU
  - 128G内存
  - Nvidia Quadro RTX 5000
- 系统 ubunt 22.04.4
- stable-diffusion-webui 1.9.4
---
### 准备工作
1. 确认PyTorch版本。本次使用的PyTorch 2.3，要求CUDA Toolkit版本为12.1。[官方PyTorch版本与CUDA版本对应的文档](https://pytorch.org/get-started/locally/)
2. 查询CUDA Toolkit 12.1工具要求的显卡驱动版本，12.1工具要求显卡驱动>=530.30.02。[Nvidia官方文档](https://docs.nvidia.com/cuda/cuda-toolkit-release-notes/index.html)
---
### 安装驱动和CUDA 工具
- 安装驱动程序
  ```bash
  # 可以使用apt search nvidia-driver搜索驱动版本。一般安装完成后，需要重启系统
  apt install nvidia-driver-550

  # 执行nvidia-smi 检查驱动是否正常安装，运行
  nvidia-smi

  Thu May 30 09:38:51 2024
  +---------------------------------------------------------------------------------------+
  | NVIDIA-SMI 530.30.02              Driver Version: 530.30.02    CUDA Version: 12.1     |
  |-----------------------------------------+----------------------+----------------------+
  | GPU  Name                  Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
  | Fan  Temp  Perf            Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
  |                                         |                      |               MIG M. |
  |=========================================+======================+======================|
  |   0  Quadro RTX 5000                 On | 00000000:03:00.0 Off |                  Off |
  | 33%   27C    P8                3W / 230W|    153MiB / 16384MiB |      0%      Default |
  |                                         |                      |                  N/A |
  +-----------------------------------------+----------------------+----------------------+

  +---------------------------------------------------------------------------------------+
  | Processes:                                                                            |
  |  GPU   GI   CI        PID   Type   Process name                            GPU Memory |
  |        ID   ID                                                             Usage      |
  |=======================================================================================|
  |    0   N/A  N/A     51659      C   python3                                     150MiB |
  +---------------------------------------------------------------------------------------+
  ```
- 安装CUDA Toolkit，这里安装的是12.1.1
  ```bash
  wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-ubuntu2204.pin
  sudo mv cuda-ubuntu2204.pin /etc/apt/preferences.d/cuda-repository-pin-600
  wget https://developer.download.nvidia.com/compute/cuda/12.1.1/local_installers/cuda-repo-ubuntu2204-12-1-local_12.1.1-530.30.02-1_amd64.deb
  sudo dpkg -i cuda-repo-ubuntu2204-12-1-local_12.1.1-530.30.02-1_amd64.deb
  sudo cp /var/cuda-repo-ubuntu2204-12-1-local/cuda-*-keyring.gpg /usr/share/keyrings/
  sudo apt-get update
  sudo apt-get -y install cuda
  ```

wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-ubuntu2204.pin
sudo mv cuda-ubuntu2204.pin /etc/apt/preferences.d/cuda-repository-pin-600
wget https://developer.download.nvidia.com/compute/cuda/12.1.1/local_installers/cuda-repo-ubuntu2204-12-1-local_12.1.1-530.30.02-1_amd64.deb
sudo dpkg -i cuda-repo-ubuntu2204-12-1-local_12.1.1-530.30.02-1_amd64.deb
sudo cp /var/cuda-repo-ubuntu2204-12-1-local/cuda-*-keyring.gpg /usr/share/keyrings/
sudo apt-get update
sudo apt-get -y install cuda



- 安装python插件
  ```bash
  apt install python3-pip
  pip3 install virtualenv

  # 创建pip的配置文件，使用国内源
  mkdir ~/.pip
  cat > ~/.pip/pip.conf <<EOF
  [global]
  index-url = http://mirrors.aliyun.com/pypi/simple/

  [install]
  trusted-host=mirrors.aliyun.com
  EOF

  mkdir /data/
  virtualenv /data/venv

  # 激活虚拟环境
  source /data/venv/bin/activate
  ```
- 安装sd-webui
  ```bash
  wget -q https://raw.githubusercontent.com/AUTOMATIC1111/stable-diffusion-webui/master/webui.sh
  bash webui.sh

  # 启动
  python3 launch.py --listen --enable-insecure-extension-access
  ```
- 遇到问题
  1. 下载models文件v1-5-pruned-emaonly.safetensors，放置在根目录下的models/Stable-diffusion。[下载地址](https://plus.gitclone.com/models/runwayml/stable-diffusion-v1-5)
  2. OSError: Can't load tokenizer for 'openai/clip-vit-large-patch14'。由于huggingface也无法访问了，需要手动下载。到huggingface的[镜像网站](https://plus.gitclone.com/models/openai/clip-vit-large-patch14#/)下载，把下载文件放置在sd-web的根目录下的openai/clip-vit-large-patch14目录(如果目录不存在，需要手动创建)

---
### 参考信息
1. [github stable-diffusion-webui](https://github.com/AUTOMATIC1111/stable-diffusion-webui)
2. [一份保姆级的Stable Diffusion部署教程，开启你的炼丹之路](https://juejin.cn/post/7252860591315746853)