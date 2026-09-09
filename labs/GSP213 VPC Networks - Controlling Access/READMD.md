# 🟢 GSP213 VPC Networks - Controlling Access

## 👉 Run the following command in Google Cloud Shell

```bash
rm -rf *
curl -LO https://raw.githubusercontent.com/nov05/nov05-gcp-skills-boost/refs/heads/main/bash-scripts/gsp213.sh
sudo chmod +x gsp213.sh
yes y | ./gsp213.sh 2>&1 | tee -a logs.txt
sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g' logs.txt > clean_logs.txt
```

## 👉 Lab information  

```text
Task 1. Create the web servers
Task 2. Create the firewall rule
Task 3. Explore the Network and Security Admin roles
```

```text
                         Google Cloud
                              |
                       +------+------+
                       | VPC: default|
                       +------+------+
                              |
          +-------------------+-------------------+
          |                   |                   |
          v                   v                   v
    +-----------+       +-----------+       +-----------+
    | VM: blue  |       | VM: green |       | VM:test-vm|
    |   nginx   |       |   nginx   |       | curl/gcloud|
    | tag:      |       | no tag    |       +-----+-----+
    | web-server|       +-----------+             |
    +-----+-----+                                 |
          ^                                        |
          |                                        |
    +-----+-----------+                            |
    | Firewall Rule   |<---------------------------+
    | allow-http-     |
    | web-server      |
    | TCP:80 / ICMP   |
    +-----------------+

       Task 1              Task 2              Task 3
    VM + nginx          Firewall Rule        IAM Roles
                                           Network Admin
                                           Security Admin
```

| IAM Role       | List | Create | Modify | Delete |
| -------------- | ---: | -----: | -----: | -----: |
| Network Admin  |    ✓ |      — |      — |      — |
| Security Admin |    ✓ |      ✓ |      ✓ |      ✓ |

