output "container_id" {
  description = "ID do container LXC criado"
  value       = proxmox_virtual_environment_container.container.vm_id
}

output "container_hostname" {
  description = "Hostname do container"
  value       = proxmox_virtual_environment_container.container.initialization[0].hostname
}

output "container_ip" {
  description = "Configuração de IP do container"
  value       = proxmox_virtual_environment_container.container.initialization[0].ip_config[0].ipv4[0].address
}

output "lxc_template_id" {
  description = "ID do template LXC baixado no datastore"
  value       = proxmox_download_file.ubuntu_lxc_template.id
}
