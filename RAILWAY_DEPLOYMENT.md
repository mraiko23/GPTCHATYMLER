# Railway Deployment Guide

## Prerequisites

1. GitHub account with this repository
2. Railway account (https://railway.app)
3. API keys from providers (OpenRouter, Perplexity, OpenAI)

## Environment Variables

Set these in Railway dashboard:

```bash
# Required
RAILS_ENV=production
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_TO_STDOUT=true
SECRET_KEY_BASE=<generate with: rails secret>

# API Keys (at least one required)
OPENROUTER_API_KEY=your_openrouter_api_key
PERPLEXITY_API_KEY=your_perplexity_api_key
OPENAI_API_KEY=your_openai_api_key

# Telegram Bot Configuration
TELEGRAM_BOT_TOKEN=your_telegram_bot_token
TELEGRAM_BOT_USERNAME=your_bot_username

# Optional: Custom domain
RAILS_ALLOWED_HOSTS=your-domain.com,your-app.up.railway.app
```

## Deployment Steps

### 1. Create Railway Project

1. Go to https://railway.app
2. Click "New Project"
3. Select "Deploy from GitHub repo"
4. Choose your repository: `mraiko23/aichatYMLER`
5. Select branch: `chore/init-clacky-env`

### 2. Configure Environment Variables

1. Go to your project in Railway
2. Click on "Variables" tab
3. Add all environment variables listed above
4. Generate SECRET_KEY_BASE:
   ```bash
   rails secret
   ```

### 3. Deploy

Railway will automatically:
- Install dependencies (bundle install, npm install)
- Precompile assets
- Start the application

### 4. Setup Telegram Bot

After deployment:

1. Get your Railway app URL (e.g., `https://your-app.up.railway.app`)
2. Set Telegram webhook:
   ```bash
   curl -X POST "https://api.telegram.org/bot<YOUR_BOT_TOKEN>/setWebhook" \
     -d "url=https://your-app.up.railway.app/api/telegram_auths"
   ```

### 5. Initialize Database

The JSON database (`db/db.json`) will be automatically created on first use.

**Important**: 
- The database is stored in the container filesystem
- Data will persist between deployments but may be lost if container is recreated
- For production, consider using Railway's persistent volumes or external storage

### 6. Create Admin Account

Access the app and navigate to `/admin` to create your first admin account.

## Post-Deployment

### Verify Deployment

1. Visit your Railway app URL
2. Click "Sign in with Telegram"
3. Test creating a chat and sending messages

### Monitor Logs

```bash
# In Railway dashboard
Click "Deployments" → Select latest deployment → "View Logs"
```

### Common Issues

**Issue**: Application crashes on startup
- Check logs for missing environment variables
- Ensure SECRET_KEY_BASE is set
- Verify API keys are correct

**Issue**: Telegram login not working
- Verify TELEGRAM_BOT_TOKEN is correct
- Check webhook is set correctly
- Ensure bot username matches TELEGRAM_BOT_USERNAME

**Issue**: Assets not loading
- Ensure RAILS_SERVE_STATIC_FILES=true
- Check assets were precompiled during build

**Issue**: Data lost after redeploy
- JSON database is ephemeral in Railway by default
- Use Railway volumes for persistent storage:
  1. Go to project settings
  2. Add volume mounted to `/app/db`
  3. Redeploy

## Architecture Notes

This application uses:
- **JSON-based database** instead of PostgreSQL (no external DB needed)
- **File storage** in `/storage` directory (consider S3 for production)
- **Single dyno** deployment (no background workers needed)
- **Inline job processing** (ChatResponseJob runs synchronously)

## Scaling Considerations

For high-traffic production:

1. **Database**: Migrate to PostgreSQL or MongoDB
2. **File Storage**: Use S3 or Cloudinary
3. **Jobs**: Use Sidekiq with Redis
4. **Caching**: Add Redis for session storage

## Support

For issues, check:
- Railway logs
- GitHub repository issues
- Application logs in Railway dashboard
