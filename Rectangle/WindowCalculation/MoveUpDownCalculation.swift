//
//  MoveUpDownCalculation.swift
//  Rectangle
//
//  Created by Ryan Hanson on 7/26/19.
//  Copyright © 2019 Ryan Hanson. All rights reserved.
//

import Foundation

class MoveUpDownCalculation: WindowCalculation, RepeatedExecutionsInThirdsCalculation {
    
    override func calculateRect(_ params: RectCalculationParameters) -> RectResult {
        
        let visibleFrameOfScreen = params.visibleFrameOfScreen
        
        var calculatedWindowRect: CGRect
        
        if Defaults.resizeOnDirectionalMove.enabled {
            calculatedWindowRect = calculateRepeatedRect(params).rect
        } else {
            calculatedWindowRect = calculateGenericRect(params).rect
        }
        
        if Defaults.centeredDirectionalMove.enabled != false {
            calculatedWindowRect.origin.x = round((visibleFrameOfScreen.width - calculatedWindowRect.width) / 2.0) + visibleFrameOfScreen.minX
        }
        
        if params.window.rect.width >= visibleFrameOfScreen.width {
            calculatedWindowRect.size.width = visibleFrameOfScreen.width
            calculatedWindowRect.origin.x = visibleFrameOfScreen.minX
        }
        
        return RectResult(calculatedWindowRect)

    }
    
    func calculateFractionalRect(_ params: RectCalculationParameters, cycleSize: CycleSize) -> RectResult {
        return calculateGenericRect(params, cycleSize: cycleSize)
    }
    
    func calculateGenericRect(_ params: RectCalculationParameters, cycleSize: CycleSize? = nil) -> RectResult {
        let visibleFrameOfScreen = params.visibleFrameOfScreen
        
        var rect = params.window.rect
        if let requestedCycleSize = cycleSize {
            rect.size.height = floor(visibleFrameOfScreen.height * CGFloat(requestedCycleSize.height))
        }
        
        if params.action == .moveUp {
            rect.origin.y = visibleFrameOfScreen.maxY - rect.height
        } else {
            rect.origin.y = visibleFrameOfScreen.minY
        }
        
        return RectResult(rect)
    }
    
}
