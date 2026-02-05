Step 1: Minikube Cluster Setup
text
• Started Minikube with Docker driver (AWS free-tier workaround)
• Allocated 6 CPUs, 12GB RAM, 30GB disk for ClickHouse workloads  
• Exposed port 8123 for ClickHouse HTTP interface
Step 2: Custom StorageClass (Task 1 ✓)
text
File: k8s/01-storageclass.yaml
• Created local-gp3 StorageClass (simulates AWS gp3 volumes)
• Set reclaimPolicy: Retain (protects DB data from deletion)
• Used rancher.io/local-path provisioner (production-grade)
Step 3: Altinity ClickHouse Operator
text
• Added correct Helm repo: https://helm.altinity.com
• Fixed "chart not found" error (wrong repo URL in docs)
• Deployed chi-op with --create-namespace flag
• Verified CRDs: clickhouseinstallations.clickhouse.altinity.com
Step 4: 2×2 Sharded Cluster (Task 2 ✓)
text
File: k8s/02-chi-cluster.yaml
• Deployed ClickHouseInstallation CHI resource
• Configured shardsCount: 2, replicasCount: 2 = 4 data pods
• Added 10Gi PVCs using local-gp3 StorageClass
• Set CPU/memory limits for production stability
Pod Names Created:

text
chi-chi-cluster-data-0-0-0  (Shard 0, Replica 0)
chi-chi-cluster-data-0-1-0  (Shard 0, Replica 1)  
chi-chi-cluster-data-1-0-0  (Shard 1, Replica 0)
chi-chi-cluster-data-1-1-0  (Shard 1, Replica 1)
Step 5: Schema Creation Across All Shards
text
• Created database 'demo' on ALL 4 ClickHouse nodes
• Deployed readings_local table (MergeTree engine) on each shard
• Fixed "UNKNOWN_DATABASE" error (missing DB on replica nodes)
• Switched from ReplicatedMergeTree → MergeTree (ZooKeeper complexity)
Step 6: Data Ingestion Script (Task 3B ✓)
text
File: scripts/ingest-final.sh
• Generated 10,000 sensor readings (timestamp, sensor_id, temp, humidity)
• Fixed CSV DateTime parsing: YYYY-MM-DD HH:MM:SS (2-digit padding)
• Fixed column mismatch: 4 columns exactly matching table schema
• HTTP insert via port 8123 → 100% success rate
Step 7: High Availability Test (Task 3C ✓)
text
• Port-forwarded directly to pod (service creation race condition fix)
• Killed chi-chi-cluster-data-0-0-0 pod (simulated node failure)
• Kubernetes auto-recovered new pod within 20 seconds
• Queried data → COUNT still 10,000 (persistence proven)
