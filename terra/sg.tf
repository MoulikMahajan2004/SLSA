resource "aws_security_group" "tfsg" {
  name   = "secure-cicd-sg"
  vpc_id = aws_vpc.Tfpipelinevpc.id

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # for testing only
  }

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "secure-cicd-sg"
  }
}


#---------------------
# resource "aws_security_group" "tfsg" {
#   vpc_id = aws_vpc.Tfpipelinevpc.id
#   tags = {
#     Name = "newsgupdatedone"
#   }
# }

#--------------------


# resource "aws_vpc_security_group_ingress_rule" "name" {
#   security_group_id = aws_security_group.tfsg.id
#   ip_protocol = "ssh"
#   from_port = 22
#   to_port = 22
#   cidr_ipv4 = aws_subnet.publicip1.id
# }
