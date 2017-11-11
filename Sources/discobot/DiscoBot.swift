import Foundation
import TelegramBot

public class DiscoBot {

	public func process(update: Update) {
		if let message = update.message, let entity = message.entities.first, entity.isCommand {
			self.process(command: message)
		}
		else {
			self.processFallback(message: update.message)
		}
	}

	private func process(command message: Message) {
		switch message.command {
			case .post : self.postNewDisco(message: message)

			default : self.processFallback(message: message)
		}
	}

	private func postNewDisco(message: Message) {
		self.getDisco() { [weak self] discoResponse in
			if let discoResponse = discoResponse {
//				var text = "*Новые скидки!*\n\n"

				for disco in discoResponse.result.items {
//				if let disco = discoResponse.result.items.first {
					let fileUrl = "http:" + disco.cover
					let discoDSCount = 200 - fileUrl.characters.count - 20

					let discoD1 = disco.description.replacingOccurrences(of: "\n", with: " ")
					let discoD2 = discoD1.description.replacingOccurrences(of: "<br>", with: "")
					let discoDescription = discoD2.truncate(length: discoDSCount, trailing: "...")

					let discoText = disco.title + "\n" + discoDescription + "\n" + "↪️ " + "https://2gis.ru/novosibirsk/sales/" + String(disco.id)

					var keyboardMarkup = InlineKeyboardMarkup()
					var useKey = InlineKeyboardButton()
					useKey.text = "👀 Посмотреть"
					useKey.callback_data = "123"
					var shareKey = InlineKeyboardButton()
					shareKey.text = "❤️ Поделиться"
					shareKey.callback_data = "456"
					keyboardMarkup.inline_keyboard = [[useKey, shareKey]]

					bot.sendPhotoSync(chat_id: Config.channelPrivateId, // message.from!.id,
					                  photo: fileUrl,
					                  caption: discoText,
					                  ["reply_markup": keyboardMarkup, "disable_notification": true])
				}
//				bot.sendMessageAsync(chat_id: Config.channelPrivateId,
//				                     text: text,
//				                     parse_mode: "markdown",
//				                     disable_notification: true)
			} else {
				self?.processFallback(message: message, errorDescription: "Couldn't obtain new discounts 😔")
			}
		}
	}

	// Echo fallback
	private func processFallback(message: Message?, errorDescription: String? = nil) {
		if let message = message, let from = message.from, let text = message.text {
			var messageText = "Hi \(from.first_name)! You said: \(text).\nBut I know only command: /post\n"
			if let errorDescription = errorDescription {
				messageText = messageText + errorDescription + "\n"
			}

			bot.sendMessageAsync(chat_id: from.id,
			                     text: messageText,
			                     parse_mode: "markdown")
		}
	}

	private func getDisco(callback: @escaping (DiscoResponse?) -> Void) {
		let url = URL(string: "https://discounts.api.2gis.ru/2.0/projects/1/discounts?limit=10&page=1")

		let task = URLSession.shared.dataTask(with: url!) {(data, response, error) in
			if let data = data {
				do {
					let jsonDecoder = JSONDecoder()
					let discoResponse = try jsonDecoder.decode(DiscoResponse.self, from: data)
					callback(discoResponse)
				}
				catch {
					print("Error decode disco request: \(error)")
					callback(nil)
				}
			}
		}

		task.resume()
	}

}
