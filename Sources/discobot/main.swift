import Foundation
import TelegramBot
import CoreData

let bot = TelegramBot(token: Config.botToken)
let router = Router(bot: bot)
let discoBot = DiscoBot()

router["post", .slashRequired] = { context in
	if let message = context.message {
		let argument = context.args.scanWord() ?? ""
		let testChannel = argument != "production"

		discoBot.postNewDisco(message: message, testChannel: testChannel)
	}

	return true
}

router["clear", .slashRequired] = {
	
}

while let update = bot.nextUpdateSync() {
	try router.process(update: update)
}

fatalError("Server stopped due to error: \(String(describing: bot.lastError))")
