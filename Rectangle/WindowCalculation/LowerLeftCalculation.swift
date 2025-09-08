//
//  LowerLeftCalculation.swift
//  Rectangle, Ported from Spectacle
//
//  Created by Ryan Hanson on 6/14/19.
//  Copyright © 2019 Ryan Hanson. All rights reserved.
//

import Foundation

class LowerLeftCalculation: WindowCalculation, RepeatedExecutionsCalculation {

    override func calculateRect(_ params: RectCalculationParameters) -> RectResult {

        if params.lastAction == nil || !Defaults.subsequentExecutionMode.resizes {
            return calculateFirstRect(params)
        }
        
        return calculateRepeatedRect(params)
    }
    
    // MARK: - RepeatedExecutionsCalculation protocol
    
    func calculateFirstRect(_ params: RectCalculationParameters) -> RectResult {
        let firstCycleSize = getFirstCycleSizeForAction(params.action)
        return calculateRect(for: firstCycleSize, params: params)
    }
    
    func calculateRect(for cycleSize: CycleSize, params: RectCalculationParameters) -> RectResult {
        let visibleFrameOfScreen = params.visibleFrameOfScreen

        var rect = visibleFrameOfScreen
        
        rect.size.width = floor(visibleFrameOfScreen.width * CGFloat(cycleSize.width))
        rect.size.height = floor(visibleFrameOfScreen.height * CGFloat(cycleSize.height))
        
        return RectResult(rect)
    }
    
    func calculateFractionalRect(_ params: RectCalculationParameters, cycleSize: CycleSize) -> RectResult {
        return calculateRect(for: cycleSize, params: params)
    }
}
