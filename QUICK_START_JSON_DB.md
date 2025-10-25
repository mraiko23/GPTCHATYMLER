# 🚀 Быстрый старт с JSON Database

## Установка и запуск за 3 шага

### Шаг 1: Инициализация базы данных
```bash
bundle exec rails runner "load 'db/seeds.rb'"
```

Это создаст файл `db/db.json` и администратора по умолчанию.

### Шаг 2: Сборка JavaScript assets
```bash
npm install
npm run build
```

### Шаг 3: Запуск приложения
```bash
bundle exec rails s
```

## 🌐 Доступ к приложению

После запуска откройте браузер:

- **Главная страница**: http://localhost:3000/
- **Админ панель**: http://localhost:3000/admin/login

### Данные для входа в админку:
- **Логин**: `admin`
- **Пароль**: `admin123`

## 📂 Где хранятся данные?

Вся база данных в одном файле:
```
db/db.json  ← ВСЯ база данных
```

Загруженные файлы:
```
storage/
  ├── uuid-1234...  ← Файл 1
  ├── uuid-5678...  ← Файл 2
  └── ...
```

## 📝 Как использовать

### Создание данных в Rails console

```bash
# Запустить консоль
bundle exec rails console

# Создать пользователя
user = User.create!(
  name: 'Test User',
  email: 'test@example.com',
  verified: true
)

# Создать чат
chat = user.chats.create!(title: 'Мой первый чат')

# Создать сообщение
message = Message.create!(
  chat_id: chat.id,
  role: 'user',
  content: 'Привет!'
)

# Посмотреть все чаты
Chat.all

# Найти пользователя
User.find_by(email: 'test@example.com')
```

### Просмотр базы данных

```bash
# Красивый вывод всей базы
cat db/db.json | jq '.'

# Посмотреть только пользователей
cat db/db.json | jq '.users'

# Посмотреть счетчики записей
cat db/db.json | jq '.counters'

# Размер базы данных
du -h db/db.json
```

## 🔄 Backup и восстановление

### Создать backup
```bash
cp db/db.json db/db.json.backup
```

### Восстановить из backup
```bash
cp db/db.json.backup db/db.json
```

### Backup с датой
```bash
cp db/db.json "db/db.json.$(date +%Y%m%d_%H%M%S)"
```

## 🗑️ Очистка данных

### Пересоздать базу с нуля
```bash
rm db/db.json
bundle exec rails runner "load 'db/seeds.rb'"
```

### Удалить все чаты (в console)
```ruby
Chat.destroy_all
Message.destroy_all
```

### Удалить всех пользователей (кроме админа)
```ruby
User.destroy_all
Session.destroy_all
```

## 📊 Мониторинг

### Посмотреть статистику
```bash
cat db/db.json | jq '.counters'
```

Вывод:
```json
{
  "users": 5,
  "sessions": 10,
  "chats": 15,
  "messages": 150,
  "administrators": 1,
  "admin_oplogs": 25,
  "active_storage_blobs": 8,
  "active_storage_attachments": 8
}
```

### Посмотреть последние сообщения
```bash
cat db/db.json | jq '.messages | sort_by(.created_at) | reverse | .[0:5]'
```

## 🔧 Troubleshooting

### База данных не создается
```bash
# Проверить существует ли папка db
ls -la db/

# Создать папку если нужно
mkdir -p db

# Запустить seeds заново
bundle exec rails runner "load 'db/seeds.rb'"
```

### Файлы не загружаются
```bash
# Проверить папку storage
ls -la storage/

# Создать если отсутствует
mkdir -p storage
```

### Ошибка при запуске сервера
```bash
# Проверить assets
npm run build

# Очистить tmp
rm -rf tmp/cache
```

### База данных повреждена
```bash
# Восстановить из backup
cp db/db.json.backup db/db.json

# Или пересоздать
rm db/db.json
bundle exec rails runner "load 'db/seeds.rb'"
```

## 📚 Дополнительная информация

Полная документация:
- **JSON_DATABASE_MIGRATION.md** - подробное описание миграции
- **MIGRATION_SUMMARY.md** - краткое резюме

## ✨ Готово!

Теперь вы можете работать с приложением, используя JSON базу данных!

Все данные хранятся в `db/db.json` - просто, удобно, портативно! 🎉
