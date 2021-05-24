enabled = true

environment = "dev"
name = "hello-world"

region = "eu-west-2"

cidr_block = "10.0.0.0/16"
availability_zones = [
  "eu-west-2a",
  "eu-west-2b",
  "eu-west-2c"
]

instance_type = "t3.micro"
min_size = 1
max_size = 1
desired_capacity = 1
key_name = "KeyPair"

container_image = "wills287/hello-world-docker:2"
container_memory = 128
