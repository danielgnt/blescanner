import os.path
from flask import Flask, jsonify, request
app = Flask(__name__)

@app.route('/which', methods=['POST'])
def which():
    data = request.json
    toSync = []
    alreadySynced = getSyncedCaptures()
    for capture in data["captures"]:
        if not capture in alreadySynced:
            toSync.append(capture)
    print("Ready to Sync:")
    print '\n'.join(toSync)
    return jsonify({"toSync": toSync})

def getSyncedCaptures():
    if not os.path.isfile('captures.txt'):
        open("captures.txt","w+")
        return []
    with open("captures.txt","r+") as file:
        lines = []
        for line in file:
            lines.append(line.strip())
        return lines
    
@app.route('/sync', methods=['POST'])
def sync():
    data = request.json
    for capture in data:
        print("Syncing: " + capture)
        with open(capture+".csv","w+") as file:
            for line in data[capture]:
                file.write(str(line) + "\n")
        with open("captures.txt","a+") as file:
            file.write(capture+"\n")
        print("Done Syncing: " + capture)
    print("All Files Synced!")
    return jsonify({"staus": "OK"})
    

    
app.run(host= '0.0.0.0')
