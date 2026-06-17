#!/bin/bash
## Created by nov05, 2026-06-16   

export USER_ID=$(gcloud auth list --format="value(account)" --filter="status:ACTIVE")
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID \
  --format='value(projectNumber)')
export REGION=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-region])")
export ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
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
# echo "🔹  Bukect: $BUCKET"
echo
gcloud auth list


cat << 'EOF'

========================================================
Task 1. Set the default region and zone for all resources
========================================================

EOF

# gcloud config set compute/region Region
# gcloud config set compute/zone Zone

cat << 'EOF'

========================================================
Task 2. Create multiple web server instances
========================================================

EOF

gcloud compute instances create www1 \
  --zone=$ZONE \
  --tags=network-lb-tag \
  --machine-type=e2-small \
  --image-family=debian-12 \
  --image-project=debian-cloud \
  --metadata=startup-script='#!/bin/bash
    apt-get update
    apt-get install apache2 -y
    service apache2 restart
    echo "
<h3>Web Server: www1</h3>" | tee /var/www/html/index.html'

gcloud compute instances create www2 \
  --zone=$ZONE \
  --tags=network-lb-tag \
  --machine-type=e2-small \
  --image-family=debian-12 \
  --image-project=debian-cloud \
  --metadata=startup-script='#!/bin/bash
    apt-get update
    apt-get install apache2 -y
    service apache2 restart
    echo "
<h3>Web Server: www2</h3>" | tee /var/www/html/index.html'

gcloud compute instances create www3 \
  --zone=$ZONE  \
  --tags=network-lb-tag \
  --machine-type=e2-small \
  --image-family=debian-12 \
  --image-project=debian-cloud \
  --metadata=startup-script='#!/bin/bash
    apt-get update
    apt-get install apache2 -y
    service apache2 restart
    echo "
<h3>Web Server: www3</h3>" | tee /var/www/html/index.html'

gcloud compute firewall-rules create www-firewall-network-lb \
    --target-tags network-lb-tag --allow tcp:80

gcloud compute instances list

curl http://$(gcloud compute instances describe www1 \
  --zone=$ZONE \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)')


cat << 'EOF'

========================================================
Task 3. Configure the load balancing service
========================================================

EOF

gcloud compute addresses create network-lb-ip-1 \
  --region $REGION

gcloud compute http-health-checks create basic-check


cat << 'EOF'

========================================================
Task 4. Create the target pool and forwarding rule
========================================================

EOF

gcloud compute target-pools create www-pool \
  --region $REGION --http-health-check basic-check

gcloud compute target-pools add-instances www-pool \
    --instances www1,www2,www3

gcloud compute forwarding-rules create www-rule \
    --region  $REGION \
    --ports 80 \
    --address network-lb-ip-1 \
    --target-pool www-pool


cat << 'EOF'

========================================================
Task 5. Send traffic to your instances
========================================================

EOF

gcloud compute forwarding-rules describe www-rule --region $REGION

IPADDRESS=$(gcloud compute forwarding-rules describe www-rule --region $REGION --format="json" | jq -r .IPAddress)
echo $IPADDRESS

while true; do curl -m1 $IPADDRESS; done


echo -e "\n✅  All done\n"