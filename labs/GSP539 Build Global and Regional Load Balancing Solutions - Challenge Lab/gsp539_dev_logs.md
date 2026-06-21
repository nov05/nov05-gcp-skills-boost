## 👉 For development

```bash
rm -rf *
curl -LO https://raw.githubusercontent.com/nov05/nov05-gcp-skills-boost/refs/heads/dev/bash-scripts/gsp539.sh
sudo chmod +x gsp539.sh
./gsp539.sh 2>&1 | tee -a logs.txt
sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g' logs.txt > clean_logs.txt
```


## Logs  

* 2026-06-21 Bash script tested and lab passed 


## Tips  

* 2026-06-21 You need to create these instance groups for the lab.  
  <img src="https://raw.githubusercontent.com/nov05/pictures/refs/heads/master/gcp-skills-boost/gsp539/2026-06-21%2017_47_43-Settings.jpg" width=800>   

  For Task 3, you need to simulate a backend failure on the instance group in Region A. You will see the following results.  
  <img src="https://raw.githubusercontent.com/nov05/pictures/refs/heads/master/gcp-skills-boost/gsp539/task3.jpg" width=800>   

* 2026-06-21 【🟢 Issue solved: Task 2 uses the `default` VPC network rather than `lb-network`. `lb-network` is used only for Task 1.】The health check issue persists. Yesterday i got "**no healthy upstream**" and now I got "**unconditional drop overload**" when open https://35.241.15.107/ in the browser.  

  - A "no healthy upstream" or "unhealthy upstream" error on a Google Cloud Platform (GCP) Load Balancer means the load balancer proxies cannot find a single backend instance passing its designated health check. Because the health check is down, the load balancer completely blocks traffic to prevent sending requests to a broken server. This issue is typically caused by missing firewall rules, mismatched app configurations, or SSL handshake failures. SSH into your instance and run `netstat -tuln` or `ss -tuln` to confirm the application is listening on `*:PORT` or `0.0.0.0:PORT`
  ```bash
  student-02-8c8060b576bb@mig-alb-api-a-w5g5:~$ netstat -tuln
  Active Internet connections (only servers)
  Proto Recv-Q Send-Q Local Address           Foreign Address         State      
  tcp        0      0 127.0.0.1:25            0.0.0.0:*               LISTEN     
  tcp        0      0 0.0.0.0:5355            0.0.0.0:*               LISTEN     
  tcp        0      0 127.0.0.53:53           0.0.0.0:*               LISTEN     
  tcp        0      0 0.0.0.0:80              0.0.0.0:*               LISTEN     
  tcp        0      0 127.0.0.54:53           0.0.0.0:*               LISTEN     
  tcp        0      0 0.0.0.0:22              0.0.0.0:*               LISTEN     
  tcp6       0      0 :::5355                 :::*                    LISTEN     
  tcp6       0      0 ::1:25                  :::*                    LISTEN     
  tcp6       0      0 :::80                   :::*                    LISTEN     
  tcp6       0      0 :::22                   :::*                    LISTEN     
  udp        0      0 0.0.0.0:5355            0.0.0.0:*                          
  udp        0      0 127.0.0.54:53           0.0.0.0:*                          
  udp        0      0 127.0.0.53:53           0.0.0.0:*                          
  udp        0      0 10.128.0.3:68           0.0.0.0:*                          
  udp6       0      0 :::5355                 :::* 
  ```

  - The "unconditional drop overload" error on a Google Cloud Platform (GCP) load balancer indicates that the downstream load balancer has zero valid or reachable backends to handle incoming traffic. Despite the word "overload," this error is almost always a symptom of a broken Network Endpoint Group (NEG) state or a configuration mismatch rather than an actual traffic capacity issue.  

  I SSHed into a backend VM and `curl localhost:80` to confirm the Nginx service is running normally. And both commands return the same result.
  ```bash
  curl -i http://localhost/ 
  curl -i http://localhost/index.html
  ```
  ```bash  
  student-04-5fc135e005c8@mig-alb-api-b-p99x:~$ curl localhost:80
  <h1>Hello from: mig-alb-api-b-p99x!</h1>
  <p>Served by a Global ALB.</p> 
  ```

