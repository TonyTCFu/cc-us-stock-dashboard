#!/bin/bash
# 自动部署 Dashboard 到 GitHub Pages
# 每次 paper_trading_live.py update 后执行
# 用法: bash deploy/deploy.sh

set -e
cd "$(dirname "$0")"

# 从 main 项目复制最新 Dashboard
mkdir -p "$(dirname "$0")"
cp /Users/tonyfu/Claude/outputs/dashboard/live.html "$(dirname "$0")/index.html"

cd /Users/tonyfu/Claude/deploy

# 推送
git add index.html
git commit -m "Update $(date '+%Y-%m-%d %H:%M')" || exit 0
git push origin main

echo "Deployed: https://cc-us-stock-dashboard.futienchun.com"
