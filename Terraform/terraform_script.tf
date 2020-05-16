##################################################################################
# VARIABLES
##################################################################################

variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "cluster_name" {}
variable "graylog_publickey" {}

variable "region" {
  default = "us-east-1"
}

variable "network_address_space" {
  default = "10.1.0.0/16"
}

variable "billing_code_tag" {}
variable "environment_tag" {}

variable "dns_zone_name" {}

variable "instance_count" {
  default = 3
}

variable "subnet_count" {
  default = 3
}

variable "controller_count" {
  default = 3
}

variable "elasticip_count" {
  default = 3
}

variable "workers" {

  default = "0.0.0.0/0"
}

##################################################################################
# PROVIDERS
##################################################################################

provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = var.region
}



##################################################################################
# KEY
##################################################################################

resource "aws_key_pair" "graylog_key" {
  key_name   = "graylog_key"
  public_key = var.graylog_publickey
}

##################################################################################
# LOCALS
##################################################################################

locals {
  common_tags = {
    BillingCode = var.billing_code_tag
    Environment = var.environment_tag
  }

  s3_bucket_name = "${var.environment_tag}-${random_integer.rand.result}"
}

##################################################################################
# DATA
##################################################################################

data "aws_availability_zones" "available" {}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

#Random ID
resource "random_integer" "rand" {
  min = 10000
  max = 99999
}

# NETWORKING #
resource "aws_vpc" "vpc" {
  cidr_block = var.network_address_space
  enable_dns_hostnames = true
  tags = merge(local.common_tags, { Name = "${var.environment_tag}-vpc" })

}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(local.common_tags, { Name = "${var.environment_tag}-igw" })

}

resource "aws_subnet" "subnet" {
  count                   = var.subnet_count
  cidr_block              = cidrsubnet(var.network_address_space, 8, count.index)
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = merge(local.common_tags, { Name = "${var.environment_tag}-subnet${count.index + 1}" })

}

# ROUTING #
resource "aws_route_table" "rtb" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(local.common_tags, { Name = "${var.environment_tag}-rtb" })
}

resource "aws_route_table_association" "rta-subnet" {
  count          = var.subnet_count
  subnet_id      = aws_subnet.subnet[count.index].id
  route_table_id = aws_route_table.rtb.id
}

# SECURITY GROUPS #
resource "aws_security_group" "elb-sg" {
  name   = "graylog_elb_sg"
  vpc_id = aws_vpc.vpc.id

  #Allow HTTP from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${var.environment_tag}-elb-sg" })
}

# graylog security group 
resource "aws_security_group" "graylog-sg" {
  name   = "graylog_sg"
  vpc_id = aws_vpc.vpc.id

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from the VPC
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  #  cidr_blocks = [var.network_address_space]
  }  
  
  # UDP access from the VPC
  ingress {
    from_port   = 12201
    to_port     = 12201
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  #  cidr_blocks = [var.network_address_space]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${var.environment_tag}-graylog-sg" })
}

# # LOAD BALANCER #
# resource "aws_elb" "web" {
#   name = "graylog-elb"

#   subnets         = aws_subnet.subnet[*].id
#   security_groups = [aws_security_group.elb-sg.id]
#   instances       = aws_instance.graylog[*].id

#   listener {
#     instance_port     = 80
#     instance_protocol = "http"
#     lb_port           = 80
#     lb_protocol       = "http"
#   }

#   tags = merge(local.common_tags, { Name = "${var.environment_tag}-elb" })
# }

# resource "aws_lb" "web" {
#   name               = "graylog-elb"
#   internal           = false
#   load_balancer_type = "network"
#   subnets            = aws_subnet.subnet[*].id

#   enable_deletion_protection = true

#    tags = merge(local.common_tags, { Name = "${var.environment_tag}-elb" })
# }


# Network Load Balancer for apiservers and ingress
resource "aws_lb" "web" {
  name               = "${var.cluster_name}-nlb"
  load_balancer_type = "network"
  internal           = false

  subnets = aws_subnet.subnet.*.id

  enable_cross_zone_load_balancing = true

  tags = merge(local.common_tags, { Name = "${var.environment_tag}-nlb" })
}

# Forward TCP apiserver traffic to controllers
resource "aws_lb_listener" "apiserver-https" {
  load_balancer_arn = aws_lb.web.arn
  protocol          = "TCP"
  port              = "80"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.controllersTCP80.arn
  }
}

# Forward HTTP ingress traffic to workers
resource "aws_lb_listener" "ingress-http" {
  load_balancer_arn = aws_lb.web.arn
  protocol          = "TCP"
  port              = 80

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.controllersTCP80.arn
  }
}

# Forward TCP apiserver traffic to controllers
resource "aws_lb_listener" "apiserver-https1" {
  load_balancer_arn = aws_lb.web.arn
  protocol          = "UDP"
  port              = "12201"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.controllersUDP.arn
  }
}

# Forward HTTP ingress traffic to workers
resource "aws_lb_listener" "ingress-http1" {
  load_balancer_arn = aws_lb.web.arn
  protocol          = "UDP"
  port              = 12201

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.controllersUDP.arn
  }
}


# Forward TCP apiserver traffic to controllers
resource "aws_lb_listener" "apiserver-https2" {
  load_balancer_arn = aws_lb.web.arn
  protocol          = "TCP"
  port              = "53"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.controllersTCP53.arn
  }
}

