//
//  ListView.Adapter + NSTableViewDataSource.swift
//  
//
//  Created by Anton Cherkasov on 08.09.2022.
//

import AppKit

// MARK: - NSTableViewDataSource
extension List.Adapter : NSTableViewDataSource {

	public func numberOfRows(in tableView: NSTableView) -> Int {
		return snapshot.count
	}

}
