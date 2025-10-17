# KEDA的使用
- KEDA对Kubernetes集群的要求

  |KEDA版本|Kubernetes版本|
  |-|-|
  |v2.17|v1.30 - v1.32|
  |v2.16|v1.29 - v1.31|
  |v2.15|v1.28 - v1.30|
  |v2.14|v1.27 - v1.29|
  |v2.13|v1.27 - v1.29|
---
## 测试样例
1. 使用python语言，利用fastapi库，构建一个简单的api接口应用，并暴露metrics，以便Prometheus抓取
   ```bash
   pip3 install fastapi uvicorn prometheus-client

   cat > main.py <<'EOF'
   from fastapi import FastAPI, Response, Request
   from prometheus_client import Counter, generate_latest, REGISTRY, CONTENT_TYPE_LATEST
   import time

   # 定义 Prometheus Counter 指标
   # 这个指标将统计 HTTP 请求的总数，并包含 method, path, status 等标签
   HTTP_REQUESTS_TOTAL = Counter(
       'http_requests_total',  # 指标名称
       'Total number of HTTP requests',  # 指标说明
       ['method', 'endpoint', 'status_code']  # 标签 (labels)
   )

   # 创建一个单独的指标用于健康检查端点（可选，但更清晰）
   HEALTH_REQUESTS_TOTAL = Counter(
       'health_requests_total',
       'Total number of health check requests',
       ['method', 'endpoint', 'status_code']
   )

   # 初始化 FastAPI 应用
   app = FastAPI(title="FastAPI Prometheus Metrics Example")

   @app.middleware("http")
   async def prometheus_middleware(request: Request, call_next):
       """中间件：用于记录所有请求的指标"""
       start_time = time.time()
       response = await call_next(request)
       process_time = time.time() - start_time

       # 获取请求方法和路径
       method = request.method
       path = request.url.path

       # 根据路径决定使用哪个指标
       if path == "/health":
           HEALTH_REQUESTS_TOTAL.labels(
               method=method,
               endpoint=path,
               status_code=response.status_code
           ).inc()
       else:
           HTTP_REQUESTS_TOTAL.labels(
               method=method,
               endpoint=path,
               status_code=response.status_code
           ).inc()

       return response

   @app.get("/health")
   async def health_check():
       """健康检查接口，返回 HTTP 200"""
       return {"status": "healthy", "message": "Service is up and running"}

   @app.get("/metrics")
   async def metrics():
       """暴露 Prometheus metrics 的端点"""
       return Response(
           content=generate_latest(REGISTRY),
           media_type=CONTENT_TYPE_LATEST
       )

   @app.get("/")
   async def read_root():
       """根路径接口"""
       return {"message": "Hello World with Prometheus Metrics!"}

   @app.get("/api/v1/test")
   async def test_endpoint():
       """另一个测试接口"""
       return {"message": "This is a test endpoint"}

   if __name__ == "__main__":
       import uvicorn
       uvicorn.run(app, host="0.0.0.0", port=8000)
   EOF
   ```
2. 运行应用
   ```bash
   python3 main.py

   # 测试健康检查接口:
   curl http://localhost:8000/health
   返回：{"status":"healthy","message":"Service is up and running"}

   # 测试其他接口:
   curl http://localhost:8000/
   返回: {"message":"Hello World with Prometheus Metrics!"}

   curl http://localhost:8000/api/v1/test
   返回: {"message":"This is a test endpoint"}

   # 查看 Prometheus metrics:
   curl http://localhost:8000/metrics

   # HELP http_requests_total Total number of HTTP requests
   # TYPE http_requests_total counter
   http_requests_total{endpoint="/",method="GET",status_code="200"} 1.0
   http_requests_total{endpoint="/api/v1/test",method="GET",status_code="200"} 1.0
   http_requests_total{endpoint="/health",method="GET",status_code="200"} 3.0
   
   # HELP health_requests_total Total number of health check requests
   # TYPE health_requests_total counter
   health_requests_total{endpoint="/health",method="GET",status_code="200"} 3.0
   ```
3. 将应用打包成镜像
   ```bash
   cat > Dockerfile <<EOF
   FROM python:3.10.18
   RUN pip3 install fastapi prometheus_client uvicorn -i https://pypi.tuna.tsinghua.edu.cn/simple
   WORKDIR /data
   COPY main.py /data/main.py
   ENTRYPOINT ["python3", "main.py"]
   EOF

   docker build . -t demo:v1
   ```
