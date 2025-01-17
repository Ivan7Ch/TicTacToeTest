//
//  PlayOnlineViewModel.swift
//  AdvancedTTT
//
//  Created by User on 08.01.2022.
//

import Foundation

protocol OnlineGameViewModelDelegate: GameViewModelDelegate {
    var playerBoardType: BoardType! { get set }
}

class PlayOnlineViewModel: SinglePlayerViewModel {

    var room = "000000"
    var bluePlayerId: String = ""
    var redPlayerId: String = ""
    
    override init(vc: OnlineGameViewModelDelegate) {
        super.init(vc: (vc as GameViewModelDelegate) as! OnlineGameViewModelDelegate)
    }
    
    override func reloadGame() {
        FirebaseHelper(room: room).writeData(data: RawGameData(field: "aaaaaaaaa", isBlueMove: true, roomNumber: room, bluePlayer: LocalStorageHelper.uniquePlayerID, redPlayer: redPlayerId, blueItems: GameFieldCoder.allBlueItems, redItems: GameFieldCoder.allRedItems))
        gameData.setupArrays()
        delegate?.reloadViews()
    }
    
    
    func fetchField() {
        FirebaseHelper(room: room).listenField { [weak self] data in
            
            self?.isBlueMove = data?.isBlueMove ?? false
            self?.setupGameData(data: data)
            self?.delegate?.reloadViews()
            
            if let bluePlayerId = data?.bluePlayer, !bluePlayerId.isEmpty {
                self?.bluePlayerId = bluePlayerId
            } else {
                self?.bluePlayerId = LocalStorageHelper.uniquePlayerID
            }
            
            if let redPlayerId = data?.redPlayer, !redPlayerId.isEmpty {
                self?.redPlayerId = redPlayerId
            } else {
                //need to write on firebase the id
                self?.redPlayerId = LocalStorageHelper.uniquePlayerID
            }
            
            if data?.bluePlayer == LocalStorageHelper.uniquePlayerID {
                self?.playerBoardType = .blue
            } else {
                self?.playerBoardType = .red
            }
        }
    }
    
    override func didTapAt(_ indexPath: IndexPath, for type: BoardType) {
        super.didTapAt(indexPath, for: type)
        
        if let encodedField = GameFieldCoder.encode(from: gameData.mainSource),
           encodedField.count == 9, type == .main {
            var blueItems: String? = nil
            var redItems: String? = nil
            
            if !isBlueMove {
                blueItems = gameData.blueSource.toStringFiltered()
            } else {
                redItems = gameData.redSource.toStringFiltered()
            }
            
            FirebaseHelper(room: room)
                .updateData(data: RawGameData(field: encodedField,
                                    isBlueMove: isBlueMove,
                                    roomNumber: room,
                                    bluePlayer: bluePlayerId,
                                    redPlayer: redPlayerId,
                                    blueItems: blueItems,
                                    redItems: redItems))
            
        }
    }
}
