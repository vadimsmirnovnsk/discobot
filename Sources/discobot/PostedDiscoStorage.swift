import Foundation

internal class PostedDiscoStorage {

	private static let discoItemIdsKey = "discoItemIds"

	private var discoItemIds: [UInt64]

	init() {
		self.discoItemIds = UserDefaults.standard.array(forKey: PostedDiscoStorage.discoItemIdsKey) as? [UInt64] ?? []
	}

	internal func contains(item: DiscoItem) -> Bool {
		let contains = self.discoItemIds.contains(item.id)
		return contains
	}

	internal func add(item: DiscoItem) {
		self.discoItemIds.append(item.id)
	}

	internal func synchronize() {
		UserDefaults.standard.setValue(self.discoItemIds, forKey: PostedDiscoStorage.discoItemIdsKey)
		UserDefaults.standard.synchronize()
	}

	internal func dropAllItems() {
		UserDefaults.standard.setValue([], forKey: PostedDiscoStorage.discoItemIdsKey)
	}

}
