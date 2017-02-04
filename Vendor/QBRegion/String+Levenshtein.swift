//
//  String+Levenshtein.swift
//  aftest
//
//  Created by hh on 17/1/16.
//  Copyright © 2017年 bobby. All rights reserved.
//

import Foundation

public func min3(a: Int, b: Int, c: Int) -> Int {
    
    return min( min(a, c), min(b, c))
    
}

public extension String {
    
    subscript(index: Int) -> Character {
        
        return self[index]
        
    }
    
    subscript(range: Range<Int>) -> String {
        
        let char0 = range.lowerBound
        
        let charN = range.upperBound
        
        return self[char0..<charN]
        
    }
    
}

public struct Array2D {
    
    var columns: Int
    var rows: Int
    var matrix: [Int]
    
    
    init(columns: Int, rows: Int) {
        
        self.columns = columns
        
        self.rows = rows
        
        matrix = Array(repeating:0, count:columns*rows)
        
    }
    
    subscript(column: Int, row: Int) -> Int {
        
        get {
            
            return matrix[columns * row + column]
            
        }
        
        set {
            
            matrix[columns * row + column] = newValue
            
        }
        
    }
    
    func columnCount() -> Int {
        
        return self.columns
        
    }
    
    func rowCount() -> Int {
        
        return self.rows
        
    }
}



public func levenshtein(_ sourceString: String, target targetString: String) -> Int {
    
    let source = Array(sourceString.unicodeScalars)
    let target = Array(targetString.unicodeScalars)
    
    let (sourceLength, targetLength) = (source.count, target.count)
    
    var distance = Array2D(columns: sourceLength + 1, rows: targetLength + 1)
    
    for x in 1...sourceLength {
        
        distance[x, 0] = x
        
    }
    
    for y in 1...targetLength {
        
        distance[0, y] = y
        
    }
    
    for x in 1...sourceLength {
        
        for y in 1...targetLength {
            
            if source[x - 1] == target[y - 1] {
                
                distance[x, y] = distance[x - 1, y - 1]
                
            } else {
                
                distance[x, y] = min3(
                    
                    a: distance[x - 1, y] + 1,
                    b: distance[x, y - 1] + 1,
                    c: distance[x - 1, y - 1] + 1
                    
                )
                
            }
            
        }
        
    }
    
    return distance[source.count, target.count]
    
}

public extension String {
    
    
    func getLevenshtein(_ target: String) -> Int {
        
        return levenshtein(self, target: target)
        
    }
    
}
