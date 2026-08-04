#!/bin/bash
# 美股量化模型每日自动更新 + Dashboard 部署 + CDN 缓存刷新
# 北京时间周二~周六 5:30 AM (美股收盘后)
cd /Users/tonyfu/Claude
LOG=/tmp/quant_daily_$(date +%Y%m%d).log
echo "=== $(date) ===" >> "$LOG"

BUILD="dash_$(date +%Y%m%d%H%M%S).html"
TOKEN_FILE="/Users/tonyfu/Claude/deploy/.gh_token"

# Step 1: 更新信号与调仓 (失败不退出)
python3 paper_trading_live.py update >> "$LOG" 2>&1 || true

# Step 2: 构建 Dashboard
python3 build_dashboard_live.py >> "$LOG" 2>&1 || true

# Step 3: 推送到 GitHub Pages — 重试 3 次避免 Actions 碰撞
cp outputs/dashboard/live.html "deploy/$BUILD"

printf '<!DOCTYPE html>\n<html lang="zh"><head>\n<meta charset="UTF-8"><meta http-equiv="Cache-Control" content="no-store,no-cache,must-revalidate">\n</head><body style="background:#0f1117;color:#e1e4e8;text-align:center;padding-top:40vh">\n<p>📊 加载中...</p>\n<script>\nvar b=localStorage.getItem("dash_ver"),c="%s";\nif(b!==c){document.querySelector("p").textContent="🔄 更新中...";localStorage.setItem("dash_ver",c)}\nlocation.replace("%s");\n</script>\n</body></html>\n' "$BUILD" "$BUILD" > deploy/index.html

git -C deploy add "$BUILD" index.html >> "$LOG" 2>&1
git -C deploy commit -m "Auto update $(date +%Y-%m-%d)" >> "$LOG" 2>&1 || true

for i in 1 2 3; do
  if git -C deploy pull --rebase origin main >> "$LOG" 2>&1 && git -C deploy push origin main >> "$LOG" 2>&1; then
    echo "Push OK on attempt $i" >> "$LOG"
    break
  fi
  echo "Push retry $i..." >> "$LOG"
  sleep 3
done

# Step 4: 刷新 CDN 缓存
if [ -f "$TOKEN_FILE" ]; then
  STATUS=$(curl -s -X POST "https://api.github.com/repos/TonyTCFu/cc-us-stock-dashboard/pages/builds" \
    -H "Authorization: Bearer $(cat "$TOKEN_FILE")" \
    -H "Accept: application/vnd.github+json" \
    -w "%{http_code}" -o /dev/null 2>/dev/null)
  echo "CDN cache bust: HTTP $STATUS" >> "$LOG"
fi

echo "Done: $(date)" >> "$LOG"
