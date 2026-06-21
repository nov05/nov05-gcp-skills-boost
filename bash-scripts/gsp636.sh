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
export ZONE2=$(gcloud compute zones list \
  --filter="region:$REGION" \
  --format="value(name)" | grep -v $ZONE | head -n 1)
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
echo "🔹  Zone 2: $ZONE2"
# echo "🔹  Bukect: $BUCKET"
echo
gcloud auth list


cat << 'EOF'

========================================================
Task 1. Configure the Network and Subnets
========================================================

EOF

# Create custom VPC network
gcloud compute networks create lb-network \
  --subnet-mode=custom

# Create backend subnet
gcloud compute networks subnets create backend-subnet \
  --network=lb-network \
  --region=$REGION \
  --range=10.1.2.0/24

# Create proxy-only subnet (required for internal proxy NLB)
gcloud compute networks subnets create proxy-only-subnet \
  --network=lb-network \
  --region=$REGION \
  --range=10.129.0.0/23 \
  --purpose=REGIONAL_MANAGED_PROXY \
  --role=ACTIVE


cat << 'EOF'

========================================================
Task 2. Create Firewall Rules
========================================================

EOF

# Allow SSH access
gcloud compute firewall-rules create fw-allow-ssh \
  --network=lb-network \
  --target-tags=allow-ssh \
  --source-ranges=0.0.0.0/0 \
  --allow=tcp:22

# Allow Google health checks to backend instances
gcloud compute firewall-rules create fw-allow-health-check \
  --network=lb-network \
  --target-tags=allow-health-check \
  --source-ranges=130.211.0.0/22,35.191.0.0/16 \
  --allow=tcp:80

# Allow traffic from proxy-only subnet to backends
gcloud compute firewall-rules create fw-allow-proxy-only-subnet \
  --network=lb-network \
  --target-tags=allow-proxy-only-subnet \
  --source-ranges=10.129.0.0/23 \
  --allow=tcp:80


cat << 'EOF'

========================================================
Task 3. Create backend Managed Instance Groups (MIGs)
========================================================

EOF

# Create instance template
gcloud compute instance-templates create int-tcp-proxy-backend-template \
  --machine-type=e2-medium \
  --network=lb-network \
  --subnet=backend-subnet \
  --tags=allow-ssh,allow-health-check,allow-proxy-only-subnet \
  --metadata=startup-script='#! /bin/bash
apt-get update
apt-get install apache2 -y
a2ensite default-ssl
a2enmod ssl
vm_hostname="$(curl -H "Metadata-Flavor:Google" \
http://metadata.google.internal/computeMetadata/v1/instance/name)"
echo "Page served from: $vm_hostname" | \
tee /var/www/html/index.html
systemctl restart apache2'

# Create MIG in first zone (mig-a)
gcloud compute instance-groups managed create mig-a \
  --zone=$ZONE \
  --template=int-tcp-proxy-backend-template \
  --size=2 \
  --base-instance-name=mig-a
# Set named port for mig-a
gcloud compute instance-groups managed set-named-ports mig-a \
  --zone=$ZONE \
  --named-ports=tcp80:80

# Create MIG in second zone (replace $ZONE with another zone in region)
gcloud compute instance-groups managed create mig-c \
  --zone=$ZONE2 \
  --template=int-tcp-proxy-backend-template \
  --size=2 \
  --base-instance-name=mig-c
# Set named port for mig-c
gcloud compute instance-groups managed set-named-ports mig-c \
  --zone=$ZONE2 \
  --named-ports=tcp80:80

## Verify backend service binding
gcloud compute instances list \
  --filter="name ~ mig-a" \
  --limit=1 --format='value(name)'
gcloud compute ssh $(gcloud compute instances list \
  --filter="name ~ mig-a" \
  --limit=1 \
  --format='value(name)') \
  --zone=$ZONE \
  --command="sudo netstat -tnlp | grep 80" \
  --quiet


