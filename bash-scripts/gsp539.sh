#!/bin/bash
## Created by nov05, 2026-06-18  

: <<'COMMENT'
NLB = Network Load Balancer (L4)
ALB = Application Load Balancer (L7)
MIG = Managed Instance Group
VM = Virtual Machine
/
└── GCP project/
    ├── VPC network: lb-network (lab pre-created)
    │    ├── Subnet: proxy-subnet-internal (Task 1, lab pre-created)
    │    │
    │    ├── Region A/
    │    │   ├── Subnet: lb-backend-subnet-region-a (Task 1, lab pre-created)
    │    │   │
    │    │   └── MIG: mig-alb-api-a (Task 2)
    │    │       ├── Global template: template-alb-api (lab pre-created)
    │    │       |   └── Network tags: allow-ssh, tag-alb-api, http-server
    │    │       ├── VM: nginx-instance-1
    │    │       ├── VM: nginx-instance-2
    │    │       └── Named port: http80:80
    │    │
    │    ├── Region B/
    │    │   ├── Subnet: lb-backend-subnet-region-b (Task 1, lab pre-created)
    │    │   │
    │    │   ├── MIG template: template-proxy-internal (Task 1, lab pre-created) 
    │    │   │
    │    │   ├── MIG: mig-proxy-internal (Task 1, lab pre-defined name)/
    │    │   │   ├── Regional template: template-proxy-internal (lab pre-created)
    │    │   │   │   └── Network tags: allow-ssh, tag-proxy-internal (lab pre-defined)
    │    │   │   ├── VM: tvs-backend-1
    │    │   │   ├── VM: tvs-backend-2
    │    │   │   └── Named port: tcp80:80
    │    │   │
    │    │   ├── VM: vm-client-internal (Task 1, lab pre-defined name)
    │    │   │   └── Network tags: allow-ssh (lab pre-defined)
    │    │   │
    │    │   └── 👉 Load balancer: Regional Internal Proxy NLB (Task 1)
    │    │       └── Backend service: bs-internal-proxy 
    │    │           ├── health check: hc-internal-proxy
    │    │           ├── Internal static IP: ip-internal-proxy
    │    │           └── Internal forwarding rule TCP/110: rule-internal-proxy 
    │    │
    │    └── Firewall rules/
    │        ├── fw-internal-health TCP/80 (Task 1, lab pre-defined name)
    │        │   └── Target tag: tag-proxy-internal
    │        └── fw-internal-proxy TCP/80 (Task 1, lab pre-defined name)
    │            └── Target tag: tag-proxy-internal
    │    
    └── VPC network: default (Task 2, GCP created)
        ├── Global/
        │   ├── MIG template: template-alb-api (Task 2, lab pre-created)
        │   │   └── Network tags: http-server, allow-ssh, tag-alb-api (lab pre-defined)
        │   │
        │   ├── MIG: mig-alb-api-b (Task 2, lab pre-defined name)
        │   │   ├── Global template: template-alb-api (lab pre-created)
        │   │   |   └── Network tags: allow-ssh, tag-alb-api, http-server (lab pre-defined)
        │   │   ├── VM: nginx-instance-1
        │   │   ├── VM: nginx-instance-2
        │   │   └── Named port: http80:80
        │   │
        │   └── 👉 Load balancer: Global External HTTPS ALB (Task 2)
        │       ├── Backend service: service-alb-global (lab pre-defined name)
        │       │   └── Health check: http-check-alb (lab pre-defined name)
        │       └── Frontend service
        │           ├── HTTPS proxy: https-proxy-alb
        │           │   ├── URL map: url-map-alb
        │           │   └── SSL certificates: cert-self-signed (lab pre-defined name)
        │           ├── External static IP: ip-alb-global (lab pre-defined name)
        │           └── External forwarding rule: rule-alb-global
        │
        └── Firewall rules/
            ├── fw-allow-ssh (Task 1 and 2, lab pre-created)
            │   └── Target tag: allow-ssh
            └── fw-allow-health-check-and-proxy (Task 2, lab pre-defined name)
                └── Target tag: tag-alb-api
COMMENT 




set -e

echo
read -p "👉  Enter Region B: " REGION2
export REGION2 
echo

export USER_ID=$(gcloud auth list --format="value(account)" --filter="status:ACTIVE")
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID \
  --format='value(projectNumber)')
