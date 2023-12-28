variable "credentials" {
  type = object({
    access_key = string
    secret_key = string
  })

  default = {
    access_key = "",
    secret_key = ""
  }
}