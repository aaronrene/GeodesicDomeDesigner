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
    @State private var diameter: Double = 20.0
    @State private var frequency: Int = 2
    @State private var selectedColors: Set<ChakraColor> = []
    @State private var showDome: Bool = false
    
    let chakraColors: [ChakraColor] = [
        ChakraColor(name: "Crown (Violet)", color: .purple),
        ChakraColor(name: "Third Eye (Indigo)", color: .indigo),
        ChakraColor(name: "Throat (Blue)", color: .blue),
        ChakraColor(name: "Heart (Green)", color: .green),
        ChakraColor(name: "Solar Plexus (Yellow)", color: .yellow),
        ChakraColor(name: "Sacral (Orange)", color: .orange),
        ChakraColor(name: "Root (Red)", color: .red)
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
                        .frame(height: 300)
                        .background(Color.gray.opacity(0.1))
                    }
                }
                
                Form {
                    Section(header: Text("Dome Parameters")) {
                        VStack(alignment: .leading) {
                            Text("Diameter: \(Int(diameter)) feet")
                            Slider(value: $diameter, in: 10...100, step: 1)
                        }
                        
                        Picker("Frequency", selection: $frequency) {
                            ForEach(2...6, id: \.self) { freq in
                                Text("v\(freq)").tag(freq)
                            }
                        }
                    }
                    
                    Section(header: Text("Chakra Colors")) {
                        ForEach(chakraColors) { chakraColor in
                            Toggle(chakraColor.name, isOn: Binding(
                                get: { selectedColors.contains(chakraColor) },
                                set: { isSelected in
                                    if isSelected {
                                        selectedColors.insert(chakraColor)
                                    } else {
                                        selectedColors.remove(chakraColor)
                                    }
                                }
                            ))
                            .tint(chakraColor.color)
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
        
        // Add lighting
        let light = SCNNode()
        light.light = SCNLight()
        light.light?.type = .omni
        light.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(light)
        
        // Add ambient light
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 100
        scene.rootNode.addChildNode(ambientLight)
        
        return scene
    }
    
    private func createGeodesicDome() -> SCNNode {
        let domeNode = SCNNode()
        let radius = Float(diameter) / 2.0
        let selectedColorsArray = Array(selectedColors)
        var colorIndex = 0
        
        // Create icosahedron vertices with special handling for v2 and v6
        let baseVertices = if frequency == 2 || frequency == 6 {
            [
                // Top vertex
                SCNVector3(0, radius, 0),
                // Upper pentagon vertices
                SCNVector3(radius * cos(0), radius * 0.5, radius * sin(0)),
                SCNVector3(radius * cos(2 * .pi / 5), radius * 0.5, radius * sin(2 * .pi / 5)),
                SCNVector3(radius * cos(4 * .pi / 5), radius * 0.5, radius * sin(4 * .pi / 5)),
                SCNVector3(radius * cos(6 * .pi / 5), radius * 0.5, radius * sin(6 * .pi / 5)),
                SCNVector3(radius * cos(8 * .pi / 5), radius * 0.5, radius * sin(8 * .pi / 5)),
                // Lower pentagon vertices (adjusted height)
                SCNVector3(radius * cos(.pi / 5), -radius * 0.15, radius * sin(.pi / 5)),
                SCNVector3(radius * cos(3 * .pi / 5), -radius * 0.15, radius * sin(3 * .pi / 5)),
                SCNVector3(radius * cos(5 * .pi / 5), -radius * 0.15, radius * sin(5 * .pi / 5)),
                SCNVector3(radius * cos(7 * .pi / 5), -radius * 0.15, radius * sin(7 * .pi / 5)),
                SCNVector3(radius * cos(9 * .pi / 5), -radius * 0.15, radius * sin(9 * .pi / 5)),
                // Bottom center vertex (adjusted height)
                SCNVector3(0, -radius * 0.2, 0)
            ]
        } else {
            [
                // Top vertex
                SCNVector3(0, radius, 0),
                // Upper pentagon vertices
                SCNVector3(radius * cos(0), radius * 0.5, radius * sin(0)),
                SCNVector3(radius * cos(2 * .pi / 5), radius * 0.5, radius * sin(2 * .pi / 5)),
                SCNVector3(radius * cos(4 * .pi / 5), radius * 0.5, radius * sin(4 * .pi / 5)),
                SCNVector3(radius * cos(6 * .pi / 5), radius * 0.5, radius * sin(6 * .pi / 5)),
                SCNVector3(radius * cos(8 * .pi / 5), radius * 0.5, radius * sin(8 * .pi / 5)),
                // Lower pentagon vertices
                SCNVector3(radius * cos(.pi / 5), -radius * 0.2, radius * sin(.pi / 5)),
                SCNVector3(radius * cos(3 * .pi / 5), -radius * 0.2, radius * sin(3 * .pi / 5)),
                SCNVector3(radius * cos(5 * .pi / 5), -radius * 0.2, radius * sin(5 * .pi / 5)),
                SCNVector3(radius * cos(7 * .pi / 5), -radius * 0.2, radius * sin(7 * .pi / 5)),
                SCNVector3(radius * cos(9 * .pi / 5), -radius * 0.2, radius * sin(9 * .pi / 5)),
                // Bottom vertex
                SCNVector3(0, -radius * 0.25, 0)
            ]
        }
        
        // Define faces for a complete dome
        let faces = if frequency == 2 || frequency == 6 {
            [
                // Top pentagon
                [0,1,2], [0,2,3], [0,3,4], [0,4,5], [0,5,1],
                // Middle strip
                [1,6,2], [2,7,3], [3,8,4], [4,9,5], [5,10,1],
                // Bottom pentagon and connections
                [6,7,2], [7,8,3], [8,9,4], [9,10,5], [10,6,1],
                // Additional connections
                [6,2,7], [7,3,8], [8,4,9], [9,5,10], [10,1,6],
                // Base triangles
                [6,7,11], [7,8,11], [8,9,11], [9,10,11], [10,6,11],
                // Extra connections for completeness
                [2,6,7], [3,7,8], [4,8,9], [5,9,10], [1,10,6]
            ]
        } else {
            // Standard faces for other frequencies (similar pattern)
            [
                [0,1,2], [0,2,3], [0,3,4], [0,4,5], [0,5,1],
                [1,6,2], [2,7,3], [3,8,4], [4,9,5], [5,10,1],
                [6,7,2], [7,8,3], [8,9,4], [9,10,5], [10,6,1],
                [6,2,7], [7,3,8], [8,4,9], [9,5,10], [10,1,6],
                [6,7,11], [7,8,11], [8,9,11], [9,10,11], [10,6,11],
                [2,6,7], [3,7,8], [4,8,9], [5,9,10], [1,10,6]
            ]
        }
        
        var processedVertices: [VertexKey: SCNVector3] = [:]
        
        for face in faces {
            let v1 = baseVertices[face[0]]
            let v2 = baseVertices[face[1]]
            let v3 = baseVertices[face[2]]
            
            let centerY = (v1.y + v2.y + v3.y) / 3.0
            if centerY >= -0.2 { // Adjusted threshold
                let subdivided = subdivideTriangle(v1, v2, v3, frequency: frequency, processedVertices: &processedVertices)
                
                for triangle in subdivided {
                    let triangleCenterY = (triangle.0.y + triangle.1.y + triangle.2.y) / 3.0
                    if triangleCenterY >= -0.2 { // Matched threshold
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
        
        // Helper function to get or create a normalized vertex
        func getVertex(_ point: SCNVector3) -> SCNVector3 {
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
        
        // Create triangles with special handling for bottom rows
        for i in 0..<frequency {
            let currentRow = vertices[i]
            let nextRow = vertices[i + 1]
            let isBottomSection = i >= frequency - 2 // Check if we're in bottom two rows
            
            for j in 0..<(currentRow.count - 1) {
                let avgY = Float((currentRow[j].y + currentRow[j + 1].y + nextRow[j].y) / 3.0)
                
                // Special handling for v2 and v6 bottom sections
                if isBottomSection && (frequency == 2 || frequency == 6) && avgY < Float(-0.2) {
                    let avgX = Float((currentRow[j].x + currentRow[j + 1].x + nextRow[j].x) / 3.0)
                    let avgZ = Float((currentRow[j].z + currentRow[j + 1].z + nextRow[j].z) / 3.0)
                    let distanceFromCenter = Float(sqrt(avgX * avgX + avgZ * avgZ))
                    
                    // Skip triangles based on position and pattern
                    if frequency == 2 && (j % 2 == 1) {
                        continue
                    }
                    if frequency == 6 && distanceFromCenter < radius * 0.8 {
                        continue
                    }
                }
                
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
        let length = Float(sqrt(Double(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)))
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
