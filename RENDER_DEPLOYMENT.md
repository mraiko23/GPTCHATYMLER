# 🚀 Деплой на Render (Бесплатно)

Этот гайд поможет вам развернуть AiChat на Render бесплатно.

## 📋 Предварительные требования

1. Аккаунт на [Render](https://render.com)
2. Аккаунт на [GitHub](https://github.com)
3. Репозиторий: https://github.com/mraiko23/aichatYMLER
4. База данных PostgreSQL на Render (уже создана)

## 🔧 Шаг 1: Подготовка репозитория

Все необходимые файлы уже созданы:
- ✅ `render.yaml` - конфигурация деплоя
- ✅ `bin/render-build.sh` - скрипт сборки
- ✅ `config/database.yml` - настроена для production
- ✅ Gemfile и зависимости

## 🎯 Шаг 2: Создание Web Service на Render

### Вариант A: Через Blueprint (Рекомендуется)

1. **Перейдите на Render Dashboard**: https://dashboard.render.com/

2. **Нажмите "New +" → "Blueprint"**

3. **Подключите GitHub репозиторий**:
   - Выберите `mraiko23/aichatYMLER`
   - Render автоматически найдет `render.yaml`

4. **Настройте Environment Variables**:
   
   Render автоматически создаст переменные из `render.yaml`, но вам нужно добавить секретные:

   ```
   RAILS_MASTER_KEY=<ваш master key>
   CLACKY_LLM_API_KEY=<ваш Clacky API ключ>
   ```

   **Где найти RAILS_MASTER_KEY:**
   ```bash
   cat config/master.key
   ```

5. **Нажмите "Apply"** - Render создаст:
   - Web Service (aichat-web)
   - База данных уже существует: `testaichatbot-db`

6. **Подождите завершения деплоя** (5-10 минут)

### Вариант B: Ручная настройка

1. **Создайте Web Service**:
   - New + → Web Service
   - Connect Repository: `mraiko23/aichatYMLER`
   - Name: `aichat-web`
   - Runtime: Ruby
   - Build Command: `./bin/render-build.sh`
   - Start Command: `bundle exec puma -C config/puma.rb`

2. **Настройте Environment Variables**:

   | Переменная | Значение |
   |-----------|---------|
   | `DATABASE_URL` | Подключите вашу БД (уже существует) |
   | `RAILS_ENV` | `production` |
   | `RAILS_MASTER_KEY` | Из `config/master.key` |
   | `CLACKY_LLM_API_KEY` | Ваш API ключ от Clacky |
   | `CLACKY_LLM_BASE_URL` | `https://proxy.clacky.ai` |
   | `CLACKY_LLM_MODEL` | `gemini-2.5-flash` |
   | `CLACKY_IMAGE_GEN_MODEL` | `gemini-2.5-flash` |
   | `RAILS_LOG_TO_STDOUT` | `enabled` |
   | `RAILS_SERVE_STATIC_FILES` | `enabled` |

3. **Подключите существующую БД**:
   - В настройках Web Service найдите "Environment"
   - Для `DATABASE_URL` выберите: "From Database"
   - Выберите: `testaichatbot-db`
   - Property: `Connection String`

## 🗄️ Шаг 3: Проверка базы данных

Ваша БД уже существует:
- **Name**: testaichatbot-db
- **Connection String**: `postgresql://testaichatbot_db_user:xcp9w3hvdRdJ4XuxZTgggbMxliDfC5rj@dpg-d3trkn0gjchc73fga140-a/testaichatbot_db`

Если нужно создать новую:
1. Dashboard → New + → PostgreSQL
2. Name: любое имя
3. Plan: Free
4. Region: выберите ближайший
5. После создания скопируйте External Database URL

## 🔑 Шаг 4: Получение RAILS_MASTER_KEY

Если у вас нет `config/master.key`, создайте его:

```bash
# В локальной разработке
EDITOR="cat" rails credentials:edit
# Скопируйте ключ из вывода
```

Или создайте новый:
```bash
rails credentials:edit
# Rails создаст новый master.key
cat config/master.key
```

## ✅ Шаг 5: Проверка деплоя

1. **Откройте URL вашего приложения**:
   - Render покажет URL типа: `https://aichat-web-xyz.onrender.com`

2. **Проверьте логи**:
   - В Dashboard → aichat-web → Logs
   - Убедитесь что нет ошибок

3. **Создайте админа** (если нужно):
   ```bash
   # Через Render Shell
   rails console
   User.create!(username: 'admin', password: 'your_password', role: 'admin')
   ```

## 🐛 Troubleshooting

### Ошибка: "Asset precompilation failed"
```bash
# Убедитесь что все зависимости установлены
bundle install
npm install
```

### Ошибка: "Database connection failed"
- Проверьте что `DATABASE_URL` правильно настроен
- Убедитесь что БД существует и доступна

### Ошибка: "Missing master key"
- Добавьте `RAILS_MASTER_KEY` в Environment Variables
- Значение из `config/master.key`

### Медленная первая загрузка
- Бесплатный план Render "засыпает" после 15 минут неактивности
- Первая загрузка может занять 30-60 секунд
- Последующие запросы будут быстрыми

## 📊 Мониторинг

- **Logs**: Render Dashboard → Logs
- **Metrics**: Render Dashboard → Metrics  
- **Shell**: Render Dashboard → Shell (для rails console)

## 💡 Полезные команды

### Через Render Shell
```bash
# Открыть Rails консоль
rails console

# Запустить миграции
rails db:migrate

# Проверить статус
rails db:migrate:status

# Создать админа
User.create!(username: 'admin', password: 'password', role: 'admin')
```

## 🎉 Готово!

Ваше приложение теперь доступно по адресу:
`https://aichat-web-<your-id>.onrender.com`

### Возможности бесплатного плана:
- ✅ 750 часов в месяц
- ✅ Автоматический SSL
- ✅ CDN
- ✅ PostgreSQL (90 дней хранения)
- ⚠️ "Засыпает" после 15 минут неактивности

### Upgrade для production:
- Paid план ($7/месяц): без "засыпания", больше ресурсов
- PostgreSQL Paid ($7/месяц): постоянное хранение данных

## 🔐 Безопасность

**ВАЖНО**: Не коммитьте в Git:
- ❌ `config/master.key`
- ❌ `config/application.yml`
- ❌ API ключи
- ❌ Пароли от БД

Все секреты должны быть в Environment Variables на Render!
