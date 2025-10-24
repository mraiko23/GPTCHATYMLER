import { Application } from "@hotwired/stimulus"

import ThemeController from "./theme_controller"
import DropdownController from "./dropdown_controller"
import SdkIntegrationController from "./sdk_integration_controller"
import ClipboardController from "./clipboard_controller"
import ChatController from "./chat_controller"
import TelegramWebAppController from "./telegram_web_app_controller"
import MessageFormatterController from "./message_formatter_controller"
import MessageActionsController from "./message_actions_controller"

const application = Application.start()

application.register("theme", ThemeController)
application.register("dropdown", DropdownController)
application.register("sdk-integration", SdkIntegrationController)
application.register("clipboard", ClipboardController)
application.register("chat", ChatController)
application.register("telegram-web-app", TelegramWebAppController)
application.register("message-formatter", MessageFormatterController)
application.register("message-actions", MessageActionsController)

window.Stimulus = application
