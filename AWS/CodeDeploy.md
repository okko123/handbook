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


  https://docs.aws.amazon.com/zh_cn/codedeploy/latest/userguide/codedeploy-agent-operations-install-linux.html
