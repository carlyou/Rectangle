//
//  RepeatedExecutionsCalculation.swift
//  Rectangle
//
//  Created by Ryan Hanson on 10/18/19.
//  Copyright © 2019 Ryan Hanson. All rights reserved.
//

import Foundation
import UserNotifications

protocol RepeatedExecutionsCalculation {
    
    func calculateFirstRect(_ params: RectCalculationParameters) -> RectResult
    
    func calculateRect(for cycleDivision: CycleSize, params: RectCalculationParameters) -> RectResult

}

extension RepeatedExecutionsCalculation {
    
    func calculateRepeatedRect(_ params: RectCalculationParameters) -> RectResult {
        
        guard let count = params.lastAction?.count,
              params.lastAction?.action == params.action
        else {
            return calculateFirstRect(params)
        }
        
        let positions = getCycleSizesForAction(params.action)
        
        // Get available sizes for this action and filter by selected ones
        let availableSizes = CycleSize.availableSizes(for: params.action)
        let sortedPositions = availableSizes.filter { positions.contains($0) }
                
        let position = count % sortedPositions.count
        
        
        let selectedSize = sortedPositions[position]
        // Debug: Check what sizes are actually configured for repeated execution
        
        return calculateRect(for: selectedSize, params: params)
    }
    
    private func getCycleSizesForAction(_ action: WindowAction) -> Set<CycleSize> {
        switch action {
        case .leftHalf:
            return Defaults.leftHalfCycleSizes.value
        case .rightHalf:
            return Defaults.rightHalfCycleSizes.value
        case .topHalf:
            return Defaults.topHalfCycleSizes.value
        case .bottomHalf:
            return Defaults.bottomHalfCycleSizes.value
        case .topLeft:
            return Defaults.topLeftCycleSizes.value
        case .topRight:
            return Defaults.topRightCycleSizes.value
        case .bottomLeft:
            return Defaults.bottomLeftCycleSizes.value
        case .bottomRight:
            return Defaults.bottomRightCycleSizes.value
        case .centerHalf:
            return Defaults.centerHalfCycleSizes.value
        default:
            // Fall back to global cycle sizes for other actions
            let useDefaultPositions = !Defaults.cycleSizesIsChanged.enabled
            return useDefaultPositions ? CycleSize.defaultSizes : Defaults.selectedCycleSizes.value
        }
    }
    
    func getFirstCycleSizeForAction(_ action: WindowAction) -> CycleSize {
        let positions = getCycleSizesForAction(action)
        
        // Get available sizes for this action and filter by selected ones
        let availableSizes = CycleSize.availableSizes(for: action)
        let sortedPositions = availableSizes.filter { positions.contains($0) }
        
        // Debug logging
        
        let result = sortedPositions.first ?? CycleSize.oneHalf
        
        // Debug: Check what sizes are actually configured
        
        // Return the first size, or fall back to oneHalf if none are configured
        return result
    }
    
}
