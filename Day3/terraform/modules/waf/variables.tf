variable "project" {
  type = string
}

variable "served_path_prefixes" {
  description = "WAF 보호(정상형태 검사) 대상 제공 엔드포인트 경로 prefix"
  type        = list(string)
  default     = ["/v1/user", "/v1/product", "/v1/stress"]
}

variable "rate_limit" {
  description = "IP당 5분 요청수 상한 (초과 시 차단). WAFv2 최소값 100"
  type        = number
  default     = 3000
}

variable "enable_managed_rules" {
  description = "AWS 관리형 룰(Count 모드) 부착 여부"
  type        = bool
  default     = true
}

variable "managed_rule_groups" {
  description = "부착할 AWS 관리형 룰 그룹"
  type        = list(string)
  default     = ["AWSManagedRulesCommonRuleSet", "AWSManagedRulesSQLiRuleSet"]
}

variable "enable_logging" {
  description = "WAF 로그를 CloudWatch Logs로 내보낼지 여부"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  type    = number
  default = 7
}

variable "public_path_prefixes" {
  description = "인증 파라미터 없이 공개 제공되는 경로 (S3 이미지)"
  type        = list(string)
  default     = ["/images/", "/images"]
}