//
//  main.swift
//  WREK Formatter
//
//  Created by David Garcia on 10/20/19.
//  Copyright © 2019 Ayy Lmao LLC. All rights reserved.
//

import Foundation
import AVFoundation


/// This is the code that splits mixes into smaller chunks

let audioLength = 59 //Length in minutes
let manager = FileManager()
let desktopPath = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true)[0]

//let date = Date()
let cal = Calendar.current
let nextWeekend = cal.nextWeekend(startingAfter: Date())!
let dateFormatter = DateFormatter()
dateFormatter.locale = .current
dateFormatter.dateFormat = "MMdd"
let dateString = dateFormatter.string(from: nextWeekend.start)
guard CommandLine.arguments.count == 2,
manager.fileExists(atPath: CommandLine.arguments[1]) else {
    print("file does not exist or incorrect number of args")
    exit(EXIT_FAILURE)
}

let url = URL(fileURLWithPath: CommandLine.arguments[1])
let asset = AVAsset(url: url)
assert(asset.tracks[0].mediaType == .audio)

let fileLength = CMTime(value: asset.duration.value, timescale: asset.duration.timescale)
print( "\(fileLength.seconds/60) minutes" )

var start: CMTime = CMTime(seconds: 0, preferredTimescale: fileLength.timescale)
var duration: CMTime = CMTime(seconds: (fileLength.seconds/60 >= 60) ? Double(audioLength * 60 + 59) : fileLength.seconds, preferredTimescale: fileLength.timescale)
print(start)
print(duration)
let group = DispatchGroup()
var index = 0

repeat {
    index += 1
    let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough)
    duration = (fileLength.value < start.value + duration.value) ?
        CMTime(value: fileLength.value - start.value, timescale: fileLength.timescale) : duration
    exportSession?.outputURL = URL(fileURLWithPath: "EDM\(index)_\(dateString).aiff",
        relativeTo: URL(fileURLWithPath: desktopPath, isDirectory: true))
    exportSession?.outputFileType = .aiff
    exportSession?.timeRange = CMTimeRangeMake(start: start,
                                               duration: duration)
    group.enter()
    exportSession?.exportAsynchronously {
        if exportSession!.error == nil {
            switch exportSession!.status {
            case .completed:
                print(exportSession!.outputURL!.absoluteString)

            default:
                print(exportSession!.status)
            }

        } else {
            print(exportSession!.error.debugDescription)
        }
        group.leave()
    }
    start = start + duration
}while(start < fileLength)

group.wait()
print("Finished exporting!")
