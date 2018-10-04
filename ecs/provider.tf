# Setup our aws provider
# provider "aws" {
#   access_key  = "${var.aws_access_key_id}"
#   secret_key  = "${var.aws_secret_access_key}"
#   region      = "${var.region}"
# }

variable "shared_key_file" {
  default = "~/.aws/credentials"
}

provider "aws" {
  region                  = "${var.region}"
  shared_credentials_file = "${var.shared_key_file}"
  profile                 = "epen2sandbox"
}