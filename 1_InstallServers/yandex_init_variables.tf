variable "auth_token" {
  description = "Yandex OAuth token"
  type        = string
  default     = "y0_AgAAAAACfrXVAATuwQAAAADZfCkKBwHOAus8T8q88sFi1yg0A03r5tM"
}

variable "cloud_id" {
  description = "Yandex Cloud ID"
  type        = string
  default     = "b1g9b3cq0n39obtdc6u6"
}

variable "folder_id" {
  description = "Default folder ID"
  type        = string
  default     = "b1glaiete2qedea3cqqn"
}


#variable "local_subnet_id" {
#  description = "Local subnet ID"
#  type        = string
#  default     = "e9bh11iogta58va9b9h1"
#}

variable "zone" {
  description = "Geo zone ID"
  type        = string
  default     = "ru-central1-a"
}

variable "kuber-master_int_ip" {
  description = "Kubernetes master node internal ip"
  type        = string
  default     = "10.128.0.3"
}

variable "kuber-app-1_int_ip" {
  description = "Kubernetes App-1 node internal ip"
  type        = string
  default     = "10.128.0.4"
}

variable "management_int_ip" {
  description = "Management server internal ip"
  type        = string
  default     = "10.128.0.5"
}