export REGION=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-region])")
export ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export ZONE2=$(gcloud compute zones list \
  --filter="region:$REGION2" \
  --format="value(name)" \
  --limit=1)
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
echo "🔹  Region A: $REGION"
echo "🔹  Zone in Region A: $ZONE"
echo "🔹  Region B: $REGION2"
echo "🔹  Zone in Region B: $ZONE2"
# echo "🔹  Bukect: $BUCKET"
echo
gcloud auth list




cat << 'EOF'

========================================================
Task 1. Secure internal transaction processor (regional internal proxy NLB)
========================================================

EOF
## Refer to GSP636 (CLI), GSP658 (REST APIs)  
## https://docs.cloud.google.com/load-balancing/docs/l7-internal/setting-up-l7-internal

## ✅ Lab progress check 1
# Create regional MIG (with lab pre-defined name)
## https://docs.cloud.google.com/sdk/gcloud/reference/compute/instance-groups/managed/create
## There is no --named-ports argument for this command.  
gcloud compute instance-groups managed create mig-proxy-internal \
  --region=$REGION2 \
  --template="https://www.googleapis.com/compute/v1/projects/$PROJECT_ID/regions/$REGION2/instanceTemplates/template-proxy-internal" \
  --size=2 \
  --base-instance-name=mig-proxy-internal
# Set named port required by grader
## https://docs.cloud.google.com/sdk/gcloud/reference/compute/instance-groups/set-named-ports
gcloud compute instance-groups managed set-named-ports mig-proxy-internal \
  --region=$REGION2 \
  --named-ports=tcp80:80
# Create firewall rule for TCP/80 health checks
## The custom VPC network lb-network has been created by the lab.
gcloud compute firewall-rules create fw-internal-health \
  --network=lb-network \
  --target-tags=tag-proxy-internal \
  --source-ranges=130.211.0.0/22,35.191.0.0/16 \
  --allow=tcp:80
# Create firewall rule for proxy-only subnet CIDR 10.129.0.0/23 (TCP 80).
gcloud compute firewall-rules create fw-internal-proxy \
  --network=lb-network \
  --target-tags=tag-proxy-internal \
  --source-ranges=10.129.0.0/23 \
  --allow=tcp:80
## https://docs.cloud.google.com/sdk/gcloud/reference/compute/firewall-rules/create

: << 'COMMNET'
gcloud compute networks subnets describe lb-backend-subnet-region-b \
  --region=$REGION2 \
  --format="get(selfLink)"
## https://www.googleapis.com/compute/v1/projects/$PROJECT_ID/regions/$REGION2/subnetworks/lb-backend-subnet-region-b
gcloud compute networks subnets describe proxy-subnet-internal \
  --region=$REGION2 \
  --format="get(selfLink)"
## https://www.googleapis.com/compute/v1/projects/$PROJECT_ID/regions/$REGION2/subnetworks/proxy-subnet-internal
COMMNET

## ✅ Lab progress check 2
# Reserve internal IP (with lab pre-defined name)
## One of [--network, --subnet] must be supplied:  if --purpose is specified.
gcloud compute addresses create ip-internal-proxy \
  --region=$REGION2 \
  --subnet=lb-backend-subnet-region-b \
  --purpose=SHARED_LOADBALANCER_VIP
# Create regional TCP/80 health check
## https://docs.cloud.google.com/load-balancing/docs/health-checks
gcloud compute health-checks create tcp hc-internal-proxy \
  --region=$REGION2 \
  --port=80

## CAUTION:The following commands work, however the result can't pass Task 1 Check 2. 
##         (Similar to GSP658, Task 2)
# # Create backend service
# gcloud compute backend-services create bs-internal-proxy \
#   --region=$REGION2 \
#   --load-balancing-scheme=INTERNAL_MANAGED \
#   --protocol=TCP \
#   --health-checks=hc-internal-proxy \
#   --health-checks-region=$REGION2 \
#   --timeout=30s
# # Add backend MIG to the backend service
# gcloud compute backend-services add-backend bs-internal-proxy \
#   --region=$REGION2 \
#   --instance-group=mig-proxy-internal \
#   --instance-group-region=$REGION2
# # Create regional target TCP proxy
# gcloud compute target-tcp-proxies create tcp-proxy-internal \
#   --region=$REGION2 \
#   --backend-service=bs-internal-proxy
# # Forwarding rule on TCP/110 (with lab pre-defined name)
# ## Network interface must specify a subnet if the network resource is in custom subnet mode
# gcloud compute forwarding-rules create rule-internal-proxy \
#   --region=$REGION2 \
#   --load-balancing-scheme=INTERNAL_MANAGED \
#   --network=lb-network \
#   --subnet=lb-backend-subnet-region-b \
#   --address=ip-internal-proxy \
#   --ports=110 \
#   --target-tcp-proxy=tcp-proxy-internal \
#   --target-tcp-proxy-region=$REGION2

