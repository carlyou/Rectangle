//
//  RepeatedExecutionsInThirdsCalculation.swift
//  Rectangle
//
//  Created by Charlie Harding on 12/06/20.
//  Copyright © 2020 Ryan Hanson. All rights reserved.
//

import Foundation

protocol RepeatedExecutionsInThirdsCalculation: RepeatedExecutionsCalculation {
    
    func calculateFractionalRect(_ params: RectCalculationParameters, cycleSize: CycleSize) -> RectResult

}

extension RepeatedExecutionsInThirdsCalculation {
    
    func calculateFirstRect(_ params: RectCalculationParameters) -> RectResult {
        let firstCycleSize = getFirstCycleSizeForAction(params.action)
        return calculateFractionalRect(params, cycleSize: firstCycleSize)
    }
    
    func calculateRect(for cycleDivision: CycleSize, params: RectCalculationParameters) -> RectResult {
        return calculateFractionalRect(params, cycleSize: cycleDivision)
    }
    
}
