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
                        .onAppear {
                            let scene = createScene()
                            let cameraNode = SCNNode()
                            cameraNode.camera = SCNCamera()
                            cameraNode.position = SCNVector3(x: CGFloat(diameter), y: CGFloat(diameter), z: CGFloat(diameter))
                            cameraNode.look(at: SCNVector3(x: 0, y: 0, z: 0))
                            scene.rootNode.addChildNode(cameraNode)
                        }
                    }
                    .frame(height: 300)
                    .background(Color.gray.opacity(0.1))
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
        
        // Create icosahedron vertices using golden ratio
        let t = Float((1.0 + sqrt(5.0)) / 2.0)
        let baseVertices = [
            SCNVector3( t,  1,  0), SCNVector3(-t,  1,  0),
            SCNVector3( t, -1,  0), SCNVector3(-t, -1,  0),
            SCNVector3( 1,  0,  t), SCNVector3( 1,  0, -t),
            SCNVector3(-1,  0,  t), SCNVector3(-1,  0, -t),
            SCNVector3( 0,  t,  1), SCNVector3( 0,  t, -1),
            SCNVector3( 0, -t,  1), SCNVector3( 0, -t, -1)
        ].map { normalize($0, radius: radius) }
        
        // Define icosahedron faces
        let faces = [
            [0,8,4], [0,5,9], [2,4,10], [2,11,5], [1,6,8],
            [1,9,7], [3,10,6], [3,7,11], [0,4,5], [2,5,4],
            [1,8,9], [3,9,8], [0,9,8], [1,8,6], [2,10,11],
            [3,11,10], [4,8,6], [4,6,10], [5,11,7], [5,7,9]
        ]
        
        var processedVertices: [VertexKey: SCNVector3] = [:]
        
        for face in faces {
            let v1 = baseVertices[face[0]]
            let v2 = baseVertices[face[1]]
            let v3 = baseVertices[face[2]]
            
            // Only process faces for the dome
            if v1.y >= 0 || v2.y >= 0 || v3.y >= 0 {
                let subdivided = subdivideTriangle(v1, v2, v3, frequency: frequency, processedVertices: &processedVertices)
                
                for triangle in subdivided {
                    if triangle.0.y >= 0 && triangle.1.y >= 0 && triangle.2.y >= 0 {
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
        
        // Calculate subdivision points for Class I pattern
        var vertices: [[SCNVector3]] = Array(repeating: [], count: frequency + 1)
        
        // Generate vertices for each row following Class I pattern
        for i in 0...frequency {
            let rowPoints = frequency - i + 1
            for j in 0..<rowPoints {
                let u = Float(j) / Float(frequency)
                let v = Float(i) / Float(frequency)
                let s = 1.0 - u - v
                
                // Break down point calculation into components
                let x = Float(v1.x) * s + Float(v2.x) * u + Float(v3.x) * v
                let y = Float(v1.y) * s + Float(v2.y) * u + Float(v3.y) * v
                let z = Float(v1.z) * s + Float(v2.z) * u + Float(v3.z) * v
                
                let point = SCNVector3(x, y, z)
                vertices[i].append(getVertex(point))
            }
        }
        
        // Create triangles following Class I pattern
        for i in 0..<frequency {
            let currentRow = vertices[i]
            let nextRow = vertices[i + 1]
            
            for j in 0..<(currentRow.count - 1) {
                // Create "A" triangle
                triangles.append((
                    currentRow[j],
                    currentRow[j + 1],
                    nextRow[j]
                ))
                
                // Create "B" triangle if not at edge
                if j < nextRow.count - 1 {
                    triangles.append((
                        currentRow[j + 1],
                        nextRow[j + 1],
                        nextRow[j]
                    ))
                }
            }
        }
        
        return triangles.filter { triangle in
            triangle.0.y >= 0 || triangle.1.y >= 0 || triangle.2.y >= 0
        }
    }
    
    private func createTriangleGeometry(_ v1: SCNVector3, _ v2: SCNVector3, _ v3: SCNVector3, color: Color) -> SCNGeometry {
        let vertices = [v1, v2, v3]
        let source = SCNGeometrySource(vertices: vertices)
        
        // Create face geometry
        let faceIndices: [UInt32] = [0, 1, 2]
        let faceElement = SCNGeometryElement(indices: faceIndices, primitiveType: .triangles)
        
        // Create edge geometry
        let edgeIndices: [UInt32] = [0, 1, 1, 2, 2, 0]
        let edgeElement = SCNGeometryElement(indices: edgeIndices, primitiveType: .line)
        
        let geometry = SCNGeometry(sources: [source], elements: [faceElement, edgeElement])
        
        // Create face material
        let faceMaterial = SCNMaterial()
        faceMaterial.diffuse.contents = PlatformColor(color)
        faceMaterial.isDoubleSided = true
        
        // Create edge material
        let edgeMaterial = SCNMaterial()
        edgeMaterial.diffuse.contents = PlatformColor.black
        
        geometry.materials = [faceMaterial, edgeMaterial]
        
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
        let epsilon: Float = 0.0001  // Tolerance for floating point comparison
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
        let vertices = [v1, v2, v3].map { normalize($0, radius: radius) }
        
        let source = SCNGeometrySource(vertices: vertices)
        let indices: [UInt32] = [0, 1, 2]
        let element = SCNGeometryElement(indices: indices, primitiveType: .triangles)
        
        let geometry = SCNGeometry(sources: [source], elements: [element])
        let material = SCNMaterial()
        material.diffuse.contents = color
        geometry.materials = [material]
        
        return geometry
    }
    
    private static func normalize(_ vector: SCNVector3, radius: Float) -> SCNVector3 {
        let length = Float(sqrt(Double(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)))
        return SCNVector3(
            Float(vector.x) / length * radius,
            Float(vector.y) / length * radius,
            Float(vector.z) / length * radius
        )
    }
}

struct ChakraColor: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let color: Color
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
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
