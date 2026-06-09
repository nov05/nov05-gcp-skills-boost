# 🟢 ARC134 Configure Service Accounts and IAM Roles for Google Cloud: Challenge Lab

https://www.skills.google/games/7223/labs/44687  
https://www.skills.google/course_templates/702   

```text
Task 1. Enable and Explore Gemini (optional)
Task 2. Create a service account using the gcloud CLI
Task 3. Grant IAM permissions to a service account using the gcloud CLI
Task 4. Create a compute instance with a service account attached using gcloud
Task 5. Create a custom role using a YAML file
Task 6. Use the client libraries to access BigQuery from a service account
```

## 👉 Run the following command in Google Cloud Shell.

SSH to the VM instance `lab-vm`.  

```bash
export ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
gcloud compute ssh lab-vm \
  --zone=$ZONE \
  --quiet
```
Inside the SSH session, run the following commands.

```bash
rm -rf *
curl -LO https://raw.githubusercontent.com/nov05/nov05-gcp-skills-boost/refs/heads/main/bash-scripts/arc134.sh
sudo chmod +x arc134.sh
./arc134.sh 2>&1 | tee -a logs.txt
sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g' logs.txt > clean_logs.txt
```

Run `exit` to log out the SSH session and then the following command to copy `clean_logs.txt` to the Cloud Shell.

```bash
gcloud compute scp \
  --zone=$ZONE \
  lab-vm:~/clean_logs.txt \
  ~/clean_logs.txt
```

* You can find a sample terminal output log file in this folder.

