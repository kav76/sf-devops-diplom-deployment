#!/usr/bin/bash

terraform init
terraform apply
terraform output external_ip_address_kuber-master | awk -F"\"" '{print $2}' > inventory
terraform output external_ip_address_kuber-app-1 | awk -F"\"" '{print $2}' >> inventory
terraform output external_ip_address_management | awk -F"\"" '{print $2}' >> inventory

