source "googlecompute" "edgenode-amd64" {
  project_id                = var.gcp_project_id
  source_image_family       = "cos-vanilla-amd64"
  ssh_password              = var.root_password
  ssh_username              = var.root_username
  zone                      = "us-central1-b"
  disk_size                 = 32
  enable_secure_boot        = false
  image_name                = "${lower(var.name)}-${replace(var.edgenode_version, "+", "-")}-${formatdate("DDMMYYYY", timestamp())}-${substr(var.git_sha, 0, 7)}-amd64"
  image_description         = "${var.name}-${replace(var.edgenode_version, "+", "-")}-${formatdate("DDMMYYYY", timestamp())}-${substr(var.git_sha, 0, 7)}-amd64"
  image_labels = {
    name          = "${lower(var.name)}"
    version       = var.edgenode_version
    git_sha       = var.git_sha  # use full sha here
  }
  image_family = "edgenode-amd64"
  image_guest_os_features = [
    "UEFI_COMPATIBLE",
    "GVNIC"
  ]
  image_storage_locations   = ["us"]
  machine_type              = "n1-standard-1"
  metadata_files = {
    user-data = "user-data/gcp.yaml"
  }
}

source "googlecompute" "edgenode-arm64" {
  project_id                = var.gcp_project_id
  source_image_family       = "cos-vanilla-arm64"
  ssh_password              = var.root_password
  ssh_username              = var.root_username
  zone                      = "us-central1-b"
  disk_size                 = 32
  enable_secure_boot        = false
  image_name                = "${lower(var.name)}-${replace(var.edgenode_version, "+", "-")}-${formatdate("DDMMYYYY", timestamp())}-${substr(var.git_sha, 0, 7)}-amd64"
  image_description         = "${var.name}-${replace(var.edgenode_version, "+", "-")}-${formatdate("DDMMYYYY", timestamp())}-${substr(var.git_sha, 0, 7)}-amd64"
  image_labels = {
    name          = "${lower(var.name)}"
    version       = var.edgenode_version
    git_sha       = var.git_sha  # use full sha here
  }
  image_family = "edgenode-amd64"
  image_guest_os_features = [
    "UEFI_COMPATIBLE",
    "GVNIC"
  ]
  image_storage_locations   = ["us"]
  machine_type              = "n1-standard-1"
  metadata_files = {
    user-data = "user-data/gcp.yaml"
  }
}

source "qemu" "edgenode-amd64" {
  qemu_binary            = "qemu-system-x86_64"
  accelerator            = "${var.accelerator}"
  boot_wait              = "${var.sleep}"
  firmware               = "${var.firmware}"
  disk_interface         = "virtio-scsi"
  disk_size              = 32000
  format                 = "raw"
  headless               = true
  iso_checksum           = "none"
  iso_url                = "https://github.com/rancher/elemental-toolkit/releases/download/v0.10.0/cOS-Seed-teal-0.10.0-12-gc3c86d73-x86_64.iso"
  shutdown_command       = "shutdown -hP now"
  ssh_handshake_attempts = "20"
  ssh_password           = "${var.root_password}"
  ssh_timeout            = "5m"
  ssh_username           = "${var.root_username}"
  vm_name                = "disk.raw"
  qemuargs               = [
    ["-m", "2048"],
    ["-cpu", "host"],
    ["-chardev", "tty,id=pts,path="],
    ["-device", "isa-serial,chardev=pts"],
    ["-device", "virtio-net,netdev=user.0"]
  ]
}

