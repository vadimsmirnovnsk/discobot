import Foundation
import TelegramBot

let bot = TelegramBot(token: Config.botToken)
let discoBot = DiscoBot()

while let update = bot.nextUpdateSync() {
	discoBot.process(update: update)
}

fatalError("Server stopped due to error: \(String(describing: bot.lastError))")
