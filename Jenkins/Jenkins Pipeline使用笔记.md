# Jenkins Pipeline使用笔记
### 在for 循环中使用if判断，when不能使用在script的块内
when is a directive used in the declarative pipeline definition - it won't work inside script {} block. Instead use if.
```bash
    stage('Execute') {
        steps {
            script {
                for (int i = 0; i < hostnameMap.size; i++) {
                    hostname = hostnameMap[i]
                    echo 'Executing ' + hostname

                    stage('Backup previous build ' + hostname) {
                        backup(hostname, env.appHome)
                    }

                    stage('Deploy ' + hostname) {
                        if (env.BRANCH_NAME ==~ /(dev|master)/) {
                            deploy(hostname, env.appHome, env.appName)
                        }
                    }

                    stage('Restart ' + hostname) {
                        if (env.BRANCH_NAME ==~ /(dev|master)/) {
                            restart(hostname, env.appName, env.port)
                        }
                    }

                }
            }
        }
    }

```
---
## 参考连接
- [No such DSL method 'when' found among steps in Jenkinsfile](https://stackoverflow.com/questions/49558221/no-such-dsl-method-when-found-among-steps-in-jenkinsfile)
- [Jenkins持续集成 - 管道详解](https://www.xncoding.com/2017/03/22/fullstack/jenkins02.html)