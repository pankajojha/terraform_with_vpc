variable "region" {
  default = "us-east-1"
}

variable "shared_key_file" {
  default = "~/.aws/credentials"
}

provider "aws" {
  region                  = "${var.region}"
  shared_credentials_file = "${var.shared_key_file}"
  profile                 = "epen2sandbox"
}

resource "aws_elb" "e2dev-elb" {
  name = "e2dev-lb"

  listener {
    instance_port     = 4200
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  instances = ["${aws_instance.e2dev-app.*.id}"]
}

resource "aws_vpc" "e2dev-vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "e2dev-igw" {
  vpc_id = "${aws_vpc.e2dev-vpc.id}"

  tags {
    Name = "e2dev"
  }
}

resource "aws_subnet" "e2dev-subnet" {
  vpc_id     = "${aws_vpc.e2dev-vpc.id}"
  cidr_block = "10.0.1.0/24"

  tags {
    Name = "e2dev"
  }

  depends_on = [
    "aws_internet_gateway.e2dev-igw",
  ]

  map_public_ip_on_launch = true
}

# Public routing
resource "aws_route_table" "e2dev-route-table" {
  vpc_id = "${aws_vpc.e2dev-vpc.id}"
}

resource "aws_route" "e2dev-route" {
  route_table_id = "${aws_route_table.e2dev-route-table.id}"
  gateway_id     = "${aws_internet_gateway.e2dev-igw.id}"

  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "e2dev-route-table" {
  subnet_id      = "${aws_subnet.e2dev-subnet.id}"
  route_table_id = "${aws_route_table.e2dev-route-table.id}"
}

resource "aws_security_group" "e2sg" {
  name        = "tf-e2dev-instance-sg-pk"
  description = "(Proxy for ssh)"
  vpc_id      = "${aws_vpc.e2dev-vpc.id}"

  tags {
    Name = "e2dev-sg-pk"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8888
    to_port     = 8888
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 8888
    to_port     = 8888
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "e2dev-app" {
  ami           = "ami-2757f631"
  instance_type = "t2.micro"
  key_name      = "epen2dev"

  tags {
    Name = "e2dev"
  }

  subnet_id              = "${aws_subnet.e2dev-subnet.id}"
  security_groups        = ["${aws_security_group.e2sg.id}"]
  vpc_security_group_ids = ["${aws_security_group.e2sg.id}"]

  #associate_public_ip_address = false

  provisioner "remote-exec" {
    inline = [
      "export PATH=$PATH:/usr/bin",

      # install java 8
      "sudo add-apt-repository ppa:webupd8team/java",

      "sudo apt-get update",
      "sudo apt-get -y install oracle-java8-installer",
      "export JAVA_HOME=/usr/lib/jvm/java-8-oracle",
      "sudo apt-get update",
      "echo $JAVA_HOME",
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = "${file("~/Documents/key/epen2dev.pem")}"
    }
  }
}

output "public_ip" {
  value = "${aws_instance.e2dev-app.public_ip}"
}

# resource "aws_eip" "ip" {
#   instance = "${aws_instance.app.id}"
# }


# module "consul" {
#   source = "github.com/hashicorp/consul/terraform/aws"
#   key_name = "epen2_nonprod30.pem"
#   key_path = "~/Documents/key"
#   region   = "us-east-1"
#   servers  = "1"
# }

