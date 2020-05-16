#!/bin/bash

#Java
sudo apt-get update
sudo apt-get -f install
sudo apt-get --yes --force-yes  install default-jre

echo -e '\n\n-------------------------------------------------------------------------------------------------------------------------------------------------------\nJava is Sucessfully Installed..\n-------------------------------------------------------------------------------------------------------------------------------------------------------\n\n'


#Java_Home
sudo chmod 777 /etc/environment
echo -e '\n\nJAVA_HOME="/usr/lib/jvm/default-java"' >> /etc/environment
source /etc/environment
echo $JAVA_HOME

echo -e '\n\n-------------------------------------------------------------------------------------------------------------------------------------------------------\nJAVA_HOME is Configured..\n-------------------------------------------------------------------------------------------------------------------------------------------------------\n\n'

#Java
sudo apt-get update
sudo apt-get -f install
sudo apt-get --yes --force-yes  install default-jre

echo -e '\n\n-------------------------------------------------------------------------------------------------------------------------------------------------------\nJava is Sucessfully Installed..\n-------------------------------------------------------------------------------------------------------------------------------------------------------\n\n'


#Java_Home
sudo chmod 777 /etc/environment
echo -e '\n\nJAVA_HOME="/usr/lib/jvm/default-java"' >> /etc/environment
source /etc/environment
echo $JAVA_HOME

echo -e '\n\n-------------------------------------------------------------------------------------------------------------------------------------------------------\nJAVA_HOME is Configured..\n-------------------------------------------------------------------------------------------------------------------------------------------------------\n\n'

#Mongo
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2930ADAE8CAF5059EE73BB4B58712A2291FA4AD5

echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.6 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.6.list

sudo apt-get update

sudo apt-get --yes --allow-unauthenticated install mongodb-org

echo -e '\n\n-------------------------------------------------------------------------------------------------------------------------------------------------------\MongoDB is Sucessfully Installed..\n-------------------------------------------------------------------------------------------------------------------------------------------------------\n\n'


#Install Packages
wget https://bitbucket.org/SabirPiludiya/graylog/raw/57a40fa81394961d796fbc7474d1fa09f9d66e21/elasticsearch-6.8.6.deb

wget https://bitbucket.org/SabirPiludiya/graylog/raw/57a40fa81394961d796fbc7474d1fa09f9d66e21/graylog-3.1-repository_latest.deb

echo -e '\n\n-------------------------------------------------------------------------------------------------------------------------------------------------------\nPackages are Sucessfully Installed..\n-------------------------------------------------------------------------------------------------------------------------------------------------------\n\n'



#ElasticSearch
sudo dpkg -i elasticsearch-6.8.6.deb

echo -e '\n\n-------------------------------------------------------------------------------------------------------------------------------------------------------\nElasticSearch is Sucessfully Installed..\n-------------------------------------------------------------------------------------------------------------------------------------------------------\n\n'



#GrayLog
sudo dpkg -i graylog-3.1-repository_latest.deb 
sudo apt-get update
sudo apt-get --yes --allow-unauthenticated install graylog-server

echo -e '\n\n-------------------------------------------------------------------------------------------------------------------------------------------------------\nGraylog is Sucessfully Installed..\n-------------------------------------------------------------------------------------------------------------------------------------------------------\n\n'

#Nginx
sudo apt-get --yes --allow-unauthenticated install nginx

echo -e '\n\n-------------------------------------------------------------------------------------------------------------------------------------------------------\nNginx is Sucessfully Installed..\n-------------------------------------------------------------------------------------------------------------------------------------------------------\n\n'



mkdir $HOME/.ssh
chmod 700 $HOME/.ssh

