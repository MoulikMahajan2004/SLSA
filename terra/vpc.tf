resource "aws_vpc" "Tfpipelinevpc" {
  cidr_block = "10.0.0.0/16"
  region = var.tfregion
  tags = {
    Name = "tfvpc"
  }
}
  
resource "aws_subnet" "publicip1" {
  vpc_id = aws_vpc.Tfpipelinevpc.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_subnet" "publicip2" {
  vpc_id = aws_vpc.Tfpipelinevpc.id
  cidr_block = "10.0.2.0/24"
}

resource "aws_subnet" "private1" {
  vpc_id = aws_vpc.Tfpipelinevpc.id
  cidr_block = "10.0.101.0/24"
}

resource "aws_subnet" "private2" {
  vpc_id = aws_vpc.Tfpipelinevpc.id
  cidr_block = "10.0.102.0/24"
}

resource "aws_internet_gateway" "Tfinternetgateway" {
  vpc_id = aws_vpc.Tfpipelinevpc.id
  tags = {
    Name = "tfvpcinternetgateway"
  }
}

resource "aws_route_table" "tfvpcroutetable" {
  vpc_id = aws_vpc.Tfpipelinevpc.id
  route{
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Tfinternetgateway.id
  }
}

resource "aws_route_table_association" "tfroutetableassociation" {
  route_table_id = aws_route_table.tfvpcroutetable.id
  subnet_id = aws_subnet.publicip1.id
}




