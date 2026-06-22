# 🟢 GSP539 Build Global and Regional Load Balancing Solutions: Challenge Lab

https://www.skills.google/games/7225/labs/44716   
https://www.skills.google/course_templates/1558/labs/612203   

```text
Task 1. Secure internal transaction processor (regional internal proxy NLB)
Task 2. Global external market data feed (global external application Load Balancer)
Task 3. Test failover and global distribution
```

## 👉 Run the following command in Google Cloud Shell

```bash
rm -rf *
curl -LO https://raw.githubusercontent.com/nov05/nov05-gcp-skills-boost/refs/heads/main/bash-scripts/gsp539.sh
sudo chmod +x gsp539.sh
./gsp539.sh 2>&1 | tee -a logs.txt
sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g' logs.txt > clean_logs.txt
```

* This lab can be fully automated by the Bash script.    
* A terminal output log sample file can be found in this folder.    

## Additional information  

* **Task 1**, Regional internal Network Load Balancer with regional access (glocal access in the figure)     
  https://docs.cloud.google.com/load-balancing/docs/l7-internal/setting-up-l7-internal   
  <img src="https://raw.githubusercontent.com/nov05/pictures/f966f106ed1af62c448b8ec7426b0a5d7fba91a8/gcp-skills-boost/gsp539/proxy-ilb-global-access-arch.svg" width=800>  

* **Task 2**, External Application Load Balancer with a managed instance group (MIG) backend   
  https://docs.cloud.google.com/load-balancing/docs/https/setup-global-ext-https-compute  
  <img src="https://raw.githubusercontent.com/nov05/pictures/ca42485c1ab8d50d02cbfe5a6cdcb0107dc17262/gcp-skills-boost/gsp539/https-load-balancer-simple-gxlb.svg" width=800>  

* Lab resource landscape  
  ```bash
  NLB = Network Load Balancer (L4)
  ALB = Application Load Balancer (L7)
  MIG = Managed Instance Group
  VM = Virtual Machine
  /
  └── GCP project/
      ├── VPC network: lb-network (lab pre-created)
      │    ├── Subnet: proxy-subnet-internal (Task 1, lab pre-created)
      │    │
      │    ├── Region A/
      │    │   ├── Subnet: lb-backend-subnet-region-a (Task 1, lab pre-created)
      │    │   │
      │    │   └── MIG: mig-alb-api-a (Task 2)
      │    │       ├── Global template: template-alb-api (lab pre-created)
      │    │       |   └── Network tags: allow-ssh, tag-alb-api, http-server
      │    │       ├── VM: nginx-instance-1
      │    │       ├── VM: nginx-instance-2
      │    │       └── Named port: http80:80
      │    │
      │    ├── Region B/
      │    │   ├── Subnet: lb-backend-subnet-region-b (Task 1, lab pre-created)
      │    │   │
      │    │   ├── MIG template: template-proxy-internal (Task 1, lab pre-created) 
      │    │   │
      │    │   ├── MIG: mig-proxy-internal (Task 1, lab pre-defined name)/
      │    │   │   ├── Regional template: template-proxy-internal (lab pre-created)
      │    │   │   │   └── Network tags: allow-ssh, tag-proxy-internal (lab pre-defined)
      │    │   │   ├── VM: tvs-backend-1
      │    │   │   ├── VM: tvs-backend-2
      │    │   │   └── Named port: tcp80:80
      │    │   │
      │    │   ├── VM: vm-client-internal (Task 1, lab pre-defined name)
      │    │   │   └── Network tags: allow-ssh (lab pre-defined)
      │    │   │
      │    │   └── 👉 Load balancer: Regional Internal Proxy NLB (Task 1)
      │    │       └── Backend service: bs-internal-proxy 
      │    │           ├── health check: hc-internal-proxy
      │    │           ├── Internal static IP: ip-internal-proxy
      │    │           └── Internal forwarding rule TCP/110: rule-internal-proxy 
      │    │
      │    └── Firewall rules/
      │        ├── fw-internal-health TCP/80 (Task 1, lab pre-defined name)
      │        │   └── Target tag: tag-proxy-internal
      │        └── fw-internal-proxy TCP/80 (Task 1, lab pre-defined name)
      │            └── Target tag: tag-proxy-internal
      │    
      └── VPC network: default (Task 2, GCP created)
          ├── Global/
          │   ├── MIG template: template-alb-api (Task 2, lab pre-created)
          │   │   └── Network tags: http-server, allow-ssh, tag-alb-api (lab pre-defined)
          │   │
          │   ├── MIG: mig-alb-api-b (Task 2, lab pre-defined name)
          │   │   ├── Global template: template-alb-api (lab pre-created)
          │   │   |   └── Network tags: allow-ssh, tag-alb-api, http-server (lab pre-defined)
          │   │   ├── VM: nginx-instance-1
          │   │   ├── VM: nginx-instance-2
          │   │   └── Named port: http80:80
          │   │
          │   └── 👉 Load balancer: Global External HTTPS ALB (Task 2)
          │       ├── Backend service: service-alb-global (lab pre-defined name)
          │       │   └── Health check: http-check-alb (lab pre-defined name)
          │       └── Frontend service
          │           ├── HTTPS proxy: https-proxy-alb
          │           │   ├── URL map: url-map-alb
          │           │   └── SSL certificates: cert-self-signed (lab pre-defined name)
          │           ├── External static IP: ip-alb-global (lab pre-defined name)
          │           └── External forwarding rule: rule-alb-global
          │
          └── Firewall rules/
              ├── fw-allow-ssh (Task 1 and 2, lab pre-created)
              │   └── Target tag: allow-ssh
              └── fw-allow-health-check-and-proxy (Task 2, lab pre-defined name)
                  └── Target tag: tag-alb-api
  ```
