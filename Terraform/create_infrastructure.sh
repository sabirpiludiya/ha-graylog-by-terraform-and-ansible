terraform init
terraform plan -out graylog.tfplan
terraform apply "graylog.tfplan"


echo -e '\n\n---------------------------------------------------------------\nInfrastucture is created..\n---------------------------------------------------------------\n\n'
