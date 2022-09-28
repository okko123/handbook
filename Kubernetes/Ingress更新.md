## Ingress更新
- k8s: 1.22.14
- IngressController
  - nginx ingress controller
  - kong ingress controller
### 更新
- 需要在ingress中指定IngressClassName，否则流量不会被正确导入
  ```yaml
  apiVersion: networking.k8s.io/v1
  kind: Ingress
  metadata:
    name: echo-80
    namespace: default
  spec:
    ingressClassName: kong
    rules:
    - host: echo.qdama.test
      http:
        paths:
        - backend:
            service:
              name: echo
              port:
                number: 8080
          path: /
          pathType: Prefix
  status:
    loadBalancer: {}
  ```