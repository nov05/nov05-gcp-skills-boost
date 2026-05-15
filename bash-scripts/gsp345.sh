#!/bin/bash
## Created by nov05, 2026-05-14

# Define color variables
BLACK=`tput setaf 0`
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
BLUE=`tput setaf 4`
MAGENTA=`tput setaf 5`
CYAN=`tput setaf 6`
WHITE=`tput setaf 7`

BG_BLACK=`tput setab 0`
BG_RED=`tput setab 1`
BG_GREEN=`tput setab 2`
BG_YELLOW=`tput setab 3`
BG_BLUE=`tput setab 4`
BG_MAGENTA=`tput setab 5`
BG_CYAN=`tput setab 6`
BG_WHITE=`tput setab 7`

BOLD=`tput bold`
RESET=`tput sgr0`

# Get required variables from user
read -p "${YELLOW}${BOLD}Enter your bucket name: ${RESET}" BUCKET
read -p "${YELLOW}${BOLD}Enter your VM instance name: ${RESET}" INSTANCE
read -p "${YELLOW}${BOLD}Enter your VPC name: ${RESET}" VPC

export BUCKET
export INSTANCE
export VPC

# cat >> ~/.bashrc <<'EOF'
## Get project id, project number, region, zone
export PROJECT_ID=$(gcloud config get-value project)
export PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID \
  --format='value(projectNumber)')
export REGION=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-region])")
export ZONE=$(gcloud compute project-info describe \
  --format="value(commonInstanceMetadata.items[google-compute-default-zone])")
# export BUCKET="$PROJECT_ID-bucket"
# gcloud config set project $(gcloud projects list --format='value(PROJECT_ID)' --filter='qwiklabs-gcp')
gcloud config set project $PROJECT_ID  
gcloud config set compute/region $REGION
echo
echo "🔹  Project ID: $PROJECT_ID"
echo "🔹  Project number: $PROJECT_NUMBER"
echo "🔹  Region: $REGION"
echo "🔹  Zone: $ZONE"
echo "🔹  User: $USER"
# echo "🔹  Bukect: $BUCKET"
echo
# EOF
# source ~/.bashrc

gcloud auth list

instances_output=$(gcloud compute instances list --format="value(id)")
# Read the instance IDs into variables
IFS=$'\n' read -r -d '' instance_id_1 instance_id_2 <<< "$instances_output"
# Output instance IDs with custom name
export INSTANCE_ID_1=$instance_id_1
export INSTANCE_ID_2=$instance_id_2
echo "🔹  Instance ID 1: $instance_id_1"
echo "🔹  Instance ID 2: $instance_id_2"

cat << 'EOF'

========================================================
Task 1. Create the configuration files
========================================================

EOF

cd ~
touch main.tf
touch variables.tf
mkdir modules
cd modules
mkdir instances
cd instances
touch instances.tf
touch outputs.tf
touch variables.tf
cd ..
mkdir storage
cd storage
touch storage.tf
touch outputs.tf
touch variables.tf

cd ~

cat > variables.tf <<EOF
variable "region" {
  default = "$REGION"
}

variable "zone" {
  default = "$ZONE"
}

variable "project_id" {
  default = "$PROJECT_ID"
}
EOF

cat > main.tf <<EOF
terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "4.53.0"
    }
  }
}

provider "google" {
  project     = var.project_id
  region      = var.region
  zone        = var.zone
}

module "instances" {
  source     = "./modules/instances"
}
EOF

terraform init 

cat << 'EOF'

========================================================
Task 2. Import infrastructure
========================================================

EOF

export MACHINE_TYPE_1=$(gcloud compute instances describe tf-instance-1 \
  --zone=$ZONE \
  --format='value(machineType.basename())')
echo "VM instance tf-instance-1 machine type: $MACHINE_TYPE_1"

export MACHINE_TYPE_2=$(gcloud compute instances describe tf-instance-2 \
  --zone=$ZONE \
  --format='value(machineType.basename())')
echo "VM instance tf-instance-2 machine type: $MACHINE_TYPE_2"

cd ~/modules/instances/

cat > instances.tf <<EOF
resource "google_compute_instance" "tf_instance_1" {
  name         = "tf-instance-1"
  machine_type = "$MACHINE_TYPE_1"
  zone         = "$ZONE"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    network = "default"
  }
  metadata_startup_script = <<-EOT
        #!/bin/bash
    EOT
  allow_stopping_for_update = true
}

