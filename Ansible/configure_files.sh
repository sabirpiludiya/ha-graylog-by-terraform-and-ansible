#!/bin/bash
IFS=, read first second third < hosts

./transfer_keys.sh $first $second $third

sed -i -e "s/\(node1 ansible_host=\).*/\1$first/" \
-e "s/\(node2 ansible_host=\).*/\1$second/" \
-e "s/\(node3 ansible_host=\).*/\1$third/" inventory_list

ansible-playbook production.yml -vv

echo -e '\n\n---------------------------------------------------------------\nFiles configured and nodes connected..\n---------------------------------------------------------------\n\n\nYou can note the IPs and DNS\n\n'

echo "Master IP: " $first
echo "Slave1 IP: " $second
echo "Slave2 IP: " $third

echo -e '\n'
cat env_vars/domain.yml

echo -e '\n\nCongratulations...!\n\n'


