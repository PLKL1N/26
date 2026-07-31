{
    "widgets": [
        {
            "type": "metric",
            "x": 0, "y": 0, "width": 5, "height": 6,
            "properties": {
                "title": "ALB 응답시간 (TargetResponseTime)",
                "region": "${region}",
                "stat": "Average", "period": 60,
                "yAxis": { "left": { "min": 0, "label": "seconds" } },
                "metrics": [
                    [ "AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", "${alb_id}", { "stat": "Average", "label": "avg", "region": "${region}" } ],
                    [ "AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", "${alb_id}", { "stat": "p95", "label": "p95", "region": "${region}" } ],
                    [ "AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", "${alb_id}", { "stat": "p99", "label": "p99", "region": "${region}" } ]
                ]
            }
        },
        {
            "type": "metric",
            "x": 5, "y": 0, "width": 5, "height": 6,
            "properties": {
                "title": "ALB 요청수",
                "region": "${region}",
                "stat": "Sum", "period": 60,
                "view": "timeSeries", "stacked": false,
                "yAxis": { "left": { "min": 0, "label": "requests/min" } },
                "metrics": [
                    [ "AWS/ApplicationELB", "RequestCount", "TargetGroup", "${tg_user}", "LoadBalancer", "${alb_id}", { "label": "user", "color": "#1f77b4" } ],
                    [ "AWS/ApplicationELB", "RequestCount", "TargetGroup", "${tg_product}", "LoadBalancer", "${alb_id}", { "label": "product", "color": "#ff7f0e" } ],
                    [ "AWS/ApplicationELB", "RequestCount", "TargetGroup", "${tg_stress}", "LoadBalancer", "${alb_id}", { "label": "stress", "color": "#2ca02c" } ]
                ]
            }
        },
        {
            "type": "metric",
            "x": 10, "y": 0, "width": 5, "height": 6,
            "properties": {
                "title": "ALB 5xx / 4xx",
                "region": "${region}",
                "stat": "Sum", "period": 60,
                "metrics": [
                    [ "AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", "${alb_id}", { "label": "target 5xx", "color": "#d62728" } ],
                    [ "AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", "${alb_id}", { "label": "elb 5xx", "color": "#ff9896" } ],
                    [ "AWS/ApplicationELB", "HTTPCode_Target_4XX_Count", "LoadBalancer", "${alb_id}", { "label": "target 4xx", "color": "#ff7f0e" } ]
                ]
            }
        },
        {
            "type": "metric",
            "x": 15, "y": 0, "width": 9, "height": 6,
            "properties": {
                "title": "ALB 성공률",
                "region": "${region}", "period": 60,
                "view": "gauge", "stacked": false,
                "yAxis": { "left": { "min": 0, "max": 100 } },
                "annotations": {
                    "horizontal": [
                        [ { "label": "위험", "value": 0, "color": "#d62728" }, { "value": 90 } ],
                        [ { "label": "주의", "value": 90, "color": "#ff9900" }, { "value": 99 } ],
                        [ { "label": "정상", "value": 99, "color": "#2ca02c" }, { "value": 100 } ]
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
            "x": 0, "y": 6, "width": 5, "height": 6,
            "properties": {
                "metrics": [
                    [ "AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", "${rds_id}", { "label": "CPU", "color": "#1f77b4", "region": "${region}" } ]
                ],
                "title": "RDS CPU",
                "region": "${region}",
                "stat": "Average", "period": 60,
                "yAxis": { "left": { "min": 0, "max": 100, "label": "CPU %" }, "right": { "min": 0, "label": "bytes" } },
                "view": "timeSeries", "stacked": false
            }
        },
        {
            "type": "metric",
            "x": 5, "y": 6, "width": 5, "height": 6,
            "properties": {
                "title": "RDS 커넥션 수 (DatabaseConnections)",
                "region": "${region}",
                "stat": "Average", "period": 60,
                "yAxis": { "left": { "min": 0, "label": "connections" } },
                "metrics": [
                    [ "AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", "${rds_id}" ]
                ]
            }
        },
        {
            "type": "metric",
            "x": 15, "y": 6, "width": 9, "height": 6,
            "properties": {
                "title": "파드 개수 (앱별)",
                "region": "${region}",
                "stat": "Maximum", "period": 60, "view": "gauge",
                "yAxis": { "left": { "min": 0, "max": 8 } },
                "annotations": {
                    "horizontal": [
                        [ { "label": "여유", "value": 0, "color": "#2ca02c" }, { "value": 4 } ],
                        [ { "label": "주의", "value": 4, "color": "#ff9900" }, { "value": 6 } ],
                        [ { "label": "포화", "value": 6, "color": "#d62728" }, { "value": 8 } ]
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
            "x": 0, "y": 12, "width": 6, "height": 6,
            "properties": {
                "title": "파드 CPU 사용률 (%)",
                "region": "${region}",
                "stat": "Average", "period": 60,
                "yAxis": { "left": { "min": 0, "label": "CPU %" } },
                "metrics": [
                    [ { "expression": "SEARCH('{ContainerInsights,ClusterName,Namespace,PodName} MetricName=\"pod_cpu_utilization\" ClusterName=\"${cluster_name}\" Namespace=\"${namespace}\"', 'Average', 60)", "label": "", "id": "e1" } ]
                ]
            }
        },
        {
            "type": "metric",
            "x": 6, "y": 12, "width": 6, "height": 6,
            "properties": {
                "title": "파드 메모리 사용률 (%)",
                "region": "${region}",
                "stat": "Average", "period": 60,
                "yAxis": { "left": { "min": 0, "label": "MEM %" } },
                "metrics": [
                    [ { "expression": "SEARCH('{ContainerInsights,ClusterName,Namespace,PodName} MetricName=\"pod_memory_utilization\" ClusterName=\"${cluster_name}\" Namespace=\"${namespace}\"', 'Average', 60)", "label": "", "id": "e1" } ]
                ]
            }
        },
        {
            "type": "metric",
            "x": 12, "y": 12, "width": 6, "height": 6,
            "properties": {
                "title": "노드 CPU / 메모리",
                "region": "${region}",
                "stat": "Average", "period": 60,
                "yAxis": { "left": { "min": 0, "max": 100, "label": "%" } },
                "metrics": [
                    [ { "expression": "SEARCH('{ContainerInsights,ClusterName,InstanceId,NodeName} MetricName=\"node_cpu_utilization\" ClusterName=\"${cluster_name}\"', 'Average', 60)", "label": "CPU", "id": "c1" } ],
                    [ { "expression": "SEARCH('{ContainerInsights,ClusterName,InstanceId,NodeName} MetricName=\"node_memory_utilization\" ClusterName=\"${cluster_name}\"', 'Average', 60)", "label": "MEM", "id": "m1" } ]
                ]
            }
        }
    ]
}
