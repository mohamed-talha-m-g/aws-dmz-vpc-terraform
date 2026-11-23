data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_ssm" {
  name               = "${var.project_name}-ec2-ssm-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json

  tags = {
    Name = "${var.project_name}-ec2-ssm-role"
  }
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_ssm" {
  name = "${var.project_name}-ec2-ssm-profile"
  role = aws_iam_role.ec2_ssm.name
}

# ---------- AMI lookup-------------

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

#----------------- App servers ------------
resource "aws_instance" "app" {
  count = length(var.availability_zones)

  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.private-app[count.index].id
  vpc_security_group_ids      = [aws_security_group.app.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_ssm.name
  associate_public_ip_address = false
  metadata_options {
    http_tokens = "required"
  }

  user_data = <<-EOF
    #!/bin/bash
    set -x
    # wait until outbound internet via NAT works
    until curl -s --max-time 5 https://aws.amazon.com > /dev/null; do sleep 5; done
    # retry dnf in case the lock or repo isn't ready yet
    for i in 1 2 3 4 5; do dnf install -y httpd && break; sleep 10; done
    mkdir -p /var/www/html
    echo "<h1>DMZ app server in ${var.availability_zones[count.index]}</h1>" > /var/www/html/index.html
    systemctl enable --now httpd
  EOF

  tags = {
    Name = "${var.project_name}-app-${var.availability_zones[count.index]}"
    Tier = "app"
  }
}