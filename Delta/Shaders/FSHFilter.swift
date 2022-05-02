//
//  FSHFilter.swift
//  Delta
//
//  Created by matrixme on 2022/4/27.
//  Copyright © 2022 Riley Testut. All rights reserved.
//

import Foundation
import CoreImage
import CoreGraphics
import GPUImage

open class FSHFilter: CIFilter {
    private var cicontext: CIContext!
    public var gpufilter: GPUImageFilter!
    @objc dynamic var inputImage: CIImage!
    open override var outputImage: CIImage? {
        let input = self.value(forKey: kCIInputImageKey) as! CIImage
        let cgimg = self.cicontext.createCGImage(input, from: input.extent)
        if cgimg == nil {
            return input
        }
        let output = self.gpufilter.newCGImage(byFilteringCGImage: cgimg).autorelease().takeUnretainedValue()
        let result = CIImage(cgImage: output)
        
        return result
    }
    static func create(_ fsh: String!) -> FSHFilter {
        let result = FSHFilter.init()
        result.cicontext = CIContext.init(options: [CIContextOption.useSoftwareRenderer: false])
        result.gpufilter = GPUImageFilter.init(fragmentShaderFromFile: fsh)
        return result
    }
    
    static func create(vsh: String!, fsh: String!) -> FSHFilter {
        let result = FSHFilter.init()
        result.cicontext = CIContext.init(options: [CIContextOption.useSoftwareRenderer: false])
        let pathvsh = Bundle.main.path(forResource: vsh, ofType: "vsh") ?? ""
        var strvsh = ""
        var strfsh = ""
        do {
            strvsh = try String(contentsOfFile: pathvsh, encoding: .utf8)
        } catch { }
        let pathfsh = Bundle.main.path(forResource: fsh, ofType: "fsh") ?? ""
        do {
            strfsh = try String(contentsOfFile: pathfsh, encoding: .utf8)
        } catch { }
        let filter = GPUImageHalftoneFilter.init()
        filter.fractionalWidthOfAPixel = 1;
        result.gpufilter = filter;
//        result.gpufilter = GPUImageFilter.init(vertexShaderFrom: strvsh, fragmentShaderFrom: strfsh)
        return result
    }
}
