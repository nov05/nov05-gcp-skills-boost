# 🟢 Google Skills Lab Automation  

This repository contains Google Cloud Shell Bash scripts and related materials for automating Google Skills Labs.
For more scripts, refer to [`gcp-skills-boost`](https://github.com/nov05/gcp-skills-boost#-google-skills-labs-automation).

* [**Script templates**](https://github.com/nov05/gcp-skills-boost/tree/dev/templates)

* **General example**  
  lab - [GSP330 Implement DevOps Workflows in Google Cloud](https://github.com/nov05/gcp-skills-boost/tree/main/GSP330%20Implement%20DevOps%20Workflows%20in%20Google%20Cloud%20-%20Challenge%20Lab)    
  Bash script - [nov05_GSP330.sh](https://github.com/nov05/gcp-skills-boost/blob/main/GSP330%20Implement%20DevOps%20Workflows%20in%20Google%20Cloud%20-%20Challenge%20Lab/nov05_GSP330.sh)    

* **Example of creating 1st-gen Cloud Build triggers via the CLI**    
  In this example, the script waits for the user to connect the GitHub repositories manually in `Cloud Build` before creating two triggers. It can also find the last but one successful build of a trigger and retry the build, which equals to a rollback.      
  lab - [GSP1077 Google Kubernetes Engine Pipeline using Cloud Build](https://github.com/nov05/gcp-skills-boost/tree/main/Google%20Kubernetes%20Engine%20Pipeline%20using%20Cloud%20Build)     
  Bash script - [nov05_gsp1077.sh](https://github.com/nov05/gcp-skills-boost/blob/main/Google%20Kubernetes%20Engine%20Pipeline%20using%20Cloud%20Build/nov05_gsp1077.sh)

* Example of creating 2nd-gen Cloud Run function  
  lab - GSP081 Cloud Run Functions: Qwik Start - Console  
  lab - GSP315 Set Up an App Dev Environment on Google Cloud: Challenge Lab  

* **Example of building data mesh, creating and adding Dataplex aspect to zone**    
  Bash script - [nov05_gsp514.sh](https://github.com/nov05/gcp-skills-boost/blob/dev/GSP514%20Build%20a%20Data%20Mesh%20with%20Knowledge%20Catalog:%20Challenge%20Lab/nov05_gsp514.sh)
  
* Exmaple of using a service account, a VM, and the client libraries to access BigQuery  
  lab - GSP199 Service Accounts and Roles: Fundamentals  

* Example of BigQuery and Data Quality operations    
  Bash script - [nov05_gsp1158.sh](https://github.com/nov05/gcp-skills-boost/blob/main/GSP1158%20Assessing%20Data%20Quality%20with%20Knowledge%20Catalog/nov05_gsp1158.sh)

* Example of creating Dataplex aspect and adding to BigQuery table and column   
  Bash script - [nov05_gsp1145.sh](https://github.com/nov05/gcp-skills-boost/blob/main/GSP1145%20Create%20and%20Add%20Aspects%20to%20Knowledge%20Catalog%20Assets/nov05_gsp1145.sh)   

* Example of migrating monolith website to microservices on K8s Engines    
  folder - [GSP699](https://github.com/nov05/gcp-skills-boost/tree/main/Migrating%20a%20Monolithic%20Website%20to%20Microservices%20on%20Google%20Kubernetes%20Engine)  

* Example of ensuring VM running status and SSH readiness   
  Bash script - [nov05_GSP004.sh](https://github.com/nov05/gcp-skills-boost/blob/main/Creating%20a%20Persistent%20Disk/nov05_GSP004.sh)

* Example of ensuring service account readiness   
  bash script - [nov05_gsp097.sh](https://github.com/nov05/gcp-skills-boost/blob/main/Cloud%20Natural%20Language%20API%3A%20Qwik%20Start/nov05_gsp097.sh)       
* Example of calling APIs from a VM   
  Bash script - [nov05_gsp038.sh](https://github.com/nov05/gcp-skills-boost/blob/main/Entity%20and%20Sentiment%20Analysis%20with%20the%20Natural%20Language%20API/nov05_gsp038.sh)

* Example of creating a Firebase app, writing and reading a Firestore document    
  Bash script - [nov05_gsp1136.sh](https://github.com/nov05/gcp-skills-boost/blob/main/GSP1136%20Getting%20Started%20with%20Firebase%20Cloud%20Firestore/nov05_gsp1136.sh)

* Example of deploying serverless Firebase app on k8s   
  Bash script - [nov05_gsp334.sh](https://github.com/nov05/gcp-skills-boost/blob/dev/GSP344%20Develop%20Serverless%20Apps%20with%20Firebase%3A%20Challenge%20Lab/nov05_gsp344.sh)   

* Example of frontend runtime environment variables injection with React and k8s    
  folder - [Develop Serverless Apps with Firebase: Challenge Lab (GSP344)](https://github.com/nov05/nov05-gcp-skills-boost/tree/main/labs/GSP344%20Develop%20Serverless%20Apps%20with%20Firebase%20-%20Challenge%20Lab)    
  Bash script - [gsp344.sh](https://github.com/nov05/nov05-gcp-skills-boost/blob/main/bash-scripts/gsp344.sh)     
  JavaScript - [firebase-frontend](https://github.com/nov05/gcp-skills-pet-theory/tree/main/lab06/firebase-frontend)    

* Example of building infrascture with Terraform  
  folder - [Build Infrastructure with Terraform on Google Cloud: Challenge Lab (GSP345)](https://github.com/nov05/nov05-gcp-skills-boost/tree/main/labs/GSP345%20Build%20Infrastructure%20with%20Terraform%20on%20Google%20Cloud%20-%20Challenge%20Lab)    
  Bash script - [gsp345.sh](https://github.com/nov05/nov05-gcp-skills-boost/blob/main/bash-scripts/gsp345.sh)   

<br><br><br>

## 👉 Information 

* [Google Developer Program forums](https://discuss.google.dev/)    

* [Google Skills Arcade](https://go.cloudskillsboost.google/arcade)   
  - [Google Skills Arcade information](https://docs.google.com/document/d/17iMpVCALHSoYOevKprBKqasOMGgkyA5Mwk2hxtJmxmo)  

* To make changes to this repo in `VS Code`, download the following repositories.   
  In `VS Code`, `File -> Open Workspace from file...`, select `vscode-workspaces\gcp-skills-boost.code-workspace`.  

  - https://github.com/nov05/vscode-workspaces
  - https://github.com/nov05/nov05-gcp-skills-boost  
  - https://github.com/nov05/gcp-skills-pet-theory