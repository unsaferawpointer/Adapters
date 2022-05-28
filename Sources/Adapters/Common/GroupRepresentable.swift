//
//  GroupRepresentable.swift
//  Done-macOS
//
//  Created by Anton Cherkasov on 24.05.2022.
//

import AppKit

public protocol GroupRepresentable: NSView {
	associatedtype ViewModel: ItemIdentifiable
	var model: ViewModel? { get set }
	init()
}
