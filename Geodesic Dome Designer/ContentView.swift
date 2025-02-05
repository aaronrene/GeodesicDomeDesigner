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
    @State private var showIconGenerator = false
    @State private var showIconSourcePicker = false
    @State private var alertMessage: String?
    @State private var showAlert = false
    @State private var showIconAlert = false
    @State private var iconAlertMessage: String?
    @State private var selectedEnvironment: Environment?  // Changed to optional
    
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
    
    struct Environment: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let type: EnvironmentType
        let panorama: String?
        let fogColor: Color?
    }

    enum EnvironmentType {
        case hdr
        case panorama
        case generated
        case skybox
        case basic
    }

    static let environments: [Environment] = [
        // Basic colored backgrounds with horizon
        Environment(name: "Light Studio", type: .basic, panorama: nil, fogColor: .white.opacity(0.1)),
        Environment(name: "Dark Studio", type: .basic, panorama: nil, fogColor: Color(red: 0.1, green: 0.1, blue: 0.1).opacity(0.8)),
        Environment(name: "Blue Studio", type: .basic, panorama: nil, fogColor: Color(red: 0.4, green: 0.6, blue: 1.0).opacity(0.2)),
        Environment(name: "Purple Studio", type: .basic, panorama: nil, fogColor: Color(red: 0.5, green: 0.3, blue: 0.8).opacity(0.2)),
        Environment(name: "Gold Studio", type: .basic, panorama: nil, fogColor: Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.2)),
        
        // HDR Environments
        Environment(name: "Forest Cave", type: .hdr, panorama: "forest_cave_4k", fogColor: nil),
        Environment(name: "Autumn Forest", type: .hdr, panorama: "autumn_forest_01_4k", fogColor: nil),
        
        // Special Environments
        Environment(name: "Space", type: .generated, panorama: nil, fogColor: .black.opacity(0.8)),
        Environment(name: "Night Sky", type: .generated, panorama: nil, fogColor: Color(red: 0.1, green: 0.1, blue: 0.3).opacity(0.8)),
        Environment(name: "Grid", type: .generated, panorama: "grid", fogColor: nil),
        Environment(name: "Neon Grid", type: .generated, panorama: nil, fogColor: Color(red: 0, green: 0.2, blue: 0.3).opacity(0.9))
    ]
    
    var body: some View {
        VStack {
            Form {
                Section(header: Text("Dome Properties")) {
                    Slider(value: $diameter, in: 6...24, step: 1) {
                        Text("Diameter: \(Int(diameter)) feet")
                    }
                    Stepper("Frequency: \(frequency)", value: $frequency, in: 2...6)
                }
                
                Section(header: Text("Environment")) {
                    Picker("Environment", selection: $selectedEnvironment) {
                        Group {
                            Text("None").tag(Optional<Environment>.none)
                            
                            Section("Studio Backgrounds") {
                                ForEach(Self.environments.filter { $0.type == .basic }) { environment in
                                    Text(environment.name).tag(Optional(environment))
                                }
                            }
                            
                            Section("HDR Environments") {
                                ForEach(Self.environments.filter { $0.type == .hdr }) { environment in
                                    Text(environment.name).tag(Optional(environment))
                                }
                            }
                            
                            Section("Special") {
                                ForEach(Self.environments.filter { $0.type == .generated }) { environment in
                                    Text(environment.name).tag(Optional(environment))
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("Colors")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(chakraColors) { chakraColor in
                                ColorToggleButton(
                                    color: chakraColor,
                                    isSelected: selectedColors.contains(chakraColor),
                                    action: { toggleColor(chakraColor) }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            
            if showDome {
                GeometryReader { geometry in
                    SceneView(
                        scene: {
                            let scene = createScene()
                            setupEnvironment(scene, selectedEnvironment)
                            return scene
                        }(),
                        pointOfView: {
                            let cameraNode = SCNNode()
                            let camera = SCNCamera()
                            camera.fieldOfView = 60
                            camera.zNear = 0.1
                            camera.zFar = 1000
                            cameraNode.camera = camera
                            
                            // Position camera to better frame the dome
                            let distance = Float(diameter) * 3.0
                            cameraNode.position = SCNVector3(distance, distance/2, distance)
                            cameraNode.look(at: SCNVector3(0, 0, 0))
                            
                            return cameraNode
                        }(),
                        options: [
                            .allowsCameraControl,
                            .autoenablesDefaultLighting
                        ]
                    )
                }
                .frame(minHeight: 300, maxHeight: .infinity)
                .background(Color.black.opacity(0.1))
            }
            
            ScrollView {
                Form {
                    Section(header: Text("View Options")) {
                        Toggle("Show Floor Guide", isOn: $showFloorGuide)
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
                .frame(maxWidth: 600)  // Limit form width for better readability
                .padding()
            }
        }
        .navigationTitle("Geodesic Dome Designer")
        .frame(minWidth: 600, maxWidth: .infinity, minHeight: 600)
        .onAppear {
            if selectedEnvironment == nil {
                selectedEnvironment = Self.environments[0]
            }
            // Initialize with two default colors
            selectedColors.insert(chakraColors[0])
            selectedColors.insert(chakraColors[1])
        }
    }
    
    private func createScene() -> SCNScene {
        let scene = SCNScene()
        
        // Create dome node with adjusted position
        let domeNode = createGeodesicDome()
        domeNode.position = SCNVector3(0, 0, 0)  // Center the dome
        scene.rootNode.addChildNode(domeNode)
        
        // Add camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        
        // Position camera to see entire dome
        let distance = Float(diameter) * 2.0
        cameraNode.position = SCNVector3(distance, distance/2, distance)
        cameraNode.look(at: SCNVector3(0, 0, 0))
        
        scene.rootNode.addChildNode(cameraNode)
        
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
        // Set the panorama background
        scene.background.contents = NSImage(named: "forest_panorama")
        
        // Add forest floor at the exact dome base level
        let ground = SCNPlane(width: 1000, height: 1000)
        ground.firstMaterial?.diffuse.contents = NSColor(red: 0.2, green: 0.3, blue: 0.1, alpha: 1.0)
        ground.firstMaterial?.isDoubleSided = true
        
        let groundNode = SCNNode(geometry: ground)
        groundNode.eulerAngles.x = -.pi / 2
        
        // Position exactly at the dome's base (y = 0)
        groundNode.position = SCNVector3(0, 0, 0)
        
        // Add the ground first, then the dome will be added on top
        scene.rootNode.addChildNode(groundNode)
        
        // Add atmospheric fog
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

    private func setupEnvironment(_ scene: SCNScene, _ environment: Environment?) {
        if let environment = environment {
            switch environment.type {
            case .basic:
                if let fogColor = environment.fogColor {
                    // Set background color
                    scene.background.contents = NSColor(fogColor)
                    
                    // Add fog
                    addAtmosphericFog(to: scene, color: NSColor(fogColor))
                    
                    // Add horizon line if showFloorGuide is true
                    if showFloorGuide {
                        let horizonLine = createHorizonLine()
                        scene.rootNode.addChildNode(horizonLine)
                    }
                    
                    // Add floor
                    let floor = SCNFloor()
                    let floorMaterial = SCNMaterial()
                    floorMaterial.diffuse.contents = NSColor.black.withAlphaComponent(0.5)
                    floorMaterial.roughness.contents = 1.0
                    floor.materials = [floorMaterial]
                    
                    let floorNode = SCNNode(geometry: floor)
                    floorNode.position = SCNVector3(0, -0.01, 0)
                    scene.rootNode.addChildNode(floorNode)
                }
            case .hdr:
                setupHDREnvironment(scene)
            case .generated:
                switch environment.name {
                case "Space":
                    scene.background.contents = NSColor.black
                    addAtmosphericFog(to: scene, color: NSColor(red: 0, green: 0, blue: 0, alpha: 0.8))
                    addStarfield(to: scene)
                    addNebula(to: scene, color: .purple.withAlphaComponent(0.3), position: SCNVector3(100, 50, -200))
                    addNebula(to: scene, color: .blue.withAlphaComponent(0.2), position: SCNVector3(-150, -30, -180))
                case "Night Sky":
                    scene.background.contents = NSColor(red: 0.1, green: 0.1, blue: 0.3, alpha: 1.0)
                    addAtmosphericFog(to: scene, color: NSColor(red: 0.1, green: 0.1, blue: 0.3, alpha: 0.8))
                    addStarfield(to: scene)
                case "Grid":
                    scene.background.contents = NSColor.black
                    addAtmosphericFog(to: scene, color: NSColor(red: 0, green: 0, blue: 0, alpha: 0.8))
                    
                    // Create a grid pattern programmatically
                    let gridSize = NSSize(width: 512, height: 512)
                    let gridImage = NSImage(size: gridSize)
                    
                    gridImage.lockFocus()
                    let rect = NSRect(origin: .zero, size: gridSize)
                    NSColor.black.setFill()
                    rect.fill()
                    
                    NSColor.white.withAlphaComponent(0.3).setStroke()
                    let path = NSBezierPath()
                    let spacing: CGFloat = 50
                    
                    // Draw vertical lines
                    for x in stride(from: 0, through: gridSize.width, by: spacing) {
                        path.move(to: NSPoint(x: x, y: 0))
                        path.line(to: NSPoint(x: x, y: gridSize.height))
                    }
                    
                    // Draw horizontal lines
                    for y in stride(from: 0, through: gridSize.height, by: spacing) {
                        path.move(to: NSPoint(x: 0, y: y))
                        path.line(to: NSPoint(x: gridSize.width, y: y))
                    }
                    
                    path.lineWidth = 1
                    path.stroke()
                    gridImage.unlockFocus()
                    
                    // Add floor with grid material
                    let floor = SCNFloor()
                    let floorMaterial = SCNMaterial()
                    floorMaterial.diffuse.contents = gridImage
                    floorMaterial.diffuse.contentsTransform = SCNMatrix4MakeScale(100, 100, 1)
                    floorMaterial.emission.contents = NSColor.white.withAlphaComponent(0.1)
                    floor.materials = [floorMaterial]
                    
                    let floorNode = SCNNode(geometry: floor)
                    floorNode.position = SCNVector3(0, -0.01, 0)
                    scene.rootNode.addChildNode(floorNode)
                case "Neon Grid":
                    scene.background.contents = NSColor.black
                    addAtmosphericFog(to: scene, color: NSColor(red: 0, green: 0.2, blue: 0.3, alpha: 0.9))
                    
                    // Add neon grid floor
                    let floor = SCNFloor()
                    let floorMaterial = SCNMaterial()
                    floorMaterial.emission.contents = NSColor(red: 0, green: 0.8, blue: 0.8, alpha: 0.5)
                    floorMaterial.emission.intensity = 0.8
                    floor.materials = [floorMaterial]
                    
                    let floorNode = SCNNode(geometry: floor)
                    floorNode.position = SCNVector3(0, -0.01, 0)
                    scene.rootNode.addChildNode(floorNode)
                    
                    // Add some neon lines in the distance
                    for i in 0...10 {
                        let line = SCNBox(width: 0.1, height: 20, length: 0.1, chamferRadius: 0)
                        let lineMaterial = SCNMaterial()
                        lineMaterial.emission.contents = NSColor(red: 1, green: 0, blue: 0.5, alpha: 0.8)
                        lineMaterial.emission.intensity = 0.8
                        line.materials = [lineMaterial]
                        
                        let lineNode = SCNNode(geometry: line)
                        lineNode.position = SCNVector3(Float(i * 10) - 50, 10, -50)
                        scene.rootNode.addChildNode(lineNode)
                    }
                default:
                    break
                }
            default:
                break
            }
        }
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

    private func setupHDREnvironment(_ scene: SCNScene) {
        guard let environment = selectedEnvironment,
              let environmentMap = NSImage(named: environment.panorama ?? "") else {
            print("Failed to load HDR environment map")
            return
        }
        
        // Set the environment map for lighting
        scene.lightingEnvironment.contents = environmentMap
        scene.lightingEnvironment.intensity = 2.0
        
        // Set the background with adjusted properties
        scene.background.contents = environmentMap
        scene.background.intensity = 1.0
        
        // Add a proper floor with material settings
        if showFloorGuide {
            let floor = SCNFloor()
            let floorMaterial = SCNMaterial()
            floorMaterial.diffuse.contents = NSColor.black.withAlphaComponent(0.5)
            floorMaterial.roughness.contents = 1.0
            floorMaterial.metalness.contents = 0.0
            floor.materials = [floorMaterial]
            
            let floorNode = SCNNode(geometry: floor)
            floorNode.position = SCNVector3(0, -0.01, 0)  // Slightly below the dome base
            scene.rootNode.addChildNode(floorNode)
        }
        
        // Add lighting
        let directionalLight = SCNNode()
        directionalLight.light = SCNLight()
        directionalLight.light?.type = .directional
        directionalLight.light?.intensity = 800
        directionalLight.light?.castsShadow = true
        directionalLight.position = SCNVector3(x: 0, y: 50, z: 50)
        directionalLight.eulerAngles = SCNVector3(x: -.pi/3, y: .pi/4, z: 0)
        scene.rootNode.addChildNode(directionalLight)
        
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 400
        scene.rootNode.addChildNode(ambientLight)
    }

    private func toggleColor(_ color: ChakraColor) {
        if selectedColors.contains(color) {
            selectedColors.remove(color)
        } else {
            selectedColors.insert(color)
        }
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

struct ColorToggleButton: View {
    let color: ChakraColor
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Circle()
                    .fill(color.color)
                    .frame(width: 30, height: 30)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: isSelected ? 3 : 0)
                    )
                Text(color.name)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ContentView()
}
