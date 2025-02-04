import AppKit

let appiconsetPath = "/Users/aaronrenecarvajal/Desktop/Geodesic Dome Designer/Geodesic Dome Designer/Assets.xcassets/AppIcon.appiconset"

// Load your original icon
guard let sourceImage = NSImage(contentsOfFile: "\(appiconsetPath)/AppIcon-1024.png"),
      let sourceTiff = sourceImage.tiffRepresentation,
      let sourceBitmap = NSBitmapImageRep(data: sourceTiff) else {
    print("Error: Could not load AppIcon-1024.png")
    exit(1)
}

func resizeImage(_ bitmap: NSBitmapImageRep, toSize size: Int) -> NSBitmapImageRep? {
    let newBitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: bitmap.bitsPerSample,
        samplesPerPixel: bitmap.samplesPerPixel,
        hasAlpha: bitmap.hasAlpha,
        isPlanar: false,
        colorSpaceName: bitmap.colorSpaceName,
        bytesPerRow: 0,
        bitsPerPixel: bitmap.bitsPerPixel
    )
    
    newBitmap?.size = NSSize(width: size, height: size)
    
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: newBitmap!)
    NSGraphicsContext.current?.imageInterpolation = .high
    
    bitmap.draw(in: NSRect(x: 0, y: 0, width: size, height: size))
    
    NSGraphicsContext.restoreGraphicsState()
    
    return newBitmap
}

let iconSpecs = [
    (16, "AppIcon-16"),
    (32, "AppIcon-32"),
    (64, "AppIcon-64"),
    (128, "AppIcon-128"),
    (256, "AppIcon-256"),
    (512, "AppIcon-512"),
    (1024, "AppIcon-1024")
]

for (size, name) in iconSpecs {
    guard let resizedBitmap = resizeImage(sourceBitmap, toSize: size),
          let pngData = resizedBitmap.representation(using: .png, properties: [:]) else {
        print("Failed to create size: \(size)")
        continue
    }
    
    let filename = "\(name).png"
    let fileURL = URL(fileURLWithPath: appiconsetPath).appendingPathComponent(filename)
    
    do {
        try pngData.write(to: fileURL)
        print("Generated: \(filename) (\(size)x\(size))")
    } catch {
        print("Error saving \(filename): \(error)")
    }
}

print("Done! All icons generated in: \(appiconsetPath)")