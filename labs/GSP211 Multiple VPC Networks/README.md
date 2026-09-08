# 🟢 **GSP211 Multiple VPC Networks**   


## 👉 Run the following command in Google Cloud Shell

```bash
rm -rf *
curl -LO https://raw.githubusercontent.com/nov05/nov05-gcp-skills-boost/refs/heads/main/bash-scripts/gsp211.sh
sudo chmod +x gsp211.sh
yes y | ./gsp211.sh 2>&1 | tee -a logs.txt
sed -r 's/\x1B\[[0-9;]*[a-zA-Z]//g' logs.txt > clean_logs.txt
```

## 👉 Lab information 

There are **4 main tasks** in the Google Cloud **Multiple VPC Networks (GSP211)** lab:

1. **Create custom mode VPC networks with firewall rules**

   * Create `managementnet` and `privatenet`
   * Create their subnets
   * Configure firewall rules for ICMP, SSH (22), and RDP (3389)

2. **Create VM instances**

   * Create `managementnet-vm-1`
   * Create `privatenet-vm-1`

3. **Explore connectivity between VM instances**

   * Test connectivity using **external IP addresses**
   * Test connectivity using **internal IP addresses**
   * Understand how VPC isolation affects connectivity

4. **Create a VM instance with multiple network interfaces**

   * Create `vm-appliance`
   * Attach it to `privatenet`, `managementnet`, and `mynetwork`
   * Explore its network interfaces and routing
   * Test connectivity across the connected networks

**In short:**
Task 1 = Networks & firewalls  
Task 2 = VMs   
Task 3 = Connectivity    
Task 4 = Multiple NICs (Network Interface Controller)

<img src="https://raw.githubusercontent.com/nov05/pictures/4ed6dfd7ef8b3ad2389295c1a195e91492ca699c/gcp-skills-boost/gsp211/Gemini_Generated_Image_f9jf30f9jf30f9jf.jpg" width=800>  

For the lab:  

```text
                 ┌── NIC0 ──> privatenet
vm-appliance ────┼── NIC1 ──> managementnet
                 └── NIC2 ──> mynetwork
```

Think it this way:  

```text
VM → VPC: through a NIC
VPC → VPC: through VPC Peering (or VPN/other connectivity mechanisms)
VM with multiple NICs → multiple VPCs: one NIC per VPC
```