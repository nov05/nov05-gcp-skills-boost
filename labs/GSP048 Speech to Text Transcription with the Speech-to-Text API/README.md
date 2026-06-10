# 🟢 GSP048 Speech to Text Transcription with the Speech-to-Text API

https://www.skills.google/games/7223/labs/44691

```text
Task 1. Create an API key
Task 2. Create your API request
Task 3. Call the Speech-to-Text API
Task 4. Speech-to-Text transcription in different languages
```

## 👉 Run the following command in Google Cloud Shell

```bash
rm -rf *
curl -LO https://raw.githubusercontent.com/nov05/nov05-gcp-skills-boost/refs/heads/main/bash-scripts/gsp048.sh
sudo chmod +x gsp048.sh
./gsp048.sh 2>&1 | tee -a logs.txt
sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g' logs.txt > clean_logs.txt
```

* You can find the terminal output log sample file in this folder.