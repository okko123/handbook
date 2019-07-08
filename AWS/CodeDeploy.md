使用aws cli创建codedeploy任务
===
## EC2实例需要安装codedeploy agent
- 安装agent
```bash
wget https://bucket-name.s3.amazonaws.com/latest/install
###bucket-name的查询地址https://docs.aws.amazon.com/zh_cn/codedeploy/latest/userguide/resource-kit.html#resource-kit-bucket-names
chmod +x ./install
sudo ./install auto
```

## 需要给EC2实例赋予IAM的角色或者IAM策略，运行EC2实例访问aws资源

## 使用cli创建codedeploy任务
```bash
#创建新应用程序
aws deploy create-application --application-name WordPress_App
#将应用程序打包到单个存档文件并把文件推送到S3上，必须进入代码根目录执行
aws deploy push \
  --application-name WordPress_App \
  --s3-location s3://erc-codedeploydemobucket/WordPressApp.zip \
  --ignore-hidden-files
#创建部署组（使用ec2的tag进行机器匹配）
aws deploy create-deployment-group \
  --application-name WordPress_App \
  --deployment-group-name WordPress_DepGroup \
  --deployment-config-name CodeDeployDefault.OneAtATime \
  --ec2-tag-filters Key=Name,Value=CodeDeployDemo,Type=KEY_AND_VALUE \
  --service-role-arn arn
#创建部署
aws deploy create-deployment \
  --application-name WordPress_App \
  --deployment-config-name CodeDeployDefault.OneAtATime \
  --deployment-group-name WordPress_DepGroup \
  --s3-location bucket=erc-codedeploydemobucket,bundleType=zip,key=WordPressApp.zip
```

## 蓝绿发布
- 在codedeploy中，由部署组（deployed group）的配置中关联对应EC2实例的tag或Amazon EC2 Auto Scaling组
- 在使用Auto Scaling的条件下，进行蓝绿发布，期间的过程如下：
  - codedeploy以原来的AS配置，进行复制。命名规则为CodeDeploy_{部署组的组名}_{部署ID}
  - 在新的AS组的作用下，创建机器
  - 机器创建完成后，触发codedeploy进行app的发布
  - 当codedeploy完成app的发布后，根据配置等待指定时间/立刻，将流量导入到新机器上。此时，新旧app都同时在线上进行服务
  - 当新机器通过了LB的健康检查后，才将旧实例从LB上摘除
  - 旧机器会根据配置等待指定时间/立刻，将旧机器进行销毁
- 回滚，codeploy执行的动作
  - 点击停止部署并回滚
  - codedeploy中止本次部署
  - 新建部署，把所有机器重新挂载回LB上
  - 当挂载完成后，通过LB的健康检查后，才开始将新实例从LB上摘除
  - 注意，回滚操作后，codedeploy不会将发布失败的AS组进行删除，需要手动删除

  https://docs.aws.amazon.com/zh_cn/codedeploy/latest/userguide/codedeploy-agent-operations-install-linux.html
