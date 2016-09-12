import os
import ctypes
import sys
import json
import gspread
from oauth2client.service_account import ServiceAccountCredentials
from multiprocessing import Process, freeze_support

def access_spreadsheet():
    print('child')
    
    if len(sys.argv) > 1:
        if len(sys.argv) == 7:
            fn = 'manualreport'
        else:
            fn = sys.argv[1]
    else:
        fn = 'noarg'
    print(fn)
    status = open('timerstatus.txt','w')
    status.write('authorizing')
    status.close()
    scope = ['https://spreadsheets.google.com/feeds']
    credentials = ServiceAccountCredentials.from_json_keyfile_name('credentials.json', scope)

    gc = gspread.authorize(credentials)
    print('authorized')
    wks = gc.open("Yggdrasil Boss Timers").sheet1
    print('open sheet')
    bossnames = wks.col_values(1)
    print('bossnames')
    if fn == 'report' or fn == 'manualreport':
        print('go')
        bossname = sys.argv[2]
        if fn == 'report':
            print('report')
            wks.update_acell('F1','=NOW()')
            time = wks.acell('F1').value
        else:
            print('set time')
            time = sys.argv[6]
        mapname = sys.argv[3]
        user = sys.argv[4]
        channel = sys.argv[5]
        bossFound = 0
        status = open('timerstatus.txt','w')
        status.write('sending')
        status.close()

        for i in range(len(bossnames)):
            if bossname == bossnames[i]:
                wks.update_cell(i+1,2,time)
                wks.update_cell(i+1,3,mapname)
                wks.update_cell(i+1,4,channel)
                wks.update_cell(i+1,5,user)
                bossFound = 1
                print('update')
                break

        if bossFound == 0:
            for i in range(len(bossnames)):
                if len(bossnames[i]) < 1:
                    cell_row = i+1
                    break
            bossnames[cell_row-1] = bossname
            print(bossnames[cell_row-1])
            wks.update_cell(cell_row,1,bossname)
            wks.update_cell(cell_row,2,time)
            wks.update_cell(cell_row,3,mapname)
            wks.update_cell(cell_row,4,channel)
            wks.update_cell(cell_row,5,user)
            print('create')
    status = open('timerstatus.txt','w')
    status.write('refreshing')
    status.close()
    times = wks.col_values(2)
    mapnames = wks.col_values(3)
    channels = wks.col_values(4)
    users = wks.col_values(5)
    bossData = []

    for i in range(len(bossnames)):
        if len(bossnames[i]) < 1:
            break
        bossData.append({
        'bossname':bossnames[i],
        'time':times[i],
        'mapname':mapnames[i],
        'channel':channels[i],
        'user':users[i]
        })
    f = open('bossdata.json','w')
    f.write(json.dumps(bossData, sort_keys=True, indent=4, separators=(',', ': ')))
    f.close()
    status = open('timerstatus.txt','w')
    status.write('saving')
    status.close()
    print('save json')
    if fn == 'noarg':
        ctypes.windll.user32.MessageBoxA(0, "Boss data has been saved to bossdata.json", "Boss Timer", 1)
    print('exit')
    status = open('timerstatus.txt','w')
    status.write('complete')
    status.close()
    sys.exit()


if __name__ == '__main__':
    freeze_support()
    print('parent')
    p = Process(target=access_spreadsheet)
    p.start()
    print('exit')
    os._exit(0)

