
output "ec2_public_ip" {
  description = "IP-адреса віртуальної машини"
  value       = aws_instance.web_server.public_ip
}

output "vm_name" {
  description = "Ім'я віртуальної машини"
  value       = aws_instance.web_server.tags["Name"]
}

output "ami_name" {
  description = "Ім'я образу використаного для створення ВМ"
  value       = data.aws_ami.ubuntu_2404.name
}

output "website_url" {
  description = "Повна адреса (URL) за якою доступний налаштований сервіс"
  value       = "http://${aws_instance.web_server.public_ip}:${var.web_port}"
}
