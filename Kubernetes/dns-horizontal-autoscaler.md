## dns-horizontal-autoscaler

cat > admin/dns/dns-horizontal-autoscaler.yaml  <<EEOOFF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dns-autoscaler
  namespace: kube-system
  labels:
    k8s-app: dns-autoscaler
spec:
  selector:
    matchLabels:
      k8s-app: dns-autoscaler
  template:
    metadata:
      labels:
        k8s-app: dns-autoscaler
    spec:
      containers:
      - name: autoscaler
        image: k8s.gcr.io/cluster-proportional-autoscaler-amd64:1.6.0
        resources:
          requests:
            cpu: 20m
            memory: 10Mi
        command:
        - /cluster-proportional-autoscaler
        - --namespace=kube-system
        - --configmap=dns-autoscaler
        - --target=<SCALE_TARGET>
        # When cluster is using large nodes(with more cores), "coresPerReplica" should dominate.
        # If using small nodes, "nodesPerReplica" should dominate.
        - --default-params={"linear":{"coresPerReplica":256,"nodesPerReplica":16,"min":1}}
        - --logtostderr=true
        - --v=2
EEOOFF
kubectl apply -f dns-horizontal-autoscaler.yaml

https://kubernetes.io/docs/tasks/administer-cluster/dns-horizontal-autoscaling/