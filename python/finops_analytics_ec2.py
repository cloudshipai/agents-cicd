#!/usr/bin/env python3
import argparse
import json
import os
import sys
import datetime
from typing import List, Dict, Any, Optional

# Optional boto3 import; script should still work offline with --input-json
try:
    import boto3  # type: ignore
    from botocore.exceptions import BotoCoreError, ClientError  # type: ignore
except Exception:  # pragma: no cover
    boto3 = None  # type: ignore

INSTANCE_SIZE_ORDER = [
    "nano","micro","small","medium","large","xlarge",
    "2xlarge","3xlarge","4xlarge","6xlarge","8xlarge","9xlarge",
    "10xlarge","12xlarge","16xlarge","18xlarge","24xlarge","32xlarge"
]

def parse_args():
    p = argparse.ArgumentParser(description="FinOps Optimization: finops_analytics_ec2")
    p.add_argument("--region", default=os.getenv("AWS_REGION", "us-east-1"))
    p.add_argument("--profile", default=os.getenv("AWS_PROFILE"))
    p.add_argument("--station", default="undefined")
    p.add_argument("--current-cost", type=float, default=2332.74)
    p.add_argument("--days", type=int, default=14, help="Observation window in days")
    p.add_argument("--cpu-threshold", type=float, default=10.0, help="Avg CPU threshold (%) to mark underutilized")
    p.add_argument("--network-threshold", type=float, default=1_000_000.0, help="Avg bytes/sec threshold for low network")
    p.add_argument("--input-json", help="Path to offline instance metrics JSON")
    p.add_argument("--aws-live", action="store_true", help="Enable live AWS fetch (requires boto3 and credentials)")
    p.add_argument("--output-json", help="Optional path to write JSON output")
    return p.parse_args()

def normalize_tags(tags: Any) -> Dict[str, str]:
    if isinstance(tags, dict):
        return {str(k): str(v) for k, v in tags.items()}
    if isinstance(tags, list):
        out = {}
        for t in tags:
            k = t.get("Key"); v = t.get("Value")
            if k is not None:
                out[str(k)] = str(v) if v is not None else ""
        return out
    return {}

def size_index(instance_type: str) -> Optional[int]:
    try:
        family, size = instance_type.split(".")
    except ValueError:
        return None
    if size in INSTANCE_SIZE_ORDER:
        return INSTANCE_SIZE_ORDER.index(size)
    return None

def next_smaller_type(instance_type: str) -> Optional[str]:
    try:
        family, size = instance_type.split(".")
    except ValueError:
        return None
    if size not in INSTANCE_SIZE_ORDER:
        return None
    idx = INSTANCE_SIZE_ORDER.index(size)
    if idx == 0:
        return None
    return f"{family}.{INSTANCE_SIZE_ORDER[idx-1]}"

def approximate_weight(instance_type: str) -> float:
    idx = size_index(instance_type)
    if idx is None:
        return 1.0
    return float(2 ** idx)

def is_non_prod(tags: Dict[str, str]) -> bool:
    for key in ("env","environment","stage","Environment","Stage","Env"):
        val = tags.get(key, "").lower()
        if val:
            return val in ("dev","development","test","qa","staging","sandbox","nonprod","non-prod")
    name = tags.get("Name", "").lower()
    if name:
        return any(x in name for x in ("dev","test","qa","staging","sandbox"))
    return True

def fetch_instances_from_aws(region: str, profile: Optional[str], days: int) -> List[Dict[str, Any]]:
    if boto3 is None:
        raise RuntimeError("boto3 not available; run with --input-json or install boto3.")
    try:
        session = boto3.Session(profile_name=profile, region_name=region) if profile else boto3.Session(region_name=region)
        ec2 = session.client("ec2", region_name=region)
        cw = session.client("cloudwatch", region_name=region)
    except Exception as e:
        raise RuntimeError(f"Failed to init AWS clients: {e}")

    instances = []
    try:
        paginator = ec2.get_paginator("describe_instances")
        for page in paginator.paginate():
            for res in page.get("Reservations", []):
                for inst in res.get("Instances", []):
                    instances.append(inst)
    except (BotoCoreError, ClientError) as e:
        raise RuntimeError(f"describe_instances failed: {e}")

    end = datetime.datetime.utcnow()
    start = end - datetime.timedelta(days=days)

    enriched = []
    for inst in instances:
        if inst.get("State", {}).get("Name") not in ("running", "stopped"):
            continue
        iid = inst.get("InstanceId")
        itype = inst.get("InstanceType", "unknown")
        tags = normalize_tags(inst.get("Tags", []))

        cpu_avg = None
        net_avg_bps = None
        try:
            metrics = cw.get_metric_statistics(
                Namespace="AWS/EC2",
                MetricName="CPUUtilization",
                Dimensions=[{"Name": "InstanceId", "Value": iid}],
                StartTime=start,
                EndTime=end,
                Period=3600,
                Statistics=["Average"],
                Unit="Percent"
            )
            datapoints = metrics.get("Datapoints", [])
            if datapoints:
                cpu_avg = sum(dp["Average"] for dp in datapoints) / len(datapoints)
        except (BotoCoreError, ClientError):
            cpu_avg = None

        try:
            in_stats = cw.get_metric_statistics(
                Namespace="AWS/EC2",
                MetricName="NetworkIn",
                Dimensions=[{"Name": "InstanceId", "Value": iid}],
                StartTime=start,
                EndTime=end,
                Period=3600,
                Statistics=["Average"],
                Unit="Bytes"
            )
            out_stats = cw.get_metric_statistics(
                Namespace="AWS/EC2",
                MetricName="NetworkOut",
                Dimensions=[{"Name": "InstanceId", "Value": iid}],
                StartTime=start,
                EndTime=end,
                Period=3600,
                Statistics=["Average"],
                Unit="Bytes"
            )
            in_dp = in_stats.get("Datapoints", [])
            out_dp = out_stats.get("Datapoints", [])
            if in_dp or out_dp:
                in_avg = sum(dp["Average"] for dp in in_dp) / max(1, len(in_dp)) if in_dp else 0.0
                out_avg = sum(dp["Average"] for dp in out_dp) / max(1, len(out_dp)) if out_dp else 0.0
                net_avg_bps = (in_avg + out_avg) / 3600.0
        except (BotoCoreError, ClientError):
            net_avg_bps = None

        enriched.append({
            "InstanceId": iid,
            "InstanceType": itype,
            "State": inst.get("State", {}).get("Name"),
            "Tags": tags,
            "AverageCPUUtilization": cpu_avg,
            "AverageNetworkBps": net_avg_bps
        })
    return enriched

