/*  
[INFO] 

NAME = Model Packer
VERSION = 1.0.5
AUTHOR = Vasily Lukyanenko
DEV = 3DGROUND
CUSTOMER = Sergey Pak
SKYPE = ssearsh
HELP = 

[INSTALL]

MACRO=ModelPacker
CAT=3DGROUND
TEXT=Model Packer
ICON=#("PhysX_Main", 30)

[1.0.0]

* First release =

[1.0.1]

+ Added: PBR Convertor=

[1.0.2]

* Changed: PBR conversion conditions=

[1.0.3]

- BugFix: Gamma 1.0 in name after conversion=

[1.0.4]

+ Added: Description field=
+ Added: Custom Attribute field=

[1.0.5]

- BugFix: CenterPivot crash for non geometry class=
* Changed: Removed About rollout=

[ABOUT]

This script helps to prepare model for internal library=

[TEST]

[SCRIPT]
*/	


try(closeRolloutFloater rModelPacker)catch()
global rModelPacker = newRolloutFloater "Model Packer" 280 600

global _STEP1

global szChars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890-"
global szGoodChars = szChars + "&$%#()!_+ "

global BitmapTypes = #(Bitmaptexture, CoronaBitmap)

global sModelName = ""
global sModelTags = ""
global sModelDesc = ""
global sModelCustom1 = ""

global _SAVEPATH = @"C:\temp\Model Packer\"

global _VRAY_PBR_GAMMA = 2.2
global _CORONA_PBR_GAMMA = 4.4

 fn useSettings k p w =
(
	/*
		useSettings "key" "value/int/float/bool/bool_not" "r/w" 
	*/
	
	u = sysInfo.username
	d = getFilenamePath  (getThisScriptFilename())
	n = filenameFromPath (getThisScriptFilename())			
	settingsFile = d + u + "_" + n + ".ini"
		
	v = maxVersion()
	v = 2000 + ((v[1] / 1000) - 2)
	
	t = v as string
	
	case w of
	(
		"r":
		(
			s = getINISetting settingsFile t k
			case p of
			(
				"int": return s as integer
				"float": return s as float
				"bool": if s == "true" or s.count < 1 then true else false
				"bool_not": if s == "true" then true else false
				
				default: return s
			)
		)
		default: return setINISetting settingsFile t k (p as string)
	)
)	

