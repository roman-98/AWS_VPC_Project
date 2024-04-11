# create security group for the rdp access to bastion
resource "aws_security_group" "bastion_rdp_access_sg" {
  name        = "rdp_access_for_bastion"
  description = "security group for the rdp access to bastion"
  vpc_id      = var.vpc_id

  ingress {
    description      = "rdp access"
    from_port        = 3389
    to_port          = 3389
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags   = {
    Name = "bastion-rdp-access-sg"
  }
}

# create launch configuration for bastion autoscaling
resource "aws_launch_configuration" "bastion-lc" {
  name_prefix                 = "Bastion-host"
  image_id                    = "ami-0d23f21c7534ae63a" # Windows Server 2022 Base
  instance_type               = "t2.micro"
  key_name                    = "your_key_pair_name"
  security_groups             = [aws_security_group.bastion_ssh_access_sg.id]

  root_block_device {
    encrypted = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# create autoscaling group for bastion
resource "aws_autoscaling_group" "bastion" {
  name                      = "Bastion"
  max_size                  = 1
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "EC2"
  desired_capacity          = 1
  force_delete              = false
  launch_configuration      = aws_launch_configuration.bastion-lc.name
  vpc_zone_identifier       = [
    var.public_subnet_az1_id, 
    var.public_subnet_az2_id, 
    var.public_subnet_az3_id
  ]

  tag {
    key                 = "name"
    value               = "bastion"
    propagate_at_launch = true
  }

}

# create security group for the http access to Jenkins master
resource "aws_security_group" "jenkins_http_access_sg" {
  name        = "http_access_for_jenkins"
  description = "security group for the http access to jenkins"
  vpc_id      = var.vpc_id

  ingress {
    description      = "web access"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = [
      var.public_subnet_az1_id, 
      var.public_subnet_az2_id, 
      var.public_subnet_az3_id,
      "0.0.0.0/0"
    ]
  }

  tags   = {
    Name = "jenkins-ssh-access-sg"
  }
}

# create launch configuration for Jenkins master autoscaling
resource "aws_launch_configuration" "jenkins-lc" {
  name_prefix                 = "Jenkins"
  image_id                    = "ami-01b32e912c60acdfa" # Ubuntu 22.04 LTS
  instance_type               = "t2.micro"
  key_name                    = "jenkins"
  security_groups             = [aws_security_group.jenkins_http_access_sg.id]
  user_data                   = <<EOF
#!/bin/bash
sudo apt update
sudo apt install -y fontconfig openjdk-17-jre
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update
sudo apt-get install -y jenkins
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
# RUN AFTER SYSTEM RUN
# jenkins ALL=(ALL) NOPASSWD: ALL >> /etc/sudoers
# ssh-keygen
EOF

  root_block_device {
    encrypted = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# create autoscaling group for Jenkins master
resource "aws_autoscaling_group" "jenkins" {
  name                      = "Jenkins"
  max_size                  = 1
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "EC2"
  desired_capacity          = 1
  force_delete              = false
  launch_configuration      = aws_launch_configuration.jenkins-lc.name
  vpc_zone_identifier       = [
    var.private_app_subnet_az1_id, 
    var.private_app_subnet_az2_id, 
    var.private_app_subnet_az3_id
  ]

  tag {
    key                 = "name"
    value               = "jenkins"
    propagate_at_launch = true
  }

}

# create security group for the http access to Prometheus
resource "aws_security_group" "prometheus_http_access_sg" {
  name        = "http_access_for_prometheus"
  description = "security group for the http access to prometheus"
  vpc_id      = var.vpc_id

  ingress {
    description      = "web access"
    from_port        = 9090
    to_port          = 9090
    protocol         = "tcp"
    cidr_blocks      = [
      var.public_subnet_az1_id, 
      var.public_subnet_az2_id, 
      var.public_subnet_az3_id
    ]
  }

  tags   = {
    Name = "prometheus-http-access-sg"
  }
}

# create launch configuration for Prometheus autoscaling
resource "aws_launch_configuration" "prometheus-lc" {
  name_prefix                 = "Prometheus"
  image_id                    = "ami-01b32e912c60acdfa" # Ubuntu 22.04 LTS
  instance_type               = "t2.micro"
  key_name                    = "your_key_pair_name"
  security_groups             = [aws_security_group.prometheus_http_access_sg.id]
  user_data                   = <<EOF
#!/bin/bash
curl -sSL https://github.com/prometheus/prometheus/releases/download/v2.45.3/prometheus-2.45.3.linux-amd64.tar.gz
tar xvfz prometheus-2.45.3.linux-amd64.tar.gz
cd prometheus-2.45.3.linux-amd64
./prometheus --config.file=prometheus.yml
EOF

  root_block_device {
    encrypted = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# create autoscaling group for Prometheus
resource "aws_autoscaling_group" "prometheus" {
  name                      = "Prometheus"
  max_size                  = 1
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "EC2"
  desired_capacity          = 1
  force_delete              = false
  launch_configuration      = aws_launch_configuration.prometheus-lc.name
  vpc_zone_identifier       = [
    var.private_app_subnet_az1_id, 
    var.private_app_subnet_az2_id, 
    var.private_app_subnet_az3_id
  ]

  tag {
    key                 = "name"
    value               = "prometheus"
    propagate_at_launch = true
  }

}

# create security group for the ssh access to Kubernetes master
resource "aws_security_group" "k8s_m_ssh_access_sg" {
  name        = "ssh_access_for_kubernetes_m"
  description = "security group for the ssh access to kubernetes master"
  vpc_id      = var.vpc_id

  ingress {
    description      = "ssh access"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [
      var.public_subnet_az1_id, 
      var.public_subnet_az2_id, 
      var.public_subnet_az3_id
    ]
  }

  tags   = {
    Name = "kubernetes-m-ssh-access-sg"
  }
}

# create launch configuration for Kubernetes master autoscaling
resource "aws_launch_configuration" "kubernetes-m-lc" {
  name_prefix                 = "Kubernetes-master"
  image_id                    = "ami-06f64fb0331ab61a0" # Amazon Linux 2023 AMI
  instance_type               = "t2.medium"
  key_name                    = "kubernetes"
  security_groups             = [aws_security_group.k8s_m_ssh_access_sg.id]
  user_data                   = <<EOF
#!/bin/bash


# RUN NEXT COMMANDS IN TERMINAL AFTER LOGIN IN ONE OF K8S MASTER
# sudo kubeadm init --control-plane-endpoint="LOAD_BALANCER_IP" --pod-network-cidr=192.168.0.0/24 --upload-certs
# export KUBECONFIG=/etc/kubernetes/admin.conf
# kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
# THEN YOU NEED TO JOIN OTHERS CONTROL-PANE NODES AND WORKER NODES TO THIS CLUSTER
# USE FOLOWING OUTPUT COMMANDS WITH UNIQUE TOKENS
# sudo kubeadm join ...
# THEN RUN THE FOLLOWING COMMAND
# kubectl get nodes
EOF

  root_block_device {
    encrypted = true
  }

  lifecycle {
    create_before_destroy = true
  }

}

# create autoscaling group for Kubernetes master
resource "aws_autoscaling_group" "kubernetes-m" {
  name                      = "Kubernetes-master"
  max_size                  = 3
  min_size                  = 3
  health_check_grace_period = 300
  health_check_type         = "EC2"
  desired_capacity          = 3
  force_delete              = false
  launch_configuration      = aws_launch_configuration.kubernetes-m-lc.name
  vpc_zone_identifier       = [
    var.private_app_subnet_az1_id, 
    var.private_app_subnet_az2_id, 
    var.private_app_subnet_az3_id
  ]

  tag {
    key                 = "name"
    value               = "kubernetes-m"
    propagate_at_launch = true
  }

}

# create security group for the access to Kubernetes worker
resource "aws_security_group" "k8s_w_access_sg" {
  name        = "access_for_kubernetes_w"
  description = "security group for the access to kubernetes worker"
  vpc_id      = var.vpc_id

  ingress {
    description      = "ssh access"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [
      var.public_subnet_az1_id, 
      var.public_subnet_az2_id, 
      var.public_subnet_az3_id
    ]
  }

  ingress {
    description      = "http access"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = [
      var.public_subnet_az1_id, 
      var.public_subnet_az2_id, 
      var.public_subnet_az3_id
    ]
  }

  ingress {
    description      = "https access"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = [
      var.public_subnet_az1_id, 
      var.public_subnet_az2_id, 
      var.public_subnet_az3_id
    ]
  }

  ingress {
    description      = "full access"
    from_port        = all
    to_port          = all
    protocol         = "all"
    cidr_blocks      = [
      "0.0.0.0/0"
    ]
  }

  tags   = {
    Name = "kubernetes-w-access-sg"
  }
}

# create launch configuration for Kubernetes worker autoscaling
resource "aws_launch_configuration" "kubernetes-w-lc" {
  name_prefix                 = "Kubernetes-worker"
  image_id                    = "ami-06f64fb0331ab61a0" # Amazon Linux 2023 AMI
  instance_type               = "t2.medium"
  key_name                    = "kubernetes"
  security_groups             = [aws_security_group.k8s_w_access_sg.id]
  user_data                   = <<EOF
#!/bin/bash


# THEN YOU NEED TO JOIN WORKER NODES TO CLUSTER
# USE FOLOWING OUTPUT COMMANDS FROM CONTROL-PANE WITH UNIQUE TOKENS
# sudo kubeadm join ...
EOF

  root_block_device {
    encrypted = true
  }

}

# create autoscaling group for Kubernetes worker
resource "aws_autoscaling_group" "kubernetes-w" {
  name                      = "Kubernetes-worker"
  max_size                  = 9
  min_size                  = 3
  health_check_grace_period = 100
  health_check_type         = "EC2"
  desired_capacity          = 3
  force_delete              = false
  launch_configuration      = aws_launch_configuration.kubernetes-w-lc.name
  vpc_zone_identifier       = [
    var.private_app_subnet_az1_id, 
    var.private_app_subnet_az2_id, 
    var.private_app_subnet_az3_id
  ]

  instance_maintenance_policy {
    min_healthy_percentage = 90
    max_healthy_percentage = 120
  }

  tag {
    key                 = "name"
    value               = "kubernetes-w"
    propagate_at_launch = true
  }

}

# Create PostgreSQL database instance in database subnet az1
resource "aws_instance" "postgres-az1" {
  count                     = 1
  ami                       = "ami-01b32e912c60acdfa" # Ubuntu 22.04 LTS
  instance_type             = "t2.micro"
  key_name                  = "your_key_pair_name"
  subnet_id                 = var.private_database_subnet_az1_id
  user_data                 = <<EOF
#!/bin/bash
sudo sh -c 'echo "deb https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update
sudo apt-get -y install postgresql
sudo -i -u postgres
psql
\q
EOF
  disable_api_stop = true
  disable_api_termination = true

  tags = {
    Name = "Postgres-az1"
  }
}

# Create PostgreSQL database instance in database subnet az2
resource "aws_instance" "postgres-az2" {
  count                     = 1
  ami                       = "ami-01b32e912c60acdfa" # Ubuntu 22.04 LTS
  instance_type             = "t2.micro"
  key_name                  = "your_key_pair_name"
  subnet_id                 = var.private_database_subnet_az2_id
  user_data                 = <<EOF
#!/bin/bash
sudo sh -c 'echo "deb https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update
sudo apt-get -y install postgresql
sudo -i -u postgres
psql
\q
EOF
  disable_api_stop = true
  disable_api_termination = true

  tags = {
    Name = "Postgres-az2"
  }
}

# Create PostgreSQL database instance in database subnet az3
resource "aws_instance" "postgres-az3" {
  count                     = 1
  ami                       = "ami-01b32e912c60acdfa" # Ubuntu 22.04 LTS
  instance_type             = "t2.micro"
  key_name                  = "your_key_pair_name"
  subnet_id                 = var.private_database_subnet_az3_id
  user_data                 = <<EOF
#!/bin/bash
sudo sh -c 'echo "deb https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
sudo apt-get update
sudo apt-get -y install postgresql
sudo -i -u postgres
psql
\q
EOF
  disable_api_stop = true
  disable_api_termination = true

  tags = {
    Name = "Postgres-az3"
  }
}


