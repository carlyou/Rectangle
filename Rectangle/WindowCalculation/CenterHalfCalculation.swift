//
//  AlmostMaximizeCalculation.swift
//  Rectangle
//
//  Created by Ryan Hanson on 7/26/19.
//  Copyright © 2019 Ryan Hanson. All rights reserved.
//

import Foundation

class CenterHalfCalculation: WindowCalculation, OrientationAware, RepeatedExecutionsInThirdsCalculation, RepeatedExecutionsCalculation {
    
    func calculateFractionalRect(_ params: RectCalculationParameters, cycleSize: CycleSize) -> RectResult {
        
        let visibleFrameOfScreen = params.visibleFrameOfScreen
        return visibleFrameOfScreen.isLandscape
            ? landscapeRect(visibleFrameOfScreen, cycleSize: cycleSize)
            : portraitRect(visibleFrameOfScreen, cycleSize: cycleSize)
    }
    
    override func calculateRect(_ params: RectCalculationParameters) -> RectResult {
        
        if (params.lastAction != nil && Defaults.subsequentExecutionMode.resizes) || Defaults.centerHalfCycles.userEnabled {
            return calculateOrientationAwareRepeatedRect(params)
        }
        
        // Use orientation-aware sizing for first execution
        let isLandscape = params.visibleFrameOfScreen.isLandscape
        let orientationSize = isLandscape ? CycleSize.widthOneHalf : CycleSize.heightOneHalf
        return calculateFractionalRect(params, cycleSize: orientationSize)
    }
    
    private func calculateOrientationAwareRepeatedRect(_ params: RectCalculationParameters) -> RectResult {
        guard let count = params.lastAction?.count,
              params.lastAction?.action == params.action
        else {
            return calculateFirstRect(params)
        }
        
        let isLandscape = params.visibleFrameOfScreen.isLandscape
        let allConfiguredSizes = Defaults.centerHalfCycleSizes.value
        
        // Get available sizes for this action first
        let availableSizes = CycleSize.availableSizes(for: params.action)
        
        // If no configured sizes, use the available ones filtered by configured or default
        let sizesToUse = allConfiguredSizes.isEmpty ? Set(CycleSize.defaultSizes(for: params.action)) : allConfiguredSizes
        
        // Filter sizes based on orientation
        let orientationAppropriate = sizesToUse.filter { cycleSize in
            if isLandscape {
                // Landscape: use width-only sizes (height = 1.0)
                return cycleSize.height == 1.0
            } else {
                // Portrait: use height-only sizes (width = 1.0)
                return cycleSize.width == 1.0
            }
        }
        
        // Filter by orientation-appropriate ones that are available
        let sortedPositions = availableSizes.filter { orientationAppropriate.contains($0) }
        
        if sortedPositions.isEmpty {
            // Fallback to first rect if no appropriate sizes configured
            return calculateFirstRect(params)
        }
        
        let position = count % sortedPositions.count
        let selectedSize = sortedPositions[position]
        
        return calculateRect(for: selectedSize, params: params)
    }
    
    func landscapeRect(_ visibleFrameOfScreen: CGRect, cycleSize: CycleSize) -> RectResult {
        var rect = visibleFrameOfScreen
        
        // Resize
        rect.size.height = round(visibleFrameOfScreen.height * CGFloat(cycleSize.height))
        rect.size.width = round(visibleFrameOfScreen.width * CGFloat(cycleSize.width))
        
        // Center
        rect.origin.x = round((visibleFrameOfScreen.width - rect.width) / 2.0) + visibleFrameOfScreen.minX
        rect.origin.y = round((visibleFrameOfScreen.height - rect.height) / 2.0) + visibleFrameOfScreen.minY
        
        return RectResult(rect, subAction: .centerVerticalHalf)
    }

    func portraitRect(_ visibleFrameOfScreen: CGRect, cycleSize: CycleSize) -> RectResult {
        var rect = visibleFrameOfScreen
        
        // Resize
        rect.size.width = round(visibleFrameOfScreen.width * CGFloat(cycleSize.width))
        rect.size.height = round(visibleFrameOfScreen.height * CGFloat(cycleSize.height))
        
        // Center
        rect.origin.x = round((visibleFrameOfScreen.width - rect.width) / 2.0) + visibleFrameOfScreen.minX
        rect.origin.y = round((visibleFrameOfScreen.height - rect.height) / 2.0) + visibleFrameOfScreen.minY
        
        return RectResult(rect, subAction: .centerHorizontalHalf)
    }

    func landscapeRect(_ visibleFrameOfScreen: CGRect) -> RectResult {
        return landscapeRect(visibleFrameOfScreen, cycleSize: CycleSize.oneHalf)
    }
    
    func portraitRect(_ visibleFrameOfScreen: CGRect) -> RectResult {
        return portraitRect(visibleFrameOfScreen, cycleSize: CycleSize.oneHalf)
    }
    
    // MARK: - RepeatedExecutionsCalculation
    
    func calculateFirstRect(_ params: RectCalculationParameters) -> RectResult {
        let isLandscape = params.visibleFrameOfScreen.isLandscape
        let allConfiguredSizes = Defaults.centerHalfCycleSizes.value
        
        // Get available sizes for this action first
        let availableSizes = CycleSize.availableSizes(for: params.action)
        
        // If no configured sizes, use the available ones filtered by configured or default
        let sizesToUse = allConfiguredSizes.isEmpty ? Set(CycleSize.defaultSizes(for: params.action)) : allConfiguredSizes
        
        // Filter sizes based on orientation
        let orientationAppropriate = sizesToUse.filter { cycleSize in
            if isLandscape {
                // Landscape: use width-only sizes (height = 1.0)
                return cycleSize.height == 1.0
            } else {
                // Portrait: use height-only sizes (width = 1.0)
                return cycleSize.width == 1.0
            }
        }
        
        // Filter by orientation-appropriate ones that are available
        let sortedPositions = availableSizes.filter { orientationAppropriate.contains($0) }
        
        // Use the first size, or fall back to orientation-based rect
        let firstSize = sortedPositions.first ?? CycleSize.oneHalf
        return calculateFractionalRect(params, cycleSize: firstSize)
    }
    
    func calculateRect(for cycleDivision: CycleSize, params: RectCalculationParameters) -> RectResult {
        return calculateFractionalRect(params, cycleSize: cycleDivision)
    }

}

