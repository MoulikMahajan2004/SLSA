resource "aws_security_group" "tfsg" {
  vpc_id = aws_vpc.Tfpipelinevpc.id
  tags = {
    Name = "newsgupdatedone"
  }
}

# resource "aws_vpc_security_group_ingress_rule" "name" {
#   security_group_id = aws_security_group.tfsg.id
#   ip_protocol = "ssh"
#   from_port = 22
#   to_port = 22
#   cidr_ipv4 = aws_subnet.publicip1.id
# }
