//
//  GraphicResourceManager.swift
//  Yami✨no✨Game macOS
//
//  Created by El-Mundo on 15/08/2024.
//

import Foundation

/// Used for searching mesh resource in CPP code and collision shape calculation
public func getConstantMeshIndexFromCPP(name: String) -> Int {
    return GraphicResourceManager.instance.constantMeshLibrary.searchIndex(name: name)
}

/// A class for managing all reusable resources. Accessed as static variable GraphicResourceManager.instance.
class GraphicResourceManager {
    public static let instance = GraphicResourceManager()
    
    /// Constant mesh resources, stored through game runtime on GPU accessible storage (ie, silicon devices' shared storage).
    let constantMeshLibrary = ResourceLibrary<Mesh>()
    /// Constant metrial resources, stored through game runtime on GPU accessible storage.
    let constantMaterialLibrary = ResourceLibrary<MeshMaterial>()
    /// Constant texture resources, stored through game runtime on GPU accessible storage.
    let constantTextureLibrary = ResourceLibrary<MeshTexture>()
    
    /// Scene-specific mesh resources, should be released after scene become unloaded
    let sceneMeshLibrary = ResourceLibrary<Mesh>()
    /// Scene-specific material resources, should be released after scene become unloaded
    let sceneMaterialLibrary = ResourceLibrary<MeshMaterial>()
    /// Scene-specific texture resources, should be released after scene become unloaded
    let sceneTextureLibrary = ResourceLibrary<MeshTexture>()
}

/// Manages mesh and material resources. One ResourceLibrary can be bound to game runtime or a specific scene
///
/// Libraries store resources that should be cached on GPU storage within a specific scope (game time, scene, or bound to a game object).
/// They are typically used for making resources indexable and reusing resources that appear repeatedly.
class ResourceLibrary<T> {
    private var nameIndexer: [String : Int] = [:]
    private var library: [T] = []
    
    /// Taking the name of a resource instance and returning its index in current library. Will return defaultValue parameter if non-existent.
    func searchIndex(name: String, defaultValue: Int=(-1)) -> Int {
        if let index = nameIndexer[name] {
            return index
        } else {
            return defaultValue
        }
    }
    
    /// Add a newly loaded resource instance to the libray. Will replace an existing resource instance if its name is duplicated.
    func append(_ object: T, name: String) {
        if let duplicate = nameIndexer[name] {
            print("Warning: trying to overwrite an existing entry in resource library")
            // Remove objects with duplicate names to keep all objects in the library indexable
            library[duplicate] = object
        } else {
            nameIndexer.updateValue(library.count, forKey: name)
            library.append(object)
        }
    }
    
    func retrieve(index: Int) -> T? {
        if(index > -1 && index < library.count) {
            return library[index]
        } else {
            return nil
        }
    }
    
    func release() {
        library.removeAll()
        nameIndexer.removeAll()
    }
}
