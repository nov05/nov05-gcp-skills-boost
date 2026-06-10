# 🟢 ARC132 Implement Speech and Language Solutions with Pre-trained APIs: Challenge Lab

https://www.skills.google/games/7223/labs/44692   
https://www.skills.google/course_templates/700/labs/625113   

```text
Task 1. Create an API key
Task 2. Create synthetic speech from text using the Text-to-Speech API
Task 3. Perform speech to text transcription with the Cloud Speech API
Task 4. Translate text with the Cloud Translation API
Task 5. Detect a language with the Cloud Translation API
```

## 👉 Run the following commands in Google Cloud Shell.

```bash
rm -rf *
curl -LO https://raw.githubusercontent.com/nov05/nov05-gcp-skills-boost/refs/heads/main/bash-scripts/arc132.sh
sudo chmod +x arc132.sh
./arc132.sh 2>&1 | tee -a logs.txt
sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g' logs.txt > clean_logs.txt
```

* You can find a terminal output log sample file in this folder.  