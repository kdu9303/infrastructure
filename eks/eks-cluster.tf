module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.2.0"

  cluster_name    = local.name
  cluster_version = local.cluster_version
  # endpoint 외부 엑세스 
  cluster_endpoint_public_access = true
  cluster_enabled_log_types      = ["audit", "api", "authenticator", "controllerManager", "scheduler"]

  cluster_addons = {
    coredns = {
      # preserve    = true
      most_recent = true
      # resolve_conflicts_on_update = "OVERWRITE"

      timeouts = {
        create = "30m"
        delete = "15m"
      }
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
      # resolve_conflicts_on_update = "OVERWRITE"
    }
  }

  create_kms_key = false
  cluster_encryption_config = {
    resources        = ["secrets"]
    provider_key_arn = module.kms.key_arn
  }

  iam_role_additional_policies = {
    additional = aws_iam_policy.additional.arn
  }


  vpc_id = module.vpc.vpc_id
  # EKS 파드가 할당되는 Subnet 대역
  subnet_ids = module.vpc.private_subnets
  #Control Plane의 파드가 할당되는 subnet 대역
  control_plane_subnet_ids = module.vpc.intra_subnets


  # Extend cluster security group rules
  cluster_security_group_additional_rules = {
    ingress_nodes_ephemeral_ports_tcp = {
      description                = "Nodes on ephemeral ports"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "ingress"
      source_node_security_group = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  # Extend node-to-node security group rules
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
  }


  eks_managed_node_group_defaults = {

    ami_type = "AL2_x86_64"

    # iam_role_additional_policies = {
    #   additional = aws_iam_policy.additional.arn
    # }

    iam_role_additional_policies = {
      additional                   = aws_iam_policy.additional.arn,
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }

    ebs_optimized = true
    block_device_mappings = {
      xvda = {
        device_name = "/dev/xvda"
        ebs = {
          volume_size = 40
          volume_type = "gp3"
          iops        = 3000
          throughput  = 150
          # encrypted             = true
          # kms_key_id            = aws_kms_key.ebs.arn
          delete_on_termination = true
        }
      }
    }

    pre_userdata = local.ssm_userdata

    tags = local.tags
  }
  # auto scaler
  eks_managed_node_groups = {
    base3 = {
      name            = "karpenter-eks-cluster"
      use_name_prefix = true

      # instance_types = ["t3.medium", "t3.large"]
      instance_types = ["t3.large"]
      capacity_type  = "SPOT"

      min_size     = 2
      max_size     = 2
      desired_size = 2

      subnet_ids = module.vpc.private_subnets

      user_data_base64 = base64encode(local.ssm_userdata)
    }
  }

  tags = merge(local.tags, {
    # NOTE - if creating multiple security groups with this module, only tag the
    # security group that Karpenter should utilize with the following tag
    # (i.e. - at most, only one security group should have this tag in your account)
    "karpenter.sh/discovery" = local.name
  })

}

module "eks-aws-auth" {
  source  = "terraform-aws-modules/eks/aws//modules/aws-auth"
  version = "~> 20.2.0"

  manage_aws_auth_configmap = true


  aws_auth_roles = [
    {
      rolearn  = module.eks.cluster_iam_role_arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups = [
        "system:bootstrappers",
        "system:nodes",
      ]
    },
    # AWS 관리자 계정 추가
    {
      rolearn  = "arn:aws:iam::633647824487:user/root"
      username = "greta"
      groups = [
        "system:masters",
      ]
    },
    # We need to add in the Karpenter node IAM role for nodes launched by Karpenter
    {
      rolearn  = "arn:aws:iam::633647824487:role/KarpenterNodeRole-${local.name}"
      username = "system:node:{{EC2PrivateDNSName}}"
      groups = [
        "system:bootstrappers",
        "system:nodes",
      ]
    },
    {
      rolearn  = module.karpenter.iam_role_arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups = [
        "system:bootstrappers",
        "system:nodes",
      ]
    },
  ]
  aws_auth_accounts = [
    "633647824487",
  ]

}