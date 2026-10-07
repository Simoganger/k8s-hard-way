output "machines" {
  description = "Connection details for every machine."
  value = {
    for name, i in aws_instance.machine : name => {
      public_ip  = i.public_ip
      private_ip = i.private_ip
      ssh        = "ssh -i ${abspath(local_sensitive_file.private_key.filename)} admin@${i.public_ip}"
    }
  }
}

output "ssh_user" {
  description = "Default user of the Debian AMI."
  value       = "admin"
}

output "ssh_private_key_path" {
  description = "Path of the generated private key."
  value       = abspath(local_sensitive_file.private_key.filename)
}

output "ssh_config" {
  description = "Paste into ~/.ssh/config to use `ssh jumpbox`, `ssh server`, ..."
  value = join("\n", [
    for name, i in aws_instance.machine : <<-EOT
    Host ${name}
      HostName ${i.public_ip}
      User admin
      IdentityFile ${abspath(local_sensitive_file.private_key.filename)}
      StrictHostKeyChecking accept-new
    EOT
  ])
}

output "machines_txt" {
  description = "Machine database in the format used by the tutorial (IPV4 FQDN HOSTNAME POD_SUBNET)."
  value = join("\n", [
    for name, i in aws_instance.machine :
    "${i.private_ip} ${name}.kubernetes.local ${name}${startswith(name, "node-") ? " 10.200.${tonumber(trimprefix(name, "node-"))}.0/24" : ""}"
  ])
}
