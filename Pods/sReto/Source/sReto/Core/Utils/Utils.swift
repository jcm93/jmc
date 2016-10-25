//
//  Utils.swift
//  sReto
//
//  Created by Julian Asamer on 07/07/14.
//  Copyright (c) 2014 - 2016 Chair for Applied Software Engineering
//
//  Licensed under the MIT License
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
//  The software is provided "as is", without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness
//  for a particular purpose and noninfringement. in no event shall the authors or copyright holders be liable for any claim, damages or other liability, 
//  whether in an action of contract, tort or otherwise, arising from, out of or in connection with the software or the use or other dealings in the software.
//

import Foundation

func NSMakeRange(range: Range<Int>) -> NSRange {
    return NSMakeRange(range.startIndex, range.endIndex - range.startIndex)
}

// Returns the first element of a sequence
func first<S: SequenceType, E where E == S.Generator.Element>(sequence: S) -> E? {
    for element in sequence { return element }
    return nil
}

// Returns the second element of a sequence
func second<S: SequenceType, E where E == S.Generator.Element>(sequence: S) -> E? {
    var first = true
    for element in sequence { if first { first = false } else { return element } }
    return nil
}

func reduce<S: SequenceType, E where S.Generator.Element == E>(sequence: S, combine: (E, E) -> E) -> E? {
    if let first = first(sequence) {
        return sequence.reduce(first, combine: combine)
    } else {
        return nil
    }
}

func pairwise<T>(elements: [T]) -> [(T, T)] {
    var elementCopy = elements
    elementCopy.removeAtIndex(0)
    return Array(Zip2Sequence(elements, elementCopy))
}

func sum<S: SequenceType where S.Generator.Element == Int>(sequence: S) -> Int {
    return sequence.reduce(0, combine: +)
}
func sum<S: SequenceType where S.Generator.Element == Float>(sequence: S) -> Float {
    return sequence.reduce(0, combine: +)
}
// Takes a key extractor that maps an element to a comparable value, and returns a function that compares to objects of type T via the extracted key.
func comparing<T, U: Comparable>(withKeyExtractor keyExtractor: (T) -> U) -> ((T, T) -> Bool) {
    return { a, b in keyExtractor(a) < keyExtractor(b) }
}

func equal<S: CollectionType, T where S.Generator.Element == T>(comparator: (T, T) -> Bool, s1: S, s2: S) -> Bool {
    return (s1.count == s2.count) && Zip2Sequence(s1, s2).reduce(true, combine: { value, pair in value && comparator( pair.0, pair.1) })
}

// Returns the non-nil parameter if only one of them is nil, nil if both parameters are nil, otherwise the minimum.
func min<T: Comparable>(a: T?, b: T?) -> T? {
    switch (a, b) {
    case (.None, .None): return nil
    case (.None, .Some(let value)): return value
    case (.Some(let value), .None): return value
    case (.Some(let value1), .Some(let value2)): return min(value1, value2)
    }
}

func minimum<T>(a: T, b: T, comparator: (T, T) -> Bool) -> T { return comparator(a, b) ? a : b }
func minimum<T, S: SequenceType where S.Generator.Element == T>(sequence: S, comparator: (T, T) -> Bool) -> T? {
    if let first = first(sequence) {
        return sequence.reduce(first, combine: { (a, b) -> T in return minimum(a, b: b, comparator: comparator) })
    }
    return nil
}

// Compares two sequences with comparable elements. 
// The first non-equal element that exists in both sequences determines the result.
// If no non-equal element exists (either because one sequence is longer than the other, or they are equal) false is returned.
func < <S: SequenceType, T: SequenceType where S.Generator.Element: Comparable, S.Generator.Element == T.Generator.Element>(a: S, b: T) -> Bool {
    if let (a, b) = first((Zip2Sequence(a, b).lazy).filter({ pair in pair.0 != pair.1 })) {
        return a < b
    }
    
    return false
}

extension Dictionary {
    mutating func getOrDefault(key: Key, @autoclosure defaultValue: () -> Value) -> Value {
        if let value = self[key] {
            return value
        } else {
            let value = defaultValue()
            self[key] = value
            return value
        }
    }
}

struct Queue<T: AnyObject> {
    typealias Element = T
    var array: [T] = []
    
    var count: Int { get { return array.count } }
    
    mutating func enqueue(element: Element) {
       array.append(element)
    }
    
    mutating func dequeue() -> Element? {
        if array.count == 0 { return nil }
        return array.removeAtIndex(0)
    }
    
    func anyMatch(predicate: (Element) -> Bool) -> Bool {
        for element in array { if predicate(element) { return true } }
        
        return false
    }
    
    mutating func filter(predicate: (Element) -> Bool) {
        self.array = array.filter({ element in predicate(element) })
    }
}

extension Dictionary {
    func map<NewKey: Hashable, NewValue>(mapping: (Key, Value) -> (NewKey, NewValue)) -> [NewKey: NewValue] {
        var dictionary: [NewKey: NewValue] = [:]
        
        for (key, value) in self {
            let (newKey, newValue) = mapping(key, value)
            dictionary[newKey] = newValue
        }
        
        return dictionary
    }
    
    func mapValues<NewValue>(mapping: (Key, Value) -> NewValue) -> [Key: NewValue] {
        return self.map { return ($0, mapping($0, $1)) }
    }
}
