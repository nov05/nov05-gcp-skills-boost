#!/bin/bash
## Created by nov05, 2026-09-08
## Google Cloud Skills Boost - GSP211 Multiple VPC Networks

set -e

echo
read -p "👉  Enter region 2 (Task 1): " REGION2
export REGION2 
read -p "👉  Enter zone 2 (Task 1): " ZONE2
export ZONE2 
echo

export USER_ID=$(gcloud auth list --format="value(account)" --filter="status:ACTIVE")
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" \
  --format='value(projectNumber)')
export REGION=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-region])")
export ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])")

gcloud config set account "$USER_ID"
gcloud config set project "$PROJECT_ID"
gcloud config set compute/region "$REGION"
gcloud config set compute/zone "$ZONE"

echo
echo "🔹 User: $USER_ID"
echo "🔹 Username: $USER_ID"
echo "🔹 Project ID: $PROJECT_ID"
echo "🔹 Project number: $PROJECT_NUMBER"
echo "🔹 Region: $REGION"
echo "🔹 Region 2: $REGION2"
echo "🔹 Zone: $ZONE"
echo "🔹 Zone 2: $ZONE2"
echo

gcloud auth list

###############################################################################
# Helper
###############################################################################

wait_for_instance() {
  local INSTANCE="$1"
  local INSTANCE_ZONE="$2"

  echo "Waiting for instance: $INSTANCE ..."
  until gcloud compute instances describe "$INSTANCE" \
      --zone="$INSTANCE_ZONE" \
      --format="value(status)" 2>/dev/null | grep -q "RUNNING"; do
    sleep 5
  done
}




cat << 'EOF'

========================================================
Task 1. Create multiple VPC networks
========================================================

EOF

echo ">>> Creating managementnet..."

gcloud compute networks create managementnet \
  --subnet-mode=custom

gcloud compute networks subnets create managementsubnet-1 \
  --network=managementnet \
  --region="$REGION" \
  --range=10.130.0.0/20

echo ">>> Creating privatenet..."

gcloud compute networks create privatenet \
  --subnet-mode=custom

gcloud compute networks subnets create privatesubnet-1 \
  --network=privatenet \
  --region="$REGION" \
  --range=172.16.0.0/24

gcloud compute networks subnets create privatesubnet-2 \
  --network=privatenet \
  --region="$REGION2" \
  --range=172.20.0.0/20

echo
echo ">>> Networks:"
gcloud compute networks list

echo
echo ">>> Subnets:"
gcloud compute networks subnets list --sort-by=NETWORK

echo ">>> Firewall rule for managementnet..."

gcloud compute firewall-rules create managementnet-allow-icmp-ssh-rdp \
  --direction=INGRESS \
  --priority=1000 \
  --network=managementnet \
  --action=ALLOW \
  --rules=icmp,tcp:22,tcp:3389 \
  --source-ranges=0.0.0.0/0

echo ">>> Firewall rule for privatenet..."

gcloud compute firewall-rules create privatenet-allow-icmp-ssh-rdp \
  --direction=INGRESS \
  --priority=1000 \
  --network=privatenet \
  --action=ALLOW \
  --rules=icmp,tcp:22,tcp:3389 \
  --source-ranges=0.0.0.0/0

echo
echo ">>> Firewall rules:"
gcloud compute firewall-rules list --sort-by=NETWORK




cat << 'EOF'

========================================================
Task 2. Create VMs
========================================================

EOF

echo ">>> Creating managementnet-vm-1..."

gcloud compute instances create managementnet-vm-1 \
  --zone="$ZONE" \
  --machine-type=e2-micro \
  --subnet=managementsubnet-1

echo ">>> Creating privatenet-vm-1..."

gcloud compute instances create privatenet-vm-1 \
  --zone="$ZONE" \
  --machine-type=e2-micro \
  --subnet=privatesubnet-1

wait_for_instance managementnet-vm-1 "$ZONE"
wait_for_instance privatenet-vm-1 "$ZONE"

echo
echo ">>> All instances:"
gcloud compute instances list --sort-by=ZONE




cat << 'EOF'

========================================================
Task 3. Explore the connectivity between VM instances
========================================================

Note: For the below task consider region_1 = $REGION and region_2 = $REGION2
  Which instance(s) should you be able to ping from mynet-region-1-vm using internal IP addresses?
    - managementnet-region-1-vm
    - privatenet-region-1-vm
    - mynet-region-2-vm ✅

EOF

echo
echo ">>> Current VM network information:"
gcloud compute instances list \
  --format="table(name,zone,networkInterfaces[0].network.basename(),networkInterfaces[0].networkIP,networkInterfaces[0].accessConfigs[0].natIP)"

echo
echo ">>> Internal connectivity inside mynetwork should work:"
echo "    mynet-vm-1 -> mynet-vm-2"

MYNET_VM2_IP=$(gcloud compute instances describe mynet-vm-2 \
  --zone="$ZONE" \
  --format="value(networkInterfaces[0].networkIP)" 2>/dev/null || true)

if [[ -n "$MYNET_VM2_IP" ]]; then
  echo "mynet-vm-2 internal IP: $MYNET_VM2_IP"
else
  echo "NOTE: mynet-vm-2 may be in another zone."
  echo "Use the VM list above to identify its zone."
fi

echo
echo "Expected internal-IP behavior:"
echo "  mynet-vm-1    <-> mynet-vm-2       : YES"
echo "  mynet-vm-1    <-> managementnet VM : NO"
echo "  mynet-vm-1    <-> privatenet VM    : NO"
echo
echo "Reason: VPC networks are isolated from one another by default."




cat << 'EOF'

========================================================
Task 4. Create a VM instance with multiple network interfaces
========================================================

EOF

echo ">>> Creating vm-appliance with 3 NICs..."

gcloud compute instances create vm-appliance \
  --zone="$ZONE" \
  --machine-type=e2-standard-4 \
  --network-interface=network=privatenet,subnet=privatesubnet-1 \
  --network-interface=network=managementnet,subnet=managementsubnet-1,no-address \
  --network-interface=network=mynetwork,subnet=mynetwork,no-address

wait_for_instance vm-appliance "$ZONE"

echo
echo ">>> vm-appliance:"
gcloud compute instances describe vm-appliance \
  --zone="$ZONE" \
  --format="table(
    name,
    networkInterfaces[].network.basename(),
    networkInterfaces[].subnetwork.basename(),
    networkInterfaces[].networkIP,
    networkInterfaces[].accessConfigs[0].natIP
  )"

sleep 30  

##############################################################################
## Explore the network interface details
##############################################################################

echo
echo ">>> vm-appliance network interfaces:"
gcloud compute ssh vm-appliance \
  --zone="$ZONE" \
  --command="sudo ifconfig" \
  --quiet

echo
echo ">>> vm-appliance routing table:"
gcloud compute ssh vm-appliance \
  --zone="$ZONE" \
  --command="ip route" \
  --quiet

##############################################################################
# Explore the network interface connectivity
##############################################################################

echo
echo ">>> Network connectivity from vm-appliance"

PRIVATENET_VM1_IP=$(gcloud compute instances describe privatenet-vm-1 \
  --zone="$ZONE" \
  --format="value(networkInterfaces[0].networkIP)")

MANAGEMENTNET_VM1_IP=$(gcloud compute instances describe managementnet-vm-1 \
  --zone="$ZONE" \
  --format="value(networkInterfaces[0].networkIP)")

MYNET_VM1_ZONE=$(gcloud compute instances list \
  --filter="name=mynet-vm-1" \
  --format="value(zone.basename())" \
  --limit=1)

MYNET_VM1_IP=$(gcloud compute instances describe mynet-vm-1 \
  --zone="$MYNET_VM1_ZONE" \
  --format="value(networkInterfaces[0].networkIP)")

echo
echo "privatenet-vm-1    = $PRIVATENET_VM1_IP"
echo "managementnet-vm-1 = $MANAGEMENTNET_VM1_IP"
echo "mynet-vm-1         = $MYNET_VM1_IP"

echo
echo ">>> Ping privatenet-vm-1..."
gcloud compute ssh vm-appliance \
  --zone="$ZONE" \
  --command="ping -c 3 $PRIVATENET_VM1_IP" \
  --quiet

echo
echo ">>> Ping managementnet-vm-1..."
gcloud compute ssh vm-appliance \
  --zone="$ZONE" \
  --command="ping -c 3 $MANAGEMENTNET_VM1_IP" \
  --quiet

echo
echo ">>> Ping mynet-vm-1..."
gcloud compute ssh vm-appliance \
  --zone="$ZONE" \
  --command="ping -c 3 $MYNET_VM1_IP" \
  --quiet

echo
echo "Expected:"
echo "  vm-appliance -> privatenet-vm-1    : YES"
echo "  vm-appliance -> managementnet-vm-1 : YES"
echo "  vm-appliance -> mynet-vm-1         : YES"

###############################################################################
# Verify network isolation
###############################################################################

MYNET_VM2_ZONE=$(gcloud compute instances list \
  --filter="name=mynet-vm-2" \
  --format="value(zone.basename())" \
  --limit=1)

MYNET_VM2_IP=$(gcloud compute instances describe mynet-vm-2 \
  --zone="$MYNET_VM2_ZONE" \
  --format="value(networkInterfaces[0].networkIP)")

echo "mynet-vm-2 zone: $MYNET_VM2_ZONE"
echo "mynet-vm-2 IP  : $MYNET_VM2_IP"

echo
echo "Testing vm-appliance -> mynet-vm-2..."
echo "This is expected to FAIL in the lab's default routing setup."

set +e
gcloud compute ssh vm-appliance \
  --zone="$ZONE" \
  --command="ping -c 3 -W 2 $MYNET_VM2_IP" \
  --quiet
PING_RESULT=$?
set -e

if [[ "$PING_RESULT" -ne 0 ]]; then
  echo
  echo "Expected: ping to mynet-vm-2 failed."
else
  echo
  echo "NOTE: ping succeeded; check the current routing configuration."
fi

###############################################################################
# Final verification
###############################################################################

echo
echo ">>> Networks"
gcloud compute networks list

echo
echo ">>> Subnets"
gcloud compute networks subnets list --sort-by=NETWORK

echo
echo ">>> Firewall rules"
gcloud compute firewall-rules list --sort-by=NETWORK

echo
echo ">>> Instances"
gcloud compute instances list --sort-by=ZONE

echo
echo ">>> vm-appliance NICs"
gcloud compute instances describe vm-appliance \
  --zone="$ZONE" \
  --format="table(
    networkInterfaces[].name,
    networkInterfaces[].network.basename(),
    networkInterfaces[].subnetwork.basename(),
    networkInterfaces[].networkIP
  )"

echo
echo "========================================================"
echo "✅  GSP211 Multiple VPC Networks setup completed"
echo "========================================================"
echo