## POD直接暴露端口，配置ports
apiVersion: v1
kind: Pod
metadata:
  name: nginx2
  labels:
    app: web
spec:
 containers:
  - name: ng-web2
    image: nginx:latest
    imagePullPolicy: Never
    ports:
    - name: http
      containerPort: 80     --容器端口
      hostPort: 80          --暴露端口
      protocol: TCP