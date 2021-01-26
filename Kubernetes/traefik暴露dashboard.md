## traefik暴露dashboard

kubectl port-forward $(kubectl get pods --selector "app.kubernetes.io/name=traefik" --output=name) 9000:9000


https://doc.traefik.io/traefik/getting-started/install-traefik/