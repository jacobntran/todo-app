provider "aws" {
  region = "us-west-1"
}

### VARIABLES ###
variable "key_name" {
  description = "SSH key used to access your instances"
}

variable "my_ip" {
  description = "Your ip address"
}

output "app_node_public_ip" {
  value = aws_instance.app.public_ip
}

### NETWORKING ###
resource "aws_vpc" "public" {
  cidr_block = "10.0.0.0/28"

  tags = {
    Name = "Todo App Public Compute VPC"
  }
}

resource "aws_vpc" "private" {
  cidr_block = "10.0.0.32/27"

  tags = {
    Name = "Todo App Private Database VPC"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.public.id
  cidr_block              = "10.0.0.0/28"
  map_public_ip_on_launch = true

  tags = {
    Name = "Todo App Public Compute Subnet"
  }
}

resource "aws_subnet" "db" {
  vpc_id            = aws_vpc.private.id
  cidr_block        = "10.0.0.32/28"
  availability_zone = "us-west-1b"

  tags = {
    Name = "Todo App Private Database Subnet 1"
  }
}

resource "aws_subnet" "db_2" {
  vpc_id            = aws_vpc.private.id
  cidr_block        = "10.0.0.48/28"
  availability_zone = "us-west-1c"

  tags = {
    Name = "Todo App Private Database Subnet 2"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.public.id

  tags = {
    Name = "Todo App"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.public.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  route {
    cidr_block                = aws_vpc.private.cidr_block
    vpc_peering_connection_id = aws_vpc_peering_connection.this.id
  }

  tags = {
    Name = "Todo App Public Subnet Route Table"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# resource "aws_route_table" "db" {
#   vpc_id = aws_vpc.private.id

#   route {
#     cidr_block                = aws_vpc.public.cidr_block
#     vpc_peering_connection_id = aws_vpc_peering_connection.this.id
#   }

#   tags = {
#     Name = "Todo App Database Subnet Route Table"
#   }
# }

# resource "aws_route_table_association" "db" {
#   subnet_id      = aws_subnet.db.id
#   route_table_id = aws_route_table.db.id
# }

# resource "aws_route_table_association" "db_2" {
#   subnet_id      = aws_subnet.db_2.id
#   route_table_id = aws_route_table.db.id
# }

resource "aws_vpc_peering_connection" "this" {
  peer_vpc_id = aws_vpc.private.id
  vpc_id      = aws_vpc.public.id
  auto_accept = true

  tags = {
    Name = "Peering connection between Todo App Compute and DB networks"
  }
}

### SERVICES ###
resource "aws_instance" "app" {
  ami                    = "ami-0d53d72369335a9d6"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.app.id]

  tags = {
    Name = "App Node"
  }
}

resource "aws_security_group" "app" {
  name        = "app_node_sg"
  description = "Allow inbound SSH and HTTP traffic from your IP"
  vpc_id      = aws_vpc.public.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  egress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [aws_vpc.private.cidr_block]
  }
}