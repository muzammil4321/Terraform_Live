variable "prefix" {
  type        = string
  default     = "Muzak"
  description = "Prefix of the resource name"
}

variable "RGName" {
  type  = string
  default = "Terraform-RG"
}

variable "RGLocation" {
  type  = string
  default = "eastus"
}

variable "tier"{
  type= string
  default  = "Standard"

}
variable "Replication"{
  type= string
  default  = "LRS"
}

variable "blob" {
type = string
default = "data"

}

variable "ipconfig"{
type= string
default ="my_nic_configuration"

}

variable "IIS1"{
 type= string
 default = "IIS_Configvm1.ps1"

}

variable "IIS2"{
 type= string
 default = "IIS_Configvm2.ps1"

}

variable "username"{
  type=string
  default = "koushik"
}

variable "password"{
  type=string
  default = "AlphaParadox@4u"
}

variable "publicip"{
  type=string
  default = "myloadip"
}
