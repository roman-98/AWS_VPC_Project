output "bastion_rdp_access_sg" {
  value = aws_security_group.bastion_rdp_access_sg.id
}

output "bastion-lc" {
  value = aws_launch_configuration.bastion-lc
}

output "bastion" {
  value = aws_autoscaling_group.bastion.id
}

output "jenkins_http_access_sg" {
  value = aws_security_group.jenkins_http_access_sg.id
}

output "jenkins-lc" {
  value = aws_launch_configuration.jenkins-lc
}

output "jenkins" {
  value = aws_autoscaling_group.jenkins.id
}

output "prometheus_http_access_sg" {
  value = aws_security_group.prometheus_http_access_sg.id
}

output "prometheus-lc" {
  value = aws_launch_configuration.prometheus-lc
}

output "prometheus" {
  value = aws_autoscaling_group.prometheus.id
}

output "k8s_m_ssh_access_sg" {
  value = aws_security_group.k8s_m_ssh_access_sg.id
}

output "k8s_w_access_sg" {
  value = aws_security_group.k8s_w_access_sg.id
}

output "kubernetes-m-lc" {
  value = aws_launch_configuration.kubernetes-m-lc.name
}

output "kubernetes-w-lc" {
  value = aws_launch_configuration.kubernetes-w-lc.name
}

output "kubernetes-m" {
  value = aws_autoscaling_group.kubernetes-m.id
}

output "kubernetes-w" {
  value = aws_autoscaling_group.kubernetes-w.id
}

output "postgres-az1" {
  value = aws_instance.postgres-az1
}

output "postgres-az2" {
  value = aws_instance.postgres-az2
}

output "postgres-az3" {
  value = aws_instance.postgres-az3
}

