"""Optional Blender render of the real scene descriptions, not a Studio screenshot.
blender -b -t 4 --python scripts/render_preview.py -- build/showcase.json build/Neighborhood.png
"""
import json
import math
import sys
from pathlib import Path
import bpy
from mathutils import Matrix, Vector

args = sys.argv[sys.argv.index("--") + 1:]
source, output = Path(args[0]), Path(args[1])
entries = json.loads(source.read_text())
close_up = "home" in source.stem.lower()
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
materials = {}
transform = Matrix(((1,0,0),(0,0,-1),(0,1,0)))


def material(entry):
    key = (entry["color"],entry.get("material","SmoothPlastic"))
    if key in materials:
        return materials[key]
    mat = bpy.data.materials.new("_".join(key))
    mat.use_nodes = True
    shader = mat.node_tree.nodes.get("Principled BSDF")
    srgb = tuple(int(key[0][i:i+2],16)/255 for i in (0,2,4))
    rgb = tuple(value/12.92 if value<=0.04045 else ((value+0.055)/1.055)**2.4 for value in srgb)
    shader.inputs["Base Color"].default_value = (*rgb,1)
    shader.inputs["Roughness"].default_value = 0.38 if key[1] == "Glass" else 0.72
    if key[1] == "Metal": shader.inputs["Metallic"].default_value = 0.5
    if key[1] == "Neon":
        shader.inputs["Emission Color"].default_value = (*rgb,1)
        shader.inputs["Emission Strength"].default_value = 0.7
    materials[key] = mat
    return mat


for entry in entries:
    if entry.get("transparency",0) >= 1:
        continue
    p, size = entry["position"], entry["size"]
    if entry.get("shape") == "Ball":
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2,radius=0.5)
    else:
        bpy.ops.mesh.primitive_cube_add(size=1)
    obj = bpy.context.object
    obj.name = entry["name"]
    obj.scale = (size[0],size[2],size[1])
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    r = entry.get("rotation",[1,0,0,0,1,0,0,0,1])
    rotation = Matrix((r[:3],r[3:6],r[6:]))
    obj.matrix_world = (transform @ rotation @ transform.transposed()).to_4x4()
    obj.location = (p[0],-p[2],p[1])
    obj.data.materials.append(material(entry))
    if entry.get("shape") != "Ball" and min(size)>0.2 and max(size)<190:
        bevel = obj.modifiers.new("Soft edges","BEVEL")
        bevel.width, bevel.segments = min(0.055,min(size)*0.15), 2
        obj.modifiers.new("Weighted normals","WEIGHTED_NORMAL")
    if entry.get("text"):
        bpy.ops.object.text_add()
        text = bpy.context.object
        text.data.body = entry["text"]
        text.data.align_x, text.data.align_y = "CENTER", "CENTER"
        text.data.size = 1
        text.data.space_line = 1.1
        text.data.extrude = 0
        front = entry.get("textFace") == "Front"
        local = Vector((0,0,-size[2]/2-0.03)) if front else Vector((0,size[1]/2+0.03,0))
        world = Vector(p) + rotation @ local
        if front:
            basis = Matrix(((-1,0,0),(0,1,0),(0,0,-1)))
        else:
            basis = Matrix(((1,0,0),(0,0,1),(0,-1,0)))
        text.matrix_world = (transform @ rotation @ basis).to_4x4()
        text.location = transform @ world
        bpy.context.view_layer.update()
        max_height = size[1]*0.72 if front else size[2]*0.68
        bounds = [Vector(point) for point in text.bound_box]
        local_width = max(point.x for point in bounds)-min(point.x for point in bounds)
        local_height = max(point.y for point in bounds)-min(point.y for point in bounds)
        fit = min(size[0]*0.85/max(0.1,local_width), max_height/max(0.1,local_height))
        text.scale = (fit,fit,fit)
        text.data.materials.append(material({"color":entry.get("textColor","475C50")}))

scene = bpy.context.scene
scene.render.engine = "CYCLES"
scene.cycles.samples = 48
scene.cycles.use_denoising = False
scene.render.resolution_x, scene.render.resolution_y = 1440, 1050
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = "PNG"
scene.render.filepath = str(output.resolve())
scene.world.color = (0.62,0.69,0.70)
scene.world.use_nodes = True
scene.world.node_tree.nodes["Background"].inputs[0].default_value = (0.70,0.78,0.80,1)
scene.world.node_tree.nodes["Background"].inputs[1].default_value = 0.5
scene.view_settings.view_transform = "AgX"
bpy.ops.object.light_add(type="SUN",location=(70,-30,130))
sun = bpy.context.object
sun.data.energy, sun.data.angle = 2.8, math.radians(12)
sun.data.color = (1,0.88,0.71)
sun.rotation_euler = (math.radians(28),math.radians(-25),math.radians(-35))
bpy.ops.object.camera_add()
camera = bpy.context.object
if close_up:
    camera.location = (51,-41,26)
    target = Vector((40,-74,7))
    camera.data.type, camera.data.ortho_scale = "ORTHO", 33
else:
    camera.location = (185,-205,220)
    target = Vector((0,-6,3))
    camera.data.type, camera.data.ortho_scale = "ORTHO", 260
camera.rotation_euler = (target-camera.location).to_track_quat("-Z","Y").to_euler()
scene.camera = camera
if close_up:
    bpy.ops.mesh.primitive_plane_add(size=200,location=(40,-74,0.9))
    bpy.context.object.data.materials.append(material({"color":"D9DECB"}))
output.parent.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=str(output.with_suffix(".blend").resolve()))
bpy.ops.render.render(write_still=True)
