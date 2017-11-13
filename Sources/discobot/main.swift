import Foundation
import TelegramBot

let bot = TelegramBot(token: Config.botToken)
let router = Router(bot: bot)
let discoBot = DiscoBot()

router["post", .slashRequired] = { context in
	let argument = context.args.scanWord() ?? ""
	let testChannel = argument != "production"
	discoBot.process(command: context.command, message: context.message, testChannel: testChannel)

	return true
}

router[.callback_query(data: "like")] = { context in
	print(context)

	return true
}

while let update = bot.nextUpdateSync() {
	try router.process(update: update)
}

fatalError("Server stopped due to error: \(String(describing: bot.lastError))")
