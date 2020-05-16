#!/bin/bash

#mkdir /home/ubuntu/.ssh/

#ssh-keygen -b 2048 -t rsa -f  -q -N "" -y
# ssh-keygen -t rsa   -P "" -y

ssh-keygen -t rsa -f /home/ubuntu/.ssh/id_rsa.pub -q -P "" -y

scp -o StrictHostKeyChecking=no /home/ubuntu/.ssh/id_rsa.pub ubuntu@$1:/home/ubuntu/.ssh/authorized_keys
scp -o StrictHostKeyChecking=no /home/ubuntu/.ssh/id_rsa.pub ubuntu@$2:/home/ubuntu/.ssh/authorized_keys
scp -o StrictHostKeyChecking=no /home/ubuntu/.ssh/id_rsa.pub ubuntu@$3:/home/ubuntu/.ssh/authorized_keys