struct zip
(
	dirs = #(),
	files = #(),
	
	fn getRecusive d =
	(		
		c = getDirectories (d + "*")
		f = getFiles (d + "*")
		join dirs c
		join files f
		for i in c do getRecusive i
	),
	
	fn writeFile f t =
	(
		local tmp
		try(tmp = createFile f) catch (return false)			
		format t to:tmp
		flush tmp
		close tmp
				
		return true
	),
	
	fn br t =
	(
		return "\"" + t + "\""
	),
	
	fn rmDir d =
	(
		cmd = "RMDIR " + (br d) + " /S /Q"
		hiddendosCommand cmd 				
	),
	fn packFile  source: "" target: "" name: "tmpzip" del: false = 
	(	
		out = name + ".zip"
		
		curDir = sysInfo.currentDir
		sysInfo.currentDir = getFilenamePath  source
		
		maz  out (filenameFromPath source)
		
		sysInfo.currentDir = curDir 
		
		if(del == true) do deleteFile source
		return true
	),
	fn packFiles source: "" target: "" name: "tmpzip" del: false =
	(
		dirs = #()
		files = #()
		
		makeDir @"C:\temp\"
		makeDir target
		tmp = @"C:\temp\ziptmp.txt" 
		maxZip = (getDir #maxRoot) + "maxzip.exe"
			
		source = (trimRight source "\\") + "\\"
		target = (trimRight target "\\") + "\\"
		
		if(not doesFileExist source or source.count < 2) do return false
		if(not doesFileExist target or target.count < 2) do return false
		
		getRecusive source
		
		if(files.count == 0) do return false
		
		if(doesFileExist tmp) do deleteFile tmp
		t = ""		
		for i in files do t += (substituteString i source "") + "\n"
		writeFile tmp t
		
		curDir = sysInfo.currentDir
		sysInfo.currentDir = source
		out = target + name + ".zip"
		
		cmd = (br maxZip) + " " + (br out) + " @" + tmp
		
		hiddendosCommand cmd exitcode:&exitcode
		sysInfo.currentDir = curDir 
		
		if(del == true) do rmDir source
		
		if(exitcode == 0) do return true 
		return false
	)
)

fn trim s c: " " = trimRight (trimLeft s c) c

fn getScriptInfo s releaseInfo: "" =
(		
	if(releaseInfo != "") do
	(
		r = getINISetting s releaseInfo
		return r
	)
	
	v = getINISetting s "INFO" "VERSION"
	a = getINISetting s "INFO" "AUTHOR"
	n = getINISetting s "INFO" "NAME"
	o = getINISetting s "ABOUT"
	c = getINISetting s "INFO" "DEV"
	h = getINISetting s "INFO" "HELP"
	
	r = for i in (getINISetting s) where i != "ABOUT" and i != "SCRIPT" and i != "COPY" collect i
	
	return #(n, a, v, o, r, c, h)
)

fn showTooltip c t =
(
	toolTip = dotnetobject "System.Windows.Forms.ToolTip"
	toolTip.SetToolTip c t   
	--toolTip.Active = true    
	toolTip.isBalloon = true
	toolTip.InitialDelay = 100
	toolTip.AutoPopDelay = 500
	toolTip.ReshowDelay = 50
	toolTip.ToolTipTitle = "Warning!"
	toolTip.Show t c 3000	
	toolTip.ToolTipIcon = (dotnetclass "System.Windows.Forms.ToolTipIcon").Warning
)


fn invalidBitmap b = 
(	
	return b == undefined or b.filename == undefined or b.filename == "" or b.filename.count == 0
)

fn validBitmap b = 
(	
	return b != undefined and b.filename != undefined and b.filename != "" and b.filename.count != 0
)

fn getFullPath p = 
(	
	if(doesFileExist p) do return p
	
	return mapPaths.getFullFilePath (filenameFromPath  p)
)

fn getColor r g b = (dotnetclass "System.Drawing.Color").FromArgb r g b

fn getUnits = 
(	
	u = trimLeft (units.SystemType as string) "#"
	u[1] = toUpper u[1]
	return u
)

fn stripName n =
(
	n = substituteString n " " "-"
)

fn replaceBadChars s rule: szChars =
(
	badChars = for i in 1 to s.count where findString rule s[i] == undefined collect s[i]
	for c in badChars do s = substituteString s c ""
		
	return s
)

fn getDim s =
(
	d = s.max - s.min
	
	d = for i in 1 to 3 collect ((d[i] * 100) as integer / 100.0 ) as string
	
	return d[1] + " x " + d[2] + " x " + d[3]
)

fn getBgColor = 
(
	b = (colorman.getcolor #background) * 255
	c = getColor b[1] b[2] b[3]
	return c
)

fn getTextColor =
(
	t = (colorMan.getColor #text) * 255
	c = getColor t[1] t[2] t[3]
	return c
)

fn implode a tag: ";" = 
(
	s = ""
	for i in a do s += i as string + tag
	return trimRight s tag
)

fn explode s tag: ";" = return filterString s tag
	
fn isSelected =
(
	if(selection.count < 1) do 
	(
		return false
	)
	
	return true
)

fn isGroup s =
(
	g = for i in s where (isGroupHead i) and (not (isGroupMember i)) collect i
	if(g[1] != undefined) do return g[1]	
	return s
)

fn isValidText t component =
(
	c = for i in 1 to t.count where findString szGoodChars t[i] == undefined collect t[i]

	if(c.count > 0) do 
	(
		c = makeUniqueArray c
		m = "Unsupported symbols:"
		for i in c do m += " " + i
				
		showTooltip component m
		return false
	)
	
	return true
)

fn setPivot zpos: undefined =
(
	selection.pivot = selection.center
	if(zpos != undefined) do selection.pivot.z = zpos
		
	ForceCompleteRedraw()
)

fn AttachObj o =
(
	undo off
	(
		x = for i in o where superclassof i == GeometryClass and classof i != TargetObject collect i
		
		j = 1
		
		while x.count > 1 do
		(				
			if(classOf x[j] != Editable_Poly) then  convertToPoly x[j]
								
			polyop.attach x[j] x[j+1]
			deleteItem x (j+1)
				
			j += 1
				
			if (j + 1) > x.count then j = 1  				
		)
	)

	try(CenterPivot x[1])catch()
	try(x[1].wirecolor = gray)catch()
	
	return x[1]
)

fn getMaxVersion =
(
	v = maxVersion()
	v = (v[1] / 1000) - 2
	
	a = 2000 + v
	
	o = case v of 
	(
		11: #(a - 1, a)
		12: #(a - 2, a - 1, a)
		default: #(a - 3, a - 2, a - 1, a)		
	)
	
	return (for i in o collect i as string)
)

fn getCurrRender =
(
	r = renderers.current as string

	if matchpattern r pattern:"*Corona*" do return #("_corona", "Corona")
	if matchpattern r pattern:"*V_Ray_Adv*" do return #("_vray", "VRay")
	if matchpattern r pattern:"*Default_Scanline*" do return #("_scanline", "Scanline")
	if matchpattern r pattern:"*mental_ray*" do return #("_mentalray", "MentalRay")
	if matchpattern r pattern:"*iray_Renderer*" do return #("_iray", "IRay")
	if matchpattern r pattern:"*maxwell*" do return #("_maxwell", "Maxwell")
		
	return #("", "")
)

fn getGamma =
(
	r = getCurrRender()
	if(r[2] == "Corona") do return "2.2"
	
	if(IDisplayGamma.colorCorrectionMode == #none) do return "1.0"
	return IDisplayGamma.gamma as string
)

fn ConvertToPBR = 
(
	IDisplayGamma.colorCorrectionMode = #gamma
	IDisplayGamma.gamma = 2.2
	
	r = getCurrRender()
	if(r[2] == "VRay") do
	(
		for m in getClassInstances VRayMtl do
		(
			g = m.texmap_reflectionGlossiness
			f = m.texmap_reflectionIOR
			
			if(g != undefined and not (classOf g == ColorCorrection and g.gammaRGB == _VRAY_PBR_GAMMA)) do
			(
				c = ColorCorrection()
				c.gammaRGB = _VRAY_PBR_GAMMA
				c.map = g
				c.lightnessMode = 1
				c.name = "PBR"
				
				m.texmap_reflectionGlossiness = c
			)
			
			if(f != undefined and not (classOf f == ColorCorrection and f.gammaRGB == _VRAY_PBR_GAMMA)) do
			(				
				c = ColorCorrection()
				c.gammaRGB = _VRAY_PBR_GAMMA
				c.map = f
				c.lightnessMode = 1
				c.name = "PBR"
				
				m.texmap_reflectionIOR = c
			)		
		)
	)

	if(r[2] == "Corona") do
	(
		for m in getClassInstances CoronaMtl do
		(
			g = m.texmapReflectGlossiness
			f = m.texmapFresnelIor
			
			if(g != undefined and not (classOf g == ColorCorrection and g.gammaRGB == _CORONA_PBR_GAMMA)) do
			(
				c = ColorCorrection()
				c.gammaRGB = _CORONA_PBR_GAMMA
				c.map = g
				c.lightnessMode = 1
				c.name = "PBR"
				
				m.texmapReflectGlossiness = c
			)
			
			if(f != undefined and not (classOf f == ColorCorrection and f.gammaRGB == _CORONA_PBR_GAMMA)) do
			(				
				c = ColorCorrection()
				c.gammaRGB = _CORONA_PBR_GAMMA
				c.map = f
				c.lightnessMode = 1
				c.name = "PBR"
				
				m.texmapFresnelIor = c
			)		
		)
	)	
)

fn isMaterialsPBR = 
(
	votes = #()
	
	r = getCurrRender()
	if(r[2] == "VRay") do
	(
		for m in getClassInstances VRayMtl do
		(
			g = m.texmap_reflectionGlossiness
			f = m.texmap_reflectionIOR
			if(
				(classOf g == ColorCorrection and 
				g.gammaRGB == 2.2) or
				(classOf f == ColorCorrection and
				f.gammaRGB == 2.2)
			) then 
			(
				appendIfUnique votes true
			) else
			(
				appendIfUnique votes false
			)
		)
	)
	
	if(r[2] == "Corona") do
	(
		for m in getClassInstances CoronaMtl do
		(
			g = m.texmapReflectGlossiness
			f = m.texmapFresnelIor
			if(
				(classOf g == ColorCorrection and 
				g.gammaRGB == 4.4) or
				(classOf f == ColorCorrection and
				f.gammaRGB == 4.4)
			) then 
			(
				appendIfUnique votes true
			) else
			(
				appendIfUnique votes false
			)
		)
	)
	
	if(votes.count == 1 and votes[1] == true) do return true
	if(votes.count == 1 and votes[1] == false) do return false
	if(votes.count == 2) do return #error
)

fn getNum n c:3 =
(
	n = n as string
	
	if(n.count < c) do
	(
		d = c - n.count
		
		s = ""
		
		for i in 1 to d do s += "0"
		return s + n
	)
	
	return n
)

fn polyCount s  =
(	
	iPoly = 0
	
	a = for i in s collect (getPolygonCount i)[1]
	for i in a do iPoly += i
	
	r = ""
	ii = 1
	sPoly = iPoly as string
	
	for i in sPoly.count to 1 by -1 do
	(
		space = ""	
			
		if (ii == 3) do 
		(
			space = " "
			ii = 0
		)
		
		ii += 1
		
		r = space + sPoly[i] + r
	)

	return (trimLeft r " ")
)

fn saveMtlLib p =
(
	for i in 1 to currentMaterialLibrary.count do deleteItem currentMaterialLibrary 1
	for i in objects where i.material != undefined do append currentMaterialLibrary i.material
	saveMaterialLibrary p
)

fn ungroupRecursive s = for i in s where isGroupHead i and isValidNode i do explodeGroup i
	
fn getColor r g b = (dotnetclass "System.Drawing.Color").FromArgb r g b

rollout _STEP1 "Model Packer"
(
	label lbl1 "Model Name:" align: #left across: 2  	
	dotNetControl lblWarn1 "System.Windows.Forms.Label" text: "*" offset: [-59, 0] width: 10	
	dotNetControl edtModelName "System.Windows.Forms.TextBox" height: 25 tabstop: true
	
	label lbl2 "Tags:" align: #left across: 2  	
	dotNetControl lblWarn2 "System.Windows.Forms.Label" text: "*" offset: [-95, 0] width: 10	
	dotNetControl edtModelTags "System.Windows.Forms.TextBox" height: 25 tabstop: true
	
	label lbl3 "Description:" align: #left across: 2  	
	dotNetControl lblWarn3 "System.Windows.Forms.Label" text: "*" offset: [-65, 0] width: 10	
	dotNetControl edtModelDesc "System.Windows.Forms.TextBox"  height: 200
	
	label lbl4 "Custom Attribute:" align: #left		
	dotNetControl edtModelCustom1 "System.Windows.Forms.TextBox" height: 25 tabstop: true
	
	group "Settings"
	(
		checkbox cbxCreateZip "Create ZIP" checked: true
	)
	
	button btnExport "Export" width: 244 height: 45 align: #left across: 2
	dotnetcontrol warnMsg "System.Windows.Forms.Button" height:0 width:0 offset: [0, 25]
	checkbox cbxConvertPBR "Convert to PBR" 
	
	fn initDotNet = 
	(
		warnLabels = #(lblWarn1, lblWarn2, lblWarn3)
		bg = getBgColor()
		txt = getTextColor()
				
		for i in warnLabels do 
		(
			i.backColor = bg
			i.foreColor = i.foreColor.red
		)		

		edtModelDesc.MultiLine = true
		edtModelDesc.scrollbars = (dotnetclass "System.Windows.Forms.ScrollBars").vertical		
		edtModelDesc.acceptsReturn = true
		edtModelDesc.acceptsTab = true
		edtModelDesc.wordWrap = true		
	)
	
	on edtModelDesc keyPress s a do
	(
		if(a.keyChar == "\r") do 
		(
			edtModelDesc.text += "\r\n"
			edtModelDesc.SelectionStart = (edtModelDesc.text.count)
		)
	)
	
	fn checkTexturesError =
	(
		errorTex = #()
		oldTex = #()
				
		for i in selection where i.material != undefined do
		(
			for type in BitmapTypes where classOf type == textureMap do
			(
				for b in getClassInstances type target:i where b != undefined do
				(
					try(b.coords.coords.realWorldScale = false)catch()
					try(b.coords.realWorldScale = false)catch()
					
					if(invalidBitmap b and findItem oldTex b == 0) then
					(										
						append errorTex #("empty file name path! Map: " + b.name, i.name) 
						append oldTex b
					)
					else if (validBitmap b and doesFileExist (getFullPath (b.filename)) == false) then
					(
						append errorTex #(b.filename, i.name) 
					)
				)
			)
		)
		
		if (errorTex.count > 0) do
		(
			m = "[" + localTime + "] : Error! Not found next textures. Please fix model and try again.\n\n"
			
			for er in errorTex do m += "Object: " + er[2] + "\nTexture: " + er[1] + "\n\n"
			
			messageBox m title: "Error!"
			
			return true
		)
		
		return false
	)
	
	fn copyMaps _selection szMaps szName = 
	(
		oldTex = #()
		oldTexPaths = #()
		toRename = #()
		iCnt = 1
				
		for i in _selection where i.material != undefined do
		(
			for type in BitmapTypes where classOf type == textureMap do 
			(	
				for b in getClassInstances type target:i where (validBitmap b) and findItem oldTex b == 0 do
				(																	
					f = getFullPath (b.filename)
				
					n = filenameFromPath f
					p = getFilenamePath f
					ext = getFilenameType f
										
					n = szName + "-" + (getNum iCnt) + ext
										
					if(doesFileExist f) do
					( 
						ep = findItem oldTexPaths b.filename
						
						if(ep != 0) then n = toRename[ep][5]
						
						append oldTex b
						append toRename #(b, (p + n), (szMaps + n), f, n) 
				
						if(ep == 0) do iCnt += 1
						append oldTexPaths b.filename
					)												
				)
			)
		)
							
		for t in toRename do
		(
			t[1].filename = @"maps\" + t[5]
			t[1].name = getFilenameFile t[5]
			
			copyFile t[4] t[3]
		)		
	)
	
	fn renameObjects szName = 
	(
		iCnt = 1
				
		for g in objects where isValidNode g do
		(
			n = g.name
			if(isGroupHead g and not (isGroupMember g)) then 
			(	
				n = szName + "-Group-001" 
			)
			else 
			(
				n = szName + "-" + (getNum iCnt) 
			)
			
			g.name = n
			iCnt += 1
		)
	)
	
	fn getMaterialDependence s type =
	(
		sceneMaps = #()
		
		for c in type.classes where c != undefined and findItem BitmapTypes c == 0 do 
		(		
			for g in s do
			(
				for m in getClassInstances c target:g where m != undefined do 
				(					
					appendIfUnique sceneMaps m
				)
			)
		)	
		
		return sceneMaps
	)
	
	fn renameMaterials szName = 
	(	
		oldMtl = #()
		iCnt = 1
						
		toRename = #()
		mat = getMaterialDependence selection material
		tex = getMaterialDependence selection textureMap	
		
		join toRename mat
		join toRename tex
				
		for i in toRename do 
		(
			i.name = szName + "-" + (getNum iCnt)
			iCnt += 1	
		)
	)
	
	fn removeLayers = 
	(
		layer0 = LayerManager.getLayer 0
		for i in objects do layer0.addNode i
	)
	
	fn copyIESfiles _selection szAssets szName = 
	(	
		global iIesCnt = 1
		
		fn copyIes ies szAssets szName =
		(
			if(ies == undefined) do return undefined
			
			ies = getFullPath ies
			
			if(not doesFileExist ies) do return ies
			
			n = filenameFromPath ies
			ext = getFilenameType ies
			
			f = szAssets  + "IES-" + szName + "-" + (getNum iIesCnt) + ext
			
			copyFile ies f
			
			iIesCnt += 1
			
			return f
		)
				
		for l in _selection where superClassOf l == light do
		(
			if(isProperty l #ies_file) do l.ies_file = copyIes (l.ies_file) szAssets szName
			if(isProperty l #webFile) do l.webFile = copyIes (l.webFile) szAssets szName
			if(isProperty l #iesFile) do l.iesFile = copyIes (l.iesFile) szAssets szName
		)		
	)
	
	fn setIniInfo f s k v = 
	(	
		-- Set correct ini setting for PHP
		v = substituteString v "\"" "'"
		v = substituteString v "\r\n" "\\r\\n"
		
		setIniSetting f s k ("\"" + v + "\"") 
	)
	
	fn geometryFix =
	(
		ungroupRecursive objects
		
		for i in objects where superClassOf i == GeometryClass do
		(			
			ResetXForm i
			convertToPoly i
		)
		
		o = AttachObj objects
		
		setPivot zpos:objects.min.z
		
		if(o != undefined) do o.pos = [0, 0, 0]
	)
	
	fn createInfo szDir =
	(
		f = szDir + "info.txt"
		v = getMaxVersion()
		r = getCurrRender()
		p = polyCount geometry
		d = getDim geometry
		u = getUnits()
							
		setIniInfo f "INFO" "TYPE" "model" 
		setIniInfo f "INFO" "NAME" sModelName 		
		setIniInfo f "INFO" "FORMAT" v[1] 
		setIniInfo f "INFO" "RENDER" r[2] 
		setIniInfo f "INFO" "POLYS" p 
		setIniInfo f "INFO" "UNITS" u 
		setIniInfo f "INFO" "DIMENSION" d 	
		setIniInfo f "INFO" "TAGS" sModelTags 
		setIniInfo f "INFO" "CUSTOM1" sModelCustom1 
		setIniInfo f "INFO" "DESC" sModelDesc 
	)
	
	on _STEP1 open do
	(	
		initDotNet()
	)
	
	on btnExport pressed do
	(
		sModelName = edtModelName.text
		sModelTags = edtModelTags.text
		sModelDesc = edtModelDesc.text
		sModelCustom1 = edtModelCustom1.text
		
		if(sModelName.count == 0) do return showTooltip edtModelName "Please enter correct model name!"
		if(sModelTags.count == 0) do return showTooltip edtModelTags "Please enter few tags!"
		if(sModelDesc.count == 0) do return showTooltip edtModelDesc "Please fill description!"
		
		if(not isValidText sModelName edtModelName) do return false 
		if(not isSelected()) do return showTooltip warnMsg "Please select model!"
					
		fileToLoad = maxFilePath + maxFileName
		if(fileToLoad.count < 1) do return showTooltip warnMsg "Please save scene!"	
			
		max file save
			
		_selection = selection as array 

		v = getMaxVersion()
		r = getCurrRender()	

		szName = stripName sModelName

		_gamma = getGamma()
		szOutName = szName + "_Gamma" + _gamma + r[1]
		szOutNamePBR = szName + "_PBR_Gamma2.2" + r[1]

		szDir = _SAVEPATH + szName + @"\"		
		szMaps = szDir + @"maps\"
		szAssets = szDir --+ @"assets\"
		szPreview = szDir --+ @"preview\"
		szExport = szDir --+ @"export\"
		szMtl = szMaps 	
		szInfo = szDir + "info.ini"

		makeDir szDir	
		makeDir szMaps	
		makeDir szAssets
		makeDir szPreview	
		makeDir szExport	
		makeDir szMtl	
		
		-- Set out zip
		szZip = _SAVEPATH + szOutName + ".zip"
		szMatLib = szMtl + szOutName + ".mat"
		szFBX = szExport + szOutName + ".fbx"
		szOBJ = szExport + szOutName + ".obj"
		szMAX = szDir + szOutName + ".max"
		szMAXPBR = szDir + szOutNamePBR + ".max"
		szMTL = szDir + szOutName + ".mtl"
		
		if(checkTexturesError()) do return false

		-- Copy maps		
		-- Some maps not copied in row (maxscript bug)	
		for i in 1 to 3 do copyMaps _selection szMaps szName

		copyIESfiles _selection szAssets szName			
		
		currentRender = renderers.current
		-- Save units
		SystemType = units.SystemType
		SystemScale = units.SystemScale 
		DisplayType = units.DisplayType	
		MetricType = units.MetricType
		
		-- Save Gamma
		colorCorrectionMode = IDisplayGamma.colorCorrectionMode
		displGamma = IDisplayGamma.gamma 
		
		
		saveNodes _selection (szDir + "_tmp.max") quiet:true
		resetMaxFile #noPrompt
		try(
			units.SystemType = SystemType
			units.SystemScale = SystemScale
			units.DisplayType	= DisplayType
			units.MetricType = MetricType
		)catch()
		
		IDisplayGamma.colorCorrectionMode = colorCorrectionMode 
		IDisplayGamma.gamma = displGamma
		
		-- Delete objects from default scene
		try(for o in objects where isValidNode o do delete o)catch()
		
		mergeMAXFile (szDir + "_tmp.max") #select #mergedups #renameMtlDups #noRedraw quiet:true			
		deleteFile (szDir + "_tmp.max")
		
		try(renderers.current = currentRender)catch()
		
		
		-- Check PBR
		isPBR = isMaterialsPBR()
		
		-- Attach to one object and place to center
		geometryFix()
		
		--
		select objects
		max tool zoomextents all
			
		-- Rename materials and objects
		renameObjects szName
		renameMaterials szName 
		removeLayers()
			
		maxFile = szMAX
		
		/*maxFile = case isPBR of
		(
			default: szMAX
			true: szMAXPBR
		)*/
		
		saveMaxFile szMAX saveAsVersion:(v[1] as integer) quiet:true
		
		saveMtlLib szMatLib	
				
		ungroupRecursive objects
		FBXExporterSetParam "FileVersion" "FBX201200"	-- Warning!! This option important!!		
		exportFile szFBX #noPrompt  --selectedOnly:true				
		exportFile szOBJ #noPrompt 
		
		-- Move MTL to maps folder
		copyFile szMTL (szMaps + szOutName + ".mtl")
		deleteFile szMTL
				
		deleteFile szZip
				
		-- PBR
		if(_gamma == "1.0" and cbxConvertPBR.checked) do
		(
			ConvertToPBR()
			saveMaxFile szMAXPBR saveAsVersion:(v[1] as integer) quiet:true
		)
				
		-- Zip maps
		zipper = zip()
		zipper.packFiles source: szMaps target: szDir name: "maps" del: true
		
		createInfo szDir
				
		if(cbxCreateZip.checked) do 
		(
			zipper = zip()
			zipper.packFiles source: szDir target: _SAVEPATH name: szOutName del: true
		)

		resetMaxFile #noPrompt
		loadMaxFile fileToLoad useFileUnits: true quiet:true		
		
		q = queryBox "Model packed success!\nDo you want to open containing folder?" title: "Success!"
		if(q) do shellLaunch _SAVEPATH ""	
	)
)

rollout _rAbout "About" 
(
	label lblName "" 
	label lblVer "" 
	
	label lblAuthor "" height: 30
	label lblCopy ""  height: 30
	
	local c = color 200 200 200 
	hyperLink href1 "http://3dground.net/" address: "http://3dground.net/" align: #center hoverColor: c visitedColor: c offset: [0, 20]
	
	on _rAbout open do
	(		
		i = getScriptInfo (getThisScriptFilename())
			
		lblName.caption = i[1]
		lblAuthor.caption = i[2]
		lblVer.caption = i[3]
		lblCopy.caption = i[6]
	)
)

addRollout _STEP1 rModelPacker 
--addRollout _rAbout rModelPacker rolledUp:true 