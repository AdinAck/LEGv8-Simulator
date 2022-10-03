//
//  SettingsModel.swift
//  LEGv8-Simulator
//
//  Created by Adin Ackerman on 10/2/22.
//

import Foundation

class SettingsModel: ObservableObject {
    @Published var executionLimit: Int = 1000
    @Published var buildOnType: Bool = false
}
