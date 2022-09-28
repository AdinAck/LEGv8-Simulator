//
//  Document.swift
//  LEGv8-Simulator
//
//  Created by Adin Ackerman on 9/27/22.
//

import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static var exampleText: UTType {
        UTType(importedAs: "com.example.plain-text")
    }
}

struct Document: FileDocument {
    var text: String

    init(text: String = "// LEG assembly goes here...") {
        self.text = text
    }

    static var readableContentTypes: [UTType] { [.assemblyLanguageSource] }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        text = string
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8)!
        return .init(regularFileWithContents: data)
    }
}
