//
//  ContentView.swift
//  Geodesic Dome Designer
//
//  Created by Aaron Rene Carvajal on 1/30/25.
//

import SwiftUI
import SceneKit

#if canImport(UIKit)
import UIKit
typealias PlatformColor = UIColor
#elseif canImport(AppKit)
import AppKit
typealias PlatformColor = NSColor
#endif

struct ContentView: View {
    @State private var diameter: Double = 12.0  // Starting with 12 inches
    @State private var frequency: Int = 2
    @State private var selectedColors: Set<ChakraColor> = []
    @State private var showDome: Bool = false
    @State private var showFloorGuide: Bool = true
    @State private var selectedBackground: BackgroundStyle = .gray
    
    let chakraColors: [ChakraColor] = [
        ChakraColor(name: "Crown (Violet)", color: .purple),
        ChakraColor(name: "Third Eye (Indigo)", color: .indigo),
        ChakraColor(name: "Throat (Blue)", color: .blue),
        ChakraColor(name: "Heart (Green)", color: .green),
        ChakraColor(name: "Solar Plexus (Yellow)", color: .yellow),
        ChakraColor(name: "Sacral (Orange)", color: .orange),
        ChakraColor(name: "Root (Red)", color: .red),
        // Additional colors
        ChakraColor(name: "Sky Blue", color: .init(red: 0.4, green: 0.7, blue: 1.0)),
        ChakraColor(name: "Rose Pink", color: .pink),
        ChakraColor(name: "Emerald", color: .init(red: 0.0, green: 0.8, blue: 0.6)),
        ChakraColor(name: "Gold", color: .init(red: 1.0, green: 0.84, blue: 0.0)),
        ChakraColor(name: "Silver", color: .init(red: 0.75, green: 0.75, blue: 0.75)),
        ChakraColor(name: "Turquoise", color: .init(red: 0.25, green: 0.88, blue: 0.82)),
        ChakraColor(name: "Lavender", color: .init(red: 0.9, green: 0.8, blue: 1.0))
    ]
    
    enum BackgroundStyle: String, CaseIterable {
        case gray = "Gray"
        case white = "White"
        case black = "Black"
        case grid = "Grid"
        case forest = "Forest"
        case countryside = "Countryside"
        case city = "City"
        case space = "Outer Space"
        case beach = "Beach"
        case mountains = "Mountains"
        case sunset = "Sunset"
        case desert = "Desert"
        case underwater = "Underwater"
        case jungle = "Jungle"
        case arctic = "Arctic"
        case volcano = "Volcano"
    }
    
    struct Environment {
        let name: String
        let type: EnvironmentType
        let panorama: String?
        let fogColor: NSColor
        let ambientLight: Float
        
        enum EnvironmentType {
            case skybox
            case panorama
            case generated
        }
    }

    let environments: [Environment] = [
        Environment(
            name: "Forest",
            type: .panorama,
            panorama: "forest_panorama",
            fogColor: .green.withAlphaComponent(0.1),
            ambientLight: 0.8
        ),
        Environment(
            name: "Mountains",
            type: .skybox,
            panorama: "mountains_skybox",
            fogColor: .white.withAlphaComponent(0.2),
            ambientLight: 1.0
        ),
        Environment(
            name: "Beach",
            type: .panorama,
            panorama: "beach_panorama",
            fogColor: .blue.withAlphaComponent(0.1),
            ambientLight: 1.0
        ),
        Environment(
            name: "Space",
            type: .generated,
            panorama: nil,
            fogColor: .clear,
            ambientLight: 0.3
        ),
        Environment(
            name: "City",
            type: .panorama,
            panorama: "city_panorama",
            fogColor: .gray.withAlphaComponent(0.2),
            ambientLight: 0.9
        )
    ]
    
