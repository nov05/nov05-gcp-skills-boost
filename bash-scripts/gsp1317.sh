#!/bin/bash
## Created by nov05, 2026-08-06 

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
# export ORG_ID=$(gcloud projects get-ancestors $PROJECT_ID \
#   --format="value(id,type)" | awk '$2=="organization"{print $1}')
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
# echo "🔹  Organization ID: $ORG_ID"
echo
gcloud auth list




cat << 'EOF'

========================================================
Task 1. Create a hub
========================================================

EOF

gcloud network-connectivity hubs create ncc-hub
gcloud network-connectivity hubs describe ncc-hub





cat << 'EOF'

========================================================
Task 2. Configure VPCs as NCC spokes
========================================================

EOF

## Enable the Network Connectivity API.
gcloud services enable networkconnectivity.googleapis.com
until gcloud services list --enabled \
  --project=$PROJECT_ID | grep -q networkconnectivity.googleapis.com
do sleep 5; done

## list all subnets belonging to VPC1
gcloud config set accessibility/screen_reader false
gcloud compute networks subnets list --network=vpc1-ncc

## Configure VPC1 as an NCC spoke.
gcloud network-connectivity spokes linked-vpc-network create vpc1-spoke1 \
  --hub=ncc-hub \
  --vpc-network=vpc1-ncc \
  --exclude-export-ranges=10.1.2.0/24 \
  --global

## List the contents of the NCC hub's default routing table
gcloud network-connectivity hubs route-tables routes list \
  --hub=ncc-hub --route_table=default --filter="NEXT_HOP:vpc1-ncc"

## Configure VPC2 as an NCC spoke
gcloud network-connectivity spokes linked-vpc-network create vpc2-spoke2 \
  --hub=ncc-hub \
  --vpc-network=vpc2-ncc \
  --exclude-export-ranges=10.3.3.0/24 \
  --global

gcloud network-connectivity hubs route-tables routes list \
  --hub=ncc-hub --route_table=default





cat << 'EOF'

========================================================
Task 3. Verify IPv4 Data Path Connectivity
========================================================

Navigate to Compute Engine > VM instances then SSH to vm1-vpc1-ncc. 
Run the following to start TCP dump to trace ICMP packets from vm2-vpc2-ncc. 
As a reminder this VM resides on VPC2.

EOF

gcloud compute ssh vm1-vpc1-ncc \
  --zone=$ZONE \
  --project=$PROJECT_ID \
  --command="bash -c 'sudo tcpdump -i any icmp -v -e -n'" \
  --quiet

## ⚠️ In another terminal, SSH to vm2-vpc2-ncc and run the following command to ping vm1-vpc1-ncc.
export PROJECT_ID=$(gcloud config get-value project)
export ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
gcloud compute ssh vm2-vpc2-ncc \
  --zone=$ZONE \
  --project=$PROJECT_ID \
  --command="bash -c 'ping 10.1.1.2'" \
  --quiet




cat << 'EOF'

========================================================
Task 4. Set up Private Service Connect (PSC)
========================================================

EOF

## Find the VPC subnet CIDR range in the Google Cloud region 
## referred to in the environment variable REGION and choose 
## a free IP address in this CIDR range for the Private Service Connect endpoint.
SUBNET_RANGE=$(gcloud compute networks subnets describe vpc2-ncc-subnet1 \
  --region=$REGION \
  --project=$PROJECT_ID \
  --format="value(ipCidrRange)")
## avoid both VM IPs and reserved addresses
USED_IPS="$(
  {
    gcloud compute instances list \
      --filter="networkInterfaces.subnetwork:vpc2-ncc-subnet1" \
      --format="value(networkInterfaces.networkIP)"
    gcloud compute addresses list \
      --filter="region:$REGION" \
      --format="value(address)"
  } | sort -u
)"
for IP in $(seq 10 250); do
  ADDRESS=$(echo $SUBNET_RANGE | cut -d'.' -f1-3).$IP
  if ! echo "$USED_IPS" | grep -q "$ADDRESS"; then
    echo "Available IP: $ADDRESS"
    break
  fi
