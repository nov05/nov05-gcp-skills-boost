## 👉 For development

```bash
rm -rf *
curl -LO https://raw.githubusercontent.com/nov05/nov05-gcp-skills-boost/refs/heads/dev/bash-scripts/gsp338.sh
sudo chmod +x gsp338.sh
./gsp338.sh 2>&1 | tee -a logs.txt
sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g' logs.txt > clean_logs.txt
```


## 👉 Logs

* 2026-06-12 Script `gsp338.sh` created


## Tips

* VM instance `lab-monitor`  

`gcloud compute ssh lab-monitor --zone=$ZONE`  

```bash
#!/bin/bash

export PROJECT_ID=$(gcloud config list --format 'value(core.project)')
export ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export REGION=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-region])")

echo Initial install setup script for Cloud Function deployment
apt-get update -y
apt-get install git kubectl -y
apt-get install python3-pip -y
pip3 install requests
echo Creating working directory and copying scripts
mkdir /work
chmod o+rwx /work 
cd /work
gsutil cp gs://spls/gsp338/monitoring-setup-script.sh /work/monitoring-setup-script.sh
chmod +x /work/monitoring-setup-script.sh
sed -i "s/us-central1/$REGION/g"  monitoring-setup-script.sh
gsutil cp gs://spls/gsp338/waitfor-monitoring.sh /work/waitfor-monitoring.sh
chmod +x /work/waitfor-monitoring.sh
echo Creating user
useradd -m user1
echo Launching Cloud Function deployment script
su -c "/work/monitoring-setup-script.sh gs://spls/gsp338" - user1
echo Signaling lab setup is complete
echo Leaving Cloud Operations dashboard setup script to run in the background waiting for user init of Cloud Monitoring
su -c "/work/waitfor-monitoring.sh" - user1
```

* VM instance `video-queue-monitor`

```bash
#!/bin/bash

export PROJECT_ID=$(gcloud config list --format 'value(core.project)')
export ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
export REGION=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-region])")

## Install Golang
sudo apt update && sudo apt -y
sudo apt-get install wget -y
sudo apt-get -y install git
sudo chmod 777 /usr/local/
sudo wget https://go.dev/dl/go1.23.0.linux-amd64.tar.gz 
sudo tar -C /usr/local -xzf go1.23.0.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin

# Install ops agent 
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
sudo bash add-google-cloud-ops-agent-repo.sh --also-install
sudo service google-cloud-ops-agent start

# Create go working directory and add go path
mkdir /work
mkdir /work/go
mkdir /work/go/cache
export GOPATH=/work/go
export GOCACHE=/work/go/cache

# Install Video queue Go source code
cd /work/go
mkdir video
gsutil cp gs://spls/gsp338/video_queue/main.go /work/go/video/main.go

# Get Cloud Monitoring (stackdriver) modules
go get go.opencensus.io
go get contrib.go.opencensus.io/exporter/stackdriver

# Configure env vars for the Video Queue processing application
export MY_PROJECT_ID=[REPLACE-WITH-PROJECT_ID]
export MY_GCE_INSTANCE_ID=[REPLACE-WITH-INSTANCE-ID]
export MY_GCE_INSTANCE_ZONE=us-east1-c

# Initialize and run the Go application
cd /work
go mod init go/video/main
go mod tidy
go run /work/go/video/main.go
```