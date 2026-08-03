## 👉 For development:

```bash
export ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
gcloud compute ssh "centos-clean" \
  --zone=$ZONE \
  --quiet
```

Inside the SSH session, run the following commands.

```bash
rm -rf *
curl -LO https://raw.githubusercontent.com/nov05/nov05-gcp-skills-boost/refs/heads/dev/bash-scripts/gsp647.sh
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

## Logs

* 2026-08-03 Fnished the lab again. Zone1 was previously the default zone; it is now entered manually.   

* 2026-06-08 Finished the lab. Figured out the grader uses `./bashrc` to store environment variables $ZONE2, $USERID2, $PROJECTID2, and OS login should be enabled for VM instance "centos-clean".  

* 2026-06-07 I wasn't able to pass the 2nd check of Task 1.