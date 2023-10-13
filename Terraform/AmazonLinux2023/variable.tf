variable "size" {
  type    = string
  default = "t3.small"
}

variable "amazon-linux-ami" {
  type    = string
  default = "ami-067d1e60475437da2"
}

output "public-ip" {
  value = aws_instance.web.public_ip
}
