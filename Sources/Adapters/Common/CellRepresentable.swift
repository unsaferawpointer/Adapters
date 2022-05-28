//
//  CellPresentable.swift
//  Adapters
//
//  Created by Anton Cherkasov on 12.05.2022.
//

import AppKit

public protocol CellModel: ItemIdentifiable {
	var isSelectable: Bool { get set }
}

public protocol CellRepresentable: NSView {
	associatedtype ViewModel: CellModel
	init()
	var model: ViewModel? { get set }
	func setFocus()
	var valueDidChanged: ((ViewModel.ID, [String: Any]) -> Void)? { get set }
}
