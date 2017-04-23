//
//  SparkMediaHelper.swift
//  SparkMediaHelper
//
//  Created by Jonathan Field on 23/10/2016.
//  Copyright © 2016 Cisco. All rights reserved.
//

import UIKit

public class SparkMediaHelper: NSObject {
    
    static func timeStringFromSeconds(currrentCallDuration: Int) -> String {
        let minutes:Int = (currrentCallDuration / 60) % 60
        let seconds:Int = currrentCallDuration % 60
        let formattedTimeString = String(format: "%02u:%02u", minutes, seconds)
        return formattedTimeString
    }

}
