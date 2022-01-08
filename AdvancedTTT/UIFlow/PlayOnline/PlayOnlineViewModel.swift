//
//  PlayOnlineViewModel.swift
//  AdvancedTTT
//
//  Created by User on 08.01.2022.
//

import Foundation

class PlayOnlineViewModel {
    
    weak var vc: PlayOnlineViewController?
    let gameData: GameData
    
    var isBlueMove: Bool {
        didSet {
            vc?.setCollectionViewDisabled(isBlueMove ? .red : .blue)
        }
    }
    var selected: Item?
    
    private var matrix = [[Item]]()
    private let sideLenght = 3
    
    var playerBoardType: BoardType
    var room = "112233"
    
    init(vc: PlayOnlineViewController) {
        self.vc = vc
        self.gameData = GameData()
        self.isBlueMove = true
        self.playerBoardType = Bool.random() ? .blue : .red
    }
    
    private func setupMatrix() {
        matrix = [[Item]]()
        for i in 0..<sideLenght {
            var arr = [Item]()
            for j in 0..<sideLenght {
                let item = gameData.mainSource[i * sideLenght + j]
                arr.append(item)
            }
            matrix.append(arr)
        }
    }
    
    private func winMessage(for side: Side) -> String {
        switch side {
        case .blue:
            return "Blue is winner"
        case .red:
            return "Red is winner"
        default:
            return ""
        }
    }
    
    func check() {
        guard let vc = vc else { return }
        
        setupMatrix()
        
        for j in 0..<3 {
            if matrix[j][0].side == .unknown { continue }
            if matrix[j][0].side == matrix[j][1].side, matrix[j][1].side == matrix[j][2].side {
                vc.showWinAlert(with: winMessage(for: matrix[j][0].side))
                return
            }
        }
        
        for j in 0..<3 {
            if matrix[0][j].side == .unknown { continue }
            if matrix[0][j].side == matrix[1][j].side, matrix[1][j].side == matrix[2][j].side {
                vc.showWinAlert(with: winMessage(for: matrix[0][j].side))
                return
            }
        }
        
        if matrix[0][0].side != .unknown, matrix[0][0].side == matrix[1][1].side, matrix[1][1].side == matrix[2][2].side {
            vc.showWinAlert(with: winMessage(for: matrix[0][0].side))
            return
        }
        
        if matrix[0][2].side != .unknown, matrix[0][2].side == matrix[1][1].side, matrix[1][1].side == matrix[2][0].side {
            vc.showWinAlert(with: winMessage(for: matrix[0][2].side))
            return
        }
        
        if isDraw() {
            vc.showWinAlert(with: "Draw")
            return
        }
    }
    
    private func isDraw() -> Bool {
        if gameData.redSource.filter({ $0.side == .unknown }).count == 6 && gameData.blueSource.filter({ $0.side == .unknown }).count == 6 {
            return true
        }
        
        if isBlueMove {
            return !gameData.canPerformMove(for: gameData.blueSource)
        } else {
            return !gameData.canPerformMove(for: gameData.redSource)
        }
    }
    
    func fetchField() {
        FirebaseHelper(room: room).listenField { [weak self] data in
            guard let field = GameFieldCoder.decode(from: data?.field ?? "") else { return }
            
            self?.isBlueMove = data?.isBlueMove ?? false
            self?.gameData.mainSource = field
            self?.vc?.reloadViews()
        }
    }
}


extension PlayOnlineViewModel {
    
    func removeSelections() {
        gameData.removeSelections()
        vc?.reloadViews()
    }
    
    func getItemFor(_ indexPath: IndexPath, in resourceType: BoardType) -> Item {
        switch resourceType {
        case .main:
            return gameData.mainSource[indexPath.row]
        case .blue:
            return gameData.blueSource[indexPath.row]
        case .red:
            return gameData.redSource[indexPath.row]
        }
    }
    
    func reloadGame() {
        FirebaseHelper(room: room).writeData(data: RawGameData(field: "aaaaaaaaa", isBlueMove: true))
        gameData.setupArrays()
        vc?.reloadViews()
    }
    
    func didTapAt(_ indexPath: IndexPath, for type: BoardType) {
        switch type {
        case .main:
            didTapOnMainSource(at: indexPath)
        case .red:
            if !isBlueMove { break }
            didTapOnSecondary(source: gameData.redSource, at: indexPath)
        case .blue:
            if !isBlueMove { break }
            didTapOnSecondary(source: gameData.blueSource, at: indexPath)
        }
        
        if let encodedField = GameFieldCoder.encode(from: gameData.mainSource),
           encodedField.count == 9 {
            FirebaseHelper(room: room).writeData(data: RawGameData(field: encodedField, isBlueMove: true))
        }
        
        vc?.reloadViews()
    }
    
    func didTapToDrag(at indexPath: IndexPath, for type: BoardType) {
        switch type {
        case .main:
            break
        case .red:
            if isBlueMove { break }
            didTapToDragOnSecondary(source: gameData.redSource, at: indexPath)
        case .blue:
            if !isBlueMove { break }
            didTapToDragOnSecondary(source: gameData.blueSource, at: indexPath)
        }
    }
    
    func canDropItem(at indexPath: IndexPath, on boardType: BoardType) -> Bool {
        if boardType != .main, (selected?.power ?? -1) <= gameData.mainSource[indexPath.row].power {
            return false
        }
        return true
    }
    
    private func didTapOnMainSource(at indexPath: IndexPath) {
        guard let selected = selected else { return }
        if selected.power == 0 { return }
        if selected.power <= gameData.mainSource[indexPath.row].power { return }
        gameData.mainSource[indexPath.row].power = selected.power
        gameData.mainSource[indexPath.row].side = selected.side
        self.selected = nil
        removeSelections()
        isBlueMove.toggle()
    }
    
    private func didTapOnSecondary(source: [Item], at indexPath: IndexPath) {
        gameData.deselectAll()
        if selected == source[indexPath.row] {
            selected = nil
        } else if selected != source[indexPath.row] {
            selected = source[indexPath.row]
            selected!.isSelected = true
        }
    }
    
    private func didTapToDragOnSecondary(source: [Item], at indexPath: IndexPath) {
        gameData.deselectAll()
        if selected != source[indexPath.row] {
            selected = source[indexPath.row]
            selected!.isSelected = true
        }
    }
}
