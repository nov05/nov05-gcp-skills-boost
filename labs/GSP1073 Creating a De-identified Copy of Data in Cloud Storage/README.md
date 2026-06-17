# 🟢 GSP1073 Creating a De-identified Copy of Data in Cloud Storage

https://www.skills.google/games/7224/labs/44703

```text
Task 1. Create de-identify templates
Task 2. Create a DLP inspection job trigger
Task 3. Run DLP Inspection and review results
```

## 👉 Run the following command in Google Cloud Shell

```bash
rm -rf *
curl -LO https://raw.githubusercontent.com/nov05/nov05-gcp-skills-boost/refs/heads/main/bash-scripts/gsp1073.sh
sudo chmod +x gsp1073.sh
yes y | ./gsp1073.sh 2>&1 | tee -a logs.txt
sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g' logs.txt > clean_logs.txt
```