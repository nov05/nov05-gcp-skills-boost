#!/bin/bash
## Created by nov05, 2026-07-29  

export USER_ID=$(gcloud auth list --format="value(account)" --filter="status:ACTIVE")
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID \
  --format='value(projectNumber)')
export REGION=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-region])")
export ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
# export ZONE2=$(gcloud compute zones list \
#   --filter="region:$REGION" \
#   --format="value(name)" | grep -v $ZONE | head -n 1)
# export BUCKET="$PROJECT_ID-bucket"
gcloud config set account $USER_ID
gcloud config set project $PROJECT_ID  
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE
echo
echo "🔹  User: $USER"
echo "🔹  Username: $USER_ID"
echo "🔹  Project ID: $PROJECT_ID"
echo "🔹  Project number: $PROJECT_NUMBER"
echo "🔹  Region: $REGION"
echo "🔹  Zone: $ZONE"
# echo "🔹  Zone 2: $ZONE2"
# echo "🔹  Bukect: $BUCKET"
echo
gcloud auth list


## create a three node cluster
gcloud container clusters create scaling-demo --num-nodes=3 --enable-vertical-pod-autoscaling
## Create a manifest for the php-apache deployment
cat << EOF > php-apache.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: php-apache
spec:
  selector:
    matchLabels:
      run: php-apache
  replicas: 3
  template:
    metadata:
      labels:
        run: php-apache
    spec:
      containers:
      - name: php-apache
        image: k8s.gcr.io/hpa-example
        ports:
        - containerPort: 80
        resources:
          limits:
            cpu: 500m
          requests:
            cpu: 200m
---
apiVersion: v1
kind: Service
metadata:
  name: php-apache
  labels:
    run: php-apache
spec:
  ports:
  - port: 80
  selector:
    run: php-apache
EOF
kubectl apply -f php-apache.yaml
echo -e "\n✅  Check the deployment at: "
echo -e "https://console.cloud.google.com/kubernetes/list/overview?project=$PROJECT_ID\n"

## 👉 Check my progress




cat << 'EOF'

========================================================
Task 1. Scale pods with Horizontal Pod Autoscaling
========================================================

EOF

## inspect your cluster's deployments
## You should see the php-apache deployment with 3/3 pods running
kubectl get deployment
## Apply horizontal autoscaling to the php-apache deployment
kubectl autoscale deployment php-apache --cpu-percent=50 --min=1 --max=10

## 👉 Check my progress

## Check the current status of your Horizontal Pod Autoscaler
## Under the Targets column you should see 1%/50%.
kubectl get hpa



cat << 'EOF'

========================================================
Task 2. Scale size of pods with Vertical Pod Autoscaling
========================================================

EOF

## Vertical Pod Autoscaling has already been enabled on the scaling-demo cluster.
## The output should read enabled: true
gcloud container clusters describe scaling-demo | grep ^verticalPodAutoscaling -A 1

## deploy the hello-server app
kubectl create deployment hello-server --image=gcr.io/google-samples/hello-app:1.0
kubectl get deployment hello-server
kubectl set resources deployment hello-server --requests=cpu=450m
## inspect the container specifics of the hello-server pods
## In the output, find Requests. Note that this pod is currently requesting the 450m CPU you assigned.
kubectl describe pod hello-server | sed -n "/Containers:$/,/Conditions:/p"

## create a manifest for you Vertical Pod Autoscaler
cat << EOF > hello-vpa.yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: hello-server-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind:       Deployment
    name:       hello-server
  updatePolicy:
    updateMode: "Off"
EOF
kubectl apply -f hello-vpa.yaml
## Wait a minute, and then view the VerticalPodAutoscaler
## Locate the "Container Recommendations" at the end of the output
sleep 60
kubectl describe vpa hello-server-vpa

## Update the manifest to set the policy to Auto and apply the configuration
sed -i 's/Off/Auto/g' hello-vpa.yaml
kubectl apply -f hello-vpa.yaml
## Scale hello-server deployment to 2 replicas
kubectl scale deployment hello-server --replicas=2
kubectl get pods -w

## 👉 Check my progress
## Ctrl+C to stop watching the pods.




cat << 'EOF'

========================================================
Task 3. HPA results
========================================================

EOF

## Horizontal Pod Autoscaler
## Look at the Replicas column. You'll see that your php-apache deployment has been scaled down to 1 pod.
kubectl get hpa




cat << 'EOF'

========================================================
Task 4. VPA results
========================================================

EOF

