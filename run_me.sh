#!/bin/bash

cd Terraform
./create_infrastructure.sh

cd ../Ansible
./configure_files.sh
