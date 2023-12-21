locals {
  projectName = var.project_name
  environment = var.env
  prefix      = "${local.projectName}-${local.environment}"
  common_tags = {
      projectName = local.projectName
      environment = local.environment
  }
}

# data "aws_iam_policy_document" "ebs_kms" {
#   statement {
#     sid = "Allow access through KMS for all principals in the account that are authorized to use EBS"

#     principals {
#       type        = "AWS"
#       identifiers = ["*"]
#     }

#     actions = [
#       "kms:Encrypt",
#       "kms:Decrypt",
#       "kms:ReEncrypt*",
#       "kms:GenerateDataKey*",
#       "kms:CreateGrant",
#       "kms:ListGrants",
#       "kms:DescribeKey"
#     ]
#     resources = ["*"]
#     effect    = "Allow"
#   }
# }

# resource "aws_kms_key" "ebs_kms" {
#   description = "Custom kms key to encrypt ebs"
#   policy      = data.aws_iam_policy_document.ebs_kms.json

#   tags = merge(
#     local.common_tags,
#     {
#       Name = "${local.projectName}/${local.environment}/ebs"
#     }
#   )
# }

# resource "aws_kms_alias" "ebs_kms" {
#   name          = "alias/${local.projectName}/${local.environment}/ebs"
#   target_key_id = aws_kms_key.ebs_kms.key_id
# }

data "aws_iam_policy_document" "assume_ec2_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_role" {
  name               = "${local.prefix}-ec2-iam-role"
  assume_role_policy = data.aws_iam_policy_document.assume_ec2_role_policy.json
}

resource "aws_iam_instance_profile" "ec2_role" {
  name = "${local.prefix}-ec2-iam-role"
  role = aws_iam_role.ec2_role.name
}

resource "aws_iam_policy" "ecr_policy" {
  name        = "${local.prefix}-ecr-policy"
  description = "Permissions required for the EC2 instance to pull the ECR image"
  policy      = jsonencode({
  Version     = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowECRActions"
        Effect    = "Allow"
        Action    = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:DescribeRepositories",
          "ecr:DescribeImages",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecr_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.ec2_role.name
}

resource "aws_iam_role_policy_attachment" "ecr_custom_policy" {
  policy_arn = aws_iam_policy.ecr_policy.arn
  role       = aws_iam_role.ec2_role.name
}

resource "aws_iam_role_policy_attachment" "ec2_role_cw_agent" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "ec2_role_ssm_permission" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ec2_role_ecr_permission" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_security_group" "ec2_security_group" {
  name        = "${local.prefix}-ec2-sg"
  description = "Security group for ec2"
  vpc_id      = var.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.prefix}-ec2-sg"
    }
  )

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [var.security_group_alb_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "template_file" "init_script" {
  template = "${file("${path.module}/cloud-init.sh")}"

  vars = {
    docker_image = var.docker_image
    region = var.region
  }
}

resource "aws_launch_template" "lt" {
  name = "${local.prefix}-launch-template"

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size           = var.volume_size
      # encrypted             = true
      # kms_key_id            = aws_kms_key.ebs_kms.arn
      volume_type           = "gp2"
      delete_on_termination = true
    }
  }

  image_id = var.image_id
  iam_instance_profile {
    arn  = aws_iam_instance_profile.ec2_role.arn
  }

  instance_type = var.instance_type

  user_data = base64encode(data.template_file.init_script.rendered)

  monitoring {
    enabled = true
  }

  vpc_security_group_ids = [aws_security_group.ec2_security_group.id]

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      local.common_tags,
      {
        Name = "${var.project_name}-ec2"
      }
    )
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-ec2-lt"
    }
  )
}

resource "aws_autoscaling_group" "asg" {
  name                      = "${local.prefix}-asg"
  max_size                  = 0
  min_size                  = 0
  health_check_grace_period = 30
  health_check_type         = "ELB"
  desired_capacity          = 0
  force_delete              = true
  vpc_zone_identifier       = var.ec2_natted_subnet_list
  target_group_arns         = [var.target_group_arn]

  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }

  tag {
    key                 = "enviornment"
    value               = local.environment
    propagate_at_launch = true
  }
  tag {
    key                 = "projectName"
    value               = local.projectName
    propagate_at_launch = true
  }
  tag {
    key                 = "Name"
    value               = "${local.prefix}-ec2-asg"
    propagate_at_launch = true
  }
}