: << 'COMMENT'
gcloud compute forwarding-rules delete rule-internal-proxy --region=$REGION2 --quiet
gcloud compute target-tcp-proxies delete tcp-proxy-internal --region=$REGION2 --quiet
gcloud compute backend-services delete bs-internal-proxy --region=$REGION2 --quiet
COMMENT

## Create backend service "bs-internal-proxy" with REST API 
curl -X POST \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  "https://compute.googleapis.com/compute/beta/projects/$PROJECT_ID/regions/$REGION2/backendServices" \
  -d '{
    "backends": [
      {
        "balancingMode": "UTILIZATION",
        "capacityScaler": 1,
        "group": "projects/'"$PROJECT_ID"'/regions/'"$REGION2"'/instanceGroups/mig-proxy-internal",
        "maxUtilization": 0.8
      }
    ],
    "connectionDraining": {
      "drainingTimeoutSec": 300
    },
    "description": "",
    "healthChecks": [
      "projects/'"$PROJECT_ID"'/regions/'"$REGION2"'/healthChecks/hc-internal-proxy"
    ],
    "ipAddressSelectionPolicy": "IPV4_ONLY",
    "loadBalancingScheme": "INTERNAL_MANAGED",
    "localityLbPolicy": "ROUND_ROBIN",
    "logConfig": {
      "enable": false
    },
    "name": "bs-internal-proxy",
    "portName": "tcp80",
    "protocol": "TCP",
    "region": "projects/'"$PROJECT_ID"'/regions/'"$REGION2"'",
    "sessionAffinity": "NONE",
    "timeoutSec": 30
  }'

## Create target TCP proxy "tcp-proxy-internal" with REST API
## Keep trying until Google says the resource already exists (409), then stop
until curl -X POST \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  "https://compute.googleapis.com/compute/v1/projects/$PROJECT_ID/regions/$REGION2/targetTcpProxies" \
  -d '{
    "name": "tcp-proxy-internal",
    "proxyHeader": "NONE",
    "region": "projects/'"$PROJECT_ID"'/regions/'"$REGION2"'",
    "service": "projects/'"$PROJECT_ID"'/regions/'"$REGION2"'/backendServices/bs-internal-proxy"
  }' | grep -q '"code": 409' && break
do
  echo "Wait 10 seconds for backend service to become attachable..."
  sleep 10
done

## Create forwarding rule "rule-internal-proxy" (lab pre-defined name) with REST API 
until curl -X POST \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  "https://compute.googleapis.com/compute/beta/projects/$PROJECT_ID/regions/$REGION2/forwardingRules" \
  -d '{
    "IPAddress": "10.20.0.4",
    "IPProtocol": "TCP",
    "allowGlobalAccess": false,
    "loadBalancingScheme": "INTERNAL_MANAGED",
    "name": "rule-internal-proxy",
    "network": "projects/'"$PROJECT_ID"'/global/networks/lb-network",
    "networkTier": "PREMIUM",
    "portRange": "110",
    "region": "projects/'"$PROJECT_ID"'/regions/'"$REGION2"'",
    "subnetwork": "projects/'"$PROJECT_ID"'/regions/'"$REGION2"'/subnetworks/lb-backend-subnet-region-b",
    "target": "projects/'"$PROJECT_ID"'/regions/'"$REGION2"'/targetTcpProxies/tcp-proxy-internal"
  }' | grep -q '"code": 409' && break
do
  echo "Wait 10 seconds for backend service to become attachable..."
  sleep 10
done

echo -e "\n👉  Check the load balancer at"  
echo -e "https://console.cloud.google.com/net-services/loadbalancing/list/loadBalancers?project=$PROJECT_ID\n"

## ✅ Lab progress check 3
# Create client VM for testing (with lab pre-defined name)
## VM instances have to be zonal and within the backend subnet.
gcloud compute instances create vm-client-internal \
  --zone=$ZONE2 \
  --machine-type=e2-medium \
  --network-interface=subnet=lb-backend-subnet-region-b \
  --tags=allow-ssh
until gcloud compute ssh vm-client-internal \
    --zone=$ZONE2 \
    --command="echo Ready" \
    --quiet 2>/dev/null
