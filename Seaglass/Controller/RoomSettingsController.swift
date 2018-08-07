//
// Seaglass, a native macOS Matrix client
// Copyright © 2018, Neil Alexander
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
//

import Cocoa
import SwiftMatrixSDK

class RoomSettingsController: NSViewController {
    var initialRoomName: String! = ""
    var initialRoomTopic: String! = ""
    var initialRoomPublishInDirectory: NSControl.StateValue! = .off
    
    var initialRoomAccessOnlyInvited: NSControl.StateValue! = .on
    var initialRoomAccessExceptGuests: NSControl.StateValue! = .off
    var initialRoomAccessIncludingGuests: NSControl.StateValue! = .off
    
    var initialRoomHistorySinceJoined: NSControl.StateValue! = .on
    var initialRoomHistorySinceInvited: NSControl.StateValue! = .off
    var initialRoomHistorySinceSelected: NSControl.StateValue! = .off
    var initialRoomHistoryAnyone: NSControl.StateValue! = .off
    
    @IBOutlet var RoomName: NSTextField!
    @IBOutlet var RoomTopic: NSTextField!
    @IBOutlet var RoomPublishInDirectory: NSButton!
    
    @IBOutlet var RoomAccessOnlyInvited: NSButton!
    @IBOutlet var RoomAccessExceptGuests: NSButton!
    @IBOutlet var RoomAccessIncludingGuests: NSButton!
    
    @IBOutlet var RoomHistorySinceJoined: NSButton!
    @IBOutlet var RoomHistorySinceInvited: NSButton!
    @IBOutlet var RoomHistorySinceSelected: NSButton!
    @IBOutlet var RoomHistoryAnyone: NSButton!
    
    @IBOutlet var RoomMemberList: NSTableView!
    
