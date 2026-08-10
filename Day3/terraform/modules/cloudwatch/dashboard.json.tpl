{
    "widgets": [
        {
            "type": "metric",
            "x": 9,
            "y": 0,
            "width": 6,
            "height": 5,
            "properties": {
                "title": "ALB 요청수",
                "region": "${region}",
                "stat": "Sum",
                "period": 60,
                "view": "timeSeries",
                "stacked": false,
                "yAxis": {
                    "left": {
                        "min": 0,
                        "label": "requests/min"
                    }
                },
                "metrics": [
                    [ "AWS/ApplicationELB", "RequestCount", "TargetGroup", "${tg_user}", "LoadBalancer", "${alb_id}", { "label": "user", "color": "#1f77b4" } ],
                    [ "AWS/ApplicationELB", "RequestCount", "TargetGroup", "${tg_product}", "LoadBalancer", "${alb_id}", { "label": "product", "color": "#ff7f0e" } ],
                    [ "AWS/ApplicationELB", "RequestCount", "TargetGroup", "${tg_stress}", "LoadBalancer", "${alb_id}", { "label": "stress", "color": "#2ca02c" } ]
                ]
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 5,
            "width": 5,
            "height": 5,
            "properties": {
                "title": "ALB 5xx / 4xx",
                "region": "${region}",
                "stat": "Sum",
                "period": 60,
                "metrics": [
                    [ "AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", "${alb_id}", { "label": "target 5xx", "color": "#d62728" } ],
                    [ "AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", "${alb_id}", { "label": "elb 5xx", "color": "#ff9896" } ],
                    [ "AWS/ApplicationELB", "HTTPCode_Target_4XX_Count", "LoadBalancer", "${alb_id}", { "label": "target 4xx", "color": "#ff7f0e" } ]
                ]
            }
        },
        {
            "type": "metric",
            "x": 14,
            "y": 5,
            "width": 5,
            "height": 5,
            "properties": {
                "metrics": [
                    [ "AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", "${rds_id}", { "label": "CPU", "color": "#1f77b4", "region": "${region}" } ]
                ],
                "title": "RDS CPU",
                "region": "${region}",
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
                "view": "timeSeries",
                "stacked": false
            }
        },
        {
            "type": "metric",
            "x": 19,
            "y": 5,
            "width": 5,
            "height": 5,
            "properties": {
                "title": "RDS Connections",
                "region": "${region}",
                "stat": "Average",
                "period": 60,
                "yAxis": {
                    "left": {
                        "min": 0,
                        "label": "connections"
                    }
                },
                "metrics": [
                    [ "AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", "${rds_id}" ]
                ]
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 0,
            "width": 9,
            "height": 5,
            "properties": {
                "title": "ALB 성공률",
                "region": "${region}",
                "period": 60,
                "view": "gauge",
                "stacked": false,
                "yAxis": {
                    "left": {
                        "min": 0,
                        "max": 100
                    }
                },
                "annotations": {
                    "horizontal": [
                        [
                            {
                                "label": "위험",
                                "value": 0,
                                "color": "#d62728"
                            },
                            {
                                "value": 90
                            }
                        ],
                        [
                            {
                                "label": "주의",
                                "value": 90,
                                "color": "#ff9900"
                            },
                            {
                                "value": 99
                            }
                        ],
                        [
                            {
                                "label": "정상",
                                "value": 99,
                                "color": "#2ca02c"
                            },
                            {
                                "value": 100
                            }
                        ]
                    ]
                },
                "metrics": [
                    [ "AWS/ApplicationELB", "HTTPCode_Target_2XX_Count", "TargetGroup", "${tg_user}", "LoadBalancer", "${alb_id}", { "id": "u2", "stat": "Sum", "visible": false } ],
                    [ "AWS/ApplicationELB", "RequestCount", "TargetGroup", "${tg_user}", "LoadBalancer", "${alb_id}", { "id": "ur", "stat": "Sum", "visible": false } ],
                    [ "AWS/ApplicationELB", "HTTPCode_Target_2XX_Count", "TargetGroup", "${tg_product}", "LoadBalancer", "${alb_id}", { "id": "p2", "stat": "Sum", "visible": false } ],
                    [ "AWS/ApplicationELB", "RequestCount", "TargetGroup", "${tg_product}", "LoadBalancer", "${alb_id}", { "id": "pr", "stat": "Sum", "visible": false } ],
                    [ "AWS/ApplicationELB", "HTTPCode_Target_2XX_Count", "TargetGroup", "${tg_stress}", "LoadBalancer", "${alb_id}", { "id": "s2", "stat": "Sum", "visible": false } ],
                    [ "AWS/ApplicationELB", "RequestCount", "TargetGroup", "${tg_stress}", "LoadBalancer", "${alb_id}", { "id": "sr", "stat": "Sum", "visible": false } ],
                    [ { "expression": "100 * u2 / ur", "label": "user", "id": "ru", "color": "#1f77b4" } ],
                    [ { "expression": "100 * p2 / pr", "label": "product", "id": "rp", "color": "#ff7f0e" } ],
                    [ { "expression": "100 * s2 / sr", "label": "stress", "id": "rs", "color": "#2ca02c" } ]
                ]
            }
        },
        {
            "type": "metric",
            "x": 9,
            "y": 10,
            "width": 6,
            "height": 5,
            "properties": {
                "title": "노드 개수",
                "region": "${region}",
                "stat": "Maximum",
                "period": 60,
                "view": "gauge",
                "yAxis": {
                    "left": {
                        "min": 0,
                        "max": 5
                    }
                },
                "annotations": {
                    "horizontal": [
                        [
                            {
                                "label": "정상",
                                "value": 0,
                                "color": "#2ca02c"
                            },
                            {
                                "value": 2
                            }
                        ],
                        [
                            {
                                "label": "주의",
                                "value": 2,
                                "color": "#ff9900"
                            },
                            {
                                "value": 3
                            }
                        ],
                        [
                            {
                                "label": "경보",
                                "value": 3,
                                "color": "#d62728"
                            },
                            {
                                "value": 5
                            }
                        ]
                    ]
                },
                "metrics": [
                    [ "ContainerInsights", "cluster_node_count", "ClusterName", "${cluster_name}", { "label": "nodes" } ]
                ]
            }
        },
        {
            "type": "metric",
            "x": 7,
            "y": 15,
            "width": 10,
            "height": 5,
            "properties": {
                "title": "파드 개수",
                "region": "${region}",
                "stat": "Maximum",
                "period": 60,
                "view": "gauge",
                "yAxis": {
                    "left": {
                        "min": 0,
                        "max": 8
                    }
                },
                "annotations": {
                    "horizontal": [
                        [
                            {
                                "label": "여유",
                                "value": 0,
                                "color": "#2ca02c"
                            },
                            {
                                "value": 4
                            }
                        ],
                        [
                            {
                                "label": "주의",
                                "value": 4,
                                "color": "#ff9900"
                            },
                            {
                                "value": 6
                            }
                        ],
                        [
                            {
                                "label": "포화",
                                "value": 6,
                                "color": "#d62728"
                            },
                            {
                                "value": 8
                            }
                        ]
                    ]
                },
                "metrics": [
                    [ "ContainerInsights", "service_number_of_running_pods", "ClusterName", "${cluster_name}", "Namespace", "${namespace}", "Service", "user-svc", { "label": "user" } ],
                    [ "ContainerInsights", "service_number_of_running_pods", "ClusterName", "${cluster_name}", "Namespace", "${namespace}", "Service", "product-svc", { "label": "product" } ],
                    [ "ContainerInsights", "service_number_of_running_pods", "ClusterName", "${cluster_name}", "Namespace", "${namespace}", "Service", "stress-svc", { "label": "stress" } ]
                ]
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 10,
            "width": 9,
            "height": 5,
            "properties": {
                "title": "노드 CPU 사용률",
                "region": "${region}",
                "stat": "Average",
                "period": 60,
                "yAxis": {
                    "left": {
                        "min": 0,
                        "max": 100,
                        "label": "CPU %"
                    }
                },
                "metrics": [
                    [ { "expression": "AVG(SEARCH('{ContainerInsights,ClusterName,InstanceId,NodeName} MetricName=\"node_cpu_utilization\" ClusterName=\"${cluster_name}\"', 'Average', 60))", "label": "노드 CPU 평균", "id": "c1", "region": "${region}" } ]
                ],
                "view": "timeSeries",
                "stacked": false
            }
        },
        {
            "type": "metric",
            "x": 15,
            "y": 10,
            "width": 9,
            "height": 5,
            "properties": {
                "title": "노드 메모리 사용률",
                "region": "${region}",
                "stat": "Average",
                "period": 60,
                "yAxis": {
                    "left": {
                        "min": 0,
                        "max": 100,
                        "label": "MEM %"
                    }
                },
                "metrics": [
                    [ { "expression": "AVG(SEARCH('{ContainerInsights,ClusterName,InstanceId,NodeName} MetricName=\"node_memory_utilization\" ClusterName=\"${cluster_name}\"', 'Average', 60))", "label": "노드 메모리 평균", "id": "m1", "region": "${region}" } ]
                ],
                "view": "timeSeries",
                "stacked": false
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 15,
            "width": 7,
            "height": 5,
            "properties": {
                "title": "파드 CPU 사용률",
                "region": "${region}",
                "stat": "Average",
                "period": 60,
                "yAxis": {
                    "left": {
                        "min": 0,
                        "label": "CPU %",
                        "max": 100
                    }
                },
                "metrics": [
                    [ { "expression": "AVG(SEARCH('{ContainerInsights,ClusterName,Namespace,PodName} MetricName=\"pod_cpu_utilization\" ClusterName=\"${cluster_name}\" Namespace=\"${namespace}\"', 'Average', 60))", "label": "파드 CPU 평균", "id": "e1", "region": "${region}" } ]
                ],
                "view": "timeSeries",
                "stacked": false
            }
        },
        {
            "type": "metric",
            "x": 17,
            "y": 15,
            "width": 7,
            "height": 5,
            "properties": {
                "title": "파드 메모리 사용률",
                "region": "${region}",
                "stat": "Average",
                "period": 60,
                "yAxis": {
                    "left": {
                        "min": 0,
                        "label": "MEM %",
                        "max": 100
                    }
                },
                "metrics": [
                    [ { "expression": "AVG(SEARCH('{ContainerInsights,ClusterName,Namespace,PodName} MetricName=\"pod_memory_utilization\" ClusterName=\"${cluster_name}\" Namespace=\"${namespace}\"', 'Average', 60))", "label": "파드 메모리 평균", "id": "e1" } ]
                ]
            }
        },
        {
            "type": "metric",
            "x": 15,
            "y": 0,
            "width": 9,
            "height": 5,
            "properties": {
                "title": "API 응답시간 SLO 달성률 (user/product <=0.2s, stress <=1.0s)",
                "region": "${region}",
                "period": 60,
                "view": "gauge",
                "stacked": false,
                "yAxis": {
                    "left": {
                        "min": 0,
                        "max": 100,
                        "label": "%"
                    }
                },
                "annotations": {
                    "horizontal": [
                        [
                            {
                                "label": "위험",
                                "value": 0,
                                "color": "#d62728"
                            },
                            {
                                "value": 80
                            }
                        ],
                        [
                            {
                                "label": "주의",
                                "value": 80,
                                "color": "#ff9900"
                            },
                            {
                                "value": 90
                            }
                        ],
                        [
                            {
                                "label": "양호",
                                "value": 90,
                                "color": "#2ca02c"
                            },
                            {
                                "value": 100
                            }
                        ]
                    ]
                },
                "metrics": [
                    [ "AWS/ApplicationELB", "TargetResponseTime", "TargetGroup", "${tg_user}", "LoadBalancer", "${alb_id}", { "stat": "PR(:0.2)", "label": "user (<=0.2s)", "color": "#1f77b4" } ],
                    [ "AWS/ApplicationELB", "TargetResponseTime", "TargetGroup", "${tg_product}", "LoadBalancer", "${alb_id}", { "stat": "PR(:0.2)", "label": "product (<=0.2s)", "color": "#ff7f0e" } ],
                    [ "AWS/ApplicationELB", "TargetResponseTime", "TargetGroup", "${tg_stress}", "LoadBalancer", "${alb_id}", { "stat": "PR(:1.0)", "label": "stress (<=1.0s)", "color": "#2ca02c" } ]
                ]
            }
        }
        %{ if cf_dist_id != "" }
        ,{
            "type": "metric",
            "x": 10,
            "y": 5,
            "width": 4,
            "height": 5,
            "properties": {
                "title": "CloudFront 캐시 히트율",
                "region": "us-east-1",
                "stat": "Average",
                "period": 60,
                "view": "gauge",
                "stacked": false,
                "yAxis": {
                    "left": {
                        "min": 0,
                        "max": 100,
                        "label": "%"
                    }
                },
                "annotations": {
                    "horizontal": [
                        [
                            {
                                "label": "낮음",
                                "value": 0,
                                "color": "#d62728"
                            },
                            {
                                "value": 50
                            }
                        ],
                        [
                            {
                                "label": "주의",
                                "value": 50,
                                "color": "#ff9900"
                            },
                            {
                                "value": 80
                            }
                        ],
                        [
                            {
                                "label": "양호",
                                "value": 80,
                                "color": "#2ca02c"
                            },
                            {
                                "value": 100
                            }
                        ]
                    ]
                },
                "metrics": [
                    [ "AWS/CloudFront", "CacheHitRate", "DistributionId", "${cf_dist_id}", "Region", "Global", { "label": "cache hit", "color": "#2ca02c" } ]
                ]
            }
        },
        {
            "type": "metric",
            "x": 5,
            "y": 5,
            "width": 5,
            "height": 5,
            "properties": {
                "title": "CloudFront 오리진 지연 (OriginLatency)",
                "region": "us-east-1",
                "period": 60,
                "view": "timeSeries",
                "stacked": false,
                "yAxis": {
                    "left": {
                        "min": 0,
                        "label": "ms"
                    }
                },
                "metrics": [
                    [ "AWS/CloudFront", "OriginLatency", "DistributionId", "${cf_dist_id}", "Region", "Global", { "stat": "Average", "label": "avg", "color": "#1f77b4" } ],
                    [ "AWS/CloudFront", "OriginLatency", "DistributionId", "${cf_dist_id}", "Region", "Global", { "stat": "p90", "label": "p90", "color": "#ff7f0e" } ],
                    [ "AWS/CloudFront", "OriginLatency", "DistributionId", "${cf_dist_id}", "Region", "Global", { "stat": "p99", "label": "p99", "color": "#d62728" } ]
                ]
            }
        }
        %{ endif ~}
    ]
}
