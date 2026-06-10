#!/bin/bash
## Created by nov05, 2026-05-12  

ask_to_proceed() {
    echo
    while true; do
        read -rp "Ready to proceed? (y): " answer
        [[ "$answer" =~ ^[Yy]$ ]] && break
    done
    echo
}


## With cursor trick
ask_to_proceed() {
  local answer=""
  echo -e "\nReady to proceed?"
  while true; do
    printf " (y/n): "
    read -r answer
    if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
      break
    fi
    # move cursor up one line and clear it
    echo -ne "\033[1A\033[2K"
  done
  echo
}