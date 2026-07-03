#!/bin/bash
# 美股量化模型每日自动更新 + Dashboard 部署
# 北京时间周二~周六 5:30 AM (美股收盘后)
set -e
cd /Users/tonyfu/Claude
LOG=/tmp/quant_daily_$(date +%Y%m%d).log
echo "=== $(date) ===" >> "$LOG"

# 确保从项目根目录运行
export PATH="/usr/local/bin:/usr/bin:/bin"

python3 paper_trading_live.py update >> "$LOG" 2>&1
python3 build_dashboard_live.py >> "$LOG" 2>&1
cp outputs/dashboard/live.html deploy/dash.html
git -C deploy add dash.html >> "$LOG" 2>&1
git -C deploy commit -m "Auto update $(date +%Y-%m-%d)" >> "$LOG" 2>&1 || true
git -C deploy push origin main >> "$LOG" 2>&1

# 触发 GitHub Pages 重建，清除 CDN 缓存
TOKEN_FILE="/Users/tonyfu/Claude/deploy/.gh_token"
if [ -f "$TOKEN_FILE" ]; then
  GH_TOKEN=$(cat "$TOKEN_FILE")
  curl -s -X POST "https://api.github.com/repos/TonyTCFu/cc-us-stock-dashboard/pages/builds" \
    -H "Authorization: Bearer $GH_TOKEN" \
    -H "Accept: application/vnd.github+json" >> "$LOG" 2>&1
fi

echo "Done: $(date)" >> "$LOG"