    var body: some View {
        NavigationView {
            VStack {
                if showDome {
                    GeometryReader { geometry in
                        SceneView(
                            scene: createScene(),
                            options: [.allowsCameraControl, .autoenablesDefaultLighting]
                        )
                        .frame(height: 400)  // Increased height
                        .background(Color.gray.opacity(0.1))
                    }
                }
                
                Form {
                    Section(header: Text("Dome Parameters")) {
                        VStack(alignment: .leading) {
                            Text("Diameter: \(Int(diameter)) inches")
                            Slider(value: $diameter, in: 6...24, step: 1)
                        }
                        
                        Picker("Frequency", selection: $frequency) {
                            ForEach(2...6, id: \.self) { freq in
                                Text("v\(freq)").tag(freq)
                            }
                        }
                    }
                    
                    Section(header: Text("Chakra Colors")) {
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 150, maximum: 200), alignment: .leading)
                        ], alignment: .leading, spacing: 8) {
                            ForEach(chakraColors) { chakraColor in
                                Toggle(chakraColor.name, isOn: 
                                    Binding(
                                        get: { selectedColors.contains(chakraColor) },
                                        set: { isSelected in
                                            if isSelected {
                                                selectedColors.insert(chakraColor)
                                            } else {
                                                selectedColors.remove(chakraColor)
                                            }
                                        }
                                    )
                                )
                                .tint(chakraColor.color)
                            }
                        }
                    }
                    
                    Section(header: Text("View Options")) {
                        Toggle("Show Floor Guide", isOn: $showFloorGuide)
                        
                        Picker("Background", selection: $selectedBackground) {
                            ForEach(BackgroundStyle.allCases, id: \.self) { style in
                                Text(style.rawValue).tag(style)
                            }
                        }
                    }
                    
