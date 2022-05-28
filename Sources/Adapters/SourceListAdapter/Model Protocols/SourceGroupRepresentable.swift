//
//  OutlineGroupRepresentable.swift
//  Done-macOS
//
//  Created by Anton Cherkasov on 10.05.2022.
//

import Foundation

public protocol SourceListGroupRepresentable: ListItemRepresentable {
	var alwaysExpanded: Bool { get set }
}
