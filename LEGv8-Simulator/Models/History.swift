//
//  History.swift
//  LEGv8-Simulator
//
//  Created by Adin Ackerman on 10/24/22.
//

import Foundation

enum HistoryType {
    case read, write
}

struct HistoryEntry: Identifiable, Equatable, Comparable {
    let id: Int // PC
    let line: Int
    let value: Int64
    let type: HistoryType
    
    static func < (lhs: HistoryEntry, rhs: HistoryEntry) -> Bool {
        lhs.id < rhs.id
    }
}

class History: ObservableObject {
    @Published var registers: [String: [Int: HistoryEntry]] = [:]
    @Published var memory: [Int64: [Int: HistoryEntry]] = [:]
}
