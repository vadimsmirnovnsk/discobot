import Foundation
import TelegramBot
import CoreData

let bot = TelegramBot(token: Config.botToken)
let router = Router(bot: bot)
let discoBot = DiscoBot()

router["post", .slashRequired] = { context in
	if let message = context.message {
		guard let user = message.from, discoBot.isApprovedForChat(userId: user.id) else { return true }

		let argItemCount = context.args.scanInt64()
		let argument = context.args.scanWord() ?? ""
		let testChannel = argument != "production"
		let testItemsCount: Int64 = testChannel ? 1 : 0
		let itemsCount64 = argItemCount ?? testItemsCount

		discoBot.postNewDisco(chatId: message.chat.id, itemsCount: Int(itemsCount64),  testChannel: testChannel)
	}

	return true
}

router["postone", .slashRequired] = { context in
	if let message = context.message {
		guard let user = message.from, discoBot.isApprovedForChat(userId: user.id) else { return true }

		if let messageText = message.text {
			var textLines = messageText.components(separatedBy: "\n")
			guard textLines.count > 4 else {
				bot.sendMessageAsync(chat_id: message.chat.id,
					text: "*Ошибка:* слишком мало строчек. Надо минимум 4 (id, title, ..., link, photoLink)",
									 parse_mode: "markdown")
				return true
			}

			let argument = context.args.scanWord() ?? ""
			let testChannel = argument != "production"

			textLines.remove(at: 0) // Убираем команду
			let id = textLines.remove(at: 0)
			let title = textLines.remove(at: 0)
			let photoLink = textLines.remove(at: textLines.count - 1)
			let link = textLines.remove(at: textLines.count - 1)
			let description = textLines.joined(separator: "\n")

			print("Did parse params: \nid: \(id)\ntitle: \(title)\ndescription: \(description)\nphotoLink: \(photoLink)\nlink: \(link)\nisTest: \(testChannel)")

			discoBot.postOneDisco(chatId: message.chat.id,
								  testChannel: testChannel,
								  title: title,
								  description: description,
								  link: link,
								  photoLink: photoLink,
								  discoId: id)
		}
	}

	return true
}

router[["help", "start"], .slashRequired] = { context in
	if let message = context.message {
		guard let user = message.from, discoBot.isApprovedForChat(userId: user.id) else { return true }

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
		guard let user = message.from, discoBot.isApprovedForChat(userId: user.id) else { return true }
		
		discoBot.clearCache(chatId: message.chat.id)
	}

	return true
}

while true {
    while let update = bot.nextUpdateSync() {
        try router.process(update: update)
    }
    
    print("Server stopped due to error: \(String(describing: bot.lastError))")
    sleep(5)
}

fatalError("Server stopped due to error: \(String(describing: bot.lastError))")
