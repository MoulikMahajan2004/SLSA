resource "aws_instance" "tfinstance" {
  instance_type               = "t2.nano"
  ami                         = "ami-0b8d527345fdace59"
  subnet_id                   = aws_subnet.publicip1.id
  vpc_security_group_ids      = [aws_security_group.tfsg.id]
  associate_public_ip_address = true

  tags = {
    Name = "tfinstance"
  }
}


# resource "aws_instance" "tfinstance" {
#   instance_type = "t3.micro"
#   ami = "ami-0b8d527345fdace59"
#   //subnet_id = aws_subnet.publicip1
#   subnet_id = aws_subnet.publicip1.id
#   //vpc_security_group_ids = 
#   tags ={
#     name="tfinstances"
#   }
# }


