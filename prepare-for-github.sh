#!/bin/bash

echo "🚀 Подготовка проекта для GitHub..."
echo ""

cd /home/runner/app

# Добавляем исключения в .gitignore
echo "📝 Обновление .gitignore..."
cat >> .gitignore << 'GITIGNORE'

# Archives
*.tar.gz
*.zip

# Documentation (optional - uncomment if don't want to upload)
# START_HERE.md
# DOWNLOAD_INSTRUCTIONS.txt
# ИТОГОВАЯ_ИНФОРМАЦИЯ.txt
# FILE_UPLOAD_INSTRUCTIONS.md
# test_file_upload.md
GITIGNORE

echo "✅ .gitignore обновлен"
echo ""

# Показываем статистику
echo "📊 Размер проекта:"
echo "   Весь проект: $(du -sh . 2>/dev/null | awk '{print $1}')"
echo "   node_modules: $(du -sh node_modules 2>/dev/null | awk '{print $1}' || echo 'не установлен')"
echo ""

echo "📦 Что будет загружено на GitHub:"
echo "   ✅ Код приложения (app/)"
echo "   ✅ Конфигурация (config/)"
echo "   ✅ Миграции БД (db/)"
echo "   ✅ Dockerfile"
echo "   ✅ Зависимости (Gemfile, package.json)"
echo "   ✅ README файлы"
echo ""

echo "❌ Что НЕ будет загружено:"
echo "   ❌ node_modules/ (восстановится через npm install)"
echo "   ❌ tmp/, log/ (временные файлы)"
echo "   ❌ storage/ (загруженные файлы)"
echo "   ❌ *.tar.gz (архивы)"
echo ""

echo "✨ Готово! Теперь выполните:"
echo ""
echo "   git init"
echo "   git add ."
echo "   git commit -m 'Initial commit: Chat app with file upload'"
echo "   git remote add origin https://github.com/ваш-username/ваш-репо.git"
echo "   git branch -M main"
echo "   git push -u origin main"
echo ""
