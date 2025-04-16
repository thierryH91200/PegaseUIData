//
//  Untitled.swift
//  PegaseUIData
//
//  Created by Thierry hentic on 16/04/2025.
//

import SwiftUI


struct RangeSlider: View {
    let minValue: Double
    let maxValue: Double

    @Binding var lowerValue: Double
    @Binding var upperValue: Double

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let knobSize: CGFloat = 20
            let range = maxValue - minValue

            let lowerX = width * CGFloat((lowerValue - minValue) / range)
            let upperX = width * CGFloat((upperValue - minValue) / range)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 4)
                Capsule()
                    .fill(Color.blue)
                    .frame(width: upperX - lowerX, height: 4)
                    .offset(x: lowerX)

                // Lower knob
                Circle()
                    .fill(Color.white)
                    .frame(width: knobSize, height: knobSize)
                    .shadow(radius: 2)
                    .position(x: lowerX, y: 10)
                    .gesture(DragGesture().onChanged { value in
                        let percent = max(0, min(1, value.location.x / width))
                        lowerValue = min(maxValue, max(minValue, percent * range))
                        if lowerValue > upperValue {
                            lowerValue = upperValue
                        }
                    })

                // Upper knob
                Circle()
                    .fill(Color.white)
                    .frame(width: knobSize, height: knobSize)
                    .shadow(radius: 2)
                    .position(x: upperX, y: 10)
                    .gesture(DragGesture().onChanged { value in
                        let percent = max(0, min(1, value.location.x / width))
                        upperValue = min(maxValue, max(minValue, percent * range))
                        if upperValue < lowerValue {
                            upperValue = lowerValue
                        }
                    })
            }
        }
    }
}
