## Higress使用
1. 安装，使用helm3进行安装
   ```bash
   helm repo add higress.io https://higress.io/helm-charts
   helm install higress -n higress-system higress.io/higress --create-namespace --render-subchart-notes --set global.local=true --set global.o11y.enabled=false
   ```
2. 下载hgctl工具
   ```bash
   curl -Ls https://raw.githubusercontent.com/alibaba/higress/main/tools/hack/get-hgctl.sh | bash
   ```