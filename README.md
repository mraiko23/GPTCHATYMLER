# AI Chat Application with Telegram Authentication

A modern AI chat application built with Ruby on Rails, featuring Telegram authentication, multiple AI providers, and file attachment support.

## Features

- 🤖 **Multiple AI Providers**: OpenRouter, Perplexity, OpenAI
- 📱 **Telegram Authentication**: Secure login via Telegram
- 📎 **File Attachments**: Send images and documents to AI
- 💬 **Real-time Chat**: WebSocket-based live responses
- 📊 **JSON Database**: No PostgreSQL required - uses JSON file storage
- 🎨 **Mobile-First Design**: Responsive UI optimized for mobile

## Tech Stack

- **Backend**: Ruby on Rails 7.2
- **Frontend**: Hotwire (Turbo + Stimulus)
- **Database**: Custom JSON-based storage (no SQL needed)
- **File Storage**: Local filesystem with UUID-based keys
- **Real-time**: ActionCable (WebSockets)
- **Styling**: TailwindCSS

## Quick Start

### Local Development

1. **Clone the repository**
   ```bash
   git clone https://github.com/mraiko23/aichatYMLER.git
   cd aichatYMLER
   git checkout chore/init-clacky-env
   ```

2. **Install dependencies**
   ```bash
   bundle install
   npm install
   ```

3. **Set up environment variables**
   ```bash
   cp .env.example .env
   # Edit .env with your API keys
   ```

4. **Initialize database**
   ```bash
   rails db:seed
   ```

5. **Start the server**
   ```bash
   rails server
   ```

6. **Access the application**
   ```
   http://localhost:3000
   ```

### Railway Deployment

See [RAILWAY_DEPLOYMENT.md](RAILWAY_DEPLOYMENT.md) for detailed deployment instructions.

Quick steps:
1. Fork this repository
2. Create new Railway project from GitHub
3. Set environment variables (see `.env.example`)
4. Deploy automatically

## Configuration

### Required Environment Variables

```bash
SECRET_KEY_BASE=          # Generate with: rails secret
TELEGRAM_BOT_TOKEN=       # From @BotFather
TELEGRAM_BOT_USERNAME=    # Your bot's username
```

### API Keys (at least one required)

```bash
OPENROUTER_API_KEY=       # From https://openrouter.ai
PERPLEXITY_API_KEY=       # From https://www.perplexity.ai
OPENAI_API_KEY=           # From https://platform.openai.com
```

## Architecture

### JSON Database

This application uses a custom JSON-based database instead of traditional SQL:

- **Location**: `db/db.json`
- **Thread-safe**: File locking for concurrent access
- **Schema**: Defined in models using `JsonModel` base class
- **Migrations**: Not needed - schema is implicit

### File Storage

Files are stored in `/storage` directory:
- UUID-based filenames for security
- Metadata in `active_storage_blobs` table
- Served via `StorageController` with authentication

### Models

- `User`: Telegram-authenticated users
- `Chat`: Conversation containers
- `Message`: Chat messages with AI responses
- `Session`: User sessions
- `Administrator`: Admin panel access

## Development

### Running Tests

```bash
rails test
```

### Code Quality

```bash
# Linting
rails standard

# Type checking (if using Sorbet/RBS)
rails typecheck
```

### Database Management

```bash
# Clean up orphaned attachments
rails db:cleanup_attachments

# Reset database (caution: deletes all data)
rm db/db.json
rails db:seed
```

## Admin Panel

Access at `/admin`:
- Default credentials created by `rails db:seed`
- Manage users, chats, and system settings
- View operation logs

## API Documentation

### Telegram Authentication

```
POST /api/telegram_auths
```

Validates Telegram Web App data and creates/updates user session.

### Chat WebSocket

Connect to `/cable` for real-time message updates:
- Subscribe to `ChatChannel` with chat_id
- Receive AI responses as they stream

## Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## License

This project is licensed under the MIT License - see LICENSE file for details.

## Support

- **Issues**: https://github.com/mraiko23/aichatYMLER/issues
- **Discussions**: https://github.com/mraiko23/aichatYMLER/discussions

## Acknowledgments

- Built with [Clacky AI](https://clacky.ai)
- Telegram authentication inspired by Telegram Web Apps
- AI providers: OpenRouter, Perplexity, OpenAI

## Roadmap

- [ ] PostgreSQL migration option
- [ ] S3 file storage
- [ ] Multi-language support
- [ ] Voice message support
- [ ] Group chat support
- [ ] Custom AI model configuration
- [ ] Export chat history
- [ ] Dark mode
