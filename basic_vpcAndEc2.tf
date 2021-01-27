########################################################################
############################################################ INSTANCES #
########################################################################


resource "aws_instance" "my_ec2_instance" {
  ami           = var.ami1
  instance_type = var.instance_1
  key_name        = var.key_name ## this pub key will be added to the instance by aws
  subnet_id     = aws_subnet.pub_sn.id
  vpc_security_group_ids = [aws_security_group.pub_sg.id]


  #user_data = data.template_file.user_data_keys.rendered ## this server has both pub and priv keys - allowed to connect to _2 instance
  
  tags = {
    "Name" = "my_ec2_instance",
    "type" = "Just_ec2",
    "project" = var.project,
  }
  

}


resource "aws_instance" "my_ec2_instance_2" {
  ami           = var.ami1
  instance_type = var.instance_1
  key_name        = var.key_name ## this pub key will be added to the instance by aws
  subnet_id     = aws_subnet.pub_sn.id
  vpc_security_group_ids = [aws_security_group.pub_sg_2.id]

  /*
  connection {
    host        = coalesce(self.public_ip, self.private_ip)
    type        = "ssh"
    user        = "ubuntu"
    private_key = file(var.private_key_path)
  } */
  #user_data = data.template_file.user_data_pub_key.rendered  ## this server can only accept connections from the holder of the priv key
  
  tags = {
    "Name" = "my_ec2_instance_2",
    "type" = "Just_ec2_2",
    "project" = var.project,
  }
  

}

















##################################################################################
# PROVIDERS
##################################################################################

provider "aws" {

  #0.12.14 Interpolation-only expressions are deprecated: an expression like "${foo}" should be rewritten as just foo.
  #access_key = var.aws_access_key
  #secret_key = var.aws_secret_key
  region     = var.region_1
  #version = "~> 2.63"
  version = "~> 3.2"
}



##################################################################################
# DATA 
##################################################################################



data "aws_availability_zones" "available" {}
/*
data "template_file" "user_data_pub_key" {
  template = file("templates/user_data_pub_key.tpl")
}

data "template_file" "user_data_keys" {
  template = file("templates/user_data_priv_pub_k.tpl")
}
*/


##################################################################################
# OUTPUT
##################################################################################



output "my_ec2_instance_ip" {
  value = aws_instance.my_ec2_instance.public_ip
}











##################################################################################
###################################################################### RESOURCES##
##################################################################################


###########################################################
############################################# NETWORKING ##
###########################################################
resource "aws_vpc" "yakir_vpc1" {
  cidr_block = var.network_address_space
  enable_dns_hostnames = "true"
  tags = {
        "Name" = "yakir_vpc1"
    }

}

resource "aws_internet_gateway" "yakir_igw1" {
  vpc_id = aws_vpc.yakir_vpc1.id
    tags = {
        "Name" = "yakir_igw1"
    }

}



resource "aws_subnet" "pub_sn" {
  cidr_block        = var.subnet1_address_space
  vpc_id            = aws_vpc.yakir_vpc1.id
  map_public_ip_on_launch = "true"
  availability_zone = data.aws_availability_zones.available.names[0]
   tags = {
        "Name" = "pub_sn"
    }

}

resource "aws_subnet" "pub_sn_2" {
  cidr_block        = var.subnet2_address_space
  vpc_id            = aws_vpc.yakir_vpc1.id
  map_public_ip_on_launch = "true"
  availability_zone = data.aws_availability_zones.available.names[1]
   tags = {
        "Name" = "pub_sn_2"
    }

}



############################################################ ROUTING #

## route table
resource "aws_route_table" "yakir_rt1" {
  vpc_id = aws_vpc.yakir_vpc1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.yakir_igw1.id
  }
     tags = {
        "Name" = "yakir_rt1"
    }
}

resource "aws_route_table_association" "yakir_rta_subnet1" {
  subnet_id      = aws_subnet.pub_sn.id
  route_table_id = aws_route_table.yakir_rt1.id
}

resource "aws_route_table_association" "yakir_rta_subnet2" {
  subnet_id      = aws_subnet.pub_sn_2.id
  route_table_id = aws_route_table.yakir_rt1.id
}








#################################################################################
############################################################ SECURITY GROUPS ####
##################################################################################






# public security group 
resource "aws_security_group" "pub_sg" {
  name        = "pub_sg"
  vpc_id      = aws_vpc.yakir_vpc1.id

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  #Destination CIDR
  }

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

     tags = {
        "Name" = "pub_sg"
    }

}


# public security group 
resource "aws_security_group" "pub_sg_2" {
  name        = "pub_sg_2"
  vpc_id      = aws_vpc.yakir_vpc1.id

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #Destinatin CIDR
  }

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

     tags = {
        "Name" = "pub_sg_2"
    }

}






##################################################################################
# VARIABLES
##################################################################################

#variable "aws_access_key" {}
#variable "aws_secret_key" {}
#variable "private_key_path" {}



variable "key_name" {
  default = "yh_terf"
}



variable "network_address_space" {
  default = "10.2.0.0/16" #65,536 addresses
}

variable "subnet1_address_space" {
  default = "10.2.1.0/24"  # 256 adresses
}

variable "subnet2_address_space" {
  default = "10.2.2.0/24" # 256 adresses
}

variable "project" {
  default = "allcloud_basic"
}

variable "ami1" {
  default = "ami-0701e7be9b2a77600"
}

variable "instance_1" {
  default = "t2.nano"
}

variable "region_1" {
  default = "eu-west-1"
}
