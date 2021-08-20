#!/usr/bin/env python
# coding: utf-8

# In[36]:


import os
import os.path
import sys

if not os.path.exists('data/train'):
    os.makedirs('data/train')
if not os.path.exists('data/test'):
    os.makedirs('data/test')
if not os.path.exists('data/truetest'):
    os.makedirs('data/truetest')


# In[37]:


for files in os.listdir('data'):
    if files == 'data-info.txt':
        info = open('data/'+files, 'r')
        i=0
        idd = []
        for x in info:
            var = []
            var.extend(x.split(' ')[1:])
            idd.append(var)

    elif files == 'transcriptions.txt':
        train1 = []
        test1 = []
        truetest1 = []
        info = open('data/'+files, 'r')
        for x in info:
            for y in idd[0]:
                if x[:15]==y[:15]:
                    # print('train')
                    train1.append(x)
                    break
            for y in idd[1]:
                if x[:15]==y[:15]:
                    # print('test')
                    test1.append(x)
                    break
            for y in idd[2]:
                if x[:15]==y[:15]:
                    # print('truetest')
                    truetest1.append(x)
                    break
    elif files == 'wav':
        train2=[]
        test2=[]
        truetest2=[]
        
        train3=[]
        test3=[]
        truetest3=[]
        
        unique = 0
        
        for file in sorted(os.listdir('data/'+files)):
            for y in sorted(idd[0]):
                if file == y[:15]:
                    print('train:',file)
                    for f in sorted(os.listdir('data/wav/'+file)):
                        train2.append(f[:-4]+' corpus/data/wav/'+file+'/'+f)
                        train3.append(f[:-4]+' '+file)
                        unique = unique+1
            for y in sorted(idd[1]):
                if file == y[:15] :
                    print('test:',file)
                    for f in sorted(os.listdir('data/wav/'+file)):
                        test2.append(f[:-4]+' corpus/data/wav/'+file+'/'+f)
                        test3.append(f[:-4]+' '+file)
                        unique = unique+1
            for y in sorted(idd[2]):
                if file == y[:15] :
                    print('truetest:',file)
                    for f in sorted(os.listdir('data/wav/'+file)):
                        truetest2.append(f[:-4]+' corpus/data/wav/'+file+'/'+f)
                        truetest3.append(f[:-4]+' '+file)
                        unique = unique+1
    


# In[38]:


with open('data/train/text', 'w') as train, open('data/test/text', 'w') as test, open('data/truetest/text', 'w') as truetest:
    train.writelines(["%s" % item  for item in train1])
    test.writelines(["%s" % item  for item in test1])
    truetest.writelines(["%s" % item  for item in truetest1])
with open('data/train/wav.scp', 'w') as train, open('data/test/wav.scp', 'w') as test, open('data/truetest/wav.scp', 'w') as truetest:
    train.writelines(["%s \n" % item  for item in train2])
    test.writelines(["%s \n" % item  for item in test2])
    truetest.writelines(["%s \n" % item  for item in truetest2])
with open('data/train/utt2spk', 'w') as train, open('data/test/utt2spk', 'w') as test, open('data/truetest/utt2spk', 'w') as truetest:
    train.writelines(["%s \n" % item  for item in train3])
    test.writelines(["%s \n" % item  for item in test3])
    truetest.writelines(["%s \n" % item  for item in truetest3])


# In[ ]:





# In[39]:


# for item in train2:
#     print("%s" % item  )
#     break


# In[ ]:




