## Jenkins 的jenkinsfile配置
- 获取git提交者的邮箱地址
```bash
stage('Deploy') { 
    steps {
        echo("Deploy")
        script {
            # 执行git命令，获取提交者的邮箱地址
            def COMMITTER_EMAIL = sh (
                script: 'git --no-pager show -s --format=\'%ae\'',
                returnStdout: true).trim()
            echo "COMMITTER_EMAIL: ${COMMITTER_EMAIL}" 

            # 定义变量，只能在当前代码块生效
            def NAME = JOB_NAME.tokenize('/')
            echo "abc " + NAME[0]

            # 设置为环境变量，全局可用
            env.NAME_1 = JOB_NAME.tokenize('/')
        }
    }
}
```
- 配置触发器
```bash
triggers {
    GenericTrigger(
        # 获取POST参数中的变量，key指的是变量名，通过$ref来访问对应的值，value指的是JSON匹配值（参考Jmeter的JSON提取器）
        # ref指的是推送的分支，格式如：refs/heads/master
        genericVariables: [[key: 'ref', value: '$.ref']],
        causeString: 'Triggered on $ref',
        # 设置token
        token: 'abc123',
        # 打印变量 和 post 信息
        printContributedVariables: true,
        printPostContent: true,
        silentResponse: false,
        regexpFilterText: '$ref',
        # regexpFilterExpression与regexpFilterExpression成对使用
        # 当两者相等时，会触发对应分支的构建
        regexpFilterExpression: 'refs/heads/k8s02_stage$'
    )
}
```