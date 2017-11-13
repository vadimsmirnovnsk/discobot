import Foundation
import TelegramBot
import CoreData

let bot = TelegramBot(token: Config.botToken)
let router = Router(bot: bot)
let discoBot = DiscoBot()

router["post", .slashRequired] = { context in
	if let message = context.message {
		let argItemCount = context.args.scanInt64()
		let argument = context.args.scanWord() ?? ""
		let testChannel = argument != "production"
		let testItemsCount: Int64 = testChannel ? 1 : 0
		let itemsCount64 = argItemCount ?? testItemsCount

		discoBot.postNewDisco(message: message, itemsCount: Int(itemsCount64),  testChannel: testChannel)
	}

	return true
}

router["clear", .slashRequired] = { context in
	if let message = context.message {
		discoBot.clearCache(message: message)
	}

	return true
}

while let update = bot.nextUpdateSync() {
	try router.process(update: update)
}

fatalError("Server stopped due to error: \(String(describing: bot.lastError))")
