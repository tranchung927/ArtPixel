//
//  AsciiArtist.swift
//  ArtPixel
//
//  Created by Chung on 2018/01/04.
//  Copyright © 2018 Chung. All rights reserved.
//

import UIKit

/** Transforms an image to ASCII art. */
class AsciiArtist {
    fileprivate let
    image:   UIImage,
    palette: AsciiPalette
    
    var matrix = [[Double]]()
    
    init(_ image: UIImage, _ palette: AsciiPalette) {
        self.image   = image
        self.palette = palette
    }
    
    func createAsciiArt() -> String {
        let
        dataProvider = image.cgImage?.dataProvider,
        pixelData    = dataProvider?.data,
        pixelPointer = CFDataGetBytePtr(pixelData),
        intensities  = intensityMatrixFromPixelPointer(pixelPointer!),
        symbolMatrix = symbolMatrixFromIntensityMatrix(intensities)
//        print(intensities)
//        print(symbolMatrix)
        self.matrix = intensities
        return symbolMatrix.joined(separator: "\n")
    }
    
    fileprivate func intensityMatrixFromPixelPointer(_ pointer: PixelPointer) -> [[Double]] {
        let
        width  = Int(image.size.width),
        height = Int(image.size.height),
        matrix = Pixel.createPixelMatrix(width, height)
//        print(matrix.count)
        return matrix.map { pixelRow in
            pixelRow.map { pixel in
                pixel.intensityFromPixelPointer(pointer)
            }
        }
    }
    
    fileprivate func symbolMatrixFromIntensityMatrix(_ matrix: [[Double]]) -> [String] {
        return matrix.map { intensityRow in
            intensityRow.reduce("") {
                $0 + self.symbolFromIntensity($1)
            }
        }
    }
    
    fileprivate func symbolFromIntensity(_ intensity: Double) -> String {
        assert(0.0 <= intensity && intensity <= 1.0)
        
        let factor = palette.symbols.count - 1,
            value  = round(intensity * Double(factor)),
            index  = Int(value)
        return palette.symbols[index]
    }
}