                    Section {
                        HStack {
                            Button(action: {
                                showDome = true
                            }) {
                                Text("Generate Dome")
                                    .frame(maxWidth: .infinity)
                                    .foregroundColor(.white)
                            }
                            .disabled(selectedColors.count < 2)
                            .listRowBackground(selectedColors.count < 2 ? Color.gray : Color.blue)
                            
                            Button(action: {
                                showDome = false
                                selectedColors.removeAll()
                            }) {
                                Text("Reset")
                                    .frame(maxWidth: .infinity)
                                    .foregroundColor(.white)
                            }
                            .listRowBackground(Color.red)
                        }
                    }
                }
            }
            .onAppear {
                // Initialize with two default colors
                selectedColors.insert(chakraColors[0])
                selectedColors.insert(chakraColors[1])
            }
            .navigationTitle("Geodesic Dome Designer")
        }
    }
    
    private func createScene() -> SCNScene {
        let scene = SCNScene()
        
        // Create dome node
        let domeNode = createGeodesicDome()
        scene.rootNode.addChildNode(domeNode)
        
        // Add floor guide if enabled
        if showFloorGuide {
            let floor = SCNFloor()
            floor.reflectivity = 0
            floor.firstMaterial?.diffuse.contents = NSColor.gray.withAlphaComponent(0.3)
            floor.firstMaterial?.isDoubleSided = true
            let floorNode = SCNNode(geometry: floor)
            floorNode.position.y = 0
            scene.rootNode.addChildNode(floorNode)
        }
        
        // Configure background and environment
        switch selectedBackground {
        case .gray, .white, .black:
            scene.background.contents = NSColor(named: selectedBackground.rawValue.lowercased())
        case .grid:
            scene.background.contents = createGridTexture()
        case .space:
            setupSpaceEnvironment(scene)
        case .forest:
            setupForestEnvironment(scene)
        case .mountains:
            setupMountainEnvironment(scene)
        case .beach:
            setupBeachEnvironment(scene)
        case .city:
            setupCityEnvironment(scene)
        default:
            scene.background.contents = createColoredBackground(.gray.withAlphaComponent(0.3))
        }
        
        return scene
    }
    
    private func setupSpaceEnvironment(_ scene: SCNScene) {
        scene.background.contents = NSColor.black
        
        // Add stars
        for _ in 0..<1000 {
            let star = SCNNode(geometry: SCNSphere(radius: 0.1))
            star.geometry?.firstMaterial?.diffuse.contents = NSColor.white
            star.geometry?.firstMaterial?.emission.contents = NSColor.white
            
            let distance: CGFloat = 400
            let theta = CGFloat.random(in: 0...CGFloat.pi * 2)
            let phi = CGFloat.random(in: 0...CGFloat.pi)
            
            star.position = SCNVector3(
                x: distance * sin(phi) * cos(theta),
                y: distance * sin(phi) * sin(theta),
                z: distance * cos(phi)
            )
            
            scene.rootNode.addChildNode(star)
        }
        
        // Add a few nebulae
        addNebula(to: scene, color: .purple.withAlphaComponent(0.3), position: SCNVector3(100, 50, -200))
        addNebula(to: scene, color: .blue.withAlphaComponent(0.2), position: SCNVector3(-150, -30, -180))
    }
    
    private func addNebula(to scene: SCNScene, color: NSColor, position: SCNVector3) {
        let nebula = SCNNode(geometry: SCNSphere(radius: 30))
        nebula.geometry?.firstMaterial?.diffuse.contents = color
        nebula.geometry?.firstMaterial?.emission.contents = color
        nebula.opacity = 0.3
        nebula.position = position
        scene.rootNode.addChildNode(nebula)
    }
    
    private func setupForestEnvironment(_ scene: SCNScene) {
        // Use panorama for background
        if let panorama = NSImage(named: "forest_panorama") {
            scene.background.contents = panorama
        }
        
        // Scale dome to match environment scale
        if let domeNode = scene.rootNode.childNodes.first {
            domeNode.scale = SCNVector3(10, 10, 10)
            domeNode.position = SCNVector3(0, 0, 0)
        }
        
        // Add directional light
        let light = SCNNode()
        light.light = SCNLight()
        light.light?.type = .directional
        light.light?.intensity = 800
        light.position = SCNVector3(50, 50, 50)
        scene.rootNode.addChildNode(light)
        
        // Add ambient light
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 300
        scene.rootNode.addChildNode(ambient)
        
        // Add subtle fog
        addAtmosphericFog(to: scene, color: .green.withAlphaComponent(0.1))
    }
    
    private func createSkyboxFaces(from panorama: NSImage) -> [NSImage] {
        let faceSize = 1024  // Size of each cube face
        
        // Create 6 empty images for each face
        let faces = (0..<6).map { _ in NSImage(size: NSSize(width: faceSize, height: faceSize)) }
        
        // Get panorama dimensions
        let panoramaSize = panorama.size
        let width = Int(panoramaSize.width)
        let height = Int(panoramaSize.height)
        
        // Convert panorama to bitmap
        guard let panoramaBitmap = panorama.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return faces
        }
        
        // Create context for each face
        for (index, face) in faces.enumerated() {
            face.lockFocus()
            let context = NSGraphicsContext.current?.cgContext
            
            // Calculate UV coordinates based on face index
            // 0: right, 1: left, 2: top, 3: bottom, 4: front, 5: back
            for y in 0..<faceSize {
                for x in 0..<faceSize {
                    let (u, v) = cubeToSpherical(
                        x: Double(x) / Double(faceSize),
                        y: Double(y) / Double(faceSize),
                        face: index
                    )
                    
                    // Map spherical coordinates to panorama pixels
                    let px = Int(u * Double(width)) % width
                    let py = Int(v * Double(height)) % height
                    
                    // Sample color from panorama
                    if let pixelData = panoramaBitmap.dataProvider?.data,
                       let data = CFDataGetBytePtr(pixelData) {
                        let offset = (py * width + px) * 4
                        let color = NSColor(
                            red: CGFloat(data[offset]) / 255.0,
                            green: CGFloat(data[offset + 1]) / 255.0,
                            blue: CGFloat(data[offset + 2]) / 255.0,
                            alpha: CGFloat(data[offset + 3]) / 255.0
                        )
                        context?.setFillColor(color.cgColor)
                        context?.fill(CGRect(x: x, y: y, width: 1, height: 1))
                    }
                }
            }
            face.unlockFocus()
        }
        
        return faces
    }
    
    private func cubeToSpherical(x: Double, y: Double, face: Int) -> (u: Double, v: Double) {
        // Convert cube face coordinates to spherical coordinates
        let x = x * 2 - 1
        let y = y * 2 - 1
        var u: Double = 0
        var v: Double = 0
        
        switch face {
        case 0: // Right
            u = atan2(1, -x) / (2 * .pi) + 0.5
            v = asin(-y) / .pi + 0.5
        case 1: // Left
            u = atan2(-1, x) / (2 * .pi) + 0.5
            v = asin(-y) / .pi + 0.5
        case 2: // Top
            u = atan2(y, x) / (2 * .pi) + 0.5
            v = asin(1) / .pi + 0.5
        case 3: // Bottom
            u = atan2(-y, x) / (2 * .pi) + 0.5
            v = asin(-1) / .pi + 0.5
        case 4: // Front
            u = atan2(x, 1) / (2 * .pi) + 0.5
            v = asin(-y) / .pi + 0.5
        case 5: // Back
            u = atan2(x, -1) / (2 * .pi) + 0.5
            v = asin(-y) / .pi + 0.5
        default:
            break
        }
        
        return (u, v)
    }
    
    private func getFogColorForBackground(_ style: BackgroundStyle) -> NSColor {
        switch style {
        case .forest: return .green.withAlphaComponent(0.1)
        case .countryside: return .yellow.withAlphaComponent(0.1)
        case .city: return .gray.withAlphaComponent(0.2)
        case .beach: return .blue.withAlphaComponent(0.1)
        case .mountains: return .white.withAlphaComponent(0.1)
        case .sunset: return .orange.withAlphaComponent(0.2)
        case .desert: return .yellow.withAlphaComponent(0.15)
        case .underwater: return .blue.withAlphaComponent(0.3)
        case .jungle: return .green.withAlphaComponent(0.2)
        case .arctic: return .white.withAlphaComponent(0.2)
        case .volcano: return .red.withAlphaComponent(0.15)
        default: return .clear
        }
    }
    
    private func createGeodesicDome() -> SCNNode {
        let domeNode = SCNNode()
        let radius = Float(diameter) / 2.0
        let selectedColorsArray = Array(selectedColors)
        var colorIndex = 0
        
        // Create icosahedron vertices with special handling for v2 and v6
        let baseVertices = [
            // Top vertex
            SCNVector3(0, radius, 0),
            // Upper pentagon vertices
            SCNVector3(radius * cos(0), radius * 0.5, radius * sin(0)),
            SCNVector3(radius * cos(2 * .pi / 5), radius * 0.5, radius * sin(2 * .pi / 5)),
            SCNVector3(radius * cos(4 * .pi / 5), radius * 0.5, radius * sin(4 * .pi / 5)),
            SCNVector3(radius * cos(6 * .pi / 5), radius * 0.5, radius * sin(6 * .pi / 5)),
            SCNVector3(radius * cos(8 * .pi / 5), radius * 0.5, radius * sin(8 * .pi / 5)),
            // Lower pentagon vertices (at equator)
            SCNVector3(radius * cos(.pi / 5), 0, radius * sin(.pi / 5)),
            SCNVector3(radius * cos(3 * .pi / 5), 0, radius * sin(3 * .pi / 5)),
            SCNVector3(radius * cos(5 * .pi / 5), 0, radius * sin(5 * .pi / 5)),
            SCNVector3(radius * cos(7 * .pi / 5), 0, radius * sin(7 * .pi / 5)),
            SCNVector3(radius * cos(9 * .pi / 5), 0, radius * sin(9 * .pi / 5))
        ]
        
        // Define faces for a complete dome
        let faces = [
            // Top pentagon
            [0,1,2], [0,2,3], [0,3,4], [0,4,5], [0,5,1],
            // Middle strip
            [1,6,2], [2,7,3], [3,8,4], [4,9,5], [5,10,1],
            // Upper connections
            [6,7,2], [7,8,3], [8,9,4], [9,10,5], [10,6,1],
            [2,6,7], [3,7,8], [4,8,9], [5,9,10], [1,10,6]
        ]
        
        var processedVertices: [VertexKey: SCNVector3] = [:]
        
        for face in faces {
            let v1 = baseVertices[face[0]]
            let v2 = baseVertices[face[1]]
            let v3 = baseVertices[face[2]]
            
            let centerY = Float((v1.y + v2.y + v3.y) / 3.0)
            if centerY >= Float(-radius * 0.2) {
                let subdivided = subdivideTriangle(v1, v2, v3, frequency: frequency, processedVertices: &processedVertices)
                
                for triangle in subdivided {
                    let triangleCenterY = Float((triangle.0.y + triangle.1.y + triangle.2.y) / 3.0)
                    if triangleCenterY >= Float(-radius * 0.2) {
                        let currentColor = selectedColorsArray[colorIndex % selectedColorsArray.count]
                        let geometry = createTriangleGeometry(
                            triangle.0,
                            triangle.1,
                            triangle.2,
                            color: currentColor.color
                        )
                        let triangleNode = SCNNode(geometry: geometry)
                        domeNode.addChildNode(triangleNode)
                        colorIndex += 1
                    }
                }
            }
        }
        
        return domeNode
    }
    
    private func subdivideTriangle(_ v1: SCNVector3, _ v2: SCNVector3, _ v3: SCNVector3, frequency: Int, processedVertices: inout [VertexKey: SCNVector3]) -> [(SCNVector3, SCNVector3, SCNVector3)] {
        var triangles: [(SCNVector3, SCNVector3, SCNVector3)] = []
        let radius = Float(diameter) / 2.0
        let bottomY = Float(-radius * 0.2)
        
        // Helper function to get or create a normalized vertex
        func getVertex(_ point: SCNVector3) -> SCNVector3 {
            // Check if this point is on the base perimeter
            if abs(Float(point.y) - bottomY) < 0.001 {
                return point // Don't normalize base perimeter points
            }
            
            let normalized = normalize(point, radius: radius)
            let key = VertexKey(normalized)
            if let existing = processedVertices[key] {
                return existing
            }
            processedVertices[key] = normalized
            return normalized
        }
        
        // Calculate subdivision points
        var vertices: [[SCNVector3]] = Array(repeating: [], count: frequency + 1)
        
        for i in 0...frequency {
            let rowPoints = frequency - i + 1
            for j in 0..<rowPoints {
                let u = Float(j) / Float(frequency)
                let v = Float(i) / Float(frequency)
                let s = 1.0 - u - v
                
                let x = Float(v1.x) * s + Float(v2.x) * u + Float(v3.x) * v
                let y = Float(v1.y) * s + Float(v2.y) * u + Float(v3.y) * v
                let z = Float(v1.z) * s + Float(v2.z) * u + Float(v3.z) * v
                
                let point = SCNVector3(x, y, z)
                vertices[i].append(getVertex(point))
            }
        }
        
        // Create triangles
        for i in 0..<frequency {
            let currentRow = vertices[i]
            let nextRow = vertices[i + 1]
            
            for j in 0..<(currentRow.count - 1) {
                triangles.append((
                    currentRow[j],
                    currentRow[j + 1],
                    nextRow[j]
                ))
                
                if j < nextRow.count - 1 {
                    triangles.append((
                        currentRow[j + 1],
                        nextRow[j + 1],
                        nextRow[j]
                    ))
                }
            }
        }
        
        return triangles
    }
    
    private func createTriangleGeometry(_ v1: SCNVector3, _ v2: SCNVector3, _ v3: SCNVector3, color: Color) -> SCNGeometry {
        let vertices = [v1, v2, v3]
        let source = SCNGeometrySource(vertices: vertices)
        
        let faceIndices: [UInt32] = [0, 1, 2]
        let faceElement = SCNGeometryElement(indices: faceIndices, primitiveType: .triangles)
        
        let geometry = SCNGeometry(sources: [source], elements: [faceElement])
        
        let material = SCNMaterial()
        #if canImport(UIKit)
        material.diffuse.contents = UIColor(color)
        #else
        material.diffuse.contents = NSColor(color)
        #endif
        material.isDoubleSided = true
        geometry.materials = [material]
        
        return geometry
    }
    
    private func normalize(_ vector: SCNVector3, radius: Float) -> SCNVector3 {
        let length = sqrt(Float(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z))
        
        // Project all points onto sphere surface
        return SCNVector3(
            Float(vector.x) / length * radius,
            Float(vector.y) / length * radius,
            Float(vector.z) / length * radius
        )
    }
    
    private func areVerticesEqual(_ v1: SCNVector3, _ v2: SCNVector3) -> Bool {
        let epsilon: Float = 0.0001
        return abs(Float(v1.x) - Float(v2.x)) < epsilon &&
               abs(Float(v1.y) - Float(v2.y)) < epsilon &&
               abs(Float(v1.z) - Float(v2.z)) < epsilon
    }
    
    private func interpolate(_ v1: SCNVector3, _ v2: SCNVector3, _ t: Float) -> SCNVector3 {
        let x = Float(v1.x) + (Float(v2.x) - Float(v1.x)) * t
        let y = Float(v1.y) + (Float(v2.y) - Float(v1.y)) * t
        let z = Float(v1.z) + (Float(v2.z) - Float(v1.z)) * t
        return SCNVector3(x, y, z)
    }
    
    private func createGridTexture() -> NSImage {
        let size = NSSize(width: 512, height: 512)
        let image = NSImage(size: size)
        
        image.lockFocus()
        NSColor.black.setFill()
        NSRect(origin: .zero, size: size).fill()
        
        NSColor.gray.setStroke()
        let path = NSBezierPath()
        let gridSize: CGFloat = 32
        
        for i in 0...Int(size.width/gridSize) {
            let x = CGFloat(i) * gridSize
            path.move(to: NSPoint(x: x, y: 0))
            path.line(to: NSPoint(x: x, y: size.height))
        }
        
        for i in 0...Int(size.height/gridSize) {
            let y = CGFloat(i) * gridSize
            path.move(to: NSPoint(x: 0, y: y))
            path.line(to: NSPoint(x: size.width, y: y))
        }
        
        path.stroke()
        image.unlockFocus()
        
        return image
    }
    
    private func createHorizonLine() -> SCNNode {
        let radius = Float(diameter) * 2 // Make horizon line wider than dome
        let segments = 64
        let path = NSBezierPath()
        
        for i in 0...segments {
            let angle = (2.0 * .pi * Float(i)) / Float(segments)
            let x = radius * cos(angle)
            let z = radius * sin(angle)
            let point = NSPoint(x: CGFloat(x), y: CGFloat(z))
            
            if i == 0 {
                path.move(to: point)
            } else {
                path.line(to: point)
            }
        }
        
        let shape = SCNShape(path: path, extrusionDepth: 0)
        let material = SCNMaterial()
        material.diffuse.contents = NSColor.gray.withAlphaComponent(0.3)
        shape.materials = [material]
        
        let node = SCNNode(geometry: shape)
        node.eulerAngles.x = .pi / 2 // Rotate to horizontal
        return node
    }
    
    private func addAtmosphericFog(to scene: SCNScene, color: NSColor) {
        scene.fogStartDistance = 0
        scene.fogEndDistance = 100
        scene.fogDensityExponent = 2
        scene.fogColor = color
    }
    
    private func addStarfield(to scene: SCNScene) {
        let starsNode = SCNNode()
        let starsCount = 1000
        
        for _ in 0..<starsCount {
            let starGeometry = SCNSphere(radius: 0.05)
            let starMaterial = SCNMaterial()
            starMaterial.diffuse.contents = NSColor.white
            starGeometry.materials = [starMaterial]
            
            let starNode = SCNNode(geometry: starGeometry)
            let distance = Float(50 + arc4random_uniform(100))
            let theta = Float(arc4random_uniform(360)) * .pi / 180
            let phi = Float(arc4random_uniform(360)) * .pi / 180
            
            starNode.position = SCNVector3(
                distance * sin(theta) * cos(phi),
                distance * sin(theta) * sin(phi),
                distance * cos(theta)
            )
            
            starsNode.addChildNode(starNode)
        }
        
        scene.rootNode.addChildNode(starsNode)
    }
    
    private func createColoredBackground(_ color: NSColor) -> NSImage {
        let size = NSSize(width: 512, height: 512)
        let image = NSImage(size: size)
        
        image.lockFocus()
        color.setFill()
        NSRect(origin: .zero, size: size).fill()
        image.unlockFocus()
        
        return image
    }
    
    private func setupMountainEnvironment(_ scene: SCNScene) {
        scene.background.contents = NSImage(named: "mountains_panorama")
        addAtmosphericFog(to: scene, color: .white.withAlphaComponent(0.2))
        
        // Add distant mountain geometry
        let mountains = SCNNode()
        let mountainGeometry = SCNPyramid(width: 10, height: 15, length: 10)
        mountainGeometry.firstMaterial?.diffuse.contents = NSColor.gray
        
        for i in 0..<8 {
            let mountain = SCNNode(geometry: mountainGeometry)
            let angle = CGFloat(i) * .pi / 4
            mountain.position = SCNVector3(
                x: CGFloat(80) * cos(angle),
                y: -5,
                z: CGFloat(80) * sin(angle)
            )
            mountains.addChildNode(mountain)
        }
        
        scene.rootNode.addChildNode(mountains)
    }

    private func setupBeachEnvironment(_ scene: SCNScene) {
        scene.background.contents = NSImage(named: "beach_panorama")
        
        // Add ocean plane
        let ocean = SCNPlane(width: 1000, height: 1000)
        ocean.firstMaterial?.diffuse.contents = NSColor.blue.withAlphaComponent(0.6)
        ocean.firstMaterial?.isDoubleSided = true
        
        let oceanNode = SCNNode(geometry: ocean)
        oceanNode.eulerAngles.x = -.pi / 2
        oceanNode.position.y = -1
        
        scene.rootNode.addChildNode(oceanNode)
        addAtmosphericFog(to: scene, color: .blue.withAlphaComponent(0.1))
    }

    private func setupCityEnvironment(_ scene: SCNScene) {
        scene.background.contents = NSImage(named: "city_panorama")
        addAtmosphericFog(to: scene, color: .gray.withAlphaComponent(0.2))
        
        // Add distant buildings
        addDistantBuildings(to: scene)
    }

    private func addDistantBuildings(to scene: SCNScene) {
        let buildingCount = 30
        let radius: CGFloat = 100
        
        for _ in 0..<buildingCount {
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 50...radius)
            let height = CGFloat.random(in: 10...30)
            
            let building = SCNBox(width: 5, height: height, length: 5, chamferRadius: 0)
            building.firstMaterial?.diffuse.contents = NSColor.darkGray
            
            let buildingNode = SCNNode(geometry: building)
            buildingNode.position = SCNVector3(
                x: distance * cos(angle),
                y: height/2,
                z: distance * sin(angle)
            )
            
            scene.rootNode.addChildNode(buildingNode)
        }
    }

    private func setupEnvironment(_ scene: SCNScene, _ environment: Environment) {
        switch environment.type {
        case .panorama:
            // Single 360° panorama image
            if let panoramaImage = NSImage(named: environment.panorama ?? "") {
                scene.background.contents = panoramaImage
            }
            
        case .skybox:
            // Six-sided cube map
            scene.background.contents = [
                NSImage(named: "right"),
                NSImage(named: "left"),
                NSImage(named: "top"),
                NSImage(named: "bottom"),
                NSImage(named: "front"),
                NSImage(named: "back")
            ]
            
        case .generated:
            // Programmatically generated environment
            if environment.name == "Space" {
                setupSpaceEnvironment(scene)
            }
        }
        
        addAtmosphericFog(to: scene, color: environment.fogColor)
    }

    // Create a basic panorama programmatically
    private func createBasicPanorama(_ name: String, baseColor: NSColor) -> NSImage {
        let width = 4096
        let height = 2048
        let image = NSImage(size: NSSize(width: width, height: height))
        
        image.lockFocus()
        
        // Create gradient background
        let gradient = NSGradient(colors: [
            baseColor,
            baseColor.withAlphaComponent(0.7),
            .white.withAlphaComponent(0.3)
        ])
        
        gradient?.draw(in: NSRect(x: 0, y: 0, width: width, height: height),
                      angle: -90)
        
        image.unlockFocus()
        return image
    }
}

extension SCNGeometry {
    static func triangleGeometry(_ v1: SCNVector3, _ v2: SCNVector3, _ v3: SCNVector3, radius: Float, color: PlatformColor) -> SCNGeometry {
        let vertices = [v1, v2, v3]
        
        let source = SCNGeometrySource(vertices: vertices)
        let indices: [UInt32] = [0, 1, 2]
        let element = SCNGeometryElement(indices: indices, primitiveType: .triangles)
        
        let geometry = SCNGeometry(sources: [source], elements: [element])
        let material = SCNMaterial()
        material.diffuse.contents = color
        geometry.materials = [material]
        
        return geometry
    }
}

struct ChakraColor: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let color: Color
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(color)
    }
    
    static func == (lhs: ChakraColor, rhs: ChakraColor) -> Bool {
        lhs.id == rhs.id
    }
}

struct VertexKey: Hashable {
    let x: Float
    let y: Float
    let z: Float
    
    init(_ vector: SCNVector3) {
        // Round to reduce floating point precision issues
        let precision: Float = 1000.0
        self.x = round(Float(vector.x) * precision) / precision
        self.y = round(Float(vector.y) * precision) / precision
        self.z = round(Float(vector.z) * precision) / precision
    }
}

#Preview {
    ContentView()
}
