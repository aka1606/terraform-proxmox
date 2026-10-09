# terraform-proxmox

Déploiement automatisé d'un petit cluster Kubernetes sur mon homelab Proxmox.
Terraform crée les machines virtuelles, Ansible les configure et monte le cluster.

## Architecture

| VM | ID | IP | RAM | Rôle |
|---|---|---|---|---|
| k8s-master | 200 | 192.168.4.203 | 4 Go | control plane |
| k8s-worker1 | 201 | 192.168.4.204 | 2 Go | worker |
| k8s-worker2 | 202 | 192.168.4.205 | 2 Go | worker |

- Hyperviseur : Proxmox VE (nœud `pve2`), provider Terraform `bpg/proxmox`
- Les VM sont clonées depuis un template cloud-init (ID 9000), 2 vCPU et 20 Go de disque chacune
- Accès SSH par clé uniquement pour l'utilisateur `ubuntu`
- Runtime : containerd, cluster initialisé avec kubeadm (CIDR des pods : `10.244.0.0/16`)

## Arborescence

```
terraform/   création des VM sur Proxmox
ansible/     configuration des VM et installation de Kubernetes
  inventory.ini
  playbooks/
    00-configure-vms.yml   configuration de base des VM
    01-prereqs.yml         prérequis (swap, modules noyau, sysctl)
    02-install-k8s.yml     containerd, kubelet, kubeadm, kubectl
    03-init-master.yml     initialisation du control plane
    04-join-workers.yml    ajout des workers au cluster
```

## Utilisation

1. Copier `terraform/terraform.tfvars.example` en `terraform/terraform.tfvars` et renseigner les mots de passe (ce fichier n'est jamais versionné).
2. Créer les VM :
   ```bash
   cd terraform
   terraform init
   terraform apply
   ```
3. Monter le cluster :
   ```bash
   cd ../ansible
   for p in playbooks/0*.yml; do ansible-playbook -i inventory.ini "$p"; done
   ```

## Sécurité

- Les secrets passent par des variables `sensitive` et un fichier `terraform.tfvars` ignoré par Git.
- Les fichiers `terraform.tfstate` contiennent des données sensibles et ne sont pas versionnés non plus.
- `insecure = true` est utilisé car Proxmox tourne avec un certificat auto-signé sur le réseau local.

## Pistes d'amélioration

- Déployer un CNI (Flannel ou Calico) directement dans le playbook d'initialisation
- Stocker l'état Terraform dans un backend distant chiffré
- Remplacer le mot de passe root Proxmox par un jeton d'API dédié avec des droits limités