source "qemu" "edgenode-arm64" {
  qemu_binary            = "qemu-system-aarch64"
  machine_type           = "virt"
  accelerator            = "${var.accelerator}"
  boot_wait              = "${var.sleep}"
  disk_interface         = "virtio-scsi"
  firmware               = "${var.firmware}"
  cdrom_interface        = "virtio-scsi"
  disk_size              = 32000
  format                 = "raw"
  headless               = true
  iso_checksum           = "none"
  iso_url                = "https://github.com/rancher/elemental-toolkit/releases/download/v0.10.0/cOS-Seed-teal-0.10.0-12-gc3c86d73-arm64.iso"
  qemuargs               = [
    ["-m", "2048"],
    ["-cpu", "host"],
    ["-boot", "menu=on,strict=on"], # Override the default packer -boot flag which is not valid on UEFI
    [ "-device", "virtio-scsi-pci" ], # Add virtio scsi device
    [ "-device", "scsi-cd,drive=cdrom0,bootindex=0" ], # Set the boot index to the cdrom, otherwise UEFI wont boot from CD
    [ "-device", "scsi-hd,drive=drive0,bootindex=1" ], # Set the boot index to the cdrom, otherwise UEFI wont boot from CD
    [ "-drive", "if=none,file=${var.iso},id=cdrom0,media=cdrom" ], # attach the iso image
    [ "-drive", "if=none,file=output-cos-arm64/${var.name},id=drive0,cache=writeback,discard=ignore,format=qcow2" ], # attach the destination disk
    ["-cpu", "cortex-a57"],
    ["-serial", "file:serial.log"],
  ]
  shutdown_command       = "shutdown -hP now"
  ssh_handshake_attempts = "20"
  ssh_password           = "${var.root_password}"
  ssh_timeout            = "5m"
  ssh_username           = "${var.root_username}"
  vm_name                = "disk.raw"
}

build {
  description = "edgenode"

  sources = ["source.qemu.edgenode-amd64", "source.qemu.edgenode-arm64"]

  source "source.qemu.edgenode-amd64" {
    name = "cos-squashfs"
  }

  source "source.qemu.edgenode-arm64" {
    name = "cos-arm64-squashfs"
  }

  provisioner "file" {
    only = ["qemu.cos-squashfs", "qemu.cos-arm64-squashfs"]
    destination = "/etc/elemental/config.d/squashed_recovery.yaml"
    source      = "squashed_recovery.yaml"
  }

  provisioner "file" {
    except = ["googlecompute.edgenode-amd64"]
    destination = "/90_custom.yaml"
    source      = "config.yaml"
  }

  provisioner "shell" {
    only = ["qemu.edgenode-amd64"]
    inline = [
      "INTERACTIVE=false elemental install --debug --system.uri=docker:${var.edgenode_docker_repo}:${var.edgenode_version}-amd64 --cloud-init /90_custom.yaml /dev/sda",
    ]
    pause_after = "30s"
  }

  provisioner "shell" {
    only = ["qemu.edgenode-arm64"]
    inline = [
      "INTERACTIVE=false elemental install --debug --system.uri=docker:${var.edgenode_docker_repo}:${var.edgenode_version}-arm64 --cloud-init /90_custom.yaml /dev/sda",
    ]
    pause_after = "30s"
  }

  post-processors {
    post-processor "compress" {
      output = "output/disk.raw.tar.gz"
    }
    post-processor "googlecompute-import" {
      only = ["qemu.edgenode-amd64"]
      bucket = "edgenode-images"
      project_id = var.gcp_project_id
      image_name = "${lower(var.name)}-${replace(var.edgenode_version, "+", "-")}-${formatdate("DDMMYYYY", timestamp())}-${substr(var.git_sha, 0, 7)}-amd64"
      image_description = "${var.name}-${replace(var.edgenode_version, "+", "-")}-${formatdate("DDMMYYYY", timestamp())}-${substr(var.git_sha, 0, 7)}-amd64"
      image_labels = {
        name          = "${lower(var.name)}"
        version       = var.edgenode_version
        git_sha       = var.git_sha  # use full sha here
      }
      image_family = "edgenode-amd64"
      image_guest_os_features = [
        "UEFI_COMPATIBLE",
        "GVNIC"
      ]
      image_storage_locations   = ["us"]
    }
    post-processor "googlecompute-import" {
      only = ["qemu.edgenode-arm64"]
      bucket = "edgenode-images"
      project_id = var.gcp_project_id
      image_name = "${lower(var.name)}-${replace(var.edgenode_version, "+", "-")}-${formatdate("DDMMYYYY", timestamp())}-${substr(var.git_sha, 0, 7)}-arm64"
      image_description = "${var.name}-${replace(var.edgenode_version, "+", "-")}-${formatdate("DDMMYYYY", timestamp())}-${substr(var.git_sha, 0, 7)}-arm64"
      image_labels = {
        name          = "${lower(var.name)}"
        version       = var.edgenode_version
        git_sha       = var.git_sha  # use full sha here
      }
      image_family = "edgenode-arm64"
      image_guest_os_features = [
        "UEFI_COMPATIBLE",
        "GVNIC"
      ]
      image_storage_locations   = ["us"]
    }
  }
}