//
//  OutlineGroupRepresentable.swift
//  Done-macOS
//
//  Created by Anton Cherkasov on 10.05.2022.
//

import Foundation

public protocol OutlineGroupRepresentable: ItemIdentifiable {

	associatedtype Item: OutlineItemRepresentable

	var alwaysExpanded: Bool { get set }

	var children: [Item] { get set }

}
