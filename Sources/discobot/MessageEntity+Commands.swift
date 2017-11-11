import TelegramBot

public extension MessageEntity { // + Commands

	public var isCommand: Bool {
		return self.type_string == "bot_command"
	}

}

public extension Message { // + Commands

	public var command: DiscoCommand {
		if let text = self.text, let cmd = DiscoCommand(rawValue: text) {
			return cmd
		}

		return DiscoCommand.undefined
	}

}