cat << 'EOF'

========================================================
Task 4. Configure the Load Balancer (internal IP and proxy rules)
========================================================

EOF

gcloud compute addresses create int-tcp-ip-address \
  --region=$REGION \
  --subnet=backend-subnet \
  --purpose=SHARED_LOADBALANCER_VIP

IP_ADDRESS=$(gcloud compute addresses describe int-tcp-ip-address \
  --region=$REGION \
  --format='value(address)')
echo -e "\n👉  Load balancer IP address: $IP_ADDRESS\n"

# Create TCP health check
gcloud compute health-checks create tcp tcp-health-check \
  --region=$REGION \
  --port=80

# Create regional backend service
## Regional L4 Envoy LB supports regional health checks only
gcloud compute backend-services create my-int-tcp-lb \
  --region=$REGION \
  --load-balancing-scheme=INTERNAL_MANAGED \
  --protocol=TCP \
  --health-checks=tcp-health-check \
  --health-checks-region=$REGION \
  --timeout=30s

# Add mig-a backend
gcloud compute backend-services add-backend my-int-tcp-lb \
  --instance-group=mig-a \
  --instance-group-zone=$ZONE

# Add mig-c backend
gcloud compute backend-services add-backend my-int-tcp-lb \
  --instance-group=mig-c \
  --instance-group-zone=$ZONE2

# Create target TCP proxy
gcloud compute target-tcp-proxies create my-int-tcp-proxy \
  --region=$REGION \
  --backend-service=my-int-tcp-lb 

# Create forwarding rule on port 110
gcloud compute forwarding-rules create int-tcp-forwarding-rule \
  --region=$REGION \
  --load-balancing-scheme=INTERNAL_MANAGED \
  --network=lb-network \
  --subnet=backend-subnet \
  --address=int-tcp-ip-address \
  --ports=110 \
  --target-tcp-proxy=my-int-tcp-proxy \
  --target-tcp-proxy-region=$REGION


cat << 'EOF'

========================================================
Task 5. Test the load balancer
========================================================

EOF

# Create client VM
gcloud compute instances create client-vm \
  --zone=$ZONE \
  --machine-type=e2-medium \
  --network-interface=subnet=backend-subnet \
  --tags=allow-ssh
until gcloud compute ssh client-vm \
    --zone=$ZONE \
    --command="echo Ready" \
    --quiet 2>/dev/null
do sleep 5; done

# Verify backend health
gcloud compute backend-services get-health my-int-tcp-lb \
  --region=$REGION

# Run the following commands FROM INSIDE client-vm:
gcloud compute ssh client-vm --zone=$ZONE --quiet \
  --command="for i in {1..10}; do curl -s ${IP_ADDRESS}:110; echo; done"


cat << 'EOF'

========================================================
(Optional) Task 6. Practice your skills
========================================================

EOF

# Create a dedicated client instance template (least privilege)
gcloud compute instance-templates create int-tcp-proxy-client-template \
  --machine-type=e2-medium \
  --network=lb-network \
  --subnet=backend-subnet \
  --tags=allow-ssh

# Delete existing client VM (safe reset step)
gcloud compute instances delete client-vm \
  --zone=$ZONE \
  --quiet || true
# Recreate client VM using the new template
gcloud compute instances create client-vm \
  --zone=$ZONE \
  --source-instance-template=int-tcp-proxy-client-template
# Wait for SSH readiness
until gcloud compute ssh client-vm \
    --zone=$ZONE \
    --command="echo Ready" \
    --quiet 2>/dev/null
do sleep 5; done

# Re-check backend health
gcloud compute backend-services get-health my-int-tcp-lb \
  --region=$REGION

# Retest load balancing from client VM
gcloud compute ssh client-vm --zone=$ZONE --quiet \
  --command="for i in {1..10}; do curl -s ${IP_ADDRESS}:110; echo; done"


echo -e "\n✅  All done\n"