//
//  RowRepresentable.swift
//  
//
//  Created by Anton Cherkasov on 02.11.2022.
//

import CoreGraphics

public protocol RowRepresentable: Identifiable, Selectable {

	func isContentEqual(to item: Any) -> Bool

	var configuration: RowConfiguration { get }

	var dragConfiguration: DragConfiguration { get }
}

extension RowRepresentable {

	/// Type erasure for item identifier
	var itemIdentifier: AnyHashable {
		return AnyHashable(id)
	}

	var isSelectable: Bool {
		return configuration.isSelectable
	}

	var height: CGFloat? {
		return configuration.height
	}

	var isGroup: Bool {
		return configuration.isGroup
	}
}
