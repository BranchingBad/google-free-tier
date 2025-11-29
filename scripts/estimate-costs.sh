#!/bin/bash
echo "Monthly Cost Estimate:"
echo "- e2-micro VM: $0 (Always Free)"
echo "- 30GB Storage: $0 (Always Free)"
echo "- Network Egress (>1GB): $0.12/GB"
echo "- GKE Autopilot (if enabled): $20-30/month minimum"
read -p "Expected monthly egress (GB): " egress
if [ "$egress" -gt 1 ]; then
  cost=$(echo "($egress - 1) * 0.12" | bc)
  echo "Estimated egress cost: \$$cost"
fi
