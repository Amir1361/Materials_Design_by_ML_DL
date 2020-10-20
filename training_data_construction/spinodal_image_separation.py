import pandas as pd
import os, shutil

path = '/run/user/1001/gvfs/smb-share:server=cifs-prd-01,share=research/MahmoodMamivand/common/CMDLab/Fe_Cr_Co'
spinodal = pd.read_csv('spinodal_label.csv')
image_name = spinodal['image_name']
folder_path=os.path.join(path,'image_grayscale')
des_folde_path=os.path.join(path,'spinodal_images2')
# for filename in os.listdir(folder_path):
#     for i in range(len(image_name)):
#         #print(type(image_name[i]))
#         if filename==image_name[i]:
#             source = os.path.join(folder_path, filename)
#             destination = os.path.join(des_folde_path, filename)
#             shutil.copyfile(source,destination)
for i in range(len(image_name)):
    #print(type(image_name[i]))
    if os.path.exists(os.path.join(folder_path,image_name[i])):
        source = os.path.join(folder_path, image_name[i])
        destination = os.path.join(des_folde_path, image_name[i])
        shutil.copyfile(source,destination)
    else:
        print(image_name[i], "is not exit")
