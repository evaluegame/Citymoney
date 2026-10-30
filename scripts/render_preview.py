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
pass_icon = "pass-icon" in output.stem.lower()
table_view = "table" in source.stem.lower()
bright_city = "bright" in source.stem.lower()
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


# Share unit geometry by material instead of repeatedly invoking Blender operators.
# This keeps review renders fast even when many purchased homes are visible.
bpy.ops.mesh.primitive_cube_add(size=1)
cube=bpy.context.object.data.copy();bpy.data.objects.remove(bpy.context.object,do_unlink=True)
bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2,radius=0.5)
ball=bpy.context.object.data.copy();bpy.data.objects.remove(bpy.context.object,do_unlink=True)
bpy.ops.mesh.primitive_cylinder_add(vertices=32,radius=0.5,depth=1)
bpy.context.object.rotation_euler[1]=math.pi/2
bpy.ops.object.transform_apply(location=False,rotation=True,scale=False)
cylinder=bpy.context.object.data.copy();bpy.data.objects.remove(bpy.context.object,do_unlink=True)
unit_meshes={"Block":cube,"Ball":ball,"Cylinder":cylinder}
mesh_cache={}
font_path=Path("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf")
world_font=bpy.data.fonts.load(str(font_path)) if font_path.exists() else None
for entry in entries:
    if entry.get("transparency",0)>=1:
        continue
    p,size=entry["position"],entry["size"]
    shape=entry.get("shape","Block")
    mat=material(entry)
    key=(shape,mat.name)
    if key not in mesh_cache:
        mesh=unit_meshes.get(shape,cube).copy();mesh.materials.clear();mesh.materials.append(mat);mesh_cache[key]=mesh
    obj=bpy.data.objects.new(entry["name"],mesh_cache[key]);bpy.context.collection.objects.link(obj)
    r=entry.get("rotation",[1,0,0,0,1,0,0,0,1])
    rotation=Matrix((r[:3],r[3:6],r[6:]))
    obj.matrix_world=(transform @ rotation @ transform.transposed()).to_4x4() @ Matrix.Diagonal((size[0],size[2],size[1],1))
    obj.location=(p[0],-p[2],p[1])
    if entry.get("text"):
        curve=bpy.data.curves.new("Caption","FONT")
        curve.body=entry["text"];curve.align_x="CENTER";curve.align_y="CENTER";curve.size=1;curve.space_line=1.1
        if world_font: curve.font=world_font
        text=bpy.data.objects.new("Caption",curve);bpy.context.collection.objects.link(text)
        front=entry.get("textFace")=="Front"
        back=entry.get("textFace")=="Back"
        local=Vector((0,0,(size[2]/2+0.03)*(1 if back else -1))) if front or back else Vector((0,size[1]/2+0.03,0))
        world=Vector(p)+rotation @ local
        basis=Matrix(((-1,0,0),(0,1,0),(0,0,-1))) if front else Matrix(((1,0,0),(0,1,0),(0,0,1))) if back else Matrix(((1,0,0),(0,0,1),(0,-1,0)))
        text.matrix_world=(transform @ rotation @ basis).to_4x4();text.location=transform @ world
        max_height=size[1]*0.72 if front or back else size[2]*0.68
        lines=entry["text"].splitlines()
        fit=min(size[0]*0.85/max(0.1,max(len(line) for line in lines)*0.66),max_height/max(0.1,len(lines)*1.1))
        fit=min(fit,entry.get("textSize",72)/40)
        text.scale=(fit,fit,fit);curve.materials.append(material({"color":entry.get("textColor","475C50")}))

scene = bpy.context.scene
scene.render.engine = "CYCLES"
scene.cycles.samples = 96
scene.cycles.use_denoising = getattr(bpy.app.build_options,"openimagedenoise",False)
scene.render.resolution_x, scene.render.resolution_y = 1440, 1050
if pass_icon: scene.render.resolution_x, scene.render.resolution_y = 512, 512
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = "PNG"
scene.render.filepath = str(output.resolve())
scene.world.color = (0.62,0.69,0.70)
scene.world.use_nodes = True
scene.world.node_tree.nodes["Background"].inputs[0].default_value = (0.70,0.78,0.80,1)
scene.world.node_tree.nodes["Background"].inputs[1].default_value = 0.5
scene.view_settings.view_transform = "Standard"
scene.view_settings.exposure = -0.6
bpy.ops.object.light_add(type="SUN",location=(70,-30,130))
sun = bpy.context.object
sun.data.energy, sun.data.angle = 2.2, math.radians(16)
sun.data.color = (1,0.96,0.89)
sun.rotation_euler = (math.radians(28),math.radians(-25),math.radians(-35))
bpy.ops.object.camera_add()
camera = bpy.context.object
if close_up:
    camera.location = (51,-41,26)
    target = Vector((40,-74,7))
    camera.data.type, camera.data.ortho_scale = "ORTHO", 42 if pass_icon else 33
elif bright_city:
    camera.location = (68,-200,340)
    target = Vector((0,0,8))
    camera.data.type, camera.data.ortho_scale = "ORTHO", 276
elif table_view:
    camera.location = (0,-90,330)
    target = Vector((0,0,8))
    camera.data.type, camera.data.ortho_scale = "ORTHO", 276
else:
    camera.location = (185,-205,220)
    target = Vector((0,-6,3))
    camera.data.type, camera.data.ortho_scale = "ORTHO", 260
camera.rotation_euler = (target-camera.location).to_track_quat("-Z","Y").to_euler()
if close_up or bright_city:
    # Fit the actual upgraded home, including its pergola, into the frame.
    # Orthographic width must also account for the shorter vertical field on wide images.
    inverse=camera.rotation_euler.to_matrix().transposed()
    corners=[inverse @ (obj.matrix_world @ Vector(corner)) for obj in scene.objects if obj.type=="MESH" and (not bright_city or obj.name!="Sea") for corner in obj.bound_box]
    lo=Vector(tuple(min(p[axis] for p in corners) for axis in range(3)))
    hi=Vector(tuple(max(p[axis] for p in corners) for axis in range(3)))
    center=(lo+hi)/2
    relative=inverse @ camera.location
    camera.location+=camera.rotation_euler.to_matrix() @ Vector((center.x-relative.x,center.y-relative.y,0))
    aspect=scene.render.resolution_x/scene.render.resolution_y
    camera.data.ortho_scale=max(hi.x-lo.x,(hi.y-lo.y)*aspect)*(1.3 if pass_icon else 1.12)
scene.camera = camera
if len(args)>2 and args[2].endswith(".json"):
    # A layout export supplies the same perspective camera as the game camera fitter.
    # This background can be composited with actual client GUI geometry for review.
    review=json.loads(Path(args[2]).read_text())
    frame=review["camera"]
    rotation=Matrix(tuple(zip(frame["right"],frame["up"],frame["back"])))
    camera.matrix_world=(transform @ rotation).to_4x4()
    camera.location=transform @ Vector(frame["position"])
    camera.data.type,camera.data.sensor_fit="PERSP","VERTICAL"
    camera.data.sensor_height=36
    camera.data.lens=36/(2*math.tan(math.radians(frame["fov"])/2))
    scene.render.resolution_x,scene.render.resolution_y=review["width"],review["height"]
if close_up:
    bpy.ops.mesh.primitive_plane_add(size=200,location=(40,-74,0.9))
    bpy.context.object.data.materials.append(material({"color":"344B43" if pass_icon else "D9DECB"}))
output.parent.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=str(output.with_suffix(".blend").resolve()))
bpy.ops.render.render(write_still=True)
