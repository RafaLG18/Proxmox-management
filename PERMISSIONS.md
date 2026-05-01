# Permissões da API Proxmox

Permissões necessárias para o token de API executar todos os módulos deste repositório (`template/` e `container/`).

Execute os comandos abaixo no shell do Proxmox como `root`:

```bash
# Criar usuário dedicado para o Terraform
pveum user add terraform@pve --comment "Terraform"

# Criar role com as permissões necessárias
pveum role add TerraformRole --privs "Datastore.Allocate Datastore.AllocateSpace Datastore.AllocateTemplate Datastore.Audit VM.Allocate VM.Audit VM.Clone VM.Config.CDROM VM.Config.CPU VM.Config.Cloudinit VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Console VM.PowerMgmt Sys.Audit Sys.Modify SDN.Use"

# Associar a role nos paths necessários
pveum aclmod / -user terraform@pve -role TerraformRole
pveum aclmod /nodes/pve -user terraform@pve -role TerraformRole
pveum aclmod /sdn/zones/localnetwork -user terraform@pve -role TerraformRole

# Gerar o token (guarde o valor retornado)
pveum user token add terraform@pve mytoken --privsep 0
```

O token retornado terá o formato: `terraform@pve!mytoken=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`

## Observações

- `Sys.Modify` é exigido pelo endpoint `query-url-metadata` (usado no download de imagens e templates LXC)
- `SDN.Use` é exigido pelo Proxmox VE 8+ para associar qualquer bridge de rede a uma VM ou container
- `/sdn/zones/localnetwork` é a zona SDN padrão criada automaticamente pelo Proxmox — ajuste se usar outra zona
- `--privsep 0` faz o token herdar as permissões do usuário diretamente
