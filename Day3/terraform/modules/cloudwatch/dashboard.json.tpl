{
  "widgets": [
    {
      "type": "metric",
      "x": 0,
      "y": 0,
      "width": 6,
      "height": 6,
      "properties": {
        "title": "ALB 응답시간 (TargetResponseTime)",
        "region": "ap-northeast-2",
        "stat": "Average",
        "period": 60,
        "yAxis": {
          "left": {
            "min": 0,
            "label": "seconds"
          }
        },
        "metrics": [
          [
            "AWS/ApplicationELB",
            "TargetResponseTime",
            "LoadBalancer",
            "${alb_id}",
            {
              "stat": "Average",
              "label": "avg"
            }
          ],
          [
            "...",
            {
              "stat": "p95",
              "label": "p95"
            }
          ],
          [
            "...",
            {
              "stat": "p99",
              "label": "p99"
            }
          ]
        ]
      }
    },
    {
      "type": "metric",
      "x": 12,
      "y": 6,
      "width": 6,
      "height": 6,
      "properties": {
        "title": "ALB 5xx / 4xx",
        "region": "ap-northeast-2",
        "stat": "Sum",
        "period": 60,
        "metrics": [
          [
            "AWS/ApplicationELB",
            "HTTPCode_Target_5XX_Count",
            "LoadBalancer",
            "${alb_id}",
            {
              "label": "target 5xx",
              "color": "#d62728"
            }
          ],
          [
            "AWS/ApplicationELB",
            "HTTPCode_ELB_5XX_Count",
            "LoadBalancer",
            "${alb_id}",
            {
              "label": "elb 5xx",
              "color": "#ff9896"
            }
          ],
          [
            "AWS/ApplicationELB",
            "HTTPCode_Target_4XX_Count",
            "LoadBalancer",
            "${alb_id}",
            {
              "label": "target 4xx",
              "color": "#ff7f0e"
            }
          ]
        ]
      }
    },
    {
      "type": "metric",
      "x": 18,
      "y": 6,
      "width": 6,
      "height": 6,
      "properties": {
        "title": "ALB 요청수 / 정상·비정상 타겟",
        "region": "ap-northeast-2",
        "period": 60,
        "metrics": [
          [
            "AWS/ApplicationELB",
            "RequestCount",
            "LoadBalancer",
            "${alb_id}",
            {
              "stat": "Sum",
              "label": "requests"
            }
          ],
          [
            "AWS/ApplicationELB",
            "HealthyHostCount",
            "LoadBalancer",
            "${alb_id}",
            {
              "stat": "Average",
              "label": "healthy hosts",
              "yAxis": "right"
            }
          ],
          [
            "AWS/ApplicationELB",
            "UnHealthyHostCount",
            "LoadBalancer",
            "${alb_id}",
            {
              "stat": "Average",
              "label": "unhealthy hosts",
              "yAxis": "right",
              "color": "#d62728"
            }
          ]
        ]
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 6,
      "width": 6,
      "height": 6,
      "properties": {
        "title": "RDS CPU / 메모리",
        "region": "ap-northeast-2",
        "stat": "Average",
        "period": 60,
        "yAxis": {
          "left": {
            "min": 0,
            "max": 100,
            "label": "CPU %"
          },
          "right": {
            "min": 0,
            "label": "bytes"
          }
        },
        "metrics": [
          [
            "AWS/RDS",
            "CPUUtilization",
            "DBInstanceIdentifier",
            "apdev-rds-instance",
            {
              "label": "CPU %",
              "color": "#1f77b4"
            }
          ],
          [
            "AWS/RDS",
            "FreeableMemory",
            "DBInstanceIdentifier",
            "apdev-rds-instance",
            {
              "label": "freeable mem",
              "yAxis": "right",
              "color": "#2ca02c"
            }
          ]
        ]
      }
    },
    {
      "type": "metric",
      "x": 6,
      "y": 6,
      "width": 6,
      "height": 6,
      "properties": {
        "title": "RDS 커넥션 수 (DatabaseConnections)",
        "region": "ap-northeast-2",
        "stat": "Average",
        "period": 60,
        "yAxis": {
          "left": {
            "min": 0,
            "label": "connections"
          }
        },
        "metrics": [
          [
            "AWS/RDS",
            "DatabaseConnections",
            "DBInstanceIdentifier",
            "apdev-rds-instance"
          ]
        ]
      }
    },
    {
      "type": "metric",
      "x": 6,
      "y": 0,
      "width": 6,
      "height": 6,
      "properties": {
        "title": "파드 CPU / 메모리 사용률 (%)",
        "region": "ap-northeast-2",
        "stat": "Average",
        "period": 60,
        "yAxis": {
          "left": {
            "min": 0,
            "max": 100,
            "label": "CPU %"
          },
          "right": {
            "min": 0,
            "max": 100,
            "label": "MEM %"
          }
        },
        "metrics": [
          [
            "ContainerInsights",
            "pod_cpu_utilization",
            "ClusterName",
            "apdev-eks-cluster",
            "Namespace",
            "apdev",
            "Service",
            "user-svc",
            {
              "label": "user CPU"
            }
          ],
          [
            "...",
            "Service",
            "product-svc",
            {
              "label": "product CPU"
            }
          ],
          [
            "...",
            "Service",
            "stress-svc",
            {
              "label": "stress CPU"
            }
          ],
          [
            "ContainerInsights",
            "pod_memory_utilization",
            "ClusterName",
            "apdev-eks-cluster",
            "Namespace",
            "apdev",
            "Service",
            "user-svc",
            {
              "label": "user MEM",
              "yAxis": "right"
            }
          ],
          [
            "...",
            "Service",
            "product-svc",
            {
              "label": "product MEM",
              "yAxis": "right"
            }
          ],
          [
            "...",
            "Service",
            "stress-svc",
            {
              "label": "stress MEM",
              "yAxis": "right"
            }
          ]
        ]
      }
    },
    {
      "type": "metric",
      "x": 12,
      "y": 0,
      "width": 6,
      "height": 6,
      "properties": {
        "title": "파드 개수 (running pods)",
        "region": "ap-northeast-2",
        "stat": "Average",
        "period": 60,
        "yAxis": {
          "left": {
            "min": 0,
            "label": "pods"
          }
        },
        "metrics": [
          [
            "ContainerInsights",
            "service_number_of_running_pods",
            "ClusterName",
            "apdev-eks-cluster",
            "Namespace",
            "apdev",
            "Service",
            "user-svc",
            {
              "label": "user"
            }
          ],
          [
            "...",
            "Service",
            "product-svc",
            {
              "label": "product"
            }
          ],
          [
            "...",
            "Service",
            "stress-svc",
            {
              "label": "stress"
            }
          ]
        ],
        "view": "singleValue",
        "sparkline": true,
        "setPeriodToTimeRange": false
      }
    },
    {
      "type": "metric",
      "x": 18,
      "y": 0,
      "width": 6,
      "height": 6,
      "properties": {
        "title": "노드 CPU / 메모리",
        "region": "ap-northeast-2",
        "stat": "Average",
        "period": 60,
        "yAxis": {
          "left": {
            "min": 0,
            "max": 100,
            "label": "%"
          }
        },
        "metrics": [
          [
            "ContainerInsights",
            "node_cpu_utilization",
            "ClusterName",
            "apdev-eks-cluster",
            {
              "label": "node CPU"
            }
          ],
          [
            "ContainerInsights",
            "node_memory_utilization",
            "ClusterName",
            "apdev-eks-cluster",
            {
              "label": "node MEM"
            }
          ]
        ]
      }
    }
  ]
}