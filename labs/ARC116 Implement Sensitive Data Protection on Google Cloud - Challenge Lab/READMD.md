# 🟢 ARC116 Implement Sensitive Data Protection on Google Cloud: Challenge Lab

https://www.skills.google/games/7224/labs/44704     
https://www.skills.google/course_templates/750/labs/598981   

```text
Task 1. Redact sensitive data from text content
Task 2. Create DLP inspection templates
Task 3. Configure a job trigger to run DLP inspection
```

## 👉 Run the following command in Google Cloud Shell

```bash
rm -rf *
curl -LO https://raw.githubusercontent.com/nov05/nov05-gcp-skills-boost/refs/heads/main/bash-scripts/arc116.sh
sudo chmod +x arc116.sh
yes y | ./arc116.sh 2>&1 | tee -a logs.txt
sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g' logs.txt > clean_logs.txt
```

* This lab can be fully automated with the Bash script.  