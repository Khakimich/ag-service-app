#!/usr/bin/env bash
# AG_WEBFAST2: быстрая сборка веб-версии и выкладка на VPS (app.autogrom.ru)
# Всё (CanvasKit + шрифт) отдаётся с вашего сервера, без gstatic.com.
#
# Запуск из папки проекта:
#   VPS=root@IP_СЕРВЕРА  WEB_DIR=/var/www/app.autogrom.ru  ./deploy_web.sh
set -euo pipefail

VPS="${VPS:?Укажите VPS=user@ip}"
WEB_DIR="${WEB_DIR:?Укажите WEB_DIR=/путь/к/сайту/на/сервере}"

# 1. Шрифт с кириллицей (один раз)
mkdir -p assets/fonts
if [ ! -s assets/fonts/Roboto.ttf ]; then
  echo "Скачиваю шрифт Roboto..."
  curl -fL -o assets/fonts/Roboto.ttf \
    "https://github.com/google/fonts/raw/main/ofl/roboto/Roboto%5Bwdth,wght%5D.ttf"
fi

# 2. Сборка без CDN Google
flutter pub get
flutter build web --release --no-web-resources-cdn

# 3. Проверка, что CanvasKit лежит локально
[ -d build/web/canvaskit ] || { echo "Нет build/web/canvaskit — обновите Flutter (нужен 3.22+)"; exit 1; }

# 4. Резервная копия на сервере и выкладка
ssh "$VPS" "cp -a '$WEB_DIR' '${WEB_DIR}.bak_$(date +%Y%m%d_%H%M)'"
rsync -az --delete build/web/ "$VPS:$WEB_DIR/"

echo "Готово. Откройте https://app.autogrom.ru и обновите страницу (Ctrl+F5)."
