#!/bin/bash
## Created by nov05, 2026-08-04

echo -e "\n\n"
read -p "👉  Enter username 2: " USER_ID2
export USER_ID2
echo

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
export ORG_ID=$(gcloud projects get-ancestors $PROJECT_ID \
  --format="value(id,type)" | awk '$2=="organization"{print $1}')
gcloud config set account $USER_ID
gcloud config set project $PROJECT_ID  
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE
echo
echo "🔹  User 1 (Cymbal Systems Admin): $USER"
echo "🔹  Username 1 (Cymbal Systems Admin): $USER_ID"
echo "🔹  Username 2 (Cymbal Security Lead): $USER_ID2"
echo "🔹  Project ID: $PROJECT_ID"
echo "🔹  Project number: $PROJECT_NUMBER"
echo "🔹  Region: $REGION"
echo "🔹  Zone: $ZONE"
# echo "🔹  Zone 2: $ZONE2"
# echo "🔹  Bukect: $BUCKET"
echo "🔹  Organization ID: $ORG_ID"
echo
gcloud auth list





cat << 'EOF'

========================================================
Task 1. Enable Privileged Access Manager (PAM)
========================================================

⚠️  Sign in to the console as the primary user $USER_ID.

EOF

## Enable the Privileged Access Manager API in your project.
gcloud services enable privilegedaccessmanager.googleapis.com
until gcloud services list --enabled \
  --project=$PROJECT_ID | grep -q privilegedaccessmanager.googleapis.com
do sleep 5; done

sleep 90  

## Locate the Google-managed Privileged Access Manager service agent 
## (created automatically upon activation) and grant it the 
## Privileged Access Manager Service Agent role.

## ⚠️ Project-level service agent (deprecated)
# PAM_SERVICE_AGENT="service-${PROJECT_NUMBER}@gcp-sa-pam.iam.gserviceaccount.com"
# gcloud projects add-iam-policy-binding $PROJECT_ID \
#   --member="serviceAccount:${PAM_SERVICE_AGENT}" \
#   --role="roles/privilegedaccessmanager.serviceAgent"
# until gcloud projects get-iam-policy $PROJECT_ID \
#   --flatten="bindings[].members" \
#   --format="value(bindings.role, bindings.members)" 2>/dev/null \
#   | grep -q "roles/privilegedaccessmanager.serviceAgent.*${PAM_SERVICE_AGENT}"
# do sleep 5; done

## Organization-level service agent (recommended)
PAM_ORG_SERVICE_AGENT="service-org-${ORG_ID}@gcp-sa-pam.iam.gserviceaccount.com"
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${PAM_ORG_SERVICE_AGENT}" \
  --role="roles/privilegedaccessmanager.serviceAgent"
until gcloud projects get-iam-policy $PROJECT_ID \
  --flatten="bindings[].members" \
  --format="value(bindings.role, bindings.members)" 2>/dev/null \
  | grep -q "roles/privilegedaccessmanager.serviceAgent.*${PAM_ORG_SERVICE_AGENT}"
do sleep 5; done




cat << 'EOF'

========================================================
Task 2. Create the entitlement
========================================================

Entitlement Name: pam-entitlement
Role: Compute Admin
Maximum duration: 10 hours
Requester principal: (provided at lab start) $USER_ID
Justification required: Not required
Approver principal: (provided at lab start) $USER_ID2
Number of approvers required: 1

⚠️  Sign in to the console as the primary user $USER_ID.

EOF

cat > entitlement.yaml << EOF
maxRequestDuration: 36000s

eligibleUsers:
- principals:
  - user:${USER_ID}

privilegedAccess:
  gcpIamAccess:
    resource: //cloudresourcemanager.googleapis.com/projects/${PROJECT_ID}
    resourceType: cloudresourcemanager.googleapis.com/Project
    roleBindings:
    - role: roles/compute.admin

approvalWorkflow:
  manualApprovals:
    steps:
    - approvalsNeeded: 1
      approvers:
      - principals:
        - user:${USER_ID2}

requesterJustificationConfig:
  notMandatory: {}
EOF

gcloud pam entitlements create pam-entitlement \
  --project=$PROJECT_ID \
  --location=global \
  --entitlement-file=entitlement.yaml
sleep 60





cat << 'EOF'

========================================================
Task 3. Update the entitlement
========================================================

⚠️  Sign in to the console as the primary user $USER_ID.

EOF

gcloud pam entitlements describe pam-entitlement \
  --project=$PROJECT_ID \
  --location=global \
  --format=yaml > entitlement.yaml
sed -i 's/maxRequestDuration: 36000s/maxRequestDuration: 14400s/' entitlement.yaml
grep maxRequestDuration entitlement.yaml

gcloud alpha pam entitlements update pam-entitlement \
  --project=$PROJECT_ID \
  --location=global \
  --entitlement-file=entitlement.yaml \
  --quiet
sleep 30





cat << 'EOF'

========================================================
Task 4. Request temporary elevated access with Privileged Access Manager
========================================================

EOF

## ⚠️  Sign in to the console as the primary user $USER_ID.
## Request the grant (run as the primary user)
gcloud pam grants create \
  --entitlement=pam-entitlement \
  --requested-duration=14400s \
  --justification="Lab test" \
  --location=global \
  --project=$PROJECT_ID


## ⚠️ Switch to secondary user ($USER_ID2) in the other browser session.
export PROJECT_ID=$(gcloud config get-value project)
## Find the pending grant (run as the approver/secondary user)
GRANT_ID=$(gcloud alpha pam grants search \
  --entitlement=pam-entitlement \
  --caller-relationship=can-approve \
  --location=global \
  --project=$PROJECT_ID \
  --format="value(name)" | head -n 1)
echo $GRANT_ID
## Approve the grant (run as the secondary user)
## gcloud pam grants approve GRANT_NAME --reason="approval reason"
gcloud pam grants approve $GRANT_ID \
  --entitlement=pam-entitlement \
  --reason="Approved for lab" \
  --location=global \
  --project=$PROJECT_ID
sleep 180
gcloud pam grants describe "$GRANT_ID" \
  --location=global \
  --format="yaml(state,timeline)"





cat << 'EOF'

========================================================
Task 5. Revoke a grant
========================================================

⚠️  Sign in to the console as the secondary user (Cymbal Security Lead).

EOF

gcloud pam grants revoke $GRANT_ID \
  --entitlement=pam-entitlement \
  --reason="Lab cleanup" \
  --location=global \
  --project=$PROJECT_ID





cat << 'EOF'

========================================================
Task 6. Delete an entitlement and review audit logs
========================================================

⚠️  Sign in to the console as the primary user $USER_ID.

EOF

## Delete the entitlement (run as the primary user)
gcloud pam entitlements delete pam-entitlement \
  --location=global \
  --project=$PROJECT_ID\
  --quiet
sleep 15
gcloud pam entitlements list \
  --location=global \
  --project=$PROJECT_ID
## Parsed [location] resource: projects/qwiklabs-gcp-02-4905ed7511ca/locations/global
## Listed 0 items.

gcloud logging read \
'protoPayload.serviceName="privilegedaccessmanager.googleapis.com" AND protoPayload.resourceName:"pam-entitlement"' \
  --project=$PROJECT_ID \
  --limit=20 \
  --format="table(timestamp, protoPayload.methodName, protoPayload.authenticationInfo.principalEmail)"





echo -e "\n✅  All done\n"