AWS cli命令行工具的使用记录
===
### EC2
- 查看所有EC2实例使用的IAM角色
  - aws ec2 describe-iam-instance-profile-associations
- 替换EC2实例使用的IAM角色
  - aws ec2 replace-iam-instance-profile-association
- 查看ec2实例
  - aws ec2 describe-instances --filters Name=instance-type,Values=i3.2xlarge --query "Reservations[*].Instances[*].{ID:InstanceId,DNS:PrivateDnsName,State:State}"
  - aws ec2 describe-instances --filters Name=instance-state-name,Values=running

### Cloudwatch
- 设置告警的状态为ALARM
  - aws cloudwatch set-alarm-state --state-value ALARM --alarm-name CPU-ALARM --state-reason "Test Alarm"

### CodeDeploy
  - 创建新应用程序
    - aws deploy create-application --application-name WordPress_App
  - 将应用程序打包到单个存档文件并把文件推送到S3上
    - aws deploy push --application-name WordPress_App --s3-location s3://codedeploydemobucket/WordPressApp.zip --ignore-hidden-files
  - 创建部署组（使用ec2的tag进行机器匹配）
    - aws deploy create-deployment-group --application-name WordPress_App --deployment-group-name WordPress_DepGroup --deployment-config-name CodeDeployDefault.OneAtATime --ec2-tag-filters Key=Name,Value=CodeDeployDemo,Type=KEY_AND_VALUE --service-role-arn serviceRoleARN
  - 创建部署
    - aws deploy create-deployment --application-name WordPress_App --deployment-config-name CodeDeployDefault.OneAtATime --deployment-group-name WordPress_DepGroup --s3-location bucket=codedeploydemobucket,bundleType=zip,key=WordPressApp.zip
### route53
  - aws route53 change-resource-record-sets --hosted-zone-id idxxxxx --change-batch file://example.json
  - aws route53  list-resource-record-sets --hosted-zone-id   --query "ResourceRecordSets[*].{Name:Name}"
### 恢复S3上删除的对象，前提是开启版本控制
  - aws s3api list-object-versions --bucket examplebucket
  - aws s3api delete-object --bucket protectedbucket --version-id 'example.d6tjAKF1iObKbEnNQkIMPjj' --key undelete-key
## 参考资料
- [AWS Cli ec2手册](https://docs.aws.amazon.com/cli/latest/reference/ec2/)
- [CodeDeploy手册](https://docs.aws.amazon.com/zh_cn/codedeploy/latest/userguide/tutorials-wordpress.html)
- [检索已删除的Amazon S3对象](https://aws.amazon.com/cn/premiumsupport/knowledge-center/s3-undelete-configuration/?nc1=f_ls )