4. 在k8s中部署deployment、svc
   ```bash
   cat > deployment-1.yaml << 'EOF'
   apiVersion: apps/v1
   kind: Deployment
   metadata:
      name: demo-app
   spec:
      replicas: 1
      selector:
         matchLabels:
            app: demo-app
      template:
         metadata:
            labels:
               app: demo-app
         spec:
            containers:
            - name: demo-app
              image: demo:v1
              ports:
                 - containerPort: 8000
   ---
   apiVersion: v1
   kind: Service
   metadata:
     annotations:
     labels:
       app: demo-app
     name: demo
   spec:
     selector:
       app: demo-app
     internalTrafficPolicy: Cluster
     ports:
     - name: http
       port: 8000
       protocol: TCP
       targetPort: 8000
     sessionAffinity: None
     type: ClusterIP
   EOF

   kubectl apply -f deployment-1.yaml
   ```
5. 添加servicemonitor
   ```bash
   cat > svcmonitor.yaml << 'EOF'
   apiVersion: monitoring.coreos.com/v1
   kind: ServiceMonitor
   metadata:
     annotations:
     labels:
       app: demo-app
     name: demo-monitor
     namespace: monitoring
   spec:
     endpoints:
     - interval: 30s
       port: http
     jobLabel: app
     namespaceSelector:
       matchNames:
       - default
     selector:
       matchLabels:
         app: demo-app
   EOF

   kubectl apply -f svcmonitor.yaml

   # 访问Prometheus的web界面检查是否添加上监控
   ```

6. 配置keda
   ```bash
   cat > so.yaml <<'EOF'
   apiVersion: keda.sh/v1alpha1
   kind: ScaledObject
   metadata:
      name: demo-app-scaledobject
   spec:
      scaleTargetRef:
         name: demo-app
      # KEDA 多长时间检查一次触发器(trigger)
      pollingInterval: 15 
      # 最小的副本数量
      minReplicaCount: 1
      # 最大的副本数量
      maxReplicaCount: 10
      advanced:
        horizontalPodAutoscalerConfig:
          behavior: # 控制扩缩容行为，使用比较保守的策略，快速扩容，缓慢缩容
            scaleDown: # 缓慢缩容：至少冷却 10 分钟才能缩容
              stabilizationWindowSeconds: 600
              selectPolicy: Min # 
            scaleUp: # 快速扩容：每 15s 最多允许扩容 5 倍
              policies:
                - type: Percent
                  value: 500
                  periodSeconds: 15
      triggers:
         - type: prometheus
           metadata:
              serverAddress: http://prometheus-k8s.monitoring.svc.cluster.local:9090
              metricName: http_requests_total
              threshold: '5'
              query: sum(rate(http_requests_total{endpoint="/api/v1/test", status_code="200"}[1m]))
   EOF

   kubectl apply -f so.yaml

   # 检查
   kubectl get scaledobject
   NAME                    SCALETARGETKIND      SCALETARGETNAME   MIN   MAX   READY   ACTIVE   FALLBACK   PAUSED    TRIGGERS     AUTHENTICATIONS   AGE
   demo-app-scaledobject   apps/v1.Deployment   demo-app          1     10    True    False    False      Unknown   prometheus                     3h54m

   ```
7. 测试验证
   - 使用ab对 压测 /api/v1/test 接口
   - 登录Prometheus的web页面，检查http_requests_total的指标变化
   - kubectl get pods 查看demo-app的副本数据是否增加

8. 其他
   - 副本的扩容、缩容时间由HPA决定
     - 默认情况下
       -  扩容默认值： 0 延迟，确保应用能够快速响应流量增长。
       - 缩容默认值： 5 分钟延迟，保护应用免受指标短暂波动的影响，避免不必要的Pod终止和可能的服务中断。
     ```bash
     # 查看HPA的规则，配置缩容和扩容的时间、扩容的副本数量。Kubernetes HPA 的默认缩放策略设计哲学是："快速扩容，保守缩容"。
     kubectl get hpa

     NAME                             REFERENCE             TARGETS     MINPODS   MAXPODS   REPLICAS   AGE
     keda-hpa-demo-app-scaledobject   Deployment/demo-app   0/5 (avg)   1         10        1          28h
     ```
   - 调整缩容策略，
     ```yaml
     apiVersion: v1
     items:
     - apiVersion: autoscaling/v2
       kind: HorizontalPodAutoscaler
       metadata:
         name: keda-hpa-demo-app-scaledobject
         namespace: default
       spec:
         behavior:
           scaleDown:
             policies:
               # 缩容间隔时间
             - periodSeconds: 60
               type: Percent
               value: 10 # 每分钟最多缩容10%的Pod
             selectPolicy: Max
             stabilizationWindowSeconds: 60 # 等待1分钟观察趋势
         maxReplicas: 10
         minReplicas: 1
         scaleTargetRef:
           apiVersion: apps/v1
           kind: Deployment
           name: demo-app
     ```
---
### 参考连接
- [定时水平伸缩 (Cron 触发器)](https://imroc.cc/kubernetes/best-practices/autoscaling/keda/cron)
- [KEDA官网-ScaledObject specification](https://keda.sh/docs/2.17/reference/scaledobject-spec/#cooldownperiod)