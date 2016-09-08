module spine.dsfml;

import std.conv : to;
import spine;
import dsfml.graphics;
import sp = spine.slot.blendmode;
import sf = dsfml.graphics.blendmode;
import std.stdio;

export class Loader : TextureLoader {

    void load(AtlasPage page, string path) {
        Texture texture = new Texture;
        if(!texture.loadFromFile(path))
            return;
        texture.setSmooth(true);
        page.rendererObject = texture;
        Vector2u size = texture.getSize();
        page.width = size.x;
        page.height = size.y;
    }

    void unload(Object texture) {
        delete texture;
    }
}

export class SkeletonDrawable : Drawable {
    
    enum { X1, Y1, X2, Y2, X3, Y3, X4, Y4 }

    this(SkeletonData skeletonData, AnimationStateData stateData = null) {
        timeScale = 1;
        vertexArray = new VertexArray(PrimitiveType.Triangles, skeletonData.bones.length * 4);
        worldVertices = new float[2000];
		//worldVertices[] = 0f;
        Bone.yDown = true;
        skeleton = new Skeleton(skeletonData);

        ownsAnimationStateData = stateData is null;
        if(ownsAnimationStateData)
            stateData = new AnimationStateData(skeletonData);
    
        state = new AnimationState(stateData);
    }

    @property {
        Skeleton skeleton() {
            return _skeleton;
        }
        void skeleton(Skeleton value) {
            _skeleton = value;
        }
    }

    @property {
        AnimationState state() {
            return _state;
        }
        void state(AnimationState value) {
            _state = value;
        }
    }

    @property {
        float timeScale() {
            return _timeScale;
        }
        void timeScale(float value) {
            _timeScale = value;
        }
    }

    @property {
        VertexArray vertexArray() {
            return _vertexArray;
        }
        void vertexArray(VertexArray value) {
            _vertexArray = value;
        }
    }

    void update(float deltaTime) {
        skeleton.update(deltaTime);
        state.update(deltaTime * timeScale);
        state.apply(skeleton);
        skeleton.updateWorldTransform();
    }

