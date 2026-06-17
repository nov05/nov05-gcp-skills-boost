#!/bin/bash
## Created by nov05, 2026-06-17   

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
  --image-family=debian-11 \
  --image-project=debian-cloud \
  --metadata=startup-script='#!/bin/bash
    apt-get update
    apt-get install apache2 -y
    service apache2 restart
    echo "
<h3>Web Server: www1</h3>" | tee /var/www/html/index.html'
until gcloud compute ssh www1 \
    --zone=$ZONE \
    --command="echo ready" \
    --quiet 2>/dev/null
do sleep 5; done

gcloud compute instances create www2 \
  --zone=$ZONE \
  --tags=network-lb-tag \
  --machine-type=e2-small \
  --image-family=debian-11 \
  --image-project=debian-cloud \
  --metadata=startup-script='#!/bin/bash
    apt-get update
    apt-get install apache2 -y
    service apache2 restart
    echo "
<h3>Web Server: www2</h3>" | tee /var/www/html/index.html'
until gcloud compute ssh www2 \
    --zone=$ZONE \
    --command="echo ready" \
    --quiet 2>/dev/null
do sleep 5; done

gcloud compute instances create www3 \
  --zone=$ZONE  \
  --tags=network-lb-tag \
  --machine-type=e2-small \
  --image-family=debian-11 \
  --image-project=debian-cloud \
  --metadata=startup-script='#!/bin/bash
    apt-get update
    apt-get install apache2 -y
    service apache2 restart
    echo "
<h3>Web Server: www3</h3>" | tee /var/www/html/index.html'
until gcloud compute ssh www3 \
    --zone=$ZONE \
    --command="echo ready" \
    --quiet 2>/dev/null
do sleep 5; done

gcloud compute firewall-rules create www-firewall-network-lb \
    --target-tags network-lb-tag --allow tcp:80

gcloud compute instances list

IP_ADDRESS=$(gcloud compute instances describe www1 \
  --format="get(networkInterfaces[0].accessConfigs[0].natIP)")
curl http://$IP_ADDRESS


cat << 'EOF'

========================================================
Task 3. Create an Application Load Balancer
========================================================

EOF

gcloud compute instance-templates create lb-backend-template \
   --region=$REGION \
   --network=default \
   --subnet=default \
   --tags=allow-health-check \
   --machine-type=e2-medium \
   --image-family=debian-11 \
   --image-project=debian-cloud \
   --metadata=startup-script='#!/bin/bash
     apt-get update
     apt-get install apache2 -y
     a2ensite default-ssl
     a2enmod ssl
     vm_hostname="$(curl -H "Metadata-Flavor:Google" \
     http://169.254.169.254/computeMetadata/v1/instance/name)"
     echo "Page served from: $vm_hostname" | \
     tee /var/www/html/index.html
     systemctl restart apache2'

gcloud compute instance-groups managed create lb-backend-group \
   --template=lb-backend-template --size=2 --zone=$ZONE

gcloud compute firewall-rules create fw-allow-health-check \
  --network=default \
  --action=allow \
  --direction=ingress \
  --source-ranges=130.211.0.0/22,35.191.0.0/16 \
  --target-tags=allow-health-check \
  --rules=tcp:80

## Set up a global static external IP address that your customers use to reach the load balancer.
gcloud compute addresses create lb-ipv4-1 \
  --ip-version=IPV4 \
  --global

gcloud compute addresses describe lb-ipv4-1 \
  --format="get(address)" \
  --global

gcloud compute health-checks create http http-basic-check \
  --port 80

gcloud compute backend-services create web-backend-service \
  --protocol=HTTP \
  --port-name=http \
  --health-checks=http-basic-check \
  --global

gcloud compute backend-services add-backend web-backend-service \
  --instance-group=lb-backend-group \
  --instance-group-zone=$ZONE \
  --global

gcloud compute url-maps create web-map-http \
    --default-service web-backend-service

gcloud compute target-http-proxies create http-lb-proxy \
    --url-map web-map-http

gcloud compute forwarding-rules create http-content-rule \
   --address=lb-ipv4-1\
   --global \
   --target-http-proxy=http-lb-proxy \
   --ports=80


cat << 'EOF'

========================================================
Task 4. Test traffic sent to your instances
========================================================

(No Bash code from the lab.)

EOF

IP_ADDRESS=$(gcloud compute addresses describe lb-ipv4-1 \
  --global \
  --format="get(address)")

echo -e "\n👉  Open http://$IP_ADDRESS in the browser. \n"
echo "Your browser should render a page with content showing the name of the instance that served the page, \
along with its zone (for example, Page served from: lb-backend-group-xxxx."


echo -e "\n✅  All done\n"