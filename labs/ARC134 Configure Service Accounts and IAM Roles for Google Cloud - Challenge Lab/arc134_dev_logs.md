## 👉 For development

* Refer to GSP647

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
curl -LO https://raw.githubusercontent.com/nov05/nov05-gcp-skills-boost/refs/heads/dev/bash-scripts/arc134.sh
sudo chmod +x arc134.sh
./gsp647.sh 2>&1 | tee -a logs.txt
sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g' logs.txt > clean_logs.txt
```

Run `exit` to log out the SSH session and then the following command to copy `clean_logs.txt` to the Cloud Shell.

```bash
gcloud compute scp \
  --zone=$ZONE \
  lab-vm:~/clean_logs.txt \
  ~/clean_logs.txt
```

## 👉 Logs

* 2026-06-08 Script `arc134.sh` created