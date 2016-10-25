//
//  File.swift
//  sReto
//
//  Created by Julian Asamer on 13/11/14.
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

/**
* Some Logging functionality used within the framework.
*/

// Set the verbosity setting to control the amount of output given by Reto.
let verbositySetting: LogOutputLevel = .Verbose

/** The available output levels */
enum LogOutputLevel: Int {
    /** Print everything */
    case Verbose = 4
    /** Print medium + high priority */
    case Normal = 3
    /** Print high priority messages only */
    case Low = 2
    /** Do not print messages */
    case Silent = 1
}

/** Output priority options */
enum LogPriority: Int {
    /** Printed only in the "Verbose" setting */
    case Low = 4
    /** Printed in "Nomal" and "Verbose" setting */
    case Medium = 3
    /** Printed in all settings except "Silent" */
    case High = 2
}

/** Available message types */
enum LogType {
    /** Used for error messages */
    case Error
    /** Used for warning messages*/
    case Warning
    /** Used for information messages*/
    case Info
}

/**
* Logs a message of given type and priority.
* All messages are prefixed with "Reto", the type and the date of the message.
*
* @param type The type of the message.
* @param priority The priority of the message.
* @param message The message to print.
*/
func log(type: LogType, priority: LogPriority, message: String) {
    if priority.rawValue > verbositySetting.rawValue { return }
    
    switch type {
        case .Info: print("Reto[Info] \(NSDate()): \(message)")
        case .Warning: print("Reto[Warn] \(NSDate()): \(message)")
        case .Error: print("Reto[Error] \(NSDate()): \(message)")
    }
}

/** Convenice method, prints a information message with a given priority. */
func log(priority: LogPriority, info: String) {
    log(.Info, priority: priority, message: info)
}
/** Convenice method, prints a warning message with a given priority. */
func log(priority: LogPriority, warning: String) {
    log(.Warning, priority: priority, message: warning)
}
/** Convenice method, prints a error message with a given priority. */
func log(priority: LogPriority, error: String) {
    log(.Error, priority: priority, message: error)
}
