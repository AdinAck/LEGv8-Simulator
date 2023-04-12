//
//  InspectorView.swift
//  LEGv8-Simulator
//
//  Created by Adin Ackerman on 4/10/23.
//

import SwiftUI
import Charts

struct InspectorView: View {
    @EnvironmentObject var interpreter: Interpreter
    
    typealias ChartPoint = (HistoryEntry.ID, Int64)
    
    let memories: Set<Memory.ID>
    @State private var selection: Set<Memory.ID> = Set()
    @State private var selectedEntry: HistoryEntry?
    @State private var hoverPosition: Charts.AnnotationPosition = .trailing
    
    private func nearest(_ position: ChartPoint) -> HistoryEntry? {
        var nearest: HistoryEntry? = nil
        var lastDis: Float = 0
        
        for memID in selection {
            if let history = interpreter.history.memory[memID]?.values.sorted(by: <) {
                for snapshot in history {
                    let dis = sqrt(pow(Float(position.0 - snapshot.id), 2) + pow(Float(position.1 - snapshot.value), 2))
                    if let _ = nearest {
                        if dis < lastDis {
                            nearest = snapshot
                            lastDis = dis
                        }
                    } else {
                        nearest = snapshot
                        lastDis = dis
                    }
                }
            }
        }
        
        return nearest
    }
    
    var body: some View {
        NavigationView {
            List(selection: $selection) {
                ForEach(memories.sorted(by: <), id: \.self) { memID in
                    Text("0x\(String(format: "%llX", memID))")
                }
            }
            
            if selection.isEmpty {
                Text("Select some memory...")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
            } else {
                Chart {
                    ForEach(selection.sorted(by: <), id: \.self) { memID in
                        if let history = interpreter.history.memory[memID]?.values.sorted(by: <) {
                            ForEach(history) { snapshot in
                                LineMark(x: .value("Program Counter", snapshot.id), y: .value("Memory Value", snapshot.value))
                                    .interpolationMethod(.stepEnd)
                                    .lineStyle(StrokeStyle(dash: [2, 4]))
                                    .opacity(0.5)
                                PointMark(x: .value("Program Counter", snapshot.id), y: .value("Memory Value", snapshot.value))
                                    .foregroundStyle(snapshot.type == .read ? .purple : .blue)
                            }
                            .foregroundStyle(by: .value("Address", "0x\(String(format: "%llX", memID))"))
                        }
                    }
                    
                    if let selectedEntry {
                        PointMark(x: .value("Program Counter", selectedEntry.id), y: .value("Memory Value", selectedEntry.value))
                            .foregroundStyle(.white.blendMode(.overlay))
                            .annotation(position: hoverPosition, alignment: .center, spacing: 0) {
                                VStack(alignment: .leading) {
                                    Text("PC: 0x\(String(format: "%llX", selectedEntry.id))")
                                    Text("Value: 0x\(String(format: "%llX", selectedEntry.value))")
                                    Text("Access: \(selectedEntry.type == .read ? "Read" : "Write")")
                                    Text("\(selectedEntry.line): \(interpreter.lexer.lines[selectedEntry.line - 1])")
                                }
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 8).fill(.thinMaterial))
                            }
                            .accessibilityHidden(true)
                    }
                }
                .chartOverlay { (chartProxy: ChartProxy) in
                    Color.clear
                        .onContinuousHover { hoverPhase in
                            withAnimation(.spring(response: 0.2, dampingFraction: 1)) {
                                switch hoverPhase {
                                case .active(let hoverLocation):
                                    if let pos: ChartPoint = chartProxy.value(at: hoverLocation) {
                                        hoverPosition = hoverLocation.x < chartProxy.plotAreaSize.width / 2 ? .trailing : .leading
                                        selectedEntry = nearest(pos)
                                    }
                                case .ended:
                                    selectedEntry = nil
                                }
                            }
                        }
                }
                .padding()
            }
        }
        .frame(width: 800, height: 600)
    }
}

//struct InspectorView_Previews: PreviewProvider {
//    static var previews: some View {
//        InspectorView()
//    }
//}
