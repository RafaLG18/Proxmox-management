output "template_vm_id" {
  description = "ID da VM do template criado"
  value       = proxmox_virtual_environment_vm.ubuntu_template.vm_id
}

output "template_name" {
  description = "Nome do template criado"
  value       = proxmox_virtual_environment_vm.ubuntu_template.name
}

output "cloud_image_id" {
  description = "ID do arquivo de imagem cloud no datastore do Proxmox"
  value       = proxmox_download_file.ubuntu_cloud_image.id
}
