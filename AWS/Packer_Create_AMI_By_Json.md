在AWS上使用packer来构建AMI
----

- 创建packer_build.js文件
```bash
cat > packer_build.js <<'EOF'
{
    "builders": [
        {
            "type": "amazon-ebs",
            "access_key": "xxxxx",
            "secret_key": "xxxxx",
            "region": "us-west-1",
            "availability_zone": "us-west-1b",
            "vpc_id": "vpc-id",
            "subnet_id": "subnet-id",
            "ssh_keypair_name": "abc-key",
            "source_ami": "ami-id",
            "security_group_id": "sg-id",
            "instance_type": "t2.micro",
            "ssh_username": "ec2-user",
            "ami_name": "packer {{timestamp}}",
            "ssh_private_key_file": "/home/dir/key.pem",
            "ami_block_device_mappings": [
                {
                    "device_name": "/dev/sda1",
                    "volume_size": 8,
                    "volume_type": "gp2",
                    "delete_on_termination": true
                }
            ],
            "launch_block_device_mappings": [
                {
                    "device_name": "/dev/sda1",
                    "volume_size": 8,
                    "volume_type": "gp2",
                    "delete_on_termination": true
                }
            ],
        }
    ],
    "provisioners": [
        {
            "type": "shell",
            "execute_command": "sudo -S sh '{{ .Path }}'",
            "script": "install"
        }
    ]
}
EOF
```
- 创建EC2的AMI镜像
```bash
packer build packer_build.json
```

https://www.packer.io/
https://shazi.info/aws-%E7%94%A8-packer-%E4%BE%86-build-ami/
https://github.com/shazi7804/packer-aws-ami
https://yq.aliyun.com/articles/72724
http://dockone.io/article/996
