erraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.40.0"
    }
  }
}

provider "aws" {
  # Configuration options
  region = "us-east-1"
}

data "aws_vpc" "df_vpc" {
  default = true
}


data "aws_ami" "aws-linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm*"]
  }

  owners = ["amazon"] 
}

resource "aws_security_group" "compose-sg" {
  name        = "docker-sg"
  description = "Allow 80 and 22"
  vpc_id      = data.aws_vpc.df_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}


resource "aws_instance" "compose" {
  ami           = data.aws_ami.aws-linux.id
  instance_type = "t2.micro"
  key_name = "otto_key"
  vpc_security_group_ids = [aws_security_group.compose-sec-gr.id]
  tags = {
    Name = "docker-compose-otto-1"
  }
  user_data = <<-EOF
              #! /bin/bash
              yum update -y
              amazon-linux-extras install docker -y
              systemctl start docker
              systemctl enable docker
              usermod -a -G docker ec2-user
              # install docker-compose
              curl -L "https://github.com/docker/compose/releases/download/v2.12.2/docker-compose-$(uname -s)-$(uname -m)" \
              -o /usr/local/bin/docker-compose
              chmod +x /usr/local/bin/docker-compose
              yum install git -y
              hostnamectl set-hostname "docker-compose-server"
              cd /home/ec2-user
              TOKEN="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"
              git clone https://$TOKEN@github.com/Selahattinasn/docker-project-203.git
              cd docker-project-203/
              docker-compose up
              EOF
}

output "intanceIP" {
  value = aws_instance.compose.public_ip
}