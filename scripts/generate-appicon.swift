#!/usr/bin/env swift
//
//  generate-appicon.swift
//  MXRouteManager
//
//  Renders the app icon with CoreGraphics and writes every mac-idiom PNG plus
//  the matching Contents.json into Assets.xcassets/AppIcon.appiconset.
//
//  Run from the repo root:   swift scripts/generate-appicon.swift
//  Optional argument: an alternative output directory (used for eyeballing a
//  design change without touching the asset catalog).
//
//  There is no SVG rasterizer on macOS by default, so the icon is drawn in
//  code. That also makes it reproducible: the PNGs in git are a build product
//  of this file.
//

import AppKit
import CoreGraphics
import Foundation

// MARK: - Drawing

/// Renders the icon at `size` × `size` pixels.
///
/// Below 128px the forwarding arrow is dropped and the envelope is drawn
/// larger with a heavier stroke: at 16 and 32 pixels a second element and a
/// hairline stroke both dissolve into noise. Simplifying the small sizes is
/// the macOS convention, not a shortcut.
func drawIcon(size: Int) -> CGImage? {
    let s = CGFloat(size)
    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    guard let ctx = CGContext(
        data: nil, width: size, height: size,
        bitsPerComponent: 8, bytesPerRow: 0, space: space,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { return nil }
    ctx.setAllowsAntialiasing(true)

    // macOS icon grid: the rounded body occupies 824 of a 1024 canvas.
    let margin = s * (100.0 / 1024.0)
    let body = CGRect(x: margin, y: margin, width: s - margin * 2, height: s - margin * 2)
    let radius = body.width * 0.2250

    ctx.saveGState()
    ctx.addPath(CGPath(roundedRect: body, cornerWidth: radius, cornerHeight: radius, transform: nil))
    ctx.clip()
    let gradient = CGGradient(colorsSpace: space, colors: [
        CGColor(srgbRed: 0.263, green: 0.541, blue: 0.988, alpha: 1),
        CGColor(srgbRed: 0.357, green: 0.243, blue: 0.855, alpha: 1)
    ] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(
        gradient,
        start: CGPoint(x: body.minX, y: body.maxY),
        end: CGPoint(x: body.maxX, y: body.minY),
        options: []
    )
    ctx.restoreGState()

    let detailed = size >= 128
    ctx.setStrokeColor(CGColor(gray: 1, alpha: 1))
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)

    // Envelope: sits above centre when the arrow is present, centred otherwise.
    let width = body.width * (detailed ? 0.50 : 0.56)
    let height = width * 0.68
    let centerY = body.midY + (detailed ? body.height * 0.07 : 0)
    let envelope = CGRect(x: body.midX - width / 2, y: centerY - height / 2, width: width, height: height)
    let lineWidth = max(1.0, s * (detailed ? 0.021 : 0.028))
    ctx.setLineWidth(lineWidth)
    ctx.addPath(CGPath(
        roundedRect: envelope,
        cornerWidth: envelope.height * 0.16,
        cornerHeight: envelope.height * 0.16,
        transform: nil
    ))
    ctx.strokePath()
    ctx.move(to: CGPoint(x: envelope.minX + envelope.width * 0.10, y: envelope.maxY - envelope.height * 0.15))
    ctx.addLine(to: CGPoint(x: envelope.midX, y: envelope.midY - envelope.height * 0.10))
    ctx.addLine(to: CGPoint(x: envelope.maxX - envelope.width * 0.10, y: envelope.maxY - envelope.height * 0.15))
    ctx.strokePath()

    // Forwarding arrow beneath the envelope — echoes the popover's
    // arrow.turn.down.right and says "forwarder", not just "mail".
    if detailed {
        let arrowWidth = body.width * 0.34
        let x = body.midX - arrowWidth / 2
        let y = envelope.minY - body.height * 0.155
        let head = arrowWidth * 0.20
        ctx.setLineWidth(lineWidth * 1.05)
        ctx.move(to: CGPoint(x: x, y: y + head * 0.85))
        ctx.addLine(to: CGPoint(x: x, y: y))
        ctx.addLine(to: CGPoint(x: x + arrowWidth, y: y))
        ctx.strokePath()
        ctx.move(to: CGPoint(x: x + arrowWidth - head, y: y + head))
        ctx.addLine(to: CGPoint(x: x + arrowWidth, y: y))
        ctx.addLine(to: CGPoint(x: x + arrowWidth - head, y: y - head))
        ctx.strokePath()
    }

    return ctx.makeImage()
}

// MARK: - Output

struct Entry {
    let point: Int
    let scale: Int
    var pixels: Int { point * scale }
    var filename: String { "icon_\(point)\(scale == 2 ? "@2x" : "").png" }
}

let entries: [Entry] = [
    Entry(point: 16, scale: 1), Entry(point: 16, scale: 2),
    Entry(point: 32, scale: 1), Entry(point: 32, scale: 2),
    Entry(point: 128, scale: 1), Entry(point: 128, scale: 2),
    Entry(point: 256, scale: 1), Entry(point: 256, scale: 2),
    Entry(point: 512, scale: 1), Entry(point: 512, scale: 2)
]

func writePNG(_ image: CGImage, to url: URL) throws {
    let rep = NSBitmapImageRep(cgImage: image)
    rep.size = NSSize(width: image.width, height: image.height)
    guard let data = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "generate-appicon", code: 1,
                      userInfo: [NSLocalizedDescriptionKey: "PNG encoding failed"])
    }
    try data.write(to: url)
}

let defaultOutput = "MXRouteManager/Assets.xcassets/AppIcon.appiconset"
let output = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : defaultOutput)
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

for entry in entries {
    guard let image = drawIcon(size: entry.pixels) else {
        FileHandle.standardError.write(Data("failed to render \(entry.pixels)px\n".utf8))
        exit(1)
    }
    try writePNG(image, to: output.appendingPathComponent(entry.filename))
    print("wrote \(entry.filename) (\(entry.pixels)px)")
}

let images = entries.map { entry -> [String: String] in
    [
        "filename": entry.filename,
        "idiom": "mac",
        "scale": "\(entry.scale)x",
        "size": "\(entry.point)x\(entry.point)"
    ]
}
let contents: [String: Any] = [
    "images": images,
    "info": ["author": "xcode", "version": 1]
]
let json = try JSONSerialization.data(withJSONObject: contents,
                                      options: [.prettyPrinted, .sortedKeys])
try json.write(to: output.appendingPathComponent("Contents.json"))
print("wrote Contents.json (\(entries.count) entries)")
