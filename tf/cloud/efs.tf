resource "aws_efs_file_system" "efs_fs" {
  creation_token                  = "${var.project_name}-efs"
  encrypted                       = true
  throughput_mode                 = "provisioned"
  provisioned_throughput_in_mibps = var.efs_throughput

  tags = var.tags
}

resource "aws_efs_mount_target" "efs_target" {
  count = length(module.vpc.private_subnets)

  file_system_id  = resource.aws_efs_file_system.efs_fs.id
  subnet_id       = element(module.vpc.private_subnets, count.index)
  security_groups = [aws_security_group.efs_sg.id]
}

resource "aws_security_group" "efs_sg" {
  vpc_id      = module.vpc.vpc_id
  description = "EFS Security group"
  name        = "${var.project_name}-efs-sg"

  ingress {
    description = "NFS"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  tags = var.tags
}