    public var roomId: String = ""
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if segue.identifier != nil {
            switch segue.identifier!.rawValue {
            case "SegueToMemberList":
                if let dest = segue.destinationController as? MemberListController {
                    dest.roomId = roomId
                }
                break
            case "SegueToAliasList":
                if let dest = segue.destinationController as? RoomAliasesController {
                    dest.roomId = roomId
                }
                break
            default:
                return
            }
        }
    }
    
    @IBAction func accessRadioClicked(_ sender: NSButton) {
        for radio in [ RoomAccessOnlyInvited, RoomAccessExceptGuests, RoomAccessIncludingGuests ] {
            radio?.state = .off
        }
        sender.state = .on
    }
    
    @IBAction func historyRadioClicked(_ sender: NSButton) {
        for radio in [ RoomHistorySinceJoined, RoomHistorySinceInvited, RoomHistorySinceSelected, RoomHistoryAnyone ] {
            radio?.state = .off
        }
        sender.state = .on
    }
    
    @IBAction func saveButtonClicked(_ sender: NSButton) {
        let room = MatrixServices.inst.session.room(withRoomId: roomId)!
        
        if RoomName.stringValue != initialRoomName {
            room.setName(RoomName.stringValue) { (response) in
                print(response)
            }
        }
        
        if RoomTopic.stringValue != initialRoomTopic {
            room.setTopic(RoomTopic.stringValue) { (response) in
                print(response)
            }
        }
        
        if initialRoomPublishInDirectory != RoomPublishInDirectory.state {
            room.setDirectoryVisibility(RoomPublishInDirectory.state == .on ? .public : .private) { (response) in
                if response.isFailure {
                    print("Failed to set directory visibility: \(response.error!.localizedDescription)")
                }
            }
        }
        
        if initialRoomAccessOnlyInvited != RoomAccessOnlyInvited.state ||
           initialRoomAccessExceptGuests != RoomAccessExceptGuests.state ||
           initialRoomAccessIncludingGuests != RoomAccessIncludingGuests.state {
            var joinrule: MXRoomJoinRule
            var guestrule: MXRoomGuestAccess
            switch NSControl.StateValue.on {
            case RoomAccessOnlyInvited.state:
                joinrule = .invite
                guestrule = .forbidden
                break
            case RoomAccessExceptGuests.state:
                joinrule = .public
                guestrule = .forbidden
                break
            case RoomAccessIncludingGuests.state:
                joinrule = .public
                guestrule = .canJoin
                break
            default:
                joinrule = .invite
                guestrule = .forbidden
            }
            room.setJoinRule(joinrule) { (response) in
                if response.isFailure {
                    print("Failed to set join rule: \(response.error!.localizedDescription)")
                }
            }
            room.setGuestAccess(guestrule) { (response) in
                if response.isFailure {
                    print("Failed to set guest access: \(response.error!.localizedDescription)")
                }
            }
        }
        
        if initialRoomHistorySinceJoined != RoomHistorySinceJoined.state ||
            initialRoomHistorySinceInvited != RoomHistorySinceInvited.state ||
            initialRoomHistorySinceSelected != RoomHistorySinceSelected.state ||
            initialRoomHistoryAnyone != RoomHistoryAnyone.state {
            var historyvisibility: MXRoomHistoryVisibility
            switch NSControl.StateValue.on {
            case RoomHistorySinceJoined.state:
                historyvisibility = .joined
                break
            case RoomHistorySinceInvited.state:
                historyvisibility = .invited
                break
            case RoomHistorySinceSelected.state:
                historyvisibility = .shared
                break
            case RoomHistoryAnyone.state:
                historyvisibility = .worldReadable
                break
            default:
                historyvisibility = .shared
            }
            room.setHistoryVisibility(historyvisibility) { (response) in
                if response.isFailure {
                    print("Failed to set history visibility: \(response.error!.localizedDescription)")
                }
            }
        }
        
        sender.window?.close()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if roomId == "" {
            self.dismissViewController(self)
            return
        }
        
        let room = MatrixServices.inst.session.room(withRoomId: roomId) as MXRoom
        
        RoomName.stringValue = room.state.name ?? ""
        RoomName.isEnabled = true
        RoomName.isEditable = true
        
        RoomTopic.stringValue = room.state.topic ?? ""
        RoomTopic.isEnabled = true
        RoomTopic.isEditable = true
        
        initialRoomName = RoomName.stringValue
        initialRoomTopic = RoomTopic.stringValue
        
        room.getDirectoryVisibility(completion: { (visibility) in
            if visibility.isSuccess {
              //  self.RoomPublishInDirectory.isEnabled = true
                self.RoomPublishInDirectory.state = visibility.value == .public ? .on : .off
            } else {
                self.RoomPublishInDirectory.state = .off
            }
        })
        
        RoomAccessOnlyInvited.state = !room.state.isJoinRulePublic ? .on : .off
        RoomAccessExceptGuests.state = room.state.isJoinRulePublic && room.state.guestAccess == .forbidden ? .on : .off
        RoomAccessIncludingGuests.state = room.state.isJoinRulePublic && room.state.guestAccess == .canJoin ? .on : .off
        
        initialRoomAccessOnlyInvited = RoomAccessOnlyInvited.state
        initialRoomAccessExceptGuests = RoomAccessExceptGuests.state
        initialRoomAccessIncludingGuests = RoomAccessIncludingGuests.state
        
        RoomHistorySinceJoined.state = room.state.historyVisibility == .joined ? .on : .off
        RoomHistorySinceInvited.state = room.state.historyVisibility == .invited ? .on : .off
        RoomHistorySinceSelected.state = room.state.historyVisibility == .shared ? .on : .off
        RoomHistoryAnyone.state = room.state.historyVisibility == .worldReadable ? .on : .off
        
        initialRoomHistorySinceJoined = RoomHistorySinceJoined.state
        initialRoomHistorySinceInvited = RoomHistorySinceInvited.state
        initialRoomHistorySinceSelected = RoomHistorySinceSelected.state
        initialRoomHistoryAnyone = RoomHistoryAnyone.state
    }
    
}