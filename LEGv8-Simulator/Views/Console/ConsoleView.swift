//
//  ConsoleView.swift
//  LEGv8-Simulator
//
//  Created by Adin Ackerman on 9/26/22.
//

import Foundation
import SwiftUI

struct ConsoleView: View {
    @EnvironmentObject var interpreter: Interpreter
    
    var body: some View {
        ScrollViewReader { scrollView in
            ScrollView(.vertical) {
                LazyVStack(alignment: .leading) {
                    if interpreter.log.count > 0 {
                        ForEach(interpreter.log, id: \.id) { entry in
                            ConsoleRowView(entry: entry, color: entry.type == LineType.error ? .red : entry.id == interpreter.log.count - 1 ? .blue : entry.type == LineType.label ? .yellow : entry.type == LineType.data ? .purple : .green)
                                .id(entry.id)
                        }
                    }
                }
                .onChange(of: interpreter.log) { newValue in
                    // this is a disgusting workaround to prevent the scrollview from lagging behind due to animation
                    DispatchQueue.global().async {
                        for _ in 0..<40 { // one second
                            // a withAnimation block here causes thread contradiction
                            if interpreter.log.count > 0 {
                                scrollView.scrollTo(interpreter.log[interpreter.log.endIndex - 1].id)
                                Thread.sleep(forTimeInterval: 0.025)
                            }
                        }
                    }
                }
            }
        }
        .padding()
    }
}

//struct ConsoleView_Previews: PreviewProvider {
//    static var previews: some View {
//        ConsoleView()
//    }
//}
