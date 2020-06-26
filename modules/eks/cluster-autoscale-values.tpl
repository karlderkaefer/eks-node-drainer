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
