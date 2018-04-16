import Foundation

internal class DiscoStuff {

	private let discoBot: DiscoBot
	private var ctrs: [Double] = [Double]()

	internal init(with discoBot: DiscoBot) {
		self.discoBot = discoBot
	}

	internal func collectCTR(for ids: [String]) -> [Double] {
		self.ctrs = []

		ids.forEach { id in
			self.discoBot.getDisco(id: id, callback: { response in
				if let ctr = response?.result.item.ctr?.current_value {
					print("DISCO: \(id), CTR: \(ctr)")
				}
			})
		}

		return self.ctrs
	}

	internal func calculateCtr() {
		let ctrs = self.collectCTR(for: [
			"143038",
			"143040",
			"142864",
			"142768",
			"142555",
			"142413",
			"142411",
			"138866",
			"140272",
			"140482",
			"128989",
			"133088",
			"142334",
			"131080",
			"141358",
			"141288",
		])

		let sum = ctrs.reduce(0.0) { (result, new) -> Double in
			return result + new
		}

		let av = sum/Double(ctrs.count)
		print("AVERAGE: \(av)")
	}

}
