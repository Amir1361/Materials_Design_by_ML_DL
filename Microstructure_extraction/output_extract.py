import os
import numpy as np
import vtk
import chigger
import glob
import pandas as pd


def files(path):
    i = []
    for file in os.listdir(path):
        if os.path.isfile(os.path.join(path, file)):
            i.append(file)
    return i
cr=[]
co=[]
temperature=[]
min=[]
max=[]

path = '/run/user/1001/gvfs/smb-share:server=cifs-prd-01,share=research/MahmoodMamivand/common/CMDLab/Fe_Cr_Co/test_fol'
folders = np.array(os.listdir(path))
for folder in folders:
    path_folder=os.path.join(path,folder)
    if os.path.isdir(path_folder):
        #print(path_folder)
        existing_matches = glob.glob(os.path.join(path_folder,'*e-s*'))
        #print(existing_matches)
        #print(existing_matches)
        if existing_matches:
            used_numbers = []
            for f in existing_matches:
                try:
                    file_number = int(os.path.splitext(os.path.basename(f))[1].split('-s')[-1])
                    used_numbers.append(file_number)
                except ValueError:
                    pass
        save_number = np.max(used_numbers)
        #print(save_number)
        number_str = str(save_number)
        #print(number_str.zfill(3))
        #print(os.path.join(path_folder,'*e-s'+number_str.zfill(3)))
        fils=np.array(files(os.path.join(path,folder)))
        #print(fils.shape)
        for i in range(len(fils)):
            if fils[i].endswith(number_str.zfill(3)):
                camera = vtk.vtkCamera()
                camera.SetViewUp(0.0000000000, 1.0000000000, 0.0000000000)
                camera.SetPosition(100.0000000000, 100.0000000000, 546.4101615138)
                camera.SetFocalPoint(100.0000000000, 100.0000000000, 0.0000000000)


                folpath=os.path.join(path, folder)
                filepath=os.path.join(folpath, fils[i])
                #print(filepath)
                #print(type(filepath))
                reader = chigger.exodus.ExodusReader(filepath)
                reader.setOptions(block=['0'])

                result = chigger.exodus.ExodusResult(reader)
                result.setOptions(edge_color=[0, 0, 0], variable='c1', block=['0'], cmap='grayscale', local_range=True, camera=camera)
                #result.setOptions(edge_color=[0, 0, 0], variable='c1', block=['0'], local_range=True, camera=camera)

                #cbar = chigger.exodus.ExodusColorBar(result)
                #cbar.setOptions(colorbar_origin=(0.8, 0.25, 0.0), cmap='grayscale')
                #cbar.setOptions(colorbar_origin=(0.8, 0.25, 0.0))
                #cbar.setOptions('primary', lim=[0.03, 0.97], font_size=16)
                window = chigger.RenderWindow(result)
                # window.setOptions(size=None, style=None, background=[1, 1, 1])
                window.setOptions(size=[300,300], style=None)
                #imagename = "images_test_fol3_nobar/%s.jpg"%folder[4:]
                window.start()


                str1=folder.split('_')
                cr.append(float(str1[1][2:]))
                co.append(float(str1[2][2:]))
                temperature.append(float(str1[3][1:]))

                min_range,max_range=result.getRange()
                min.append(min_range)
                max.append(max_range)
                print(co)

out=pd.DataFrame({'cr':cr, 'co':co, 'temperature':temperature,'min':min, 'max':max})
out.to_csv('output/output_test_fol.csv', index=False)
