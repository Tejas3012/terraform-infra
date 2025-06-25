#for vpc

resource "aws_vpc" "vpc-1"{
    cidr_block = "192.167.0.0/16"
    instance_tenancy= "default"
    tags={
        Name="vpc-1" 
    }
}

#internate gateway
resource "aws_internet_gateway" "ig-1"{
    vpc_id = aws_vpc.vpc-1.id

    tags = {
        Name = "ig-1"
    }
}

#route table

resource "aws_route_table" "route-1" {
  vpc_id = aws_vpc.vpc-1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ig-1.id
  }

  tags = {
    Name = "route-1"
  }
}

#subnet

resource "aws_subnet" "public_subnet"{
    vpc_id = aws_vpc.vpc-1.id
    cidr_block = "192.167.1.0/24"
    availability_zone = "ap-south-1a"

    tags = {
        Name = "public-subnet"
    }

}
#route table association with subnet

resource "aws_route_table_association" "a-1" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.route-1.id
}

resource "tls_private_key" "pvt-key-1" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Step 2: Create AWS key pair using public key
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = tls_private_key.pvt-key-1.public_key_openssh
}

# Step 3: Save the private key to a file
resource "local_file" "private_key_pem" {
  content  = tls_private_key.pvt-key-1.private_key_pem
  filename = "${path.module}/deployer-key.ppk"
  file_permission = "0600"
}

resource "aws_security_group" "sg-1" {
  name        = "sg1"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.vpc-1.id

  tags = {
    Name = "sg-1"
  }



#security group
  ingress  {
      description    =  "ssh"
      from_port      = 22
      to_port        = 22
      protocol       = "tcp"
      cidr_blocks    = ["0.0.0.0/0"]

  }
   ingress  {
      description    =  "http"
      from_port      = 80
      to_port        = 80
      protocol       = "tcp"
      cidr_blocks    = ["0.0.0.0/0"]

  }



  egress    {
     from_port     = 0
     to_port       = 0
     protocol      = "-1"
     cidr_blocks   = ["0.0.0.0/0"]
  }
}

resource "aws_instance""testing" {
  ami = "ami-0b09627181c8d5778"
  instance_type = "t2.micro"
  count = 1
  subnet_id = "${aws_subnet.public_subnet.id}"
  key_name = aws_key_pair.deployer.id
  associate_public_ip_address = true
  security_groups = [aws_security_group.sg-1.id]
  
  tags = {
    Name = "testing"
  }
}
