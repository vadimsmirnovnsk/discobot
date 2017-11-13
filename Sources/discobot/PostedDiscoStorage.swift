import Foundation

internal class PostedDiscoStorage {

	private static let discoItemIdsKey = "discoItemIds"
	private static let discoItemIdsTestKey = "discoItemIds"

	private var discoItemIds: [UInt64]
	private let test: Bool

	private var key: String {
		return self.test
			? PostedDiscoStorage.discoItemIdsTestKey
			: PostedDiscoStorage.discoItemIdsKey
	}

	init(test: Bool) {
		self.discoItemIds = []
		self.test = test

		self.discoItemIds = UserDefaults.standard.array(forKey: self.key) as? [UInt64] ?? []
	}

	internal func contains(item: DiscoItem) -> Bool {
		let contains = self.discoItemIds.contains(item.id)
		return contains
	}

	internal func add(item: DiscoItem) {
		self.discoItemIds.append(item.id)
	}

	internal func synchronize() {
		UserDefaults.standard.setValue(self.discoItemIds, forKey: self.key)
		UserDefaults.standard.synchronize()
	}

	internal func dropAllItems() {
		self.discoItemIds = []
		UserDefaults.standard.setValue([], forKey: self.key)
	}

}
