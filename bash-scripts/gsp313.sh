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
Task 1. Create multiple web server instances
========================================================

Bash code:
  #!/bin/bash
  apt-get update
  apt-get install apache2 -y
  service apache2 restart
  echo "<h3>Web Server: web-number</h3>" | tee /var/www/html/index.html

Test command:
  curl http://[IP_ADDRESS]

EOF
## Refer to GSP155 Task 1

for i in 1 2 3
do
  gcloud compute instances create web$i \
    --zone=$ZONE \
    --tags=network-lb-tag \
    --machine-type=e2-small \
    --image-family=debian-12 \
    --image-project=debian-cloud \
    --metadata=startup-script='#!/bin/bash
      apt-get update
      apt-get install apache2 -y
      service apache2 restart
      echo "<h3>Web Server: web'"$i"'</h3>" | tee /var/www/html/index.html'
  until gcloud compute ssh web$i \
      --zone=$ZONE \
      --command="echo ready" \
      --quiet 2>/dev/null
  do sleep 5; done
done

gcloud compute firewall-rules create www-firewall-network-lb \
    --target-tags network-lb-tag --allow tcp:80
sleep 30

IP_ADDRESS=$(gcloud compute instances describe web1 \
  --format="get(networkInterfaces[0].accessConfigs[0].natIP)")
echo -e "\n👉  curl http://${IP_ADDRESS} \n"
curl http://$IP_ADDRESS
echo

cat << 'EOF'

========================================================
Task 2. Configure the load balancing service
========================================================

EOF
## Refer to GSP007 Task 3 and 4

gcloud compute addresses create network-lb-ip-1 \
  --region $REGION

gcloud compute http-health-checks create basic-check

gcloud compute target-pools create www-pool \
  --region $REGION --http-health-check basic-check

gcloud compute target-pools add-instances www-pool \
    --instances web1,web2,web3

gcloud compute forwarding-rules create www-rule \
    --region $REGION \
    --ports 80 \
    --address network-lb-ip-1 \
    --target-pool www-pool


cat << 'EOF'

========================================================
Task 3. Create an HTTP load balancer
========================================================

Managed instance groups (MIGs)

EOF
## Refer to GSP155, Task 3 and 4

gcloud compute instance-templates create lb-backend-template \
   --region=$REGION \
   --network=default \
   --subnet=default \
   --tags=allow-health-check \
   --machine-type=e2-medium \
   --image-family=debian-12 \
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

sleep 30

IP_ADDRESS=$(gcloud compute addresses describe lb-ipv4-1 \
  --global \
  --format="get(address)")
echo -e "\n👉  Open http://$IP_ADDRESS in the browser. \n"
echo "Your browser should render a page with content showing the name of the instance that served the page, \
along with its zone (for example, Page served from: lb-backend-group-xxxx."



echo -e "\n✅  All done\n"