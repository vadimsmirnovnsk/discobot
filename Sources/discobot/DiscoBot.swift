import Foundation
import TelegramBot

public class DiscoBot {

	public func process(command: String, message: Message?, testChannel: Bool) {
		guard let message = message else { return }

		switch command {
			case "post" : self.postNewDisco(message: message, testChannel: testChannel)

			default : self.processFallback(message: message)
		}
	}

	private func postNewDisco(message: Message, testChannel: Bool) {
		self.getDisco() { [weak self] discoResponse in
			if let discoResponse = discoResponse {

				let maxDiscos = discoResponse.result.items.count > 3 ? 3 : discoResponse.result.items.count
				let discos = discoResponse.result.items[0..<maxDiscos].reversed()

				for disco in discos {
					let photoUrl = disco.photoUrlString
					let discoText = disco.messageTruncated(by: 200)
					let replyMarkup = DiscoBot.replyMarkup(with: disco)

					let channel: ChatId = testChannel ? message.from!.id : Config.channelPrivateId
					bot.sendPhotoSync(chat_id: channel,
					                  photo: photoUrl,
					                  caption: discoText,
					                  disable_notification: true,
					                  replyMarkup)
				}
			} else {
				self?.processFallback(message: message, errorDescription: "Couldn't obtain new discounts 😔")
			}
		}
	}

	// Echo fallback
	public func processFallback(message: Message?, errorDescription: String? = nil) {
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
		let url = URL(string: "https://discounts.api.2gis.ru/2.0/projects/1/discounts?limit=3&page=1")

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

	private class func inlineKeyboard(with item: DiscoItem) -> InlineKeyboardMarkup {
		var keyboardMarkup = InlineKeyboardMarkup()
		var showButton = InlineKeyboardButton()
		showButton.text = "👀 Посмотреть"
		showButton.url = item.saleUrlString

		var keyboard = [showButton]

//		if let filialUrlString = item.filiafUrlString {
//			var filialButton = InlineKeyboardButton()
//			filialButton.text = "💚 В 2ГИС"
//			filialButton.url = filialUrlString
//
//			keyboard.append(filialButton)
//		}

		if let reviewUrlString = item.reviewsUrlString {
			var reviewButton = InlineKeyboardButton()
			reviewButton.text = "✍️ Отзывы"
			reviewButton.url = reviewUrlString

			keyboard.append(reviewButton)
		}

		keyboardMarkup.inline_keyboard = [keyboard]

//		var shareKey = InlineKeyboardButton()
//		var shareText = "❤️ Нравится"
//		if likes > 0 {
//			shareText = shareText + " (" + String(likes) + ")"
//		}
//		shareKey.text = shareText
//		shareKey.callback_data = "like"


		return keyboardMarkup
	}

	internal class func replyMarkup(with item: DiscoItem) -> [String : Any] {
		let keyboardMarkup = DiscoBot.inlineKeyboard(with: item)
		return ["reply_markup": keyboardMarkup] // , "disable_notification": true
	}

}
