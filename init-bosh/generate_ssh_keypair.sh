
#!/usr/bin/env bash
set -eu

green() {
  echo -e "\033[0;32m${@}\033[0m"
}

red() {
  echo -e "\033[0;31m${@}\033[0m"
}

# abort if a key pair already exists
[[ -e "validator.pem"     ]] && red "Found key. Aborting!" && exit 1
[[ -e "validator.pub" ]] && red "Found key. Aborting!" && exit 1

# create new key pair
ssh-keygen -t rsa -b 4096 -C "validator" -N "" -f "validator.pem"
mv validator.pem.pub validator.pub

# finally inform user about successful completion
green "Key pair created successfully."

