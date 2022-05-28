//
//  File.swift
//  
//
//  Created by Anton Cherkasov on 16.06.2022.
//

import AppKit

struct PasterboardData {

	var data: [Data]
	var type: NSPasteboard.PasteboardType
	var source: DraggingSource

}
