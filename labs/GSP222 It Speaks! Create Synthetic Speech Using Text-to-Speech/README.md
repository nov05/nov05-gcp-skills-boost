# 🟢 GSP222 It Speaks! Create Synthetic Speech Using Text-to-Speech

https://www.skills.google/games/7223/labs/44689

```text
Task 1: Enable the Text-to-Speech API
Task 2: Create a virtual environment
Task 3: Create a service account
Task 4: Get a list of available voices
Task 5: Create synthetic speech from text
Task 6: Create synthetic speech from SSML
Task 7: Configure audio output and device profiles
```

## 👉 Run the following commands in Google Cloud Shell.

```bash
rm -rf *
curl -LO https://raw.githubusercontent.com/nov05/nov05-gcp-skills-boost/refs/heads/main/bash-scripts/gsp222.sh
sudo chmod +x gsp222.sh
./gsp222.sh 2>&1 | tee -a logs.txt
sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g' logs.txt > clean_logs.txt
```


* You can find the 3 sample audio files [here](https://github.com/nov05/pictures/tree/master/gcp-skills-boost%20/gsp222).   
* You can find the terminal output log file in this folder. 