## Now, the VPA should have resized your pods in the hello-server deployment.
## Find the Requests: field.
kubectl describe pod hello-server | sed -n "/Containers:$/,/Conditions:/p"
## If you still see a CPU request of 450m for either of the pods, manually set your CPU resource to the target.
kubectl set resources deployment hello-server --requests=cpu=25m
sleep 10
kubectl describe pod hello-server | sed -n "/Containers:$/,/Conditions:/p"



cat << 'EOF'

========================================================
Task 5. Cluster autoscaler
========================================================

EOF

## enable autoscaling for your cluster
gcloud beta container clusters update scaling-demo --enable-autoscaling --min-nodes 1 --max-nodes 5
## Switch to the optimize-utilization autoscaling profile so that the full effects of scaling can be observed
gcloud beta container clusters update scaling-demo \
  --autoscaling-profile optimize-utilization
## verify that autoscaling is enabled for your cluster
kubectl get deployment -n kube-system

## Create the Pod Disruption Budgets for each of your kube-system pods
kubectl create poddisruptionbudget kube-dns-pdb --namespace=kube-system --selector k8s-app=kube-dns --max-unavailable 1
kubectl create poddisruptionbudget prometheus-pdb --namespace=kube-system --selector k8s-app=prometheus-to-sd --max-unavailable 1
kubectl create poddisruptionbudget kube-proxy-pdb --namespace=kube-system --selector component=kube-proxy --max-unavailable 1
kubectl create poddisruptionbudget metrics-agent-pdb --namespace=kube-system --selector k8s-app=gke-metrics-agent --max-unavailable 1
kubectl create poddisruptionbudget metrics-server-pdb --namespace=kube-system --selector k8s-app=metrics-server --max-unavailable 1
kubectl create poddisruptionbudget fluentd-pdb --namespace=kube-system --selector k8s-app=fluentd-gke --max-unavailable 1
kubectl create poddisruptionbudget backend-pdb --namespace=kube-system --selector k8s-app=glbc --max-unavailable 1
kubectl create poddisruptionbudget kube-dns-autoscaler-pdb --namespace=kube-system --selector k8s-app=kube-dns-autoscaler --max-unavailable 1
kubectl create poddisruptionbudget stackdriver-pdb --namespace=kube-system --selector app=stackdriver-metadata-agent --max-unavailable 1
kubectl create poddisruptionbudget event-pdb --namespace=kube-system --selector k8s-app=event-exporter --max-unavailable 1
sleep 120

## 👉 Check my progress

kubectl get nodes




cat << 'EOF'

========================================================
Task 6. Node Auto Provisioning
========================================================

EOF

## Enable Node Auto Provisioning
gcloud container clusters update scaling-demo \
  --enable-autoprovisioning \
  --min-cpu 1 \
  --min-memory 2 \
  --max-cpu 45 \
  --max-memory 160

## 👉 Check my progress




cat << 'EOF'

========================================================
Task 7. Test with larger demand
========================================================

EOF

## In a new terminal, send an infinite loop of queries to the php-apache service
kubectl run -i \
  --tty load-generator \
  --rm \
  --image=busybox \
  --restart=Never \
  -- /bin/sh \
  -c "while sleep 0.01; do wget -q -O- http://php-apache; done"

## In the original terminal, within a minute or so, you should see the higher CPU load on your HPA
kubectl get hpa
## monitor how your cluster handles the increased load by periodically
kubectl get deployment php-apache




cat << 'EOF'

========================================================
Task 8. Optimize larger loads
========================================================

In order to handle these different latencies for autoscaling, 
you'll probably want to over-provision a little bit so there's 
less pressure on your apps when autoscaling-up. This is really 
important for cost-optimization, because you don't want to pay 
for more resources than you need, but you also don't want your 
apps' performance to suffer.

EOF

## Create a manifest for a pause pod:
cat << EOF > pause-pod.yaml
---
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: overprovisioning
value: -1
globalDefault: false
description: "Priority class used by overprovisioning."
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: overprovisioning
  namespace: kube-system
spec:
  replicas: 1
  selector:
    matchLabels:
      run: overprovisioning
  template:
    metadata:
      labels:
        run: overprovisioning
    spec:
      priorityClassName: overprovisioning
      containers:
      - name: reserve-resources
        image: k8s.gcr.io/pause
        resources:
          requests:
            cpu: 1
            memory: 4Gi
EOF
kubectl apply -f pause-pod.yaml
sleep 60
## wait a minute and then refresh the nodes tab of your scaling-demo cluster.
## Observe how a new node is created, most likely in a new node pool, to fit your newly created pause pod.
echo -e "\n✅  Check the nodes tab of your scaling-demo cluster in the GCP console:"
echo -e "https://console.cloud.google.com/kubernetes/list/overview?project=$PROJECT_ID\n"

## 👉 Check my progress


echo -e "\n✅  All done\n"