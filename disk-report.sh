#!/bin/bash
echo "=== $(date --iso-8601=seconds) ===" >> /var/log/disk-report.log
df -h / >> /var/log/disk-report.logo
