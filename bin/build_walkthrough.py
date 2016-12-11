#!/usr/bin/python

from os import listdir
from os.path import isfile, join
import json, string, io, os, sys

cwd = os.getcwd()

if len(sys.argv) == 1:
    print "Please specify the infrastructure name after the script name. \n For example: aws, google, azure, openstack, vsphere, etc. \n"
    quit()

infra_name = str(sys.argv[1])

def extract_keys(d,n):
    retval = {}
    if n != "":
        n = n + "."
    for k, v in d.iteritems():
        if isinstance(v, dict):
            retval.update(extract_keys(v,k))
        else:
            retval[n+k] = v
            print "{0}{1}: {2}".format(n, k, v)
    return retval

def build(buildPath, outputPath):
    with io.open(join(buildPath, infra_name, "walkthrough.md"), 'r', encoding="utf-8") as walkthroughFile:
        walkthroughText = walkthroughFile.read()
    with io.open(join(buildPath, infra_name, "parameters.json"), 'r', encoding="utf-8") as walkthroughParamsFile:
        walkthroughParams = json.load(walkthroughParamsFile)
    print "Extracting Parameters..."
    walkthroughParams = extract_keys(walkthroughParams,'')
    print ""

    snippetFiles = [f for f in listdir(buildPath) if isfile(join(buildPath, f))]

    for snippetFileName in snippetFiles:
        print "Merging in " + snippetFileName + "..."
        snippetFile = io.open(join(buildPath, snippetFileName), 'r', encoding="utf-8")
        snippetText = snippetFile.read()
        walkthroughText = string.replace(walkthroughText, "(( insert_file " + snippetFileName + " ))", snippetText)

    print ""
    print "Merging in Parameters..."
    for k,v in walkthroughParams.iteritems():
        walkthroughText = string.replace(walkthroughText, "(( insert_parameter " + k + " ))", v)

    outputFile = io.open(outputPath, 'w', encoding="utf-8")
    outputFile.write(walkthroughText)

walkthroughPath = cwd + "/walkthrough"
buildPath = walkthroughPath + "/.build"

# Prime the pump if the build directory doesn't exist
if not os.path.exists(buildPath):
    os.mkdir(buildPath)
    os.system("cp " + walkthroughPath + "/*.md " + buildPath)
    os.system("cp -R " + walkthroughPath + "/" + infra_name + " " + buildPath)

# First build, so we can ensure that the product wasn't changed before the source files
print "BUILDING WALKTHROUGH FOR INITIAL COMPARISON..."
build(buildPath, join(buildPath, infra_name + ".md.out"))
with io.open(join(cwd, infra_name + ".md"), 'r', encoding="utf-8") as oldWalkthroughFile:
    oldWalkthroughText = oldWalkthroughFile.read()
with io.open(join(buildPath, infra_name + ".md.out"), 'r', encoding="utf-8") as newWalkthroughFile:
    newWalkthroughText = newWalkthroughFile.read()
if oldWalkthroughText != newWalkthroughText:
    print "ERROR - This walkthrough may have previously been manually changed without changing the source files."
else:
    print ""
    print "BUILDING FINAL WALKTHROUGH FILE..."
    os.system("cp " + walkthroughPath + "/*.md " + buildPath)
    os.system("cp -R " + walkthroughPath + "/" + infra_name + " " + buildPath)
    build(buildPath, join(cwd, infra_name + ".md"))
    print "\n File " + infra_name + ".md is generated. Well Done!"
