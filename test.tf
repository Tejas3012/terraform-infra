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

