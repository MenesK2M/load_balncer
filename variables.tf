variable "security_group_lb" {
  description = "Object to structure the SG dynamic block"
  type = map(object({
    description = string
    port        = number
    port2       = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = {
    "http" = {
      description = "Allow HTTP communication"
      port        = 80
      port2       = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}

variable "security_group" {
  description = "Object to structure the SG dynamic block"
  type = map(object({
    description = string
    port        = number
    port2       = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = {
    "ssh" = {
      description = "Allow SSH communication"
      port        = 22
      port2       = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}