# 写Dockerfile的注意事项
1. 减少构建时间
   * 构建顺序影响缓存的利用率
   * 只拷贝需要的文件，防止缓存溢出
   * 最小化可缓存的执行层
2. 减少镜像体积
   * 删除不必要依赖
   * 删除包管理工具的缓存
3. 可维护性
   * 尽量使用官方镜像
   * 使用更具体的标签
   * 使用体积最小的基础镜像
4. 重复利用
   * 在一致的环境中，从源代码构建
   * 在单独的步骤中获取依赖项
   * 使用多阶段构建来删除构建时的依赖项
5. 使用多阶段构建

## 参考连接
* [你确定你会写Dockerfile](https://fuckcloudnative.io/posts/intro-guide-to-dockerfile-best-practices/)