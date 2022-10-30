//
//  SettingsModel.swift
//  LEGv8-Simulator
//
//  Created by Adin Ackerman on 10/2/22.
//

import Foundation
import SwiftUI

class SettingsModel: ObservableObject, Equatable {
    @AppStorage("executionLimit") var executionLimit: Int = 1000
    @AppStorage("buildOnType") var buildOnType: Bool = false
    
    static func == (lhs: SettingsModel, rhs: SettingsModel) -> Bool {
        lhs.executionLimit == rhs.executionLimit && lhs.buildOnType == rhs.buildOnType
    }
}
