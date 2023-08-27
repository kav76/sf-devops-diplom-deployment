#!/usr/bin/bash

ansible-playbook -i inventory install_kubernetes_playbook.yml

ansible-playbook - inventory install_helm.yml