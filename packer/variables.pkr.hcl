variable "firmware" {
  default = ""
}

variable "accelerator" {
  type    = string
  default = "kvm"
}

variable "gcp_project_id" {
  type = string
  description = "Project to look for the image family"
  default = env("GCP_PROJECT_ID")
}

variable "edgenode_version" {
  type    = string
  default = "latest"
}

variable "edgenode_docker_repo" {
  type    = string
  default = "ghcr.io/jtcressy-home/edgenode"
}

variable "cpus" {
  type    = string
  default = "3"
}

variable "root_password" {
  type    = string
  default = "cos"
}

variable "root_username" {
  type    = string
  default = "root"
}

variable "sleep" {
  type    = string
  default = "30s"
}

variable "name" {
  type = string
  default = "edgenode"
  description = "Name of the product being built. Only used for naming artifacts."
}

variable "git_sha" {
  type = string
  default ="none"
  description = "Git sha of the current build, defaults to none."
}
