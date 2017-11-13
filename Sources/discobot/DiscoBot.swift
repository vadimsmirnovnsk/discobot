import Foundation
import TelegramBot

public class DiscoBot {

	private static let kMaxCaptionLength = 200

	private let discoStorage = PostedDiscoStorage(test: false)

	public func postNewDisco(message: Message, itemsCount: Int, testChannel: Bool) {
		self.getDisco() { [weak self] discoResponse in
			guard let this = self else { return }

			if let discoResponse = discoResponse {
				let discos = this.discosForPost(from: discoResponse.result.items, itemsCount: itemsCount)
				guard discos.count > 0 else {
					this.printInfo(message: message, info: "There is no one new disco.")
					return
				}

				for disco in discos {
					let photoUrl = disco.photoUrlString
					let discoText = disco.messageTruncated(by: DiscoBot.kMaxCaptionLength)
					let replyMarkup = DiscoBot.replyMarkup(with: disco)

					let channel: ChatId = testChannel ? message.from!.id : Config.channelPrivateId
					bot.sendPhotoSync(chat_id: channel,
					                  photo: photoUrl,
					                  caption: discoText,
					                  disable_notification: true,
					                  replyMarkup)
					this.discoStorage.add(item: disco)
				}

				this.discoStorage.synchronize()
			} else {
				this.printInfo(message: message, info: "Couldn't obtain new discounts 😔")
			}
		}
	}

	public func clearCache(message: Message) {
		self.discoStorage.dropAllItems()

		self.printInfo(message: message, info: "All items have been droped.")
	}

	// Echo fallback
	public func processFallback(message: Message, errorDescription: String? = nil) {
		if let from = message.from, let text = message.text {
			var messageText = "Hi \(from.first_name)! You said: \(text).\nBut I know only command: /post\n"
			if let errorDescription = errorDescription {
				messageText = messageText + errorDescription + "\n"
			}

			bot.sendMessageAsync(chat_id: from.id,
			                     text: messageText,
			                     parse_mode: "markdown")
		}
	}

	public func printInfo(message: Message, info: String) {
		if let from = message.from {
			bot.sendMessageAsync(chat_id: from.id,
			                     text: info,
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


	private func discosForPost(from discos: [DiscoItem], itemsCount: Int) -> [DiscoItem] {
		let discosToAdd = discos.filter { !self.discoStorage.contains(item: $0) }

		let maxDiscos = discosToAdd.count > itemsCount
			? itemsCount
			: discosToAdd.count

		let discosForPost = Array<DiscoItem>(discosToAdd[0..<maxDiscos].reversed())
		return discosForPost
	}
}
