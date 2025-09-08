//
//  MoveLeftRightCalculation.swift
//  Rectangle
//
//  Created by Ryan Hanson on 7/26/19.
//  Copyright © 2019 Ryan Hanson. All rights reserved.
//

import Cocoa

// Applicable options:
// Defaults.subsequentExecutionMode.traversesDisplays
// Defaults.centeredDirectionalMove.enabled
// Defaults.resizeOnDirectionalMove.enabled (resizes in thirds, or just to half-width if traversesDisplays is enabled

class MoveLeftRightCalculation: WindowCalculation, RepeatedExecutionsInThirdsCalculation {
    
    override func calculate(_ params: WindowCalculationParameters) -> WindowCalculationResult? {
        
        var screen = params.usableScreens.currentScreen
        var action = params.action
        
        let canTraverseDisplays = Defaults.subsequentExecutionMode.traversesDisplays && params.usableScreens.numScreens > 1
        
        let rectResult: RectResult
        if canTraverseDisplays && isRepeatedCommand(params) {
            if action == .moveLeft {
                if let prevScreen = params.usableScreens.adjacentScreens?.prev {
                    screen = prevScreen
                }
                action = .moveRight
            } else {
                if let nextScreen = params.usableScreens.adjacentScreens?.next {
                    screen = nextScreen
                }
                action = .moveLeft
            }
            
            rectResult = calculateRect(params.asRectParams(visibleFrame: screen.adjustedVisibleFrame(params.ignoreTodo), differentAction: action))
        } else {
            rectResult = calculateRect(params.asRectParams())
        }
        
        return WindowCalculationResult(rect: rectResult.rect, screen: screen, resultingAction: action)

    }
    
    override func calculateRect(_ params: RectCalculationParameters) -> RectResult {
        calculateRect(params, newDisplay: false)
    }
    
    func calculateRect(_ params: RectCalculationParameters, newDisplay: Bool) -> RectResult {
        
        let visibleFrameOfScreen = params.visibleFrameOfScreen
        
        var calculatedWindowRect: CGRect
        if newDisplay && Defaults.resizeOnDirectionalMove.enabled {
            calculatedWindowRect = calculateFirstRect(params).rect
        } else if Defaults.resizeOnDirectionalMove.enabled {
            calculatedWindowRect = calculateRepeatedRect(params).rect
        } else {
            calculatedWindowRect = calculateGenericRect(params).rect
        }
        
        // Don't center vertically for pure movement - only center if resizing is enabled
        if Defaults.centeredDirectionalMove.enabled != false && Defaults.resizeOnDirectionalMove.enabled {
            calculatedWindowRect.origin.y = round((visibleFrameOfScreen.height - calculatedWindowRect.height) / 2.0) + visibleFrameOfScreen.minY
        }
        
        if params.window.rect.height >= visibleFrameOfScreen.height {
            calculatedWindowRect.size.height = visibleFrameOfScreen.height
            calculatedWindowRect.origin.y = visibleFrameOfScreen.minY
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
            rect.size.width = floor(visibleFrameOfScreen.width * CGFloat(requestedCycleSize.width))
        }
        
        // Use incremental movement instead of edge-to-edge movement
        let moveOffset = visibleFrameOfScreen.width * CGFloat(Defaults.pureMovementOffset.value)
        
        if params.action == .moveRight {
            rect.origin.x += moveOffset
        } else {
            rect.origin.x -= moveOffset
        }
        
        // Ensure window stays within screen bounds
        if rect.origin.x < visibleFrameOfScreen.minX {
            rect.origin.x = visibleFrameOfScreen.minX
        } else if rect.origin.x + rect.width > visibleFrameOfScreen.maxX {
            rect.origin.x = visibleFrameOfScreen.maxX - rect.width
        }
        
        return RectResult(rect)
    }
    
}

