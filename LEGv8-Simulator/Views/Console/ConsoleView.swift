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
    
    @State var isPresented: Bool = false
    @State var text: String = ""
    
    var body: some View {
        VStack {
            HStack {
                Button {
                    isPresented.toggle()
                } label: {
                    Image(systemName: "text.line.last.and.arrowtriangle.forward")
                }
                .buttonStyle(.borderless)
                .padding(.leading, 8)
                .padding(.top, 8)
                .popover(isPresented: $isPresented) {
                    TextEditor(text: $text)
                        .frame(width: 300, height: 300)
                        .padding()
                }
                .onChange(of: isPresented) { newValue in
                    interpreter.breakPoints = text.split(separator: "\n").map { sub in Int(String(sub))! }
                }
                .help("Breakpoints")
                
                Button {
                    interpreter.stepOver()
                } label: {
                    Image(systemName: "arrow.uturn.forward")
                }
                .buttonStyle(.borderless)
                .padding(.leading, 8)
                .padding(.top, 8)
                .help("Step over")
                .disabled(interpreter.lastInstruction != "bl")
                
                Spacer()
            }
            
            ScrollViewReader { scrollView in
                List {
                    if interpreter.log.count > 0 {
                        ForEach(interpreter.log, id: \.id) { entry in
                            ConsoleRowView(entry: entry, color: entry.type == LineType.error ? .red : entry.id == interpreter.log.count - 1 ? .blue : entry.type == LineType.label ? .yellow : entry.type == LineType.data ? .purple : .green)
                                .id(entry.id)
                        }
                    }
                }
                .onChange(of: interpreter.log) { newValue in
                    if interpreter.log.count > 0 {
                        withAnimation {
                            scrollView.scrollTo(interpreter.log[interpreter.log.endIndex - 1].id)
                        }
                    }
                }
            }
        }
    }
}

//struct ConsoleView_Previews: PreviewProvider {
//    static var previews: some View {
//        ConsoleView()
//    }
//}
