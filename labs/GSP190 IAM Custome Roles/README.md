# 🟢 GSP190 IAM Custom Roles

https://www.skills.google/games/7223/labs/44686

```text
Task 1. View the available permissions for a resource
Task 2. Get the role metadata
Task 3. View the grantable roles on resources
Task 4. Create a custom role
Task 5. List the custom roles
Task 6. Update an existing custom role
Task 7. Disable a custom role
Task 8. Delete a custom role
Task 9. Restore a custom role
```

## 👉 Run the following commands in Google Cloud Shell.

```bash
rm -rf *
curl -LO https://raw.githubusercontent.com/nov05/nov05-gcp-skills-boost/refs/heads/main/bash-scripts/gsp190.sh
sudo chmod +x gsp190.sh
yes y | ./gsp190.sh 2>&1 | tee -a logs.txt
sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g' logs.txt > clean_logs.txt
```

* You can find a sample log file in this folder.  