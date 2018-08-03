variable "cluster-name" {
  default = "eks-cluster"
  type = "string"
}
variable "region" {
  default = "us-west-2"
  type = "string"
}
variable "node-type" {
  default = "m5.2xlarge"
  type = "string"
}
