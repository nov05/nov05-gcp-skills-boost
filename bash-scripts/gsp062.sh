#!/bin/bash
## Created by nov05, 2026-06-01  

## User inputs
echo
read -p "👉  Enter zone 2: " ZONE2
export ZONE2  
export REGION2=$(gcloud compute zones describe "$ZONE2" \
    --format="value(region.basename())")
echo
read -p "👉  Enter my secret: " MY_SECRET
export MY_SECRET 

## Get project id, project number, region, zone
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID \
  --format='value(projectNumber)')
export REGION=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-region])")
export ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
# export BUCKET="$PROJECT_ID-bucket"
# gcloud config set project $(gcloud projects list --format='value(PROJECT_ID)' --filter='qwiklabs-gcp')
gcloud config set project $PROJECT_ID  
gcloud config set compute/region $REGION
echo
echo "🔹  Project ID: $PROJECT_ID"
echo "🔹  Project number: $PROJECT_NUMBER"
echo "🔹  Region: $REGION"
echo "🔹  Zone: $ZONE"
echo "🔹  User: $USER"
# echo "🔹  Bukect: $BUCKET"
echo

cat << 'EOF'

========================================================
Task 1. Create the cloud VPC
========================================================

EOF

gcloud compute networks create cloud --subnet-mode custom
gcloud compute firewall-rules create cloud-fw --network cloud --allow tcp:22,tcp:5001,udp:5001,icmp
gcloud compute networks subnets create cloud-east --network cloud \
    --range 10.0.1.0/24 --region $REGION2

cat << 'EOF'

========================================================
Task 2. Create the on-prem VPC
========================================================

EOF

gcloud compute networks create on-prem --subnet-mode custom
gcloud compute firewall-rules create on-prem-fw --network on-prem --allow tcp:22,tcp:5001,udp:5001,icmp
gcloud compute networks subnets create on-prem-central \
    --network on-prem --range 192.168.1.0/24 --region $REGION

cat << 'EOF'

========================================================
Task 3. Create VPN gateways
========================================================

EOF

gcloud compute target-vpn-gateways create on-prem-gw1 --network on-prem --region $REGION
gcloud compute target-vpn-gateways create cloud-gw1 --network cloud --region $REGION2

cat << 'EOF'

========================================================
Task 4. Create a route-based VPN tunnel between local and Google Cloud networks
========================================================

EOF

gcloud compute addresses create cloud-gw1 --region $REGION2
gcloud compute addresses create on-prem-gw1 --region $REGION

cloud_gw1_ip=$(gcloud compute addresses describe cloud-gw1 \
    --region $REGION2 --format='value(address)')
on_prem_gw_ip=$(gcloud compute addresses describe on-prem-gw1 \
    --region $REGION --format='value(address)')

## Forward the Encapsulating Security Payload (ESP) protocol from cloud-gw1
gcloud compute forwarding-rules create cloud-1-fr-esp --ip-protocol ESP \
    --address $cloud_gw1_ip --target-vpn-gateway cloud-gw1 --region $REGION2
## Forward UDP:500 traffic from cloud-gw1
gcloud compute forwarding-rules create cloud-1-fr-udp500 --ip-protocol UDP \
    --ports 500 --address $cloud_gw1_ip --target-vpn-gateway cloud-gw1 --region $REGION2
## Forward UDP:4500 traffic from cloud-gw1
gcloud compute forwarding-rules create cloud-fr-1-udp4500 --ip-protocol UDP \
    --ports 4500 --address $cloud_gw1_ip --target-vpn-gateway cloud-gw1 --region $REGION2

## Do the same for op-prem
gcloud compute forwarding-rules create on-prem-fr-esp --ip-protocol ESP \
    --address $on_prem_gw_ip --target-vpn-gateway on-prem-gw1 --region $REGION
gcloud compute forwarding-rules create on-prem-fr-udp500 --ip-protocol UDP --ports 500 \
    --address $on_prem_gw_ip --target-vpn-gateway on-prem-gw1 --region $REGION 
gcloud compute forwarding-rules create on-prem-fr-udp4500 --ip-protocol UDP --ports 4500 \
    --address $on_prem_gw_ip --target-vpn-gateway on-prem-gw1 --region $REGION

## Create the VPN tunnel from on-prem to cloud
gcloud compute vpn-tunnels create on-prem-tunnel1 --peer-address $cloud_gw1_ip \
    --target-vpn-gateway on-prem-gw1 --ike-version 2 --local-traffic-selector 0.0.0.0/0 \
    --remote-traffic-selector 0.0.0.0/0 --shared-secret=$MY_SECRET --region $REGION
## Create the VPN tunnel from cloud to on-prem
gcloud compute vpn-tunnels create cloud-tunnel1 --peer-address $on_prem_gw_ip \
    --target-vpn-gateway cloud-gw1 --ike-version 2 --local-traffic-selector 0.0.0.0/0 \
    --remote-traffic-selector 0.0.0.0/0 --shared-secret=$MY_SECRET --region $REGION2

## Route traffic from the on-prem VPC to the cloud 10.0.1.0/24 range into the tunnel
gcloud compute routes create on-prem-route1 --destination-range 10.0.1.0/24 \
    --network on-prem --next-hop-vpn-tunnel on-prem-tunnel1 \
    --next-hop-vpn-tunnel-region $REGION
## Route traffic from the cloud VPC to the on-prem 192.168.1.0/24 range into the tunnel.
## This creates an iperf client with twenty streams, which reports values after 10 seconds of testing.
gcloud compute routes create cloud-route1 --destination-range 192.168.1.0/24 \
    --network cloud --next-hop-vpn-tunnel cloud-tunnel1 --next-hop-vpn-tunnel-region $REGION2

cat << 'EOF'

========================================================
Task 5. Test throughput over VPN
========================================================

EOF

## Single VPN load testing:
## Now you create a virtual machine for the cloud VPC named is cloud-loadtest.
gcloud compute instances create "cloud-loadtest" --zone $ZONE2 \
    --machine-type "e2-standard-4" --subnet "cloud-east" \
    --image-family "debian-11" --image-project "debian-cloud" --boot-disk-size "10" \
    --boot-disk-type "pd-standard" --boot-disk-device-name "cloud-loadtest"
## Create a virtual machine for the on-prem VPC named on-prem-loadtest.
gcloud compute instances create "on-prem-loadtest" --zone $ZONE \
    --machine-type "e2-standard-4" --subnet "on-prem-central" \
    --image-family "debian-11" --image-project "debian-cloud" --boot-disk-size "10" \
    --boot-disk-type "pd-standard" --boot-disk-device-name "on-prem-loadtest"

## Install a copy of iperf for each VM.
gcloud compute ssh on-prem-loadtest \
    --zone=$ZONE \
    --command="sudo apt-get update && sudo apt-get install -y iperf"
gcloud compute ssh cloud-loadtest \
    --zone=$ZONE2 \
    --command="sudo apt-get update && sudo apt-get install -y iperf"

## Create an iperf server on the VM on-prem-loadtest that reports its status every 5 seconds
gcloud compute ssh on-prem-loadtest \
    --zone=$ZONE \
    --command="nohup iperf -s -i 5 > /tmp/iperf.log 2>&1 &"
## Test from the VM cloud-loadtest
gcloud compute ssh cloud-loadtest \
    --zone=$ZONE2 \
    --command="iperf -c 192.168.1.2 -P 20 -x C"

echo -e "\n✅  All done\n"