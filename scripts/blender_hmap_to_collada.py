import bpy
import sys
from os import listdir
from os.path import isfile, join

mypath = "/Users/stefanopeverelli/Documents/usi/6ths/BachelorProject/data/heightmaps"

onlyfiles = [f for f in listdir(mypath) if isfile(join(mypath, f))]

for file_name in onlyfiles:

	bpy.ops.object.delete(use_global=False)

	bpy.ops.mesh.primitive_plane_add(radius=1, view_align=False, enter_editmode=False,
		location=(0, 0, 0),
		layers=(True, False, False, False, False, False, False, False, False, False, False,
				False, False, False, False, False, False, False, False, False))


	bpy.context.object.scale[0] = 10
	bpy.context.object.scale[1] = 10
	bpy.ops.object.editmode_toggle()

	bpy.ops.mesh.subdivide(number_cuts=100, smoothness=0)
	bpy.ops.mesh.subdivide(number_cuts=2, smoothness=0)

	modif = bpy.data.objects['Plane'].modifiers.new(type='DISPLACE', name='hmap_displace')

	tex = bpy.data.textures.new('displace_tex', type='IMAGE')

	img_path = join(mypath, file_name)

	img = bpy.data.images.load(img_path)


	tex.image = img
	bpy.ops.object.editmode_toggle()

	modif.texture_coords = 'OBJECT'
	#modif.strength = 0.06 # this is current max height
	modif.texture = tex

	# apply to regenerate mesh for export
	bpy.ops.object.modifier_apply(modifier=modif.name)

	export_path = join(mypath, '.'.join(file_name.split('.')[:-1]))
	bpy.ops.wm.collada_export(filepath=export_path)

sys.exit(0)
