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

		discoBot.postNewDisco(chatId: message.chat.id, itemsCount: Int(itemsCount64),  testChannel: testChannel)
	}

	return true
}

router[["help", "start"], .slashRequired] = { context in
	if let message = context.message {
		let firstName = message.from?.first_name ?? "Неизвестный"
		let info = "Привет, " + firstName + "\n Используй команды:\n" +
		"*/clear* — чтобы дропнуть все записи из кеша\n" +
		"*/post <opt int: itemsCount> <opt: `production`>* — чтобы отправить itemsCount новых постов. " +
		"Если указано слово `production`, то в канальчик."
		bot.sendMessageAsync(chat_id: message.chat.id,
		                     text: info,
		                     parse_mode: "markdown")
	}

	return true
}

router["clear", .slashRequired] = { context in
	if let message = context.message {
		discoBot.clearCache(chatId: message.chat.id)
	}

	return true
}

while let update = bot.nextUpdateSync() {
	try router.process(update: update)
}

fatalError("Server stopped due to error: \(String(describing: bot.lastError))")
