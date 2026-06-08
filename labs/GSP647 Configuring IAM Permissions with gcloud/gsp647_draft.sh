#!/bin/bash

gcloud auth login --quiet

export ZONE=$(
    gcloud compute project-info describe \
        --format="value(commonInstanceMetadata.items[google-compute-default-zone])"
)

export REGION=$(
    gcloud compute project-info describe \
        --format="value(commonInstanceMetadata.items[google-compute-default-region])"
)

gcloud config set compute/region "$REGION"
gcloud config set compute/zone "$ZONE"

gcloud compute instances create lab-1 \
    --zone "$ZONE" \
    --machine-type=e2-standard-2

export NEWZONE=$(
    gcloud compute zones list \
        --filter="name~'^$REGION'" \
        --format="value(name)" |
    grep -v "^$ZONE$" |
    head -n 1
)

gcloud config set compute/zone "$NEWZONE"

gcloud config configurations create user2 --quiet

gcloud auth login \
    --no-launch-browser \
    --quiet

gcloud config set project \
    "$(gcloud config get-value project --configuration=default)" \
    --configuration=user2

gcloud config set compute/zone \
    "$(gcloud config get-value compute/zone --configuration=default)" \
    --configuration=user2

gcloud config set compute/region \
    "$(gcloud config get-value compute/region --configuration=default)" \
    --configuration=user2

gcloud config configurations activate default

sudo yum -y install epel-release
sudo yum -y install jq

get_and_export_values() {
    read -p "Enter PROJECTID2: " PROJECTID2
    read -p "Enter USERID2: " USERID2
    read -p "Enter ZONE2: " ZONE2

    export PROJECTID2 USERID2 ZONE2

    echo "export PROJECTID2=$PROJECTID2" >> ~/.bashrc
    echo "export USERID2=$USERID2" >> ~/.bashrc
    echo "export ZONE2=$ZONE2" >> ~/.bashrc
}

get_and_export_values

. ~/.bashrc

gcloud projects add-iam-policy-binding "$PROJECTID2" \
    --member="user:$USERID2" \
    --role="roles/viewer"

gcloud config configurations activate user2

gcloud config set project "$PROJECTID2"

gcloud config configurations activate default

gcloud iam roles create devops \
    --project "$PROJECTID2" \
    --permissions \
    "compute.instances.create,\
compute.instances.delete,\
compute.instances.start,\
compute.instances.stop,\
compute.instances.update,\
compute.disks.create,\
compute.subnetworks.use,\
compute.subnetworks.useExternalIp,\
compute.instances.setMetadata,\
compute.instances.setServiceAccount"

gcloud projects add-iam-policy-binding "$PROJECTID2" \
    --member="user:$USERID2" \
    --role="roles/iam.serviceAccountUser"

gcloud projects add-iam-policy-binding "$PROJECTID2" \
    --member="user:$USERID2" \
    --role="projects/$PROJECTID2/roles/devops"

gcloud config configurations activate user2

gcloud compute instances create lab-2 \
    --zone "$ZONE2" \
    --machine-type=e2-standard-2

gcloud config configurations activate default

gcloud config set project "$PROJECTID2"

gcloud iam service-accounts create devops \
    --display-name devops

SA=$(
    gcloud iam service-accounts list \
        --format="value(email)" \
        --filter="displayName=devops"
)

gcloud projects add-iam-policy-binding "$PROJECTID2" \
    --member="serviceAccount:$SA" \
    --role="roles/iam.serviceAccountUser"

gcloud projects add-iam-policy-binding "$PROJECTID2" \
    --member="serviceAccount:$SA" \
    --role="roles/compute.instanceAdmin"

gcloud compute instances create lab-3 \
    --zone "$ZONE2" \
    --machine-type=e2-standard-2 \
    --service-account "$SA" \
    --scopes="https://www.googleapis.com/auth/compute"