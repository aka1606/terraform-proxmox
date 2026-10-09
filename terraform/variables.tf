variable "proxmox_password" {
  description = "Mot de passe du compte root@pam sur Proxmox"
  type        = string
  sensitive   = true
}

variable "vm_password" {
  description = "Mot de passe du compte ubuntu cree dans chaque VM"
  type        = string
  sensitive   = true
}
