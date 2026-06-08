## 👉 For development:

```bash
export ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
gcloud compute instances add-metadata "centos-clean" \
  --zone=$ZONE \
  --metadata enable-oslogin=FALSE
gcloud compute ssh "centos-clean" \
  --zone=$ZONE \
  --quiet
```

Inside the SSH session, run the following commands.

```bash
rm -f gsp647.sh logs.txt clean_logs.txt
curl -LO https://raw.githubusercontent.com/nov05/nov05-gcp-skills-boost/refs/heads/dev/bash-scripts/gsp647.sh
sudo chmod +x gsp647.sh
./gsp647.sh 2>&1 | tee -a logs.txt
sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g' logs.txt > clean_logs.txt
```