# Forward HTTP ingress traffic to workers
resource "aws_lb_listener" "ingress-http2" {
  load_balancer_arn = aws_lb.web.arn
  protocol          = "TCP"
  port              = 53

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.controllersTCP53.arn
  }
}

# Target group of controllers
resource "aws_lb_target_group" "controllersTCP80" {
  name        = "${var.cluster_name}-TCP80"
  vpc_id      = aws_vpc.vpc.id
  target_type = "instance"

  protocol = "TCP"
  port     = 80

  # TCP health check for apiserver
  health_check {
    protocol = "TCP"
    port     = 80

    # NLBs required to use same healthy and unhealthy thresholds
    healthy_threshold   = 3
    unhealthy_threshold = 3

    # Interval between health checks required to be 10 or 30
    interval = 10
  }
}



# Attach controller instances to apiserver NLB
resource "aws_lb_target_group_attachment" "controllersTCP80" {
#  count = var.controller_count

  target_group_arn = aws_lb_target_group.controllersTCP80.arn
#  target_id        = aws_instance.graylog.*.id[count.index]
#  target_id         = [aws_instance.graylog[1].id, aws_instance.graylog[2].id]
  target_id        = aws_instance.graylog[1].id
  port             = 80
}


# Attach controller instances to apiserver NLB
resource "aws_lb_target_group_attachment" "controllers2TCP80" {

  target_group_arn = aws_lb_target_group.controllersTCP80.arn
  target_id        = aws_instance.graylog[2].id
  port             = 80
}




# Target group of controllers UDP
resource "aws_lb_target_group" "controllersUDP" {
  name        = "${var.cluster_name}-UDP"
  vpc_id      = aws_vpc.vpc.id
  target_type = "instance"

  protocol = "UDP"
  port     = 12201

  # TCP health check for apiserver
  health_check {
    protocol = "TCP"
    port     = 12201

    # NLBs required to use same healthy and unhealthy thresholds
    healthy_threshold   = 3
    unhealthy_threshold = 3

    # Interval between health checks required to be 10 or 30
    interval = 10
  }
}

# Attach controller instances to apiserver NLB
resource "aws_lb_target_group_attachment" "controllersUDP" {
  count = var.controller_count

  target_group_arn = aws_lb_target_group.controllersUDP.arn
  target_id        = aws_instance.graylog[1].id
#aws_instance.graylog.*.id[count.index]
  port             = 12201
}


# Attach controller instances to apiserver NLB
resource "aws_lb_target_group_attachment" "controllersUDP2" {
  target_group_arn = aws_lb_target_group.controllersUDP.arn
  target_id        = aws_instance.graylog[2].id
  port             = 12201
}




# Target group of controllers TCP
resource "aws_lb_target_group" "controllersTCP53" {
  name        = "${var.cluster_name}-TCP53"
  vpc_id      = aws_vpc.vpc.id
  target_type = "instance"

  protocol = "TCP"
  port     = 53

  # TCP health check for apiserver
  health_check {
    protocol = "TCP"
    port     = 53

    # NLBs required to use same healthy and unhealthy thresholds
    healthy_threshold   = 3
    unhealthy_threshold = 3

    # Interval between health checks required to be 10 or 30
    interval = 10
  }
}


# Attach controller instances to apiserver NLB
resource "aws_lb_target_group_attachment" "controllersTCP53" {
  count = var.controller_count

  target_group_arn = aws_lb_target_group.controllersTCP53.arn
  target_id        = aws_instance.graylog.*.id[count.index]
  port             = 53
}



# INSTANCES #
resource "aws_instance" "graylog" {
  count                  = var.instance_count
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.medium"
  subnet_id              = aws_subnet.subnet[count.index % var.subnet_count].id
  vpc_security_group_ids = [aws_security_group.graylog-sg.id]
  key_name               = "graylog_key"
 
  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = file("~/.ssh/id_rsa")

  }


  provisioner "file" {
    source      = "script_graylog_packages.sh"
    destination = "/home/ubuntu/script.sh"
  }


  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/script.sh",
      "/home/ubuntu/script.sh args"
    ]
  }


  provisioner "local-exec" {
    command =  "echo domain: ${aws_lb.web.dns_name} > /home/ubuntu/Ansible/env_vars/domain.yml"
  }


  provisioner "local-exec" {
    command =  "echo ${aws_eip.graylog[0].public_ip},${aws_eip.graylog[1].public_ip},${aws_eip.graylog[2].public_ip} > /home/ubuntu/Ansible/hosts"
  }



  tags = merge(local.common_tags, { Name = "${var.environment_tag}-graylog${count.index + 1}" })
}



  ##################################################################################
  # OUTPUT
  ##################################################################################

  output "aws_lb_public_dns" {
    value = aws_lb.web.dns_name
  }

  # output "cname_record_url" {
  #   value = "http://${var.environment_tag}-website.${var.dns_zone_name}"
  # }



resource "aws_eip" "graylog" {
    count = var.elasticip_count
    vpc = true
}

output "eip_id" {
  value = aws_eip.graylog.*.id
}

output "nodes_public_ip" {
    value = aws_eip.graylog.*.public_ip
}

resource "aws_eip_association" "eip_assoc" {
    count = var.instance_count
    instance_id = element(aws_instance.graylog.*.id, count.index)
    allocation_id = element(aws_eip.graylog.*.id, count.index)
}

