### kubeshark使用笔记
#### 注意事项
- kubeshark组件会访问以下地址：
  1. https://release-assets.githubusercontent.com
  2. https://github.com/kubeshark/kubeshark.github.io/releases/download/kubeshark-52.9.0/kubeshark-52.9.0.tgz
  3. https://helm.kubeshark.co
  4. https://api.kubeshark.co/health
#### 部署
- 下载kubeshark 二进制文件，版本为52.9.0
  ```bash
  curl -Lo kubeshark https://github.com/kubeshark/kubeshark/releases/download/v52.9.0/kubeshark_linux_amd64 && chmod 755 kubeshark
  ```
- 执行kubeshark，自动创建相应的应用
  ```bash
  kubeshark tap
  ```