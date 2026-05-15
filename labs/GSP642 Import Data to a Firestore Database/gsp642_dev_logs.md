## 👉 For development

```bash
rm -f gsp514.sh
curl -LO https://raw.githubusercontent.com/nov05/nov05-gcp-skills-boost/refs/heads/dev/bash-scripts/gsp514.sh
chmod +x gsp514.sh
./gsp514.sh 2>&1 | tee -a logs.txt
sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g' logs.txt > clean_logs.txt
```

## 👉 Logs

* 2026-05-15 Changed and tested `bash-scripts/gsp642.sh`.  