    void draw(RenderTarget target, RenderStates states) {
        vertexArray.clear();

        Vertex[4] vertices;
        Vertex vertex;
        for(int i = 0; i < skeleton.slots.length; i++) {
            Slot slot = skeleton.drawOrder[i];
            Attachment attachment = slot.attachment;
            if(attachment is null)
                continue;

            sf.BlendMode blend;
            switch(slot.data.blendMode) {
            case sp.BlendMode.additive:
                blend = sf.BlendMode.Add;
                break;
            case sp.BlendMode.multiply:
                blend = sf.BlendMode.Multiply;
                break;
            case sp.BlendMode.screen:
            default:
                blend = sf.BlendMode.Alpha;
            }

            if(states.blendMode != blend) {
                target.draw(vertexArray, states);
                vertexArray.clear();
                states.blendMode = blend;
            }

            Texture texture;
            if(cast(RegionAttachment)attachment) {
                RegionAttachment regionAttachment = cast(RegionAttachment)attachment;
                texture = cast(Texture)(cast(AtlasRegion)regionAttachment.rendererObject).page.rendererObject;
                regionAttachment.computeWorldVertices(slot.bone, worldVertices);
                auto r = to!ubyte(skeleton.r * slot.r * 255f);
                auto g = to!ubyte(skeleton.g * slot.g * 255f);
                auto b = to!ubyte(skeleton.b * slot.b * 255f);
                auto a = to!ubyte(skeleton.a * slot.a * 255f);

                Vector2u size = texture.getSize();
                with(vertices[0]) {
                    color.r = r;
                    color.g = g;
                    color.b = b;
                    color.a = a;
                    position.x = worldVertices[X1];
                    position.y = worldVertices[Y1];
                    texCoords.x = regionAttachment.uvs[X1] * size.x;
                    texCoords.y = regionAttachment.uvs[Y1] * size.y;
                }
                with(vertices[1]) {
                    color.r = r;
                    color.g = g;
                    color.b = b;
                    color.a = a;
                    position.x = worldVertices[X2];
                    position.y = worldVertices[Y2];
                    texCoords.x = regionAttachment.uvs[X2] * size.x;
                    texCoords.y = regionAttachment.uvs[Y2] * size.y;
                }
                with(vertices[2]) {
                    color.r = r;
                    color.g = g;
                    color.b = b;
                    color.a = a;
                    position.x = worldVertices[X3];
                    position.y = worldVertices[Y3];
                    texCoords.x = regionAttachment.uvs[X3] * size.x;
                    texCoords.y = regionAttachment.uvs[Y3] * size.y;
                }
                with(vertices[3]) {
                    color.r = r;
                    color.g = g;
                    color.b = b;
                    color.a = a;
                    position.x = worldVertices[X4];
                    position.y = worldVertices[Y4];
                    texCoords.x = regionAttachment.uvs[X4] * size.x;
                    texCoords.y = regionAttachment.uvs[Y4] * size.y;
                }

                with(vertexArray) {
                    append(vertices[0]);
                    append(vertices[1]);
                    append(vertices[2]);
                    append(vertices[0]);
                    append(vertices[2]);
                    append(vertices[3]);
                }

            } else if(cast(MeshAttachment)attachment) {
                MeshAttachment mesh = cast(MeshAttachment)attachment;
                texture = cast(Texture)(cast(AtlasRegion)mesh.rendererObject).page.rendererObject;
                mesh.computeWorldVertices(slot, worldVertices);

                vertex.color.r = to!ubyte(skeleton.r * slot.r * 255f);
                vertex.color.g = to!ubyte(skeleton.g * slot.g * 255f);
                vertex.color.b = to!ubyte(skeleton.b * slot.b * 255f);
                vertex.color.a = to!ubyte(skeleton.a * slot.a * 255f);

                Vector2u size = texture.getSize();
                for(int j = 0; j < mesh.triangles.length; j++) {
                    int index = mesh.triangles[j] << 1;
                    vertex.position.x = worldVertices[index];
                    vertex.position.y = worldVertices[index + 1];
                    vertex.texCoords.x = mesh.uvs[index] * size.x;
                    vertex.texCoords.y = mesh.uvs[index + 1] * size.y;
                    vertexArray.append(vertex);
                }

            } else if(cast(SkinnedMeshAttachment)attachment) {
                SkinnedMeshAttachment mesh = cast(SkinnedMeshAttachment)attachment;
                texture = cast(Texture)(cast(AtlasRegion)mesh.rendererObject).page.rendererObject;
                mesh.computeWorldVertices(slot, worldVertices);

                vertex.color.r = to!ubyte(skeleton.r * slot.r * 255f);
                vertex.color.g = to!ubyte(skeleton.g * slot.g * 255f);
                vertex.color.b = to!ubyte(skeleton.b * slot.b * 255f);
                vertex.color.a = to!ubyte(skeleton.a * slot.a * 255f);

                Vector2u size = texture.getSize();
                for(int j = 0; j < mesh.triangles.length; j++) {
                    int index = mesh.triangles[j] << 1;
                    vertex.position.x = worldVertices[index];
                    vertex.position.y = worldVertices[index + 1];
                    vertex.texCoords.x = mesh.uvs[index] * size.x;
                    vertex.texCoords.y = mesh.uvs[index + 1] * size.y;
                    vertexArray.append(vertex);
                }
            }

            if(texture !is null) {
                states.texture = texture;
            }
        }

        target.draw(vertexArray, states);
    }

private:
    Skeleton _skeleton;
    AnimationState _state;
    float _timeScale;
    VertexArray _vertexArray;

    bool ownsAnimationStateData;
    float[] worldVertices;
}