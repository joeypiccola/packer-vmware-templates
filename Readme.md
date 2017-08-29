<!-- TOC -->

- [Packer Generated VMware Templates](#packer-generated-vmware-templates)
    - [Use case](#use-case)
        - [Potential downsides](#potential-downsides)
    - [How it works](#how-it-works)
    - [Getting started](#getting-started)
        - [Prerequisites](#prerequisites)
        - [Modifications](#modifications)
        - [Initiate a build](#initiate-a-build)
    - [Things to know](#things-to-know)
        - [VMware templates](#vmware-templates)
        - [Windows updates](#windows-updates)
        - [Sysprep](#sysprep)
        - [Post deployment tasks](#post-deployment-tasks)
    - [Thanks](#thanks)

<!-- /TOC -->

# Packer Generated VMware Templates

[Packer](https://www.Packer.io/) templates that can be used to create Windows virtual machine templates in VMware. As is, these templates will create a fully patched system with VMware Tools installed running PowerShell Version 5 for Windows Server 2008 R2 Standard, 2012 R2 Standard and 2016 Standard. These Packer templates intentionally create vanilla systems.

## Use case

Managing VMware templates in an environment of multiple vCenters can be difficult. Sure it's possible to script out the management of them with PowerCLI, whether it be to spin them up once a month to patch or to update tools. However, in time there's opportunity for them to drift from one another and sooner or later you have these precious templates that you can't remember what you did to get them to sysprep with WMF5 installed (true story). Enter Packer, with Packer we can store a template's entire configuration in just a few version controlled files. Better yet, we can regenerate templates from scratch whenever we want.

1. Need to upgarde tools on all your templates, script the tools install and re-run Packer.
2. Need to patch Windows for the current month, wrap PowerShell around Packer and have it auto run to rebuild fully patched machines every 30 days.
3. Need to modify your baseline configuration, script it out and re-run Packer.
4. Have a new vCenter come online that needs your templates, add that vCenter as an additional post-processor and re-run Packer (see below).

```json
"post-processors": [
  {
  "type": "vsphere",
  "host": "{{ user `Seattle_vcenter` }}"
  }
  ,
  {
  "type": "vsphere",
  "host": "{{ user `Dallas_vcenter` }}"
  }
  ,
  {
  "type": "vsphere",
  "host": "{{ user `Denver_vcenter` }}"
  }
]
```

### Potential downsides

Regenerating a fully patched Windows machine takes time. But who cares if it's tucked away in Jenkins or the Windows task scheduler. If time is of concern, perhaps consider breaking up the builds with the vmware-ovf builder. @maddhodge talks about that [here](https://hodgkins.io/best-practices-with-packer-and-windows#step-by-step).

These Packer templates require Internet access to pull down VMware tools, different versions of WMF, and Windows updates; consider hosting the binaries internally and using WSUS if air-gapped.

## How it works

Use Packer to locally build a VM in [VMware Workstation](https://www.vmware.com/products/workstation.html) and then upload it to a vCenter via the Packer [vSphere Post-Processor](https://www.Packer.io/docs/post-processors/vsphere.html). Use PowerCLI to adjust anything extra on the VM and convert it to a template.

## Getting started

Clone this repo, install the prerequisites, edit the variables-global-template.json and then initiate a build.

### Prerequisites

Begin by installing Packer and the Packer provisioner [Packer-provisioner-windows-update](https://github.com/rgl/Packer-provisioner-windows-update) via [Chocolatey](https://chocolatey.org/). You will also need [VMware Workstation](https://www.vmware.com/products/workstation.html). VMware Workstation provides the Packer builder [vmware](https://www.Packer.io/docs/builders/vmware.html). The Packer builder vmware is the only builder that can produce an artifact that the vsphere post-processor can handle. The vsphere post-processor requires the [OVFTool](https://www.vmware.com/support/developer/ovf/), ensure it's in your path ```C:\Program Files\VMware\VMware OVF Tool``` and you're on the latest version.

```cmd
choco install Packer, Packer-provisioner-windows-update -y
```

### Modifications

As listed in the prerequisites you'll need to modify the variables-global-template.json with your vCenter info. As is, these templates are set to use a local copy of the retail ISO (specifed in the Packer json) in addition to using the KMS key (specified in the Autounattend.xml).

### Initiate a build

Simply via the command line
```cmd
Packer build -force -var-file .\variables-global.json -var 'vcenter_password=SecretPassword' -var 'name=Template2008r2' .\vsphere-2008r2.json
```

Or maybe wrapped in PowerShell leveraging @jaykul [BetterCredentials](https://www.powershellgallery.com/packages/BetterCredentials) module so not to store the vCenter password in plaintext. 
```PowerShell
Import-Module bettercredentials
$cred = bettercredentials\Get-Credential -UserName 'vCenterServiceAccount@mydomain.com'
$password = $cred.GetNetworkCredential().Password
$env:Packer_LOG=1
$env:Packer_LOG_PATH="C:\Packer_logs\Packerlog_2008r2_$(get-date -Format MM-dd-yy-HHmmss).txt"
$server08r2 = Start-Process -FilePath 'Packer.exe' -ArgumentList "build  -force -var-file=`".\variables-global.json`" -var `"name=Template2008r2`" -var `"vcenter_password=$password`" .\vsphere-2008r2.json" -WindowStyle Normal -Wait -PassThru

if ($server08r2.ExitCode -eq 0)
{
    # log success
}
else
{
    # log failure
}
```

## Things to know

### VMware templates

Packer does not actually convert the uploaded VMs to a template. PowerCLI will need to be used to run ```Get-VM $myvm -ToTemplate```.

### Windows updates

Windows updates are handled via the Packer provisioner [Packer-provisioner-windows-update](https://github.com/rgl/Packer-provisioner-windows-update). At least in my experience, handling windows updates in batches works best (especially for Server 2008r2 and older). Note the provisioner code below sets an ```update_limit```. The provisioner will continually run to install updates in batches of 50 until all updates are installed. This loop and install until done behavior was previously handled by this script [Install-WinUpdates.ps1](https://gist.github.com/joeypiccola/9004c659d0d7e2065d0e46af40bcefab). However, this would require Packer to blindly run a PowerShell provisioner executing this script at least four times. It was sloppy. Huge thanks to @tvories for adding the [update_limit](https://github.com/rgl/packer-provisioner-windows-update/pull/4) support.

```json
{
  "type": "windows-update",
  "update_limit": "50"
},
```

### Sysprep

There are many uses for Packer, the most common for vagrant box generation. Typically, at the end of any Windows Packer run the system is sysprep'd and an unattend.xml is copied over to configure WinRM for when the box completes sysprep'ing. @matthodge does an excellent job in explaining this here: [Disable WinRM on build completion and only enable it on first boot](https://hodgkins.io/best-practices-with-Packer-and-windows#disable-winrm-on-build-completion-and-only-enable-it-on-first-boot). Since these Packer templates are specifically for generating VMware templates, the generated VM is not sysprep'd. **It's expected that something will be used to sysprep the VM once it's been cloned from the template (like a customization specification or some other post deployment configuration).**

### Post deployment tasks

The generated VM is left with an account named vagrant with the password vagrant. This was left this way on purpose because 1) it's easy to add a vagrant post-processor box that may expect vagrant\vagrant one day and 2) there are a few Packer provisioners that default to vagrant\vagrant. **That said, whether it be some form of configuration management, a vmware runonce command, or something in a unattend.xml the vagrant user needs ot be cleaned up!**

## Thanks

@jasonmorgan for the Packer introduction

@mwrock for laying down most of this work

@tvories for figuring out the vsphere post-processor syntax and adding ```update_limit``` support for Packer-provisioner-windows-update via [PR4](https://github.com/rgl/Packer-provisioner-windows-update/pull/4)

@rgl for writing [Packer-provisioner-windows-update](https://github.com/rgl/Packer-provisioner-windows-update)