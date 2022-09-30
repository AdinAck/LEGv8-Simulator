//
//  ContentView.swift
//  LEGv8-Simulator
//
//  Created by Adin Ackerman on 9/25/22.
//

import SwiftUI
import SwiftyMonaco

#if os(macOS)
typealias _hsplitview = HSplitView
typealias _vsplitview = VSplitView
#else
typealias _hsplitview = HStack
typealias _vsplitview = VStack
#endif

struct ContentView: View {
    // monaco
    let syntax = SyntaxHighlight(title: "asm", fileURL: Bundle.main.url(forResource: "asm", withExtension: "js")!)
    
    @StateObject var interpreter: Interpreter = Interpreter()
    @Binding var document: Document
    
    var body: some View {
        _hsplitview {
            _vsplitview {
                SwiftyMonaco(text: $document.text)
                    .syntaxHighlight(syntax)
                    .smoothCursor(true)
                    .cursorBlink(.smooth)
                    .layoutPriority(1)
                
                ConsoleView()
                    .environmentObject(interpreter)
            }
            
            _vsplitview {
                RegisterView()
                    .environmentObject(interpreter)
                                
                MemoryView()
                    .environmentObject(interpreter)
            }
        }
        .toolbar {
            ToolbarItemGroup {
                    Button {
                        withAnimation {
                            if !interpreter.running {
                                interpreter.start(document.text)
                                interpreter.running = true
                            }
                            interpreter.step()
                        }
                    } label: {
                        Image(systemName: "forward.end.fill")
                    }
                    .keyboardShortcut("k")
                    .help("Step")
                
                    Button {
                        withAnimation {
                            interpreter.start(document.text)
                            interpreter.running = true
                            
                            while interpreter.running {
                                interpreter.step()
                            }
                        }
                    } label: {
                        Image(systemName: "play.fill")
                    }
                    .keyboardShortcut("l")
                    .help("Run/Continue")
                
                    Button {
                        interpreter.running = false
                    } label: {
                        VStack {
                            Image(systemName: "stop.fill")
                        }
                    }
                    .disabled(!interpreter.running)
                    .keyboardShortcut("j")
                    .help("Stop")
            }
        }
        .onChange(of: document.text) { newValue in
            interpreter.running = false
        }
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
