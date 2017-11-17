import Foundation

struct DiscoResponse: Codable {

	let meta: DiscoResponseMeta
	let result: DiscoResponseResult

}

struct DiscoResponseMeta: Codable {

	let code: Int

}

struct DiscoResponseResult: Codable {

	let total_count: Int
	let items: [DiscoItem]

}

struct DiscoItem: Codable {

	let id: UInt64
	let updated_at: String
	let org_id: String
	let title: String
	let description: String
	let cover_hash: String
	let cover_id: String
	let project_id: Int
	let order: Int
	let cover: String
	let filials: [String]
	let percent: Int?

}
