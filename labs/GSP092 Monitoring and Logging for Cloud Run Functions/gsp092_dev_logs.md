## 👉 For development

```bash
rm -rf *
curl -LO https://raw.githubusercontent.com/nov05/nov05-gcp-skills-boost/refs/heads/dev/bash-scripts/gsp092.sh
sudo chmod +x gsp092.sh
./gsp092.sh 2>&1 | tee -a logs.txt
sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g' logs.txt > clean_logs.txt
```


## 👉 Logs

* 2026-06-11 Script `gsp092.sh` created and tested


## Tips

| Field            | Value                                                   |
|------------------|---------------------------------------------------------|
| Name             | logging/user/CloudRunFunctionLatency-Logs              |
| Description      | Metric                                                  |
| Metric           | logging.googleapis.com/user/CloudRunFunctionLatency-Logs |
| Resource types   | cloud_run_revision                                     |
| Unit             | 1                                                       |
| Kind             | DELTA                                                   |
| Value type       | DISTRIBUTION                                            |

