import Foundation
import TelegramBot

public class DiscoBot {

	private static let kMaxCaptionLength = 200
	private static let kMaxDiscoPostCount = 1

	private let discoStorage = PostedDiscoStorage()

	public func postNewDisco(message: Message, testChannel: Bool) {
		self.getDisco() { [weak self] discoResponse in
			guard let this = self else { return }

			if let discoResponse = discoResponse {

				let discos = this.discosForPost(from: discoResponse.result.items)
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
//					if (testChannel) {
						this.discoStorage.add(item: disco)
//					}
				}

				this.discoStorage.synchronize()
			} else {
				self?.processFallback(message: message, errorDescription: "Couldn't obtain new discounts 😔")
			}
		}
	}

	public func clearCache() {
		self.discoStorage.dropAllItems()
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
		let url = URL(string: "https://discounts.api.2gis.ru/2.0/projects/1/discounts?limit=30&page=1")

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


	private func discosForPost(from discos: [DiscoItem]) -> [DiscoItem] {
		let discosToAdd = discos.filter { !self.discoStorage.contains(item: $0) }

		let maxDiscos = discosToAdd.count > DiscoBot.kMaxDiscoPostCount
			? DiscoBot.kMaxDiscoPostCount
			: discosToAdd.count

		let discosForPost = Array<DiscoItem>(discosToAdd[0..<maxDiscos].reversed())
		return discosForPost
	}
}
