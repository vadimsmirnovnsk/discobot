extension DiscoItem { // BotMessage

	var photoUrlString: String {
		return "http:" + self.cover
	}

	var saleUrlString: String {
		return "https://2gis.ru/novosibirsk/sales/" + String(self.id)
	}

	var filiafUrlString: String? {
		if let filial = self.filials.first {
			return "https://2gis.ru/novosibirsk/firm/" + filial
		}

		return nil
	}

	var reviewsUrlString: String? {
		if let filial = self.filials.first {
			return "https://m.2gis.ru/novosibirsk/firm/" + filial + "/cardTab/reviews"
		}

		return nil
	}

	func messageTruncated(by symbolsCount: Int) -> String {
		let menshen = "💫 @gisdisco"
		let urlPrefix = "↪️ "

		let discoD1 = self.description.replacingOccurrences(of: "\n", with: " ")
		let discoD2 = discoD1
			.replacingOccurrences(of: "<br>", with: "")
			.replacingOccurrences(of: "<li>", with: "")
			.replacingOccurrences(of: "</li>", with: "")
			.replacingOccurrences(of: "<ul>", with: "")
			.replacingOccurrences(of: "</ul>", with: "")

		let discoDescriptionCount = symbolsCount - self.saleUrlString.characters.count - menshen.characters.count - urlPrefix.characters.count - self.title.characters.count - 8
		let discoDescription = discoD2.truncate(length: discoDescriptionCount, trailing: "...")

		let discoText = self.title + "\n" + discoDescription + "\n" + urlPrefix + self.saleUrlString + "\n\n" + menshen

		return discoText
	}

}
