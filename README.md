# StackGen ClickHouse HA Cluster (Local Demo)

Production-grade ClickHouse high-availability cluster deployed on Kubernetes using Helm and the Altinity ClickHouse Operator, with sharding, replication, persistent storage, and failure recovery.

---

## Project Context

Assessment: StackGen DevOps / SRE Assignment  
Platform: Kubernetes (Minikube)  
Operator: Altinity ClickHouse Operator (Helm)  
Database: ClickHouse  

---

## Architecture Overview

Kubernetes Cluster (Minikube)

- ClickHouse Data Nodes
  - Shard 0
    - Pod 0
    - Pod 1
  - Shard 1
    - Pod 0
    - Pod 1

- Persistent volumes attached to each pod
- No external coordination service

---

## Key Characteristics

- 2 shards × 2 pods (4 total ClickHouse pods)
- Persistent storage via PVCs
- Data survives pod restarts
- Distributed table for sharded queries
- Fully reproducible via Kubernetes manifests

---

## Coordination Model (Important)

### What Was Used

- Engine: MergeTree
- Tables:
  - demo.readings_local → ENGINE = MergeTree
  - demo.readings → ENGINE = Distributed
- Order key: (timestamp, sensor_id)

### What Was NOT Used

- ZooKeeper
- ClickHouse Keeper
- ReplicatedMergeTree

This was a deliberate design decision to reduce coordination complexity and keep the demo deterministic and easy to operate.

---

## Why MergeTree Was Chosen

- No coordination dependency
- Simple and stable
- Ideal for demos and assessments
- Focuses on Kubernetes fundamentals:
  - Persistent storage
  - Pod lifecycle
  - Scheduling and recovery
  - Data ingestion

In production, this design would evolve to ReplicatedMergeTree with ClickHouse Keeper.

---

## Step 1: Kubernetes Cluster Setup

- Minikube started with Docker driver
- Resources allocated:
  - 6 CPUs
  - 12 GB RAM
  - 30 GB disk

Command:
minikube start --driver=docker --nodes=3 --cpus=6 --memory=12g --disk-size=30g

---

## Step 2: Custom StorageClass

File: k8s/storageclass.yaml

- StorageClass: local-gp3
- Simulates AWS gp3 behavior
- reclaimPolicy: Retain
- Provisioner: rancher.io/local-path

Purpose:
- Prevents accidental data loss
- Matches production database storage behavior

---

## Step 3: ClickHouse Operator Installation (Helm)

Commands:
helm repo add altinity https://helm.altinity.com  
helm repo update  

helm install clickhouse-operator altinity/altinity-clickhouse-operator \
  --namespace clickhouse-operator \
  --create-namespace

Verified CRD:
- clickhouseinstallations.clickhouse.altinity.com

---

## Step 4: ClickHouse Cluster Deployment

File: k8s/chi-cluster.yaml

- Deployed ClickHouseInstallation custom resource
- Configuration:
  - 2 shards
  - 2 pods per shard
- 10Gi persistent volume per pod

Pods created:
- chi-chi-cluster-data-0-0-0
- chi-chi-cluster-data-0-1-0
- chi-chi-cluster-data-1-0-0
- chi-chi-cluster-data-1-1-0

---

## Step 5: Schema Creation
File: k8s/stackgen-tables.yaml


SQL:
CREATE DATABASE demo;

CREATE TABLE demo.readings_local
(
  timestamp DateTime,
  sensor_id Int32,
  temperature Float32,
  humidity Float32
)
ENGINE = MergeTree
ORDER BY (timestamp, sensor_id);

CREATE TABLE demo.readings
AS demo.readings_local
ENGINE = Distributed(cluster, demo, readings_local, rand());

---

## Step 6: Data Ingestion

Script: scripts/ingest.sh

- Generates 10,000 sensor readings
- Inserts data via ClickHouse HTTP interface (port 8123)
- CSV format matches schema exactly

Validation query:
SELECT count() FROM demo.readings;
Result: 10000

---

## Step 7: Failure Recovery Test

Simulated pod failure:
kubectl delete pod chi-chi-cluster-data-0-0-0

Observed behavior:
- Pod recreated automatically by Kubernetes
- Persistent volume reattached
- Data remained intact

Verification query:
SELECT count() FROM demo.readings;
Result: 10000

---

## What This Demo Proves

- ClickHouse runs reliably on Kubernetes
- Persistent volumes protect data
- Kubernetes recovers failed pods
- Sharded query execution works as expected
- Data ingestion is reliable at scale

---

## Production Considerations

For a production-grade deployment:
- Use ReplicatedMergeTree
- Deploy ClickHouse Keeper
- Separate coordination and data workloads
- Use cloud storage (gp3 / managed disks)
- Enable monitoring, backups, and alerting

These were intentionally excluded from this demo to keep it simple and stable.

---

## Project Structure

stackgen-clickhouse/
- README.md
- k8s/
  - storageclass.yaml
  - chi-cluster.yaml
- scripts/
  - ingest.sh
- .gitignore

---

## Cleanup

kubectl delete -f k8s/  
minikube delete  

---

