#!/bin/bash
## Created by nov05, 2026-06-18  

echo
read -p "👉  Enter zone 2 (Task 1): " ZONE2
echo
export ZONE2 
export REGION2=$(gcloud compute zones describe $ZONE2 \
  --format="value(region.basename())")

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

# Create an instance group 
gcloud compute instance-groups unmanaged create ${REGION}-instance-group \
  --zone=$ZONE
gcloud compute instance-groups unmanaged add-instances ${REGION}-instance-group \
  --zone=$ZONE \
  --instances=backend-vm-$REGION

# Create another instance group
gcloud compute instance-groups unmanaged create ${REGION2}-instance-group \
  --zone=$ZONE2
gcloud compute instance-groups unmanaged add-instances ${REGION2}-instance-group \
  --zone=$ZONE2 \
  --instances=backend-vm-$REGION2


cat << 'EOF'

========================================================
Task 2. Create a health check
========================================================

EOF

gcloud compute health-checks create http http-health-check \
  --port=80 \
  --request-path="/" \
  --check-interval=5s \
  --timeout=5s \
  --unhealthy-threshold=2 \
  --healthy-threshold=2


cat << 'EOF'

========================================================
Task 3. Create a backend service
========================================================

EOF

## Configure frontend with HTTPS
gcloud compute addresses create global-lb-ip \
  --ip-version=IPV4 \
  --global

gcloud compute backend-services create global-backend-service \
  --protocol=HTTP \
  --port-name=http \
  --health-checks=http-health-check \
  --global
# Add REGION backend instance group
gcloud compute backend-services add-backend global-backend-service \
  --instance-group=${REGION}-instance-group \
  --instance-group-zone=$ZONE \
  --global
# Add REGION2 backend instance group
gcloud compute backend-services add-backend global-backend-service \
  --global \
  --instance-group=${REGION2}-instance-group \
  --instance-group-zone=$ZONE2

## Create a Certificate
openssl genrsa -out key.pem 2048
cat key.pem
openssl req -new -x509 -key key.pem -out cert.pem -days 365 \
  -subj "/C=US/ST=CA/L=Mountain View/O=Lab/OU=Training/CN=example.com"
cat cert.pem
gcloud compute ssl-certificates create self-signed-lb-cert \
  --certificate=cert.pem \
  --private-key=key.pem \
  --global
## HTTP to HTTPS redirect (CLI equivalent)
gcloud compute url-maps create global-url-map \
  --default-service=global-backend-service 
## Create the HTTPS proxy (frontend entry point)
gcloud compute target-https-proxies create https-frontend \
  --url-map=global-url-map \
  --ssl-certificates=self-signed-lb-cert
## $ gcloud compute target-https-proxies delete https-frontend --quiet
## $ gcloud compute url-maps delete global-url-map --quiet
## Create HTTPS forwarding rule (port 443)
gcloud compute forwarding-rules create https-frontend-rule \
  --global \
  --target-https-proxy=https-frontend \
  --ports=443 \
  --address=global-lb-ip



cat << 'EOF'

========================================================
Task 4. Test and verify Load Balancing
========================================================

EOF

export IP_ADDRESS=$(gcloud compute addresses describe global-lb-ip \
  --global \
  --format="get(address)")
echo -e "\n👉  Open https://${IP_ADDRESS} in the browser.\n"
echo 'Refresh the page multiple times. You should observe the content changing \
between '\''Hello from backend-vm-${REGION}!'\'' and '\''Hello from backend-vm-${REGION2}!'\'''
echo
for i in {1..20}; do
  curl -k -s -H "Connection: close" https://${IP_ADDRESS}
  echo
done

cat << 'EOF'

========================================================
Task 5. Understand health checks
========================================================

sudo systemctl stop nginx
sudo systemctl start nginx

EOF

gcloud compute ssh backend-vm-$REGION \
  --zone=$ZONE \
  --quiet \
  --command="sudo systemctl stop nginx"
while true; do
  gcloud compute backend-services get-health global-backend-service \
    --global \
    --format="table(status,instance)"
  read -rp "Ready to proceed? (y): " answer
  [[ "$answer" =~ ^[Yy]$ ]] && break
done

gcloud compute ssh backend-vm-$REGION \
  --zone=$ZONE \
  --quiet \
  --command="sudo systemctl start nginx"
while true; do
  gcloud compute backend-services get-health global-backend-service \
    --global \
    --format="table(status,instance)"
  read -rp "Ready to proceed? (y): " answer
  [[ "$answer" =~ ^[Yy]$ ]] && break
done


cat << 'EOF'

========================================================
Task 6. Clean up
========================================================

EOF

# Delete Load Balancer (frontend components)
gcloud compute forwarding-rules delete https-frontend-rule \
  --global \
  --quiet
gcloud compute target-https-proxies delete https-frontend \
  --quiet
gcloud compute url-maps delete global-url-map \
  --quiet
gcloud compute ssl-certificates delete self-signed-lb-cert \
  --global \
  --quiet

# Delete backend service
gcloud compute backend-services delete global-backend-service \
  --global \
  --quiet

# Delete health check
gcloud compute health-checks delete http-health-check \
  --quiet

# Delete instance groups
gcloud compute instance-groups unmanaged delete ${REGION}-instance-group \
  --zone=$ZONE \
  --quiet
gcloud compute instance-groups unmanaged delete ${REGION2}-instance-group \
  --zone=$ZONE2 \
  --quiet

# Delete VM instances
gcloud compute instances delete backend-vm-$REGION \
  --zone=$ZONE \
  --quiet
gcloud compute instances delete backend-vm-$REGION2 \
  --zone=$ZONE2 \
  --quiet

echo -e "\n✅  All done\n"