resource "aws_vpc" "mtc_vpc" {
  cidr_block           = "10.123.0.0/16"
  enable_dns_hostnames = true

  tags = {
    "Name" = "dev"
  }
}

resource "aws_subnet" "mtc_public_subnet" {
  vpc_id                  = aws_vpc.mtc_vpc.id
  cidr_block              = "10.123.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    "Name" = "dev-public"
  }

}

resource "aws_internet_gateway" "mtc_internet_gateway" {
  vpc_id = aws_vpc.mtc_vpc.id
  tags = {
    "Name" = "dev-igw"
  }
}

resource "aws_route_table" "mtc_public_rt" {
  vpc_id = aws_vpc.mtc_vpc.id
  tags = {
    "Name" = "dev_public_rt"
  }

}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.mtc_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.mtc_internet_gateway.id

}

resource "aws_route_table_association" "mtc_public_assoc" {
  route_table_id = aws_route_table.mtc_public_rt.id
  subnet_id      = aws_subnet.mtc_public_subnet.id

}

resource "aws_security_group" "mtc_sg" {
  name        = "dev_sg"
  description = "dev sg"
  vpc_id      = aws_vpc.mtc_vpc.id

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }
}

resource "tls_private_key" "key" {
  algorithm = "RSA"
}

resource "local_file" "keypair" {
  filename = "/Users/divyak/DevOps/Terraform/Terraform-Course/keyforcourse.pem"
  content  = tls_private_key.key.private_key_pem
  file_permission = "0400"
}

resource "aws_key_pair" "aws_key" {
  public_key = tls_private_key.key.public_key_openssh
  key_name   = "mtckey"
}

resource "aws_instance" "mtc_ec2" {
  instance_type          = "t3.micro"
  ami                    = data.aws_ami.server_ami.id
  key_name               = aws_key_pair.aws_key.id
  vpc_security_group_ids = [aws_security_group.mtc_sg.id]
  subnet_id              = aws_subnet.mtc_public_subnet.id
  user_data              = file("userdata.tpl")
  root_block_device {
    volume_size = 10
  }

  tags = {
    "Name" = "dev-node"
  }

  provisioner "local-exec" {
    command = templatefile("${var.host_os}-ssh-config.tpl",{
      hostname = self.public_ip,
      user = "ubuntu",
      identityfile = "keyforcourse.pem"
    })
    interpreter = [ "bash", "-c" ]
  }
}