resource "tls_private_key" "rsa-4096-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "key_pair" {
  public_key = tls_private_key.rsa-4096-key.public_key_openssh
  key_name   = "amazonlinuxkey"
}

resource "local_file" "key_file" {
  filename = "/Users/divyak/DevOps/Terraform/${aws_key_pair.key_pair.key_name}.pem"
  content  = tls_private_key.rsa-4096-key.private_key_pem
  file_permission = "0400"
}

resource "aws_security_group" "security_group" {
  name        = "Amazon-Linux-SG"
  description = "Allow Port 80 and 443"

  ingress {
    description      = "https allowed"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    description      = "http allowed"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    description      = "ssh allowed"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "Amazon-Linux-SG"
  }
}

resource "aws_instance" "web" {
  ami           = var.amazon-linux-ami
  instance_type = var.size
  key_name      = aws_key_pair.key_pair.key_name
  user_data     = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2
              yum install -y httpd mariadb-server
              systemctl start httpd
              systemctl enable httpd
              usermod -a -G apache ec2-user
              chown -R ec2-user:apache /var/www
              chmod 2775 /var/www
              find /var/www -type d -exec chmod 2775 {} \;
              find /var/www -type f -exec chmod 0664 {} \;
              echo "<?php phpinfo(); ?>" > /var/www/html/phpinfo.php
              systemctl start mariadb
              systemctl enable mariadb
              yum install php-mbstring php-xml -y
              systemctl restart httpd
              systemctl restart php-fpm
              cd /var/www/html
              wget https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz
              mkdir phpMyAdmin
              tar -xvzf phpMyAdmin-latest-all-languages.tar.gz -C phpMyAdmin --strip-components 1
              rm phpMyAdmin-latest-all-languages.tar.gz
              cd phpMyAdmin
              mv config.sample.inc.php config.inc.php
              chown -R ec2-user:apache /var/www
              chmod 2775 /var/www
              find /var/www -type d -exec chmod 2775 {} \;
              find /var/www -type f -exec chmod 0664 {} \;
              EOF
  tags = {
    Name = "Amazon Linux Instance Demonstration"
  }

}