resource "google_compute_instance" "tf_instance_2" {
  name         = "tf-instance-2"
  machine_type = "$MACHINE_TYPE_2"
  zone         = "$ZONE"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    network = "default"
  }
  metadata_startup_script = <<-EOT
        #!/bin/bash
    EOT
  allow_stopping_for_update = true
}
EOF

cd ~

# terraform import module.instances.google_compute_instance.tf-instance-1 $INSTANCE_ID_1
# terraform import module.instances.google_compute_instance.tf-instance-2 $INSTANCE_ID_2
terraform import module.instances.google_compute_instance.tf_instance_1 $INSTANCE_ID_1
terraform import module.instances.google_compute_instance.tf_instance_2 $INSTANCE_ID_2

terraform plan
terraform apply --auto-approve

cat << 'EOF'

========================================================
Task 3. Configure a remote backend
========================================================

EOF

cd ~/modules/storage/

## Changed by nov05, 2026-05-14
## resource "google_storage_bucket" "storage-bucket" { ->
##   resource "google_storage_bucket" "storage_bucket" {

cat > storage.tf <<EOF
resource "google_storage_bucket" "storage_bucket" {
  name          = "$BUCKET"
  location      = "US"
  force_destroy = true
  uniform_bucket_level_access = true
}
EOF

cd ~

cat > main.tf <<EOF
terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "4.53.0"
    }
  }
}

provider "google" {
  project     = var.project_id
  region      = var.region
  zone        = var.zone
}

module "instances" {
  source     = "./modules/instances"
}

module "storage" {
  source     = "./modules/storage"
}
EOF

## The backend bucket must already exist before Terraform can use it as a remote backend.
terraform init
terraform apply --auto-approve

cat > main.tf <<EOF
terraform {
  backend "gcs" {
    bucket  = "$BUCKET"
    prefix  = "terraform/state"
  }
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "4.53.0"
    }
  }
}

provider "google" {
  project     = var.project_id
  region      = var.region
  zone        = var.zone
}

module "instances" {
  source     = "./modules/instances"
}

module "storage" {
  source     = "./modules/storage"
}
EOF

echo "yes" | terraform init

cat << 'EOF'

========================================================
Task 4. Modify and update infrastructure
========================================================

EOF

cd ~/modules/instances/

cat > instances.tf <<EOF
resource "google_compute_instance" "tf_instance_1" {
  name         = "tf-instance-1"
  machine_type = "e2-standard-2"
  zone         = "$ZONE"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
 network = "default"
  }
  metadata_startup_script = <<-EOT
        #!/bin/bash
    EOT
  allow_stopping_for_update = true
}

resource "google_compute_instance" "tf_instance_2" {
  name         = "tf-instance-2"
  machine_type = "e2-standard-2"
  zone         = "$ZONE"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    network = "default"
  }
  metadata_startup_script = <<-EOT
        #!/bin/bash
    EOT
  allow_stopping_for_update = true
}

## resource "google_compute_instance" "$INSTANCE" {
resource "google_compute_instance" "tf_instance_3" {
  name         = "$INSTANCE"
  machine_type = "e2-standard-2"
  zone         = "$ZONE"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
 network = "default"
  }
  metadata_startup_script = <<-EOT
        #!/bin/bash
    EOT
  allow_stopping_for_update = true
}
EOF

cd ~

terraform init
terraform apply --auto-approve

cat << 'EOF'

========================================================
Task 5. Destroy resources
========================================================

EOF

## terraform taint module.instances.google_compute_instance.$INSTANCE
terraform taint module.instances.google_compute_instance.tf_instance_3
terraform plan
terraform apply --auto-approve

cat << 'EOF'

========================================================
Task 6. Use a module from the Registry
========================================================

EOF

cd ~/modules/instances/

cat > instances.tf <<EOF
resource "google_compute_instance" "tf_instance_1" {
  name         = "tf-instance-1"
  machine_type = "e2-standard-2"
  zone         = "$ZONE"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
 network = "default"
  }
  metadata_startup_script = <<-EOT
        #!/bin/bash
    EOT
  allow_stopping_for_update = true
}

resource "google_compute_instance" "tf_instance_2" {
  name         = "tf-instance-2"
  machine_type = "e2-standard-2"
  zone         = "$ZONE"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
 network = "default"
  }
  metadata_startup_script = <<-EOT
        #!/bin/bash
    EOT
  allow_stopping_for_update = true
}
EOF

cd ~
terraform apply --auto-approve

cat > main.tf <<EOF
terraform {
  backend "gcs" {
    bucket  = "$BUCKET"
    prefix  = "terraform/state"
  }
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "4.53.0"
    }
  }
}

provider "google" {
  project     = var.project_id
  region      = var.region
  zone        = var.zone
}

module "instances" {
  source     = "./modules/instances"
}

module "storage" {
  source     = "./modules/storage"
}

module "vpc" {
    ## remote module source
    source  = "terraform-google-modules/network/google"
    version = "~> 6.0.0"

    project_id   = "$PROJECT_ID"
    network_name = "$VPC"
    routing_mode = "GLOBAL"

    subnets = [
        {
            subnet_name           = "subnet-01"
            subnet_ip             = "10.10.10.0/24"
            subnet_region         = "$REGION"
            description           = "GSP345"
        },
        {
            subnet_name           = "subnet-02"
            subnet_ip             = "10.10.20.0/24"
            subnet_region         = "$REGION"
            subnet_private_access = "true"
            subnet_flow_logs      = "true"
            description           = "GSP345"
        },
    ]
}
EOF

terraform init
terraform apply --auto-approve

## Task 6.4 Navigate to the instances.tf file and update 
## the configuration resources to connect tf-instance-1 
## to subnet-01 and tf-instance-2 to subnet-02.

cd ~/modules/instances/

cat > instances.tf <<EOF
resource "google_compute_instance" "tf_instance_1" {
  name         = "tf-instance-1"
  machine_type = "e2-standard-2"
  zone         = "$ZONE"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    network = "$VPC"
    subnetwork = "subnet-01"
  }
  metadata_startup_script = <<-EOT
        #!/bin/bash
    EOT
  allow_stopping_for_update = true
}

resource "google_compute_instance" "tf_instance_2" {
  name         = "tf-instance-2"
  machine_type = "e2-standard-2"
  zone         = "$ZONE"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    network = "$VPC"
    subnetwork = "subnet-02"
  }
  metadata_startup_script = <<-EOT
        #!/bin/bash
    EOT
  allow_stopping_for_update = true
}
EOF

cd ~
terraform init
terraform apply --auto-approve

cat << 'EOF'

========================================================
Task 7. Configure a firewall
========================================================

EOF

cat > main.tf <<EOF
terraform {
  backend "gcs" {
    bucket  = "$BUCKET"
    prefix  = "terraform/state"
  }
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "4.53.0"
    }
  }
}

provider "google" {
  project     = var.project_id
  region      = var.region
  zone        = var.zone
}

module "instances" {
  source     = "./modules/instances"
}

module "storage" {
  source     = "./modules/storage"
}

## Changed by nov05, 2026-05-15
## network = "projects/$PROJECT_ID/global/networks/$VPC"
## subnetwork = "subnet-01" ->
##    network    = module.vpc.network_self_link
##    subnetwork = module.vpc.subnets["subnet-01"].self_link

module "vpc" {
    source  = "terraform-google-modules/network/google"
    version = "~> 6.0.0"

    project_id   = "$PROJECT_ID"
    network_name = "$VPC"
    routing_mode = "GLOBAL"

    subnets = [
        {
            subnet_name           = "subnet-01"
            subnet_ip             = "10.10.10.0/24"
            subnet_region         = "$REGION"
            description           = "GSP345"
        },
        {
            subnet_name           = "subnet-02"
            subnet_ip             = "10.10.20.0/24"
            subnet_region         = "$REGION"
            subnet_private_access = "true"
            subnet_flow_logs      = "true"
            description           = "GSP345"
        },
    ]
}

resource "google_compute_firewall" "tf_firewall"{
  name    = "tf-firewall"
  network = module.vpc.network_self_link

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_tags = ["web"]
  source_ranges = ["0.0.0.0/0"]
}
EOF

terraform init
terraform apply --auto-approve

cd ~

echo -e "\n✅  All done\n"
