//
//  SettingsModel.swift
//  LEGv8-Simulator
//
//  Created by Adin Ackerman on 10/2/22.
//

import Foundation

class SettingsModel: ObservableObject, Equatable {
    @Published var executionLimit: Int = 1000
    @Published var buildOnType: Bool = false
    
    static func == (lhs: SettingsModel, rhs: SettingsModel) -> Bool {
        lhs.executionLimit == rhs.executionLimit && lhs.buildOnType == rhs.buildOnType
    }
}
