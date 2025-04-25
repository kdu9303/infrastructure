###############################################################################
# EKS
###############################################################################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.24.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  cluster_endpoint_public_access = true
  cluster_enabled_log_types      = ["audit", "api", "authenticator", "controllerManager", "scheduler"]

  cluster_addons = {
    coredns    = { 
      most_recent = true 
    }
    kube-proxy = { 
      most_recent = true 
    }
    vpc-cni = {
      most_recent = true
    }
    eks-pod-identity-agent = { 
      most_recent = true 
    }
    aws-ebs-csi-driver     = { 
      most_recent = true 
    }
  }

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  # 보안 그룹 설정 - 모듈 기본값 사용
  # create_node_security_group = true
  # # Extend cluster security group rules
  # cluster_security_group_additional_rules = {
  #   ingress_nodes_ephemeral_ports_tcp = {
  #     description                = "Nodes on ephemeral ports"
  #     protocol                   = "tcp"
  #     from_port                  = 1025
  #     to_port                    = 65535
  #     type                       = "ingress"
  #     source_node_security_group = true
  #   }
  #   egress_all = {
  #     description      = "Node all egress"
  #     protocol         = "-1"
  #     from_port        = 0
  #     to_port          = 0
  #     type             = "egress"
  #     cidr_blocks      = ["0.0.0.0/0"]
  #     ipv6_cidr_blocks = ["::/0"]
  #   }
  # }

  # # Extend node-to-node security group rules
  # node_security_group_additional_rules = {
  #   ingress_self_all = {
  #     description = "Node to node all ports/protocols"
  #     protocol    = "-1"
  #     from_port   = 0
  #     to_port     = 0
  #     type        = "ingress"
  #     self        = true
  #   }
  # }



  eks_managed_node_groups = {
    karpenter_cluster = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = var.node_instance_types

      min_size     = var.node_group_min_size
      max_size     = var.node_group_max_size
      desired_size = var.node_group_desired_size

      # spot인스턴스 추가할것것
      capacity_type = var.node_group_capacity_type

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 30
            volume_type           = "gp3"
            delete_on_termination = true
          }
        }
      }

      taints = {
        # This Taint aims to keep just EKS Addons and Karpenter running on this MNG
        # The pods that do not tolerate this taint should run on nodes created by Karpenter
        addons = {
          key    = "CriticalAddonsOnly"
          value  = "true"
          effect = "NO_SCHEDULE"
        },
      }
      # 노드 자동 복구 기능 활성화
      # enable_node_auto_repair = true

      # AZ Rebalance 비활성화로 블루/그린 마이그레이션 용이하게 설정
      # suspended_processes = ["AZRebalance"]

      tags = var.tags
    }
  }

  # Cluster access entry
  # To add the current caller identity as an administrator
  enable_cluster_creator_admin_permissions = true

  node_security_group_tags = {
    # NOTE - if creating multiple security groups with this module, only tag the
    # security group that Karpenter should utilize with the following tag
    # (i.e. - at most, only one security group should have this tag in your account)
    "karpenter.sh/discovery" = var.cluster_name
  }
}