do sleep 5; done
# Get load balancer IP
IP_ADDRESS=$(gcloud compute addresses describe ip-internal-proxy \
  --region=$REGION2 \
  --format='value(address)')
echo -e "\n👉  Task 1 load balancer IP: $IP_ADDRESS\n"
# Validate from client VM
gcloud compute ssh vm-client-internal --zone=$ZONE2 --quiet \
  --command="for i in {1..10}; do curl -s ${IP_ADDRESS}:110; echo; done"

: << 'COMMENT'
## Make sure both return the same IP address
gcloud compute forwarding-rules describe rule-internal-proxy \
  --region=$REGION2 \
  --format="get(IPAddress)"
gcloud compute instances delete vm-client-internal --zone=$ZONE2 --quiet
COMMENT


cat << 'EOF'

========================================================
Task 2. Global external market data feed (global external application Load Balancer)
========================================================

EOF
## Refer to GSP652
## https://docs.cloud.google.com/load-balancing/docs/https/setup-global-ext-https-compute

# Create Regional MIG in Region A (with lab pre-defined name)
gcloud compute instance-groups managed create mig-alb-api-a \
  --region=$REGION \
  --template=template-alb-api \
  --size=2 \
  --base-instance-name=mig-alb-api-a
## https://docs.cloud.google.com/load-balancing/docs/backend-service#named_ports
gcloud compute instance-groups managed set-named-ports mig-alb-api-a \
  --region=$REGION \
  --named-ports=http80:80
# Create Regional MIG in Region B (with lab pre-defined name)
gcloud compute instance-groups managed create mig-alb-api-b \
  --region=$REGION2 \
  --template=template-alb-api \
  --size=2 \
  --base-instance-name=mig-alb-api-b
gcloud compute instance-groups managed set-named-ports mig-alb-api-b \
  --region=$REGION2 \
  --named-ports=http80:80

# Create firewall rule for health checks and proxy access to backend VMs (lab pre-defined name)
##  --network=lb-network is for Task 1 only. Task 2 uses default network, 
##  which allows all traffic within the same network by default.
gcloud compute firewall-rules create fw-allow-health-check-and-proxy \
  --network=default \
  --allow=tcp:80 \
  --source-ranges=130.211.0.0/22,35.191.0.0/16 \
  --target-tags=tag-alb-api
## gcloud compute firewall-rules delete fw-allow-health-check-and-proxy --quiet
## gcloud compute backend-services get-health service-alb-global --global
# Create global HTTP 80 health check (with lab pre-defined name)
gcloud compute health-checks create http http-check-alb \
  --global \
  --port=80
## gcloud compute health-checks delete http-check-alb --global --quiet
# Reserve global static IP (with lab pre-defined name)
## https://docs.cloud.google.com/sdk/gcloud/reference/compute/addresses/create
gcloud compute addresses create ip-alb-global \
  --global
## https://docs.cloud.google.com/load-balancing/docs/ssl-certificates/self-managed-certs
# Create private key
openssl genrsa -out key.pem 2048
# Create self-signed certificate
openssl req -new -x509 -key key.pem -out cert.pem -days 1 -subj "/CN=example.com"
# Upload certificate to GCP (with lab pre-defined name)
## https://docs.cloud.google.com/sdk/gcloud/reference/compute/ssl-certificates/create
gcloud compute ssl-certificates create cert-self-signed \
  --global \
  --certificate=cert.pem \
  --private-key=key.pem 

# Create global backend service (with lab pre-defined name)
## Argument --port-name=http80 is necessary. 
gcloud compute backend-services create service-alb-global \
  --global \
  --load-balancing-scheme=EXTERNAL_MANAGED \
  --protocol=HTTP \
  --port-name=http80 \
  --health-checks=http-check-alb
## https://docs.cloud.google.com/sdk/gcloud/reference/compute/backend-services/add-backend
# Add backend MIG in Region A
gcloud compute backend-services add-backend service-alb-global \
  --global \
  --instance-group=mig-alb-api-a \
  --instance-group-region=$REGION \
  --balancing-mode=RATE \
  --max-rate-per-instance=1
# Add backend MIG in Region B
gcloud compute backend-services add-backend service-alb-global \
  --global \
  --instance-group=mig-alb-api-b \
  --instance-group-region=$REGION2 \
  --balancing-mode=RATE \
  --max-rate-per-instance=1
# Create URL map, HTTP to HTTPS redirect (CLI equivalent), load balancer 
## https://docs.cloud.google.com/sdk/gcloud/reference/compute/url-maps/create
gcloud compute url-maps create url-map-alb \
  --global \
  --default-service service-alb-global
