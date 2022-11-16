//
//  RowRepresentable.swift
//  
//
//  Created by Anton Cherkasov on 02.11.2022.
//

import CoreGraphics

public protocol RowRepresentable: Selectable {

	func isContentEqual(to item: Any) -> Bool

	var configuration: RowConfiguration { get }

	var dragConfiguration: DragConfiguration { get }

	var itemIdentifier: AnyHashable { get }
}

extension RowRepresentable {

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

extension RowRepresentable where Self: Identifiable {

	var itemIdentifiable: AnyHashable {
		return AnyHashable(id)
	}
}
