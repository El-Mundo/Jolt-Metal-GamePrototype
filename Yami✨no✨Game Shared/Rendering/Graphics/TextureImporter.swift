//
//  TextureImporter.swift
//  Yami✨no✨Game macOS
//
//  Created by El-Mundo on 23/08/2024.
//

import MetalKit

class TextureImporter {
    let device: MTLDevice
    let textureLoaderOptions: [MTKTextureLoader.Option : NSNumber]

    init(device: MTLDevice) {
        self.device = device
        textureLoaderOptions = [
            MTKTextureLoader.Option.textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue),
            MTKTextureLoader.Option.textureStorageMode: NSNumber(value: MTLStorageMode.`private`.rawValue)
        ]
    }

    func loadTexture(named textureName: String) -> MeshTexture? {
        let library = GraphicResourceManager.instance.constantTextureLibrary
        if let cachedTexture = library.retrieve(index: library.searchIndex(name: textureName)) {
            return cachedTexture
        }
        
        let textureLoader = MTKTextureLoader(device: device)
        
        if let textureURL = Bundle.main.url(forResource: textureName, withExtension: nil) {
            do {
                let mtlTexture = try textureLoader.newTexture(URL: textureURL, options: textureLoaderOptions)
                let texture = MeshTexture(mtlTexture: mtlTexture)
                library.append(texture, name: textureName)
                return texture
            } catch {
                print("Error loading texture \(textureName): \(error)")
            }
        } else {
            print("Texture \(textureName) not found in bundle.")
        }
        
        return nil
    }
    
    func parseMTLFile(at url: URL, baseName:String?=nil) -> [MeshMaterial] {
        var material: Material? = nil
        var colorMap: MeshTexture?
        var name = ""
        var meshMaterials: [MeshMaterial] = []
        var hasPr = false, hasPa = false
        let nameRoot = baseName == nil ? url.deletingPathExtension().lastPathComponent : baseName!
        
        do {
            let mtlContent = try String(contentsOf: url)
            let lines = mtlContent.components(separatedBy: .newlines)
            
            for line in lines {
                let components = line.split(separator: " ").map(String.init)
                guard components.count > 1 else { continue }
                
                let key = components[0]

                switch key {
                case "newmtl":
                    if components.count > 1 {
                        let materialName = components[1]
                        if(material != nil) {
                            meshMaterials.append(MeshMaterial(material: material!, name: name, texture: colorMap))
                        }
                        hasPr = false; hasPa = false
                        name = nameRoot + ":" + materialName
                        material = MeshMaterial.defaultMaterial
                    }
                case "Kd": // Diffuse color -> used as Albedo
                    if components.count == 4, let r = Float(components[1]), let g = Float(components[2]), let b = Float(components[3]) {
                        material!.albedo = SIMD3(r, g, b)
                    }
                case "Ke": // Emissive color
                    if components.count == 4, let r = Float(components[1]), let g = Float(components[2]), let b = Float(components[3]) {
                        material!.emissive = SIMD3(r, g, b)
                    }
                case "Pm": // Metallic property (non-standard, assuming for this example)
                    if let metallicValue = Float(components[1]) {
                        material!.metallic.value = metallicValue
                    }
                case "Pr": // Roughness property (non-standard, assuming for this example)
                    hasPr = true
                    if let roughnessValue = Float(components[1]) {
                        material!.roughness.value = roughnessValue
                    }
                case "Pa": // Ambient Occlusion (non-standard, assuming for this example)
                    hasPa = true
                    if let aoValue = Float(components[1]) {
                        material!.ambientOcclusion.value = aoValue
                    }
                case "Ks":
                    if(hasPr) {
                        break
                    }
                    if components.count == 4, let specularR = Float(components[1]), let specularG = Float(components[2]), let specularB = Float(components[3]) {
                        let roughnessValue = mapValue((specularR + specularG + specularB) / 3, min1: 0, max1: 1, min2: 0.985, max2: 0.05)
                        material!.roughness.value = roughnessValue
                    }
                case "Ka":
                    if(hasPa) {
                        break
                    }
                    if components.count == 4, let ambientR = Float(components[1]), let ambientG = Float(components[2]), let ambientB = Float(components[3]) {
                        material!.ambientOcclusion.value = (ambientR + ambientG + ambientB) / 3
                    }
                case "map_Kd":
                    if components.count > 1 {
                        let textureName = components[1]
                        if let texture = self.loadTexture(named: textureName) {
                            colorMap = texture
                            material?.hasAlbedoTexture = true
                        }
                    }
                default:
                    continue
                }
            }
            
            if(material != nil) {
                meshMaterials.append(MeshMaterial(material: material!, name: name, texture: colorMap))
            }
            return meshMaterials
        } catch {
            print("Error reading MTL file: \(error)")
            return []
        }
    }
}
