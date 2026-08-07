

## Tips

* A **hub-and-spoke** model is a network design where one central resource (the hub) manages connections to multiple other resources (the spokes 辐条/分支). 

  E.g.  
  ```text
             VPC 1
              |
             Spoke 1
              |
  VPC 2 ---- Spoke 2 ---- HUB ---- Spoke 3 ---- VPC 3
              |
             Spoke 4
              |
             VPC 4
  ```