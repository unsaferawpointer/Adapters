//
//  DiffableItem.swift
//  Adapters
//
//  Created by Anton Cherkasov on 03.05.2022.
//

import Foundation

public protocol ItemIdentifiable: Hashable {
	/// A type representing the stable identity of the entity associated with
	/// an instance.
	associatedtype ID : Hashable

	/// The stable identity of the entity associated with this instance.
	var id: Self.ID { get }

	/// Represents the content identity
	func isContentEqual(to source: Self) -> Bool
}

extension ItemIdentifiable {

	static func == (lhs: Self, rhs: Self) -> Bool {
		return lhs.id == rhs.id
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(id)
	}

}
