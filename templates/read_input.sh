#!/bin/bash
## Created by nov05, 2026-05-12

echo
read -p "👉  Enter user 2: " USER2
export USER2 

##################################################3

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
echo
read -p "${YELLOW}${BOLD}Enter your bucket name: ${RESET}" BUCKET
read -p "${YELLOW}${BOLD}Enter your VM instance name: ${RESET}" INSTANCE
read -p "${YELLOW}${BOLD}Enter your VPC name: ${RESET}" VPC
echo

export BUCKET
export INSTANCE
export VPC
