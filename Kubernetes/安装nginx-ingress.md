# 安装nginx-ingress
## 安装过程
```bash
# 官方使用NodePort的方式创建nginx-ingress
wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/baremetal/deploy.yaml
# 希望使用Loadbalance方式生成nginx，需执行以下步骤
sed -i 's|NodePort|LoadBalancer|g' deploy.yaml

kubectl apply -f deploy.yaml
```

## 验证
```bash
POD_NAME=$(kubectl get pods -l app.kubernetes.io/name=ingress-nginx -l app.kubernetes.io/component=controller -n ingress-nginx -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $POD_NAME -n ingress-nginx -- /nginx-ingress-controller --version
-------------------------------------------------------------------------------
NGINX Ingress controller
  Release:       0.30.0
  Build:         git-7e65b90c4
  Repository:    https://github.com/kubernetes/ingress-nginx
  nginx version: nginx/1.17.8

-------------------------------------------------------------------------------

kubectl get svc -n ingress-nginx
NAME                                 TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
ingress-nginx-controller             LoadBalancer   10.104.88.155    <pending>     80:30663/TCP,443:30249/TCP   66m
ingress-nginx-controller-admission   ClusterIP      10.103.201.166   <none>        443/TCP                      66m
```
### 参考信息
* [官方文档](https://kubernetes.github.io/ingress-nginx/deploy/#detect-installed-version)