//
//  HeaderCellRepresentable.swift
//  Adapters
//
//  Created by Anton Cherkasov on 24.05.2022.
//

import AppKit

/// Represents section header
public protocol OutlineHeaderCellRepresentable: NSView {
	associatedtype ViewModel: ItemIdentifiable
	/// View model of the header
	var model: ViewModel? { get set }
	init()
}