def load_instances_from_file(path: str) -> List[Dict[str, Any]]:
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
    if isinstance(data, dict) and "instances" in data:
        return data["instances"]
    if isinstance(data, list):
        return data
    raise ValueError("Unsupported input JSON format")

def analyze(instances: List[Dict[str, Any]], current_cost: float, cpu_threshold: float, network_threshold: float) -> Dict[str, Any]:
    running = [i for i in instances if i.get("State") == "running"]
    if not running:
        return {
            "total_estimated_savings": 0.0,
            "recommendations": [],
        }
    weights = []
    for i in running:
        w = approximate_weight(i.get("InstanceType","unknown"))
        weights.append(max(1.0, w))
    total_weight = sum(weights) if weights else 1.0

    recs = []
    total_savings = 0.0

    for idx, inst in enumerate(running):
        iid = inst.get("InstanceId","unknown")
        itype = inst.get("InstanceType","unknown")
        tags = normalize_tags(inst.get("Tags", {}))
        cpu = inst.get("AverageCPUUtilization")
        net = inst.get("AverageNetworkBps")
        cost_share = current_cost * (max(1.0, approximate_weight(itype)) / total_weight)

        reasons = []
        actions = []
        est_save = 0.0
        details = {}

        under_cpu = (cpu is not None and cpu < cpu_threshold)
        under_net = (net is not None and net < network_threshold)

        if is_non_prod(tags) and (under_cpu or under_net):
            actions.append("scheduling")
            sched_saving_pct = 0.5
            est_save += cost_share * sched_saving_pct
            reasons.append(f"Non-prod underutilized: CPU={cpu if cpu is not None else 'n/a'}% Net={int(net) if net is not None else 'n/a'} B/s")
            details["schedule_suggestion"] = "Schedule to 12h/day Mon-Fri (approx 50% savings)"

        if under_cpu and under_net:
            smaller = next_smaller_type(itype)
            if smaller:
                actions.append("rightsizing")
                rightsize_saving_pct = 0.5
                est_save += cost_share * rightsize_saving_pct
                reasons.append("Low CPU and low network over observation window")
                details["proposed_instance_type"] = smaller

        if actions:
            total_savings += est_save
            recs.append({
                "instance_id": iid,
                "instance_type": itype,
                "tags": tags,
                "actions": actions,
                "reason": "; ".join(reasons) if reasons else "",
                "estimated_monthly_savings": round(est_save, 2),
                **details
            })

    return {
        "total_estimated_savings": round(total_savings, 2),
        "recommendations": recs
    }

def main():
    args = parse_args()
    try:
        if args.input_json:
            instances = load_instances_from_file(args.input_json)
        elif args.aws_live:
            instances = fetch_instances_from_aws(args.region, args.profile, args.days)
        else:
            raise SystemExit("Provide --input-json for offline analysis or use --aws-live with AWS credentials.")
    except Exception as e:
        print(json.dumps({"error": str(e)}), file=sys.stderr)
        sys.exit(1)

    result = analyze(
        instances=instances,
        current_cost=args.current_cost,
        cpu_threshold=args.cpu_threshold,
        network_threshold=args.network_threshold
    )

    output = {
        "metadata": {
            "station": args.station,
            "region": args.region,
            "observation_days": args.days,
            "cpu_threshold_percent": args.cpu_threshold,
            "network_threshold_bps": args.network_threshold,
            "current_cost": args.current_cost
        },
        "analysis": result
    }

    out_str = json.dumps(output, indent=2)
    if args.output_json:
        with open(args.output_json, "w", encoding="utf-8") as f:
            f.write(out_str)
    print(out_str)

if __name__ == "__main__":
    main()
