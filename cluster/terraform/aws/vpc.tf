data "aws_availability_zones" "available" {}

resource "aws_vpc" "cluster" {
  cidr_block = "10.0.0.0/16"
  tags = "${
    map(
     "Name", "${var.cluster-name}-node",
     "kubernetes.io/cluster/${var.cluster-name}", "shared",
    )
  }"
}

resource "aws_subnet" "cluster" {
  count = 2
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  cidr_block = "10.0.${count.index}.0/24"
  vpc_id = "${aws_vpc.cluster.id}"
  tags = "${
    map(
     "Name", "${var.cluster-name}-node",
     "kubernetes.io/cluster/${var.cluster-name}", "shared",
    )
  }"
}

resource "aws_internet_gateway" "cluster" {
  vpc_id = "${aws_vpc.cluster.id}"
  tags {
    Name = "${var.cluster-name}"
  }
}

resource "aws_route_table" "cluster" {
  vpc_id = "${aws_vpc.cluster.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.cluster.id}"
  }
}

resource "aws_route_table_association" "cluster" {
  count = 2
  subnet_id      = "${aws_subnet.cluster.*.id[count.index]}"
  route_table_id = "${aws_route_table.cluster.id}"
}

resource "aws_security_group" "cluster-master" {
  name        = "${var.cluster-name}-master"
  description = "Cluster communication with worker nodes"
  vpc_id      = "${aws_vpc.cluster.id}"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags {
    Name = "${var.cluster-name}-master"
  }
}

# OPTIONAL: Allow inbound traffic from your local workstation external IP
#           to the Kubernetes. You will need to replace A.B.C.D below with
#           your real IP. Services like icanhazip.com can help you find this.
resource "aws_security_group_rule" "cluster-master-ingress" {
  cidr_blocks       = ["205.175.106.228/32"]
  description       = "Allow workstation to communicate with the cluster API Server"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = "${aws_security_group.cluster-master.id}"
  to_port           = 443
  type              = "ingress"
}

resource "aws_security_group" "cluster-node" {
  name        = "${var.cluster-name}-node"
  description = "Security group for all nodes in the cluster"
  vpc_id      = "${aws_vpc.cluster.id}"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = "${
    map(
     "Name", "${var.cluster-name}-node",
     "kubernetes.io/cluster/${var.cluster-name}", "owned",
    )
  }"
}

resource "aws_security_group_rule" "cluster-node-ingress-self" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = "${aws_security_group.cluster-node.id}"
  source_security_group_id = "${aws_security_group.cluster-node.id}"
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "cluster-node-ingress-master" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.cluster-node.id}"
  source_security_group_id = "${aws_security_group.cluster-master.id}"
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "cluster-master-ingress-node" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.cluster-master.id}"
  source_security_group_id = "${aws_security_group.cluster-node.id}"
  to_port                  = 443
  type                     = "ingress"
}
