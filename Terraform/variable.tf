variable "size" {
  type    = string
  default = "t3.small"
}

variable "amazon-linux-ami" {
  type    = string
  default = "ami-0bb4c991fa89d4b9b"
}

output "public-ip" {
  value = aws_instance.web.public_ip
}
