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
        
        // Don't center horizontally for pure movement - only center if resizing is enabled
        if Defaults.centeredDirectionalMove.enabled != false && Defaults.resizeOnDirectionalMove.enabled {
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
        
        // Use incremental movement instead of edge-to-edge movement
        let moveOffset = visibleFrameOfScreen.height * CGFloat(Defaults.pureMovementOffset.value)
        
        if params.action == .moveUp {
            rect.origin.y += moveOffset
        } else {
            rect.origin.y -= moveOffset
        }
        
        // Ensure window stays within screen bounds
        if rect.origin.y < visibleFrameOfScreen.minY {
            rect.origin.y = visibleFrameOfScreen.minY
        } else if rect.origin.y + rect.height > visibleFrameOfScreen.maxY {
            rect.origin.y = visibleFrameOfScreen.maxY - rect.height
        }
        
        return RectResult(rect)
    }
    
}
