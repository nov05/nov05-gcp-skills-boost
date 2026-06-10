# 🟢 GSP081 Cloud Run Functions: Qwik Start - Console

https://www.skills.google/games/7223/labs/44690

```text
Task 1. Create a function
Task 2. Deploy the function
Task 3. Test the function
Task 4. View logs
Task 5. Test your understanding
```

## 👉 Run the following command in Google Cloud Shell

```bash
rm -rf *
curl -LO https://raw.githubusercontent.com/nov05/nov05-gcp-skills-boost/refs/heads/main/bash-scripts/gsp081.sh
sudo chmod +x gsp081.sh
./gsp081.sh 2>&1 | tee -a logs.txt
sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g' logs.txt > clean_logs.txt
```

* You can find the terminal output log sample file in this folder.