# 🟢 GSP647 Configuring IAM Permissions with gcloud

```text
Task 1. Configure the gcloud environment
Task 2. Create and switch between multiple IAM configurations
Task 3. Identify and assign correct IAM permissions
Task 4. Test that user2 has access
Task 5. Using a service account
Task 6. Using the service account with a compute instance
Task 7. Test the service account
```

## 👉 Run the following commands in Google Cloud Shell. 

SSH to the VM instance `centos-clean`.  

```bash
export ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
gcloud compute ssh "centos-clean" \
  --zone=$ZONE \
  --quiet
```

Inside the SSH session, run the following commands.

```bash
rm -f gsp647.sh clean_logs.txt
curl -LO https://raw.githubusercontent.com/nov05/nov05-gcp-skills-boost/refs/heads/main/bash-scripts/gsp647.sh
sudo chmod +x gsp647.sh
./gsp647.sh 2>&1 | tee -a logs.txt
sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g' logs.txt > clean_logs.txt
```

Run `exit` to log out the SSH session and then the following command to copy `clean_logs.txt` to the Cloud Shell.

```bash
gcloud compute scp \
  --zone=$ZONE \
  centos-clean:~/clean_logs.txt \
  ~/clean_logs.txt
```

* You can find a sample log file in this folder.  
* The final landscape  
  <img src="https://raw.githubusercontent.com/nov05/pictures/refs/heads/master/gcp-skills-boost%20/gsp647/gsp647_landscape.jpg" width=500>
