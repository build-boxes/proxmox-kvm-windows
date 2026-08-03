# proxmox-kvm-windows
Proxmox KVM Image creation for Windows 11 and Windows Server 2025.

1. Windows Server 2025 - [README.md](./winserver2025/README.md)
1. Windows 11 Pro - [README.md](./win11pro/README.md)

## General Steps - Applicable to All Windows OS included here
1. Manually download Windows Installer ISO on Proxmox Server.
1. Manually create a Installed Windows Golden Image KVM.
1. Manually install or enable all desired features and components.
1. Manually Sysprep and Shutdown this Golden Image KVM.
1. Manually Convert this Golden Image KVM to a KVM-Template.
1. Manually Define all Tags on this KVM-Template, that will allow Terraform scripts to pick it up.
1. Automated - Switch into the tf* folder and do the following steps to Launch Terraform apply:
    ```
    terraform init
    terraform plan
    terraform apply -auto-approve
    ```

## Automated Packer Work In Progress
1. Windows Server 2025 now also has an initial Packer HCL build path in [winserver2025/pkr-proxmox-kvm-winserver2025](./winserver2025/pkr-proxmox-kvm-winserver2025).
1. That build is intended to automate the template creation steps that were previously manual, then feed the existing Terraform clone workflow.

## Required Pre-Requisite Software
To use this software you need to have the following software tools installed in your Linux like cient computer.
1. packer
1. terraform
1. ansible
1. powershell

