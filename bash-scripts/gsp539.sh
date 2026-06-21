#!/bin/bash
## Created by nov05, 2026-06-18

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
 
gcloud compute instance-groups managed create mig-proxy-internal \
  --region=$REGION2 \
  --template="https://www.googleapis.com/compute/v1/projects/$PROJECT_ID/regions/$REGION2/instanceTemplates/template-proxy-internal" \
  --size=2 \
  --base-instance-name=mig-proxy-internal
gcloud compute instance-groups managed set-named-ports mig-proxy-internal \
  --region=$REGION2 \
  --named-ports=tcp80:80
gcloud compute firewall-rules create fw-internal-health \
  --network=lb-network \
  --target-tags=tag-proxy-internal \
  --source-ranges=130.211.0.0/22,35.191.0.0/16 \
  --allow=tcp:80
gcloud compute firewall-rules create fw-internal-proxy \
  --network=lb-network \
  --target-tags=tag-proxy-internal \
  --source-ranges=10.129.0.0/23 \
  --allow=tcp:80

gcloud compute addresses create ip-internal-proxy \
  --region=$REGION2 \
  --subnet=lb-backend-subnet-region-b \
  --purpose=SHARED_LOADBALANCER_VIP
gcloud compute health-checks create tcp hc-internal-proxy \
  --region=$REGION2 \
  --port=80

echo -e "\n👉  Creating backend service 'bs-internal-proxy' with REST API...\n"
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
echo -e "\n👉  Creating target TCP proxy 'tcp-proxy-internal' with REST API...\n"
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
echo -e "\n👉  Creating forwarding rule 'rule-internal-proxy' with REST API...\n"
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
IP_ADDRESS=$(gcloud compute addresses describe ip-internal-proxy \
  --region=$REGION2 \
  --format='value(address)')
echo -e "\n👉  Task 1 load balancer IP: $IP_ADDRESS\n"
gcloud compute ssh vm-client-internal --zone=$ZONE2 --quiet \
  --command="for i in {1..10}; do curl -s ${IP_ADDRESS}:110; echo; done"

cat << 'EOF'

========================================================
Task 2. Global external market data feed (global external application Load Balancer)
========================================================

EOF

gcloud compute instance-groups managed create mig-alb-api-a \
  --region=$REGION \
  --template=template-alb-api \
  --size=1 \
  --base-instance-name=mig-alb-api-a
gcloud compute instance-groups managed set-named-ports mig-alb-api-a \
  --region=$REGION \
  --named-ports=http80:80
gcloud compute instance-groups managed create mig-alb-api-b \
  --region=$REGION2 \
  --template=template-alb-api \
  --size=1 \
  --base-instance-name=mig-alb-api-b
gcloud compute instance-groups managed set-named-ports mig-alb-api-b \
  --region=$REGION2 \
  --named-ports=http80:80

gcloud compute firewall-rules create fw-allow-health-check-and-proxy \
  --network=default \
  --allow=tcp:80 \
  --source-ranges=130.211.0.0/22,35.191.0.0/16 \
  --target-tags=tag-alb-api
gcloud compute health-checks create http http-check-alb \
  --global \
  --port=80
gcloud compute addresses create ip-alb-global \
  --global
openssl genrsa -out key.pem 2048
openssl req -new -x509 -key key.pem -out cert.pem -days 1 -subj "/CN=example.com"
gcloud compute ssl-certificates create cert-self-signed \
  --global \
  --certificate=cert.pem \
  --private-key=key.pem 

gcloud compute backend-services create service-alb-global \
  --global \
  --load-balancing-scheme=EXTERNAL_MANAGED \
  --protocol=HTTP \
  --port-name=http80 \
  --health-checks=http-check-alb
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
gcloud compute url-maps create url-map-alb \
  --global \
  --default-service service-alb-global
gcloud compute target-https-proxies create https-proxy-alb \
  --global \
  --url-map=url-map-alb \
  --ssl-certificates=cert-self-signed
gcloud compute forwarding-rules create rule-alb-global \
  --global \
  --target-https-proxy=https-proxy-alb \
  --ports=443 \
  --address=ip-alb-global

cat << 'EOF'

========================================================
Task 3. Test failover and global distribution
========================================================

EOF

echo -e "\n👉  Sleep 180 seconds...\n"
sleep 180

export IP_ADDRESS2=$(gcloud compute addresses describe ip-alb-global \
  --global \
  --format="get(address)")
echo -e "\n👉  Task 2 load balancer IP: $IP_ADDRESS2"
echo -e "    Observe the global distribution.\n"
for i in {1..30}; do curl -k -s --http1.0 https://$IP_ADDRESS2 | grep "Hello from"; sleep 0.5; done

read VM_NAME VM_ZONE < <(
gcloud compute instances list \
  --filter="name~mig-alb-api-a" \
  --format="value(name,zone)" | head -n 1)
echo -e "\n👉  Using Task 2 backend VM '$VM_NAME' in zone: '$VM_ZONE'...\n"

echo -e "\n👉  Stopping nginx on backend VM...\n"
gcloud compute ssh "$VM_NAME" \
  --zone "$VM_ZONE" \
  --quiet \
  --command "sudo systemctl stop nginx"

echo -e "\n👉  Check backend health (Press 'enter' if 'mig-alb-api-a' is still healthy):\n"
while true; do
  sleep 5
  gcloud compute backend-services get-health service-alb-global \
    --global \
    --format="table(status,instance)"
  echo 
  read -rp "Ready to proceed? (y): " answer
  [[ "$answer" =~ ^[Yy]$ ]] && break
done

for i in {1..100}; do curl -k -s https://$IP_ADDRESS2 | grep "Hello from"; sleep 0.5; done

echo -e "\n👉  Starting nginx on backend VM...\n"
gcloud compute ssh "$VM_NAME" \
  --zone "$VM_ZONE" \
  --quiet \
  --command "sudo systemctl start nginx"

echo -e "\n👉  Check backend health (Press 'enter' if 'mig-alb-api-a' is still unhealthy):\n"
while true; do
  sleep 5
  gcloud compute backend-services get-health service-alb-global \
    --global \
    --format="table(status,instance)"
  echo 
  read -rp "Ready to proceed? (y): " answer
  [[ "$answer" =~ ^[Yy]$ ]] && break
done

echo -e "\n✅  All done\n"