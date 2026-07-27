{
    "widgets": [
        {
            "type": "metric",
            "x": 0, "y": 0, "width": 6, "height": 6,
            "properties": {
                "title": "ALB 응답시간 (TargetResponseTime)",
                "region": "ap-northeast-2",
                "stat": "Average", "period": 60,
                "yAxis": { "left": { "min": 0, "label": "seconds" } },
                "metrics": [
                    [ "AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", "${alb_id}", { "stat": "Average", "label": "avg" } ],
                    [ "...", { "stat": "p95", "label": "p95" } ],
                    [ "...", { "stat": "p99", "label": "p99" } ]
                ]
            }
        },
        {
            "type": "metric",
            "x": 6, "y": 0, "width": 6, "height": 6,
            "properties": {
                "title": "ALB 5xx / 4xx",
                "region": "ap-northeast-2",
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
            "x": 12, "y": 0, "width": 6, "height": 6,
            "properties": {
                "title": "파드 CPU 사용률 (%)",
                "region": "ap-northeast-2",
                "stat": "Average", "period": 60,
                "yAxis": { "left": { "min": 0, "label": "CPU %" } },
                "metrics": [
                    [ { "expression": "SEARCH('{ContainerInsights,ClusterName,Namespace,PodName} MetricName=\"pod_cpu_utilization\" ClusterName=\"apdev-eks-cluster\" Namespace=\"apdev\"', 'Average', 60)", "label": "", "id": "e1" } ]
                ]
            }
        },
        {
            "type": "metric",
            "x": 18, "y": 0, "width": 6, "height": 6,
            "properties": {
                "title": "파드 메모리 사용률 (%)",
                "region": "ap-northeast-2",
                "stat": "Average", "period": 60,
                "yAxis": { "left": { "min": 0, "label": "MEM %" } },
                "metrics": [
                    [ { "expression": "SEARCH('{ContainerInsights,ClusterName,Namespace,PodName} MetricName=\"pod_memory_utilization\" ClusterName=\"apdev-eks-cluster\" Namespace=\"apdev\"', 'Average', 60)", "label": "", "id": "e1" } ]
                ]
            }
        },
        {
            "type": "metric",
            "x": 0, "y": 6, "width": 6, "height": 6,
            "properties": {
                "title": "RDS CPU / 메모리",
                "region": "ap-northeast-2",
                "stat": "Average", "period": 60,
                "yAxis": { "left": { "min": 0, "max": 100, "label": "CPU %" }, "right": { "min": 0, "label": "bytes" } },
                "metrics": [
                    [ "AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", "apdev-rds-instance", { "label": "CPU %", "color": "#1f77b4" } ],
                    [ "AWS/RDS", "FreeableMemory", "DBInstanceIdentifier", "apdev-rds-instance", { "label": "freeable mem", "yAxis": "right", "color": "#2ca02c" } ]
                ]
            }
        },
        {
            "type": "metric",
            "x": 6, "y": 6, "width": 6, "height": 6,
            "properties": {
                "title": "RDS 커넥션 수 (DatabaseConnections)",
                "region": "ap-northeast-2",
                "stat": "Average", "period": 60,
                "yAxis": { "left": { "min": 0, "label": "connections" } },
                "metrics": [
                    [ "AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", "apdev-rds-instance" ]
                ]
            }
        },
        {
            "type": "metric",
            "x": 12, "y": 6, "width": 6, "height": 6,
            "properties": {
                "title": "파드 개수 (namespace)",
                "region": "ap-northeast-2",
                "stat": "Average", "period": 60,
                "yAxis": { "left": { "min": 0, "label": "pods" } },
                "metrics": [
                    [ "ContainerInsights", "namespace_number_of_running_pods", "ClusterName", "apdev-eks-cluster", "Namespace", "apdev", { "label": "apdev pods" } ]
                ]
            }
        },
        {
            "type": "metric",
            "x": 18, "y": 6, "width": 6, "height": 6,
            "properties": {
                "title": "노드 CPU / 메모리",
                "region": "ap-northeast-2",
                "stat": "Average", "period": 60,
                "yAxis": { "left": { "min": 0, "max": 100, "label": "%" } },
                "metrics": [
                    [ { "expression": "SEARCH('{ContainerInsights,ClusterName,InstanceId,NodeName} MetricName=\"node_cpu_utilization\" ClusterName=\"apdev-eks-cluster\"', 'Average', 60)", "label": "CPU", "id": "c1" } ],
                    [ { "expression": "SEARCH('{ContainerInsights,ClusterName,InstanceId,NodeName} MetricName=\"node_memory_utilization\" ClusterName=\"apdev-eks-cluster\"', 'Average', 60)", "label": "MEM", "id": "m1" } ]
                ]
            }
        }
    ]
}
