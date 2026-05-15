# 🟢 GSP642 porting Data to a Firestore Database

https://www.skills.google/games/7172/labs/44421

```text
Task 1. Set up Firestore in Google Cloud
Task 2. Write database import code
Task 3. Create test data
Task 4. Import the test customer data
Task 5. Inspect the data in Firestore
```

### 👉 Run the following Commands in CloudShell

```bash
rm -f gsp514.sh
curl -LO https://raw.githubusercontent.com/nov05/nov05-gcp-skills-boost/refs/heads/main/bash-scripts/gsp514.sh
chmod +x gsp514.sh
./gsp514.sh 2>&1 | tee -a logs.txt
sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g' logs.txt > clean_logs.txt
```

* If we want to use `Gemini Code Assist` in the `Cloud Shell` IDE, in `Cloud Shell`, enable the Gemini for `Google Cloud API` with the following command:  
  
  ```bash
  gcloud services enable cloudaicompanion.googleapis.com
  ```