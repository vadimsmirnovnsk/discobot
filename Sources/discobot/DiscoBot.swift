import Foundation
import TelegramBot

public class DiscoBot {

	private static let kMaxCaptionLength = 200

	private let discoStorage = PostedDiscoStorage(test: false)

	public func postOneDisco(chatId: ChatId,
							 testChannel: Bool,
							 title: String,
							 description: String,
							 link: String,
							 photoLink: String,
							 discoId: String
	) {
		self.getDisco(id: discoId) {
			[weak self] discoResponse in
			guard let this = self else { return }

			if let discoResponse = discoResponse {
				let discos = this.discosForPost(from: [discoResponse.result.item], itemsCount: 1)
				guard let disco = discos.first else {
					this.printInfo(chatId: chatId, info: "There is no one disco for " + discoId)
					return
				}

				let discoText = disco.messageTruncated(by: DiscoBot.kMaxCaptionLength, title: title, descritpion: description, urlString: link)
				let replyMarkup = DiscoBot.replyMarkup(with: disco)

				let channel: ChatId = testChannel ? chatId : Config.channelPrivateId
				bot.sendPhotoSync(chat_id: channel,
								  photo: photoLink,
								  caption: discoText,
								  disable_notification: true,
								  replyMarkup)
//				this.discoStorage.add(item: disco)
//
//				this.discoStorage.synchronize()
			} else {
				this.printInfo(chatId: chatId, info: "Couldn't obtain new discounts 😔")
			}
		}
	}

	public func postNewDisco(chatId: ChatId, itemsCount: Int, testChannel: Bool) {
		self.getDisco() { [weak self] discoResponse in
			guard let this = self else { return }

			if let discoResponse = discoResponse {
				let discos = this.discosForPost(from: discoResponse.result.items, itemsCount: itemsCount)
				guard discos.count > 0 else {
					this.printInfo(chatId: chatId, info: "There is no one new disco.")
					return
				}

				for disco in discos {
					let photoUrl = disco.photoUrlString
					let discoText = disco.messageTruncated(by: DiscoBot.kMaxCaptionLength)
					let replyMarkup = DiscoBot.replyMarkup(with: disco)

					let channel: ChatId = testChannel ? chatId : Config.channelPrivateId
					bot.sendPhotoSync(chat_id: channel,
					                  photo: photoUrl,
					                  caption: discoText,
					                  disable_notification: true,
					                  replyMarkup)
					this.discoStorage.add(item: disco)
				}

				this.discoStorage.synchronize()
			} else {
				this.printInfo(chatId: chatId, info: "Couldn't obtain new discounts 😔")
			}
		}
	}

	public func clearCache(chatId: ChatId) {
		self.discoStorage.dropAllItems()

		self.printInfo(chatId: chatId, info: "All items have been droped.")
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

	public func printInfo(chatId: ChatId, info: String) {
		bot.sendMessageAsync(chat_id: chatId,
							 text: info,
							 parse_mode: "markdown")
	}

	private func getDisco(id: String, callback: @escaping (DiscoSingleResponse?) -> Void) {
		guard let url = URL(string: "https://discounts.api.2gis.ru/2.0/discounts/" + id) else {
			print("Bad url for id:" + id)
			return
		}
		print("Will fetch discos: " + url.absoluteString)

		let task = URLSession.shared.dataTask(with: url) {(data, response, error) in
			if let data = data {
				do {
					let jsonDecoder = JSONDecoder()
					let discoResponse = try jsonDecoder.decode(DiscoSingleResponse.self, from: data)
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


	private func getDisco(callback: @escaping (DiscoResponse?) -> Void) {
		let url = URL(string: "https://discounts.api.2gis.ru/2.0/projects/1/discounts?limit=20&page=1")

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

		let discosForPost = Array<DiscoItem>(discosToAdd[0..<maxDiscos])
		return discosForPost
	}

	public func isApprovedForChat(userId: Int64) -> Bool {
		guard Config.approvedUserIds.contains(userId) else {
			let info = "Вы не можете управлять ботом, сорян."
			bot.sendMessageAsync(chat_id: userId,
			                     text: info,
			                     parse_mode: "markdown")

			return false
		}

		return true
	}
}