# Create target HTTPS proxy (frontend entry point)
## https://docs.cloud.google.com/sdk/gcloud/reference/compute/target-https-proxies/create
gcloud compute target-https-proxies create https-proxy-alb \
  --global \
  --url-map=url-map-alb \
  --ssl-certificates=cert-self-signed
# Create global forwarding rule on HTTPS/443
gcloud compute forwarding-rules create rule-alb-global \
  --global \
  --target-https-proxy=https-proxy-alb \
  --ports=443 \
  --address=ip-alb-global

  : << 'COMMENT'
gcloud compute forwarding-rules delete rule-alb-global --global --quiet
gcloud compute target-https-proxies delete https-proxy-alb --global --quiet
gcloud compute url-maps delete url-map-alb --global --quiet
gcloud compute backend-services delete service-alb-global --global --quiet
COMMENT

cat << 'EOF'

========================================================
Task 3. Test failover and global distribution
========================================================

Test 1: observe global distribution
while true; do curl -k -s https://[YOUR_LOAD_BALANCER_IP_ADDRESS] | grep "Hello from"; sleep 0.5; done

Test 2: simulate a backend failure
sudo systemctl stop nginx
sudo systemctl start nginx

Tip: You can SSH into a VM and curl localhost:80 to confirm the Nginx service is running normally. 
student-04-5fc135e005c8@mig-alb-api-b-p99x:~$ curl localhost:80
<h1>Hello from: mig-alb-api-b-p99x!</h1>
<p>Served by a Global ALB.</p>

Tip: In curl, -i means include HTTP response headers in the output. 
The following commands should return the same result.  
curl -i http://localhost/ 
curl -i http://localhost/index.html

EOF
## Refer to GSP652, Task 5

## Test 1: observe global distribution
export IP_ADDRESS2=$(gcloud compute addresses describe ip-alb-global \
  --global \
  --format="get(address)")
echo -e "\n👉  Task 2 load balancer IP: $IP_ADDRESS2\n"
# for i in {1..10}; do curl -k -s https://$IP_ADDRESS2 | grep "Hello from"; sleep 0.5; done
# while true; do curl -k -s https://$IP_ADDRESS2 | grep "Hello from"; sleep 0.5; done
while true; do
  curl -k -s https://$IP_ADDRESS2 | grep "Hello from"
  sleep 0.5
done &
PID=$!
echo "👉  Started background job PID=$PID"

: << 'COMMENT'
<h1>Hello from: mig-alb-api-a-ts0w!</h1>
<h1>Hello from: mig-alb-api-a-4djz!</h1>
<h1>Hello from: mig-alb-api-a-ts0w!</h1>
<h1>Hello from: mig-alb-api-a-ts0w!</h1>
<h1>Hello from: mig-alb-api-a-4djz!</h1>
<h1>Hello from: mig-alb-api-a-ts0w!</h1>
<h1>Hello from: mig-alb-api-a-4djz!</h1>
<h1>Hello from: mig-alb-api-a-4djz!</h1>
<h1>Hello from: mig-alb-api-a-ts0w!</h1>
<h1>Hello from: mig-alb-api-a-ts0w!</h1>
...
COMMENT

## Test 2: simulate a backend failure. 
## SSH into a VM in mig-alb-api-a and stop the Nginx service to simulate a failure.
# read VM_NAME VM_ZONE < <(
# gcloud compute instances list \
#   --filter="name~mig-alb-api-a" \
#   --format="value(name,zone)" | head -n 1)
# echo -e "\n👉  Using Task 2 backend VM '$VM_NAME' in zone: '$VM_ZONE'...\n"
## Stop all the Nginx services in the mig-alb-api-a VMs to trigger failover to pass the lab check.
gcloud compute instances list \
  --filter="name~mig-alb-api-a" \
  --format="value(name,zone)" | while read VM_NAME VM_ZONE
do
  echo "👉  Stopping nginx on $VM_NAME ($VM_ZONE)..."
  gcloud compute ssh "$VM_NAME" \
    --zone="$VM_ZONE" \
    --quiet \
    --command="sudo systemctl stop nginx"
done
sleep 10

echo -e "\n👉  Check backend health:\n"
while true; do
  gcloud compute backend-services get-health service-alb-global \
    --global \
    --format="table(status,instance)"
  echo 
  read -rp "Ready to proceed? (y): " answer
  [[ "$answer" =~ ^[Yy]$ ]] && break
done



echo -e "\n✅  All done\n"