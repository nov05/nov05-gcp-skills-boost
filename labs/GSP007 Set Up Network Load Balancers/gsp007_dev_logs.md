## 👉 For development

```bash
rm -rf *
curl -LO https://raw.githubusercontent.com/nov05/nov05-gcp-skills-boost/refs/heads/dev/bash-scripts/gsp007.sh
sudo chmod +x gsp007.sh
./gsp007.sh 2>&1 | tee -a logs.txt
sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g' logs.txt > clean_logs.txt
```


## 👉 Logs

* 2026-06-16 Script `gsp007.sh` created


## Tips

ChatGPT:  

| Feature                  | L4 Load Balancer         | L7 Load Balancer |
| ------------------------ | ------------------------ | ---------------- |
| Layer                    | Transport                | Application      |
| Understands HTTP?        | ❌ No                    | ✅ Yes          |
| Routing based on URL     | ❌ No                    | ✅ Yes          |
| Routing based on IP/port | ✅ Yes                   | ✅ Yes          |
| Speed                    | Very fast                | Slightly slower  |
| Complexity               | Low                      | High             |
| Smart features           | Minimal                  | Advanced         |
| Typical use              | Raw traffic distribution | Web/API routing  |

L4 Network Load Balancer = fast packet forwarding  
L7 Application Load Balancer = intelligent HTTP routing  

- Use L4 when:  
    You want speed  
    You don’t care about request content  
    You’re handling TCP/UDP or simple HTTP  
- Use L7 when:  
    You need routing logic  
    You have microservices  
    You need modern web features (A/B testing, HTTPS termination)  