# 🟢 Build Infrastructure with Terraform on Google Cloud: Challenge Lab (GSP345)

https://www.skills.google/focuses/42740
https://www.skills.google/course_templates/636/labs/592700

```text
Task 1. Create the configuration files
Task 2. Import infrastructure
Task 3. Configure a remote backend
Task 4. Modify and update infrastructure
Task 5. Destroy resources
Task 6. Use a module from the Registry
Task 7. Configure a firewall
```

## 👉 Run the following commands in Cloud Shell

```bash
rm -f gsp345.sh
curl -LO https://raw.githubusercontent.com/nov05/nov05-gcp-skills-boost/refs/heads/dev/bash-scripts/gsp345.sh
chmod +x gsp345.sh
./gsp345.sh 2>&1 | tee -a logs.txt
sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g' logs.txt > clean_logs.txt
```

* Check [the example Google Cloud terminal output logs](https://github.com/nov05/nov05-gcp-skills-boost/blob/main/labs/GSP345%20Build%20Infrastructure%20with%20Terraform%20on%20Google%20Cloud%20-%20Challenge%20Lab/clean_logs.txt).  
* Check [the YouTube video demo](https://www.youtube.com/watch?v=yzIAZQlkk1U). 