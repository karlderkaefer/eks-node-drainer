## EKS node drainer with terraform

serverless python function from https://github.com/aws-samples/amazon-k8s-node-drainer

**STEPS**
* build python zip https://docs.aws.amazon.com/lambda/latest/dg/python-package.html
```
# script need to be adapted to your system (python 3 version)
cd modules/node-drainer
./build.sh
```
* define variables for your cluster, this is an example replace ${user_name} and ${account_id} 
```
cat <<EOF > terraform.auto.tfvars
map_roles = [
  {
    rolearn  = "arn:aws:iam::${account_id}:role/NodeDrainerRole"
    username = "lambda"
    groups   = []
  },
]

map_users = [
  {
    userarn  = "arn:aws:iam::${account_id}:user/${user_name}"
    username = "${user.name}"
    groups   = ["system:masters"]
  }
]

cluster_name = "eks-test"

tags = {
  Owner = "${user_name}"
  Environment = "test"
  Ticket = "POM-3102"
}
EOF
```
* apply
```
terraform init
terraform apply
```
* update kubeconfig and deploy example grafana with pod disruption budget
```
aws eks update-kubeconfig --name $CLUSTER_NAME

# optional prepare helm
helm repo add stable https://kubernetes-charts.storage.googleapis.com
helm repo update

# optional install latest cni plugin to ensure we can destroy cluster clean
# https://github.com/terraform-aws-modules/terraform-aws-eks/issues/285
# https://docs.aws.amazon.com/eks/latest/userguide/cni-upgrades.html
kubectl apply -f https://raw.githubusercontent.com/aws/amazon-vpc-cni-k8s/release-1.6/config/v1.6/aws-k8s-cni.yaml

# install grafana
helm upgrade --install grafana --set podDisruptionBudget.minAvailable=3 --set replicas=6 --namespace default stable/grafana

kubectl get pods
```
* change version number of `worker_ami_name_filter` in [main.tf](modules/eks/main.tf)
* apply terraform again pod should be drained gracefully

# autoscaler
```
export CLUSTER_NAME=eks-test-karl
export ACCOUNT_ID=$(aws sts get-caller-identity | jq -r '.Account')
export REGION=$(aws configure get region)
cat <<EOF > autoscaler-values.yaml
awsRegion: ${REGION}

# override would interfere with node drainer
podDisruptionBudget: |

rbac:
  create: true
  serviceAccountAnnotations:
    eks.amazonaws.com/role-arn: "arn:aws:iam::${ACCOUNT_ID}:role/cluster-autoscaler"

autoDiscovery:
  clusterName: ${CLUSTER_NAME}
  enabled: true

extraArgs:
  # faster response of auto-scaler for demo
  scale-down-unneeded-time: 1m
  scale-down-delay-after-add: 1m
  max-inactivity: 1m
  skip-nodes-with-local-storage: false
EOF

envsubst < autoscaler-values.yaml

helm upgrade --install cluster-autoscaler --namespace kube-system -f ./autoscaler-values.yaml stable/cluster-autoscaler
kubectl logs -l app.kubernetes.io/instance=cluster-autoscaler -f -n kube-system
```

# stateful set
```
helm upgrade --install solr --namespace default incubator/solr
helm repo add incubator http://storage.googleapis.com/kubernetes-charts-incubator
helm repo update
```

