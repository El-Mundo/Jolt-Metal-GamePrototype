//
//  BufferIndices.h
//  Yami✨no✨Game
//
//  Created by El-Mundo on 22/08/2024.
//

#ifndef BufferIndices_h
#define BufferIndices_h

#ifdef __METAL_VERSION__
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
typedef metal::int32_t EnumBackingType;
#else
#import <Foundation/Foundation.h>
typedef NSInteger EnumBackingType;
#endif

typedef NS_ENUM(EnumBackingType, VertexBufferIndex)
{
    VertexBufferIndexMeshPositions = 0,
    VertexBufferIndexMeshUVs       = 1,
    VertexBufferIndexMeshNormals   = 2,
    VertexBufferIndexSceneUniforms = 3,
    VertexBufferIndexModelUniforms = 4
};

typedef NS_ENUM(EnumBackingType, FragmentBufferIndex)
{
    FragmentBufferIndexSceneUniforms = 0,
    FragmentBufferIndexMaterial  = 1
};


typedef NS_ENUM(EnumBackingType, VertexAttribute)
{
    VertexAttributePosition  = 0,
    VertexAttributeTexcoord  = 1,
    VertexAttributeNormal   = 2
};

typedef NS_ENUM(EnumBackingType, TextureIndex)
{
    TextureIndexColor    = 0,
};

#endif /* BufferIndices_h */
