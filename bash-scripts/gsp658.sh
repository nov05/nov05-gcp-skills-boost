#!/bin/bash
## Created by nov05, 2026-06-18  
## Refer to GSP652

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

cat << 'EOF'

========================================================
Task 1. Create Instance Groups
========================================================

EOF

# Create first unmanaged instance group
gcloud compute instance-groups unmanaged create web-server-1 \
  --zone=$ZONE

# Add backend VM to the group
gcloud compute instance-groups unmanaged add-instances web-server-1 \
  --instances=backend-vm-$REGION \
  --zone=$ZONE

# Create second unmanaged instance group
gcloud compute instance-groups unmanaged create web-server-2 \
  --zone=$ZONE

# Add backend VM to the group
gcloud compute instance-groups unmanaged add-instances web-server-2 \
  --instances=backend-vm1-$REGION \
  --zone=$ZONE

echo -e "\n👉  Check the instance groups at"  
echo -e "https://console.cloud.google.com/compute/instanceGroups/list?project=$PROJECT_ID\n"


cat << 'EOF'

========================================================
Task 2. Configure the load balancing components
========================================================

EOF

# Create a regional TCP health check
gcloud compute health-checks create tcp basic-http-check \
  --region=$REGION \
  --port=80
# Reserve an external IP address
gcloud compute addresses create network-lb-ip \
  --region=$REGION 

## CAUSION: The following commands work, however the result can't pass Task 2 check.
# # Create a regional backend service
# gcloud compute backend-services create network-lb-backend-service \
#   --region=$REGION \
#   --load-balancing-scheme=EXTERNAL \
#   --protocol=TCP \
#   --health-checks=basic-http-check \
#   --health-checks-region=$REGION
# # Add the backend instance groups
# gcloud compute backend-services add-backend network-lb-backend-service \
#   --region=$REGION \
#   --instance-group=web-server-1 \
#   --instance-group-zone=$ZONE
# gcloud compute backend-services add-backend network-lb-backend-service \
#   --region=$REGION \
#   --instance-group=web-server-2 \
#   --instance-group-zone=$ZONE \

# ## Task 2, frontend configuration
# # Create the forwarding rule
# ## https://docs.cloud.google.com/sdk/gcloud/reference/compute/forwarding-rules/create#--load-balancing-scheme
# gcloud compute forwarding-rules create network-lb-backend-service-forwarding-rule \
#   --region=$REGION \
#   --load-balancing-scheme=EXTERNAL \
#   --ip-protocol=TCP \
#   --ports=80 \
#   --address=network-lb-ip \
#   --backend-service=network-lb-backend-service

: <<'COMMENT'
gcloud compute forwarding-rules delete network-lb-forwarding-rule --region=$REGION --quiet
gcloud compute addresses delete network-lb-ip --region=$REGION --quiet
gcloud compute backend-services delete network-lb-backend-service --region=$REGION --quiet
COMMENT

## Using REST API can pass the check.
curl -X POST \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  "https://compute.googleapis.com/compute/beta/projects/$PROJECT_ID/regions/$REGION/backendServices" \
  -d '{
  "backends": [
    {
      "balancingMode": "CONNECTION",
      "failover": false,
      "group": "projects/'"$PROJECT_ID"'/zones/'"$ZONE"'/instanceGroups/web-server-1"
    },
    {
      "balancingMode": "CONNECTION",
      "failover": false,
      "group": "projects/'"$PROJECT_ID"'/zones/'"$ZONE"'/instanceGroups/web-server-2"
    }
  ],
  "connectionDraining": {
    "drainingTimeoutSec": 300
  },
  "description": "",
  "failoverPolicy": {},
  "healthChecks": [
    "projects/'"$PROJECT_ID"'/regions/'"$REGION"'/healthChecks/basic-http-check"
  ],
  "loadBalancingScheme": "EXTERNAL",
  "localityLbPolicy": "MAGLEV",
  "logConfig": {
    "enable": false
  },
  "name": "network-lb-backend-service",
  "protocol": "TCP",
  "region": "projects/'"$PROJECT_ID"'/regions/'"$REGION"'/",
  "sessionAffinity": "NONE"
}'

## CAUTION: The backend service has to be ready for the forwarding rule creation.
##          The "describe" or "get-health" check isn't sufficient. 
# until gcloud compute backend-services describe network-lb-backend-service --region=$REGION >/dev/null 2>&1
# until gcloud compute backend-services get-health network-lb-backend-service \
#   --region=$REGION 2>/dev/null | grep -q "backend:"
# do sleep 5; done

until curl -X POST \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  "https://compute.googleapis.com/compute/beta/projects/$PROJECT_ID/regions/$REGION/forwardingRules" \
  -d '{
  "IPAddress": "projects/'"$PROJECT_ID"'/regions/'"$REGION"'/addresses/network-lb-ip",
  "IPProtocol": "TCP",
  "backendService": "projects/'"$PROJECT_ID"'/regions/'"$REGION"'/backendServices/network-lb-backend-service",
  "description": "",
  "ipVersion": "IPV4",
  "loadBalancingScheme": "EXTERNAL",
  "name": "network-lb-backend-service-forwarding-rule",
  "networkTier": "PREMIUM",
  "ports": [
    "80"
  ],
  "region": "projects/'"$PROJECT_ID"'/regions/'"$REGION"'/"
}' | grep -q '"code": 409' && break
do
  echo "Wait 10 seconds for backend service to become attachable..."
  sleep 10
done

echo -e "\n👉  Check the load balancer at"  
echo -e "https://console.cloud.google.com/net-services/loadbalancing/list/loadBalancers?project=$PROJECT_ID\n"


cat << 'EOF'

========================================================
Task 3. Test the load balancer
========================================================

EOF

# Get the load balancer IP address
export IP_ADDRESS=$(gcloud compute forwarding-rules describe network-lb-backend-service-forwarding-rule \
  --region=$REGION \
  --format="value(IPAddress)")
echo -e "\n👉  Load Balancer IP: $IP_ADDRESS\n"

# Send requests to verify traffic distribution
for i in {1..10}; do
  curl -s http://$IP_ADDRESS
  echo
done


echo -e "\n✅  All done\n"