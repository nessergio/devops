# Create VPC
resource "aws_vpc" "one" {
  cidr_block = var.cidr_block_ipv4
  assign_generated_ipv6_cidr_block = true
  enable_dns_hostnames = true
  tags       = { Name = "${local.name_prefix}_vpc" }
}

# Creating subnets for workers
resource "aws_subnet" "workers" {
  count                   = local.n_zones
  vpc_id                  = aws_vpc.one.id
  cidr_block              = cidrsubnet(
    aws_vpc.one.cidr_block, 
    8,                    # using 8 bit for net index
    10 + count.index      # net index will be 10 + zone index
  )
  ipv6_cidr_block         = cidrsubnet(
    aws_vpc.one.ipv6_cidr_block, 
    8,                    # using 8 bit for net index
    10 + count.index)     # net index will be 10 + zone index
  assign_ipv6_address_on_creation = true  
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  tags                    = { Name = "${local.name_prefix}_subnet_${count.index}" }
}

# Create Internet Gateway
resource "aws_internet_gateway" "one" {
  vpc_id = aws_vpc.one.id
  tags   = { Name = "${local.name_prefix}_gw" }
}

# Create Routing Table for public
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.one.id
  # The routing table will have only default gateways
  route {
    cidr_block = "0.0.0.0/0" # IPv4
    gateway_id = aws_internet_gateway.one.id
  }
  route {
    ipv6_cidr_block = "::/0" # IPv6
    gateway_id      = aws_internet_gateway.one.id
  }
  tags = { Name = "${local.name_prefix}_public_rt" }
}

# Associate Subnet with Routing Table
resource "aws_route_table_association" "public" {
  count          = local.n_zones
  subnet_id      = aws_subnet.workers[count.index].id
  route_table_id = aws_route_table.public.id
}

# --------------------- SECURITY GROUP ---------------------------------------

resource "aws_security_group" "public" {
  name        = "${replace(local.name_prefix, "_", "-")}-sg-public"
  description = "Allow Web and SSH inbound traffic"
  vpc_id      = aws_vpc.one.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"    
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    description = "metrics"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.one.cidr_block] #via IPv4 only from vpc
    ipv6_cidr_blocks = [aws_vpc.one.ipv6_cidr_block]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = { Name = "sg_public" }
}

# ----------------------------------------------------------------------------