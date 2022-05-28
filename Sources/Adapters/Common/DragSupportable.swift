//
//  File.swift
//  
//
//  Created by Anton Cherkasov on 05.06.2022.
//

import AppKit

/// The source of dragging operation
public enum DraggingSource {
	/// Destination view equals source view
	case local
	/// Destination app equals source app
	case `internal`
	/// Source is external application
	case external
}

public protocol DragSupportable {

	/// Array of the available pasterboard types to write to pasterboard
	var availableTypes: [NSPasteboard.PasteboardType] { get }

	/// The data to write pasterboard item
	/// - Parameters:
	///    - type: Pasterboard type
	/// - Returns: The data to write pasterboard item for concrete pasterboard type
	func providedData(for type: NSPasteboard.PasteboardType) -> Data?

}
