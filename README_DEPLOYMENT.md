# 🎯 Быстрый старт: Деплой на Render.com

## ✅ Что было исправлено в проекте

### Прикрепление файлов - ПОЛНОСТЬЮ РАБОТАЕТ! ✅

1. **Контроллер** (`app/controllers/messages_controller.rb`):
   - Принимает массив файлов через `files: []`

2. **Форма** (`app/views/chats/show.html.erb`):
   - Правильное имя поля: `message[files][]`
   - Поддержка множественной загрузки
   - Превью перед отправкой

3. **Отображение** (`app/views/messages/_message.html.erb`):
   - Изображения с превью
   - Текстовые файлы с иконками и содержимым
   - Кнопки скачивания
   - Мобильная адаптация

4. **AI обработка** (`app/jobs/chat_response_job.rb`):
   - Изображения → base64 для vision models
   - Текстовые файлы → включаются в промпт
   - Поддержка .txt, .json, image/*

5. **База данных**:
   - PostgreSQL настроен через ENV переменные
   - Готов для Render

---

## 🚀 Деплой за 3 шага

### 1️⃣ Загрузите на GitHub

```bash
git init
git add .
git commit -m "Chat app with file upload support"
git remote add origin https://github.com/ваш-username/репо.git
git push -u origin main
```

### 2️⃣ Создайте сервисы на Render

**PostgreSQL:**
1. New + → PostgreSQL
2. Name: `my-chat-db`
3. Plan: Free (или Starter $7/mo)
4. Create Database
5. Скопируйте **Internal Database URL**

**Web Service:**
1. New + → Web Service
2. Connect Repository
3. Name: `my-chat-app`
4. Runtime: **Docker** (автоопределится)
5. Plan: Free (или Starter $7/mo)

### 3️⃣ Настройте переменные окружения

В настройках Web Service добавьте:

```bash
# ⚙️ ОБЯЗАТЕЛЬНЫЕ
DATABASE_URL=<скопируйте Internal Database URL>
SECRET_KEY_BASE=<сгенерируйте: rails secret>
PUBLIC_HOST=my-chat-app.onrender.com

# 🤖 LLM для AI чата (обязательно!)
LLM_BASE_URL=https://api.openai.com/v1
LLM_API_KEY=sk-ваш-ключ
LLM_MODEL=gpt-4o-mini

# 🐳 Rails
RAILS_ENV=production
RAILS_LOG_TO_STDOUT=enabled
RAILS_SERVE_STATIC_FILES=enabled
```

**Нажмите "Create Web Service"** - готово! 🎉

---

## 📁 Файлы: 2 варианта

### Вариант 1: Render Disk (проще)
1. В Web Service → Disks → Add Disk
2. Mount Path: `/rails/storage`
3. Size: 10GB

### Вариант 2: AWS S3 (для продакшн)
См. полное руководство в `DEPLOY_GUIDE.md`

---

## 🧪 После деплоя

### Создайте админа:
```bash
# В Render Shell (Environment → Shell):
rails runner "Administrator.create!(email: 'admin@example.com', password: 'admin123', name: 'Admin')"
```

### Проверьте:
1. Откройте `https://my-chat-app.onrender.com`
2. Войдите через Telegram
3. Создайте чат
4. Прикрепите изображение и текстовый файл
5. Отправьте - AI должен ответить с учетом файлов!

---

## 📦 Архив проекта

**app-archive.tar.gz** (3.1 MB)
- Весь исходный код
- Все исправления включены
- Готов к деплою
- Без node_modules и временных файлов

### Распаковка:
```bash
tar -xzf app-archive.tar.gz
cd app
```

---

## 🎯 Что работает

✅ Telegram авторизация  
✅ Создание чатов  
✅ Отправка сообщений  
✅ **Загрузка файлов (изображения, текст)**  
✅ **AI Vision (анализ изображений)**  
✅ **Чтение текстовых файлов**  
✅ Скачивание файлов  
✅ Мобильная адаптация  
✅ Админ панель  

---

## 💡 Полезные ссылки

- **Полное руководство**: `DEPLOY_GUIDE.md`
- **Инструкция по файлам**: `FILE_UPLOAD_INSTRUCTIONS.md`
- **Render Docs**: https://render.com/docs
- **Rails Guides**: https://guides.rubyonrails.org

---

## ⚡ Быстрая проверка после деплоя

```bash
# Проверка БД
rails runner "puts User.count"

# Проверка LLM
rails runner "puts LlmService.new(prompt: 'Hello').call"

# Проверка файлов
rails runner "puts ActiveStorage::Blob.count"
```

---

## 🆘 Проблемы?

**AI не отвечает:**
- Проверьте `LLM_API_KEY` и баланс
- Проверьте логи в Render

**Файлы не сохраняются:**
- Добавьте Persistent Disk или настройте S3

**Ошибка БД:**
- Проверьте `DATABASE_URL`
- Выполните `rails db:migrate` в Shell

---

## 🎉 Готово к продакшн!

Проект полностью готов к использованию с:
- ✅ Исправленной загрузкой файлов
- ✅ AI обработкой изображений и текста
- ✅ Telegram интеграцией
- ✅ Масштабируемой архитектурой

**Загружайте архив и деплойте! 🚀**