done

## Reserve an internal IP address for the Private Service Connect 
## endpoint in the derived VPC subnet CIDR range
gcloud compute addresses create cloudsql-psc \
  --project=$PROJECT_ID \
  --region=$REGION \
  --subnet=vpc2-ncc-subnet1 \
  --addresses=$ADDRESS

## Verify that the internal IP address is reserved and that the status RESERVED appears for the IP address.
gcloud compute addresses list \
  --project=$PROJECT_ID \
  --filter="name=cloudsql-psc"

## Get the service attachment URI and use it to create the Private Service Connect endpoint 
## with the reserved internal IP address
SQL_INSTANCE=$(gcloud sql instances list --format="value(name)")
SERVICE_ATTACHMENT_URI=$(gcloud sql instances describe $SQL_INSTANCE \
  --project=$PROJECT_ID \
  --format="value(pscServiceAttachmentLink)")

## Create the Private Service Connect endpoint in VPC2 using the available IP address.
gcloud compute forwarding-rules create cloudsql-psc-ep \
  --address=cloudsql-psc \
  --project=$PROJECT_ID \
  --region=$REGION \
  --network=vpc2-ncc \
  --target-service-attachment=$SERVICE_ATTACHMENT_URI \
  --allow-psc-global-access

## Verify that the endpoint can connect to the service attachment
gcloud compute forwarding-rules describe cloudsql-psc-ep \
  --project=$PROJECT_ID \
  --region=$REGION \
  --format="value(pscConnectionStatus)"

## To add the suggested DNS name for the Cloud SQL instance it is best 
## to create a private DNS zone in the corresponding VPC network.
gcloud dns managed-zones create cloudsql-dns \
  --project=$PROJECT_ID \
  --description="DNS zone for the Cloud SQL instances" \
  --dns-name=$REGION.sql.goog. \
  --networks=vpc2-ncc \
  --visibility=private

## Get the suggested DNS record for the Cloud SQL instance
DNS_RECORD=$(gcloud sql instances describe $SQL_INSTANCE \
  --project=$PROJECT_ID \
  --format="value(dnsName)")
echo $DNS_RECORD

## Add the suggested DNS record to the DNS managed zone
gcloud dns record-sets create $DNS_RECORD \
  --project=$PROJECT_ID \
  --type=A \
  --rrdatas=$ADDRESS \
  --zone=cloudsql-dns





cat << 'EOF'

========================================================
Task 5. Connect to Cloud SQL via Private Service Connect
========================================================

EOF

gcloud compute ssh --zone=$ZONE cloudsql-client \
  --tunnel-through-iap \
  --project=$PROJECT_ID \
  --command="bash -c '
export PGPASSWORD=changeme
psql \"sslmode=disable dbname=postgres user=postgres host=$DNS_RECORD\" <<EOF
CREATE DATABASE company;
\l
\c company
CREATE TABLE employees (
    id SERIAL PRIMARY KEY,
    first VARCHAR(255) NOT NULL,
    last VARCHAR(255) NOT NULL,
    salary DECIMAL (10, 2)
);
INSERT INTO employees (first, last, salary) VALUES
    (''Max'', ''Mustermann'', 5000.00),
    (''Anna'', ''Schmidt'', 7000.00),
    (''Peter'', ''Mayer'', 6000.00);
SELECT * FROM employees;
\q
EOF
'"





cat << 'EOF'

========================================================
Task 6. Delete resources
========================================================

EOF

gcloud network-connectivity spokes delete vpc1-spoke1 --global --quiet
gcloud network-connectivity spokes delete vpc2-spoke2 --global --quiet
gcloud network-connectivity hubs delete ncc-hub --quiet
gcloud dns record-sets delete $DNS_RECORD \
  --project=$PROJECT_ID \
  --type=A \
  --zone=cloudsql-dns
gcloud dns managed-zones delete cloudsql-dns \
  --project=$PROJECT_ID \
  --quiet





echo -e "\n✅  All done\n"