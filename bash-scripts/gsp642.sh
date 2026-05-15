#!/bin/bash
## Changed by nov05, 2026-05-15

# Define color variables
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'

NO_COLOR=$'\033[0m'
RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

## Function to show spinner while commands run
show_spinner() {
    local pid=$!
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

echo
echo "${BLUE_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}                     Begin of execution${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo

# Set Project ID
gcloud config set project $DEVSHELL_PROJECT_ID

# Create Firestore Database
## nam5 is the Firestore database location (region/multi-region) in North America.
echo "${YELLOW_TEXT}${BOLD_TEXT}Creating Firestore database in nam5 region...${RESET_FORMAT}"
(gcloud firestore databases create --location=nam5 --quiet) & show_spinner
echo "${GREEN_TEXT}✅  Firestore database created${RESET_FORMAT}"
echo

# Clone Repository
echo "${YELLOW_TEXT}${BOLD_TEXT}Cloning the pet-theory repository...${RESET_FORMAT}"
## Use either ~/pet-theory or "$HOME/pet-theory"
if [ -d ~/pet-theory ]; then
    echo "${CYAN_TEXT}Repository already exists. Pulling the latest changes...${RESET_FORMAT}"
    (cd ~/pet-theory && git pull) & show_spinner
else
    (git clone https://github.com/rosera/pet-theory.git) & show_spinner
fi
echo "${GREEN_TEXT}✅  Repository ready${RESET_FORMAT}"
echo

cd ~/pet-theory/lab01

# Install required packages
echo "${YELLOW_TEXT}${BOLD_TEXT}Installing required Node.js packages...${RESET_FORMAT}"
echo "${CYAN_TEXT}Installing @google-cloud/firestore...${RESET_FORMAT}"
(npm install @google-cloud/firestore) & show_spinner
echo "${CYAN_TEXT}Installing @google-cloud/logging...${RESET_FORMAT}"
(npm install @google-cloud/logging) & show_spinner
echo "${CYAN_TEXT}Installing faker@5.5.3...${RESET_FORMAT}"
(npm install faker@5.5.3) & show_spinner
echo "${CYAN_TEXT}Installing csv-parse...${RESET_FORMAT}"
(npm install csv-parse) & show_spinner
echo "${GREEN_TEXT}✅  All packages installed${RESET_FORMAT}"
echo

# Download required scripts
echo "${YELLOW_TEXT}${BOLD_TEXT}Downloading required scripts...${RESET_FORMAT}"
echo "${CYAN_TEXT}Downloading gsp642_create_test_data.js...${RESET_FORMAT}"
(curl -sLO https://raw.githubusercontent.com/nov05/nov05-gcp-skills-boost/refs/heads/main/javascript-scripts/gsp642_create_test_data.js) & show_spinner
echo "${CYAN_TEXT}Downloading gsp642_import_test_data.js...${RESET_FORMAT}"
(curl -sLO https://raw.githubusercontent.com/nov05/nov05-gcp-skills-boost/refs/heads/main/javascript-scripts/gsp642_import_test_data.js) & show_spinner
echo "${GREEN_TEXT}✅  Scripts downloaded${RESET_FORMAT}"
echo

# Create and import test data
echo "${YELLOW_TEXT}${BOLD_TEXT}Generating and importing test data...${RESET_FORMAT}"
echo "${CYAN_TEXT}Creating 1000 test records...${RESET_FORMAT}"
(node gsp642_create_test_data 1000) & show_spinner
echo "${CYAN_TEXT}Importing 1000 records to Firestore...${RESET_FORMAT}"
(node gsp642_import_test_data customers_1000.csv) & show_spinner
echo "${CYAN_TEXT}Creating 20000 test records...${RESET_FORMAT}"
(node gsp642_create_test_data 20000) & show_spinner
echo "${CYAN_TEXT}Importing 20000 records to Firestore...${RESET_FORMAT}"
(node gsp642_import_test_data customers_20000.csv) & show_spinner
echo "${GREEN_TEXT}✅  Test data generation and import completed${RESET_FORMAT}"
echo

echo
echo "${BLUE_TEXT}${BOLD_TEXT}╔════════════════════════════════════════════════════════╗${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}                     End of execution${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}╚════════════════════════════════════════════════════════╝${RESET_FORMAT}"
echo