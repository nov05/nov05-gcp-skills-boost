# 🟢 GSP049 Translate Text with the Cloud Translation API

https://www.skills.google/games/7223/labs/44690

```text
Task 1. Create an API key
Task 2. Translate text
Task 3. Detect the language
```

## 👉 Run the following command in Google Cloud Shell

```bash
rm -rf *
curl -LO https://raw.githubusercontent.com/nov05/nov05-gcp-skills-boost/refs/heads/main/bash-scripts/gsp049.sh
sudo chmod +x gsp049.sh
yes y | ./gsp049.sh 2>&1 | tee -a logs.txt
sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g' logs.txt > clean_logs.txt
```

* You can find the terminal output log sample file in this folder.
