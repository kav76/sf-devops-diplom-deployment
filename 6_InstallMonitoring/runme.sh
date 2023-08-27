#!/usr/bin/bash

ansible-playbook -t $1 -i inventory playbook.yml