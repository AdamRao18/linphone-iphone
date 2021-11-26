/*
 * Copyright (c) 2010-2020 Belledonne Communications SARL.
 *
 * This file is part of linphone-iphone
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */


import UIKit
import Foundation
import linphonesw

@objc class CallsListView: DismissableView, UITableViewDataSource {
	
	// Layout constants
	let buttons_distance_from_center_x = 38
	let buttons_size = 60
	
	let callsListTableView =  UITableView()
	let menuView = VoipCallContextMenu()
	
	var callsDataObserver : MutableLiveDataOnChangeClosure<[CallData]>? = nil
	
	init() {
		super.init(title: VoipTexts.call_action_calls_list)
		
		// New Call
		let newCall = CallControlButton(width: buttons_size,height: buttons_size, buttonTheme: VoipTheme.call_add, onClickAction: {
			let view: DialerView = self.VIEW(DialerView.compositeViewDescription());
			view.setAddress("")
			CallManager.instance().nextCallIsTransfer = false
			PhoneMainView.instance().changeCurrentView(view.compositeViewDescription())
		})
		addSubview(newCall)
		newCall.centerX(withDx: -buttons_distance_from_center_x).alignParentBottom(withMargin:SharedLayoutConstants.buttons_bottom_margin).done()
		
		// Merge  Calls
		let mergeIntoLocalConference = CallControlButton(width: buttons_size,height: buttons_size, buttonTheme: VoipTheme.call_merge, onClickAction: {
			self.removeFromSuperview()
			CallsViewModel.shared.mergeCallsIntoLocalConference()
		})
		addSubview(mergeIntoLocalConference)
		mergeIntoLocalConference.centerX(withDx: buttons_distance_from_center_x).alignParentBottom(withMargin:SharedLayoutConstants.buttons_bottom_margin).done()
		
		
		CallsViewModel.shared.callsData.readCurrentAndObserve{ (callsData) in
			if let callsData = callsData {
				mergeIntoLocalConference.isEnabled = callsData.count >= 2 && Core.get().conference?.isIn != true
			} else {
				mergeIntoLocalConference.isEnabled = false
			}
			self.callsListTableView.reloadData()
		}
		
		
		// CallsList
		super.contentView.addSubview(callsListTableView)
		callsListTableView.matchParentDimmensions().done()
		callsListTableView.dataSource = self
		callsListTableView.register(VoipCallCell.self, forCellReuseIdentifier: "VoipCallCell")
		callsListTableView.allowsSelection = false
		if #available(iOS 15.0, *) {
			callsListTableView.allowsFocus = false
		}
		callsListTableView.separatorStyle = .singleLine
		callsListTableView.separatorColor = .white
		callsListTableView.onClick {
			self.hideMenu()
		}
		
		// Floating menu
		super.contentView.addSubview(menuView)
		
		menuView.isHidden = true
		
	}

	
	func toggleMenu(forCell:VoipCallCell) {
		if (menuView.isHidden) {
			showMenu(forCell: forCell)
		} else if (menuView.callData?.call.callLog?.callId != forCell.callData?.call.callLog?.callId) {
			hideMenu()
			showMenu(forCell: forCell)
		} else {
			hideMenu()
		}
	}
	
	func showMenu(forCell:VoipCallCell) {
		menuView.removeConstraints().alignUnder(view: forCell).alignParentRight().done()
		menuView.callData = forCell.callData
		menuView.isHidden = false
	}
	
	func hideMenu() {
		menuView.isHidden = true
	}
	
	// TableView datasource delegate
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		guard let callsData = CallsViewModel.shared.callsData.value else {
			return 0
		}
		return callsData.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell:VoipCallCell = tableView.dequeueReusableCell(withIdentifier: "VoipCallCell") as! VoipCallCell
		guard let callData = CallsViewModel.shared.callsData.value?[indexPath.row] else {
			return cell
		}
		cell.selectionStyle = .none
		cell.callData = callData
		cell.owningCallsListView = self
		return cell
	}
	
	// View controller
	
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
}
