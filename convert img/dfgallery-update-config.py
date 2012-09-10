#!/usr/bin/env python
# coded by Matteo 'Peach' Pescarin
#	www.smartart.it
# relased under the GPLv2

import libxml2, os, string, datetime, commands, sys
# Options Parser
from optparse import OptionParser

#~ parser = OptionParser(usage="dfgallery-update-config.py [-c|--config-file <config.xml>][[[-d|--date <YYYY-MM-DD>][-f|--files <path/>][-b|--thumbs <REGEXP>] -i|--desc <description>]|[-r|--remove-album <name>]] -t|--title <title>")
parser = OptionParser()
parser.add_option("-v", "--verbose", help="Available verbosity levels: 0, 1, 2", default=0, type="int")
parser.add_option("-d", "--date", dest="date", help="date of the photos to be added (all the photos will have the same date). Defaults to TODAY")
parser.add_option("-c", "--config-file", dest="cfgfile", default="gallery.xml", help="path to configuration file name (must be present, defaults to 'gallery.xml')")
parser.add_option("-p", "--path", dest="path", default=".", help="directory path where your photos are stored")
parser.add_option("-w", "--web-server-path", dest="wpath", default=".", help="webserver directory path where your photos will be stored, relative to the gallery.xml file")
parser.add_option("-b", "--thumbs", dest="tregexp", default="none", help="REGEXP for thumbs filenames, i.e. \".*thumbs\.jpg\" (unset means \"build thumbs!\")")
parser.add_option("-t", "--title", dest="title", help="Title of the album gallery (if not set only image thumbs will be created)")
parser.add_option("-i", "--description", dest="description", help="Description of the album gallery")
parser.add_option("-o", "--overwrite-imgs", dest="overwriteImages", action="store_true", default=False, help="rewrite whole album instead of adding images to an existing album (it will be created it if not existing)")
parser.add_option("-r", "--remove-album", dest="removeAlbum", action="store_true", default=False, help="album name to be removed")

(options, args) = parser.parse_args()

resizex=265
resizey=265

def albumExists(xmlDoc):
	return xmlDoc.xpathEval("//album[@title='"+options.title+"']") 
	
def addAlbum(xmlDoc):
	return xmlDoc.xpathEval("//albums")[0].addChild(libxml2.newNode("album"))

def addImage(filename):
	imageN = libxml2.newNode("image")
	#~ imageN.setProp("title",options.title)
	#~ imageN.setProp("description",options.description)
	imageN.setProp("date",options.date)
	imageN.setProp("thumbnail",options.wpath+os.sep+filename.rsplit(".",1)[0]+".thumb.jpg")
	imageN.setProp("image",options.wpath+os.sep+filename)
	imageN.setProp("title",filename)
	imageN.addContent(filename)
	return imageN
	
def insertImages():
	xmlFile = open(options.cfgfile, "r+")
	xmlDoc = libxml2.parseDoc(xmlFile.read())
	if options.verbose>0:
		print albumExists(xmlDoc)
	if len(albumExists(xmlDoc)) == 0:
		album = addAlbum(xmlDoc)  # FIXME 1st call
		album.setProp("title",options.title)
		album.setProp("description",options.description)
	else:
		album = albumExists(xmlDoc)[0] # FIXME 2nd call: no good.
	#~ if options.overwriteImages and not album.isBlankNode():
	for file in os.listdir(options.path):
		if file.rfind("thumb",len(file)-9,len(file))==-1 and \
			(file.rfind("jpg",len(file)-3,len(file))!=-1 or \
			file.rfind("JPG",len(file)-3,len(file))!=-1) :
			album.addChild(addImage(file))
	#~ print str(xmlDoc)
	xmlFile.truncate(0)
	xmlFile.seek(0,0)
	xmlFile.write(str(xmlDoc))
	xmlFile.close()
	sys.exit(0)


def thumbnalizeImg(filename):
	if options.verbose>0:
		print("creo la thumbnail: "+options.path+os.sep+filename.rsplit(".",1)[0]+".thumb.jpg")
	if commands.getstatusoutput("convert -resize "+str(resizex)+"x"+str(resizey)+" '"+options.path+os.sep+filename+"' '"+options.path+os.sep+filename.rsplit(".",1)[0]+".thumb.jpg'")[0] != 0:
		print("errore nella creazione della thumbnail "+filename)
		sys.exit(1)

def thumbnalizeDir():
	if (os.path.exists(options.path) and os.path.isdir(options.path)):
		if options.verbose>0:
			print("Inizio ad iterare tra i file per creare le thumbnail...")
		for file in os.listdir(options.path):
			if os.path.isfile(options.path+os.sep+file) and \
				file.rfind("thumb",len(file)-9,len(file))==-1 and \
				(file.rfind("jpg",len(file)-3,len(file))!=-1 or \
				file.rfind("JPG",len(file)-3,len(file))!=-1) :
				if os.path.exists(options.path+os.sep+file.rsplit(".",1)[0]+".thumb.jpg"):
					if (options.verbose>0):
						print("la thumbnail per "+file+" esiste gia'")
					continue;
				thumbnalizeImg(file)
	else:
		print(options.path+" non e' una directory")
		sys.exit(1)

def fileExists(filepath):
	if os.path.exists(filepath) and os.path.isfile(filepath):
		return True

if __name__ == "__main__":
	#~ if len(args) < 1:
		#~ parser.error("incorrect number of arguments")
	thumbnalizeDir()
	if fileExists(options.cfgfile):
		insertImages()
	else:
		print "errore: file di configurazione specificato inesistente\nverificare che esista"
		sys.exit(1)
	