fs = require('fs');
zipUtility = require('./zipCodeUtility')
###
log = ''
logError = ''
logEle = ''
###

###
將郵局資料insert入DB時,將X之X號轉換為X.X號入DB
scope = 郵局資料中scope資料
###
exports.convertScopeDashToPoint = (scope) ->
	return scope	unless scope.match('之')
	regex = [/\d+之\d+至之\d+號/, /\d+之\d+[號巷]/]
	if regex[0].test(scope)
		dashInt = /\d+之/.exec(scope).toString().replace(/[^\d]/g, '')
		dashPoint = /之\d+至/.exec(scope).toString().replace(/[^\d]/g, '')
		scope = scope.replace(/之\d+至/, (dashPoint / 1000 + '號至').slice(1))
		dashPoint = /至之\d+號/.exec(scope).toString().replace(/[^\d]/g, '')
		scope = scope.replace(/之\d+/, dashInt + (dashPoint / 1000).toString().slice(1))
	else
		while regex[1].test(scope)
			dashPoint = /之\d+[號巷]/.exec(scope).toString().replace(/[^\d]/g, '')
			scope = scope.replace(/之\d+/, (dashPoint / 1000).toString().slice(1))
	scope

###
將郵局資料insert入DB時,將scope分為lane,alley,no,floor.
每種又分為[單雙連全],最大值,最小值
scope = 郵局資料中scope資料
number = 第n筆資料
###
exports.decomposeScope = (scope, number) ->	
	num = 0
	scopeArrayName = ['巷', '弄', '號', '樓']
	scopeEle = new Array()

	i = 0
	while i < 4
		scopeEle[i] = new Array()
		scopeEle[i][0]=scopeEle[i][1]=scopeEle[i][2]=''
		i++
	scope = this.convertScopeDashToPoint scope
	regex = [
		/[單雙連].+至.*以[上下]$/		# case 1, X 至 X 以上下, it's strange, change to X 至 X, include 單雙連 
		/至.*以[上下]$/		# case 2, X 至 X  Y Floor 以上下, it's strange, change to X 至 X , no 單雙連
		/[單雙連].+至/		# case 3, X 至 X include 單雙連	,deal with 含附號全
		/^[\d\.巷弄號樓]+至/		# case 4, X 至 X no 單雙連
		/[單雙連].*以[上下]$/		# case 5, X 以上下 include 單雙連	,deal with 含附號以下
		/.*樓以[上下]$/		# case 6, X 以上下 no 單雙連,only for 樓
		/^[\d\.巷弄號樓]+[全單雙][全]?$/		# case7, X巷X弄[全單雙]
		/^[\d\.巷弄號樓]+$/		#case8, X巷X弄X號X樓
		/^[全單雙][全]?$/		#case9, just全單雙	
		/號及以上附號/		#case10, X號及以上附號
		/附號/		#case11, such as 號含附號, 附號全
		/號\(.*\)/ #case12, like X 號(XXXXX)
	]
	
	#判斷符合規則種類,選擇處理方式
	i = 0
	while i < regex.length
		if regex[i].test scope
			num = i + 1
			break
		i++
	#console.log 'num = ' + num + '; reg = ' + regex[num - 1]
	#console.log scope
	#log = log + number + ' : case' + num + ': ' + scope+ '\n'
	#處理範圍資料,將其分為巷弄號樓 並分為 種類(單雙連) 最大 最小
	switch num
		when 1 , 3 #	/[單雙連].+至/
			tmpOdevity = scopeEleMinNum = scopeEleMaxNum = undefined
			if /^[\d\.巷弄號樓]+/.test scope
				scopePartA = /^[\d\.巷弄號樓]+/.exec(scope)[0].toString()
				scope = scope.slice scopePartA.length 
				setScopeEle scopePartA, scopeArrayName, scopeEle, 'setBoth', (scopeEleVal, odevityVal, scopeEleNumVal) ->
					scopeEle = scopeEleVal
			#console.log scope
			scopePartB = /^[單雙連]\d+\.?\d*\D至/.exec(scope)[0].toString()
			scope = scope.slice scopePartB.length 
			setScopeEle scopePartB, scopeArrayName, scopeEle, 'setMin', (scopeEleVal, odevityVal, scopeEleNumVal) ->
				scopeEle = scopeEleVal
				tmpOdevity = odevityVal
				scopeEleMinNum = scopeEleNumVal

			scopePartC = /^\d+\.?\d*[巷弄號樓](含附號)?/.exec(scope)[0].toString()
			scope = scope.slice scopePartC.length 
			setScopeEle scopePartC, scopeArrayName, scopeEle, 'setMax', (scopeEleVal, odevityVal, scopeEleNumVal) ->
				scopeEleVal[scopeEleNumVal][2] = scopeEleVal[scopeEleNumVal][2] + '.999'	if /含附號/.test(scopePartC)
				scopeEle = scopeEleVal
				scopeEleMaxNum = scopeEleNumVal

			if scopeEleMinNum < scopeEleMaxNum then scopeEle[scopeEleMinNum][0] = tmpOdevity else scopeEle[scopeEleMaxNum][0] = tmpOdevity

		when 2 , 4 #
			if /\d+至\d+樓$/.test scope 
				scope = scope.replace '至', '樓至' 
				scopePartA = /\d+\.?\d*號/.exec(scope)[0].toString()
				scope = scope.slice scopePartA.length 
				setScopeEle scopePartA, scopeArrayName, scopeEle, 'setBoth', (scopeEleVal, odevityVal, scopeEleNumVal) ->
					scopeEle = scopeEleVal
			#console.log scope
			scopePartB = /\d+\.?\d*\D至/.exec(scope)[0].toString()
			scope = scope.slice scopePartB.length 
			#console.log scope
			setScopeEle scopePartB, scopeArrayName, scopeEle, 'setMin', (scopeEleVal, odevityVal, scopeEleNumVal) ->
				scopeEleVal[scopeEleNumVal][0] = '連'
				scopeEle = scopeEleVal
			scopePartC = /^\d+\.?\d*[巷弄號樓](含附號)?/.exec(scope)[0].toString()
			#console.log scopePartC
			scope = scope.slice scopePartC.length 
			setScopeEle scopePartC, scopeArrayName, scopeEle, 'setMax', (scopeEleVal, odevityVal, scopeEleNumVal) ->
				scopeEle = scopeEleVal

		when 5 # 
			return null if /以[上下].*以[上下]/.test scope	#for 單3號以下2樓以上 no process
			if /^[\d\.巷弄號樓]+/.test scope 
				scopePartA = /^[\d\.巷弄號樓]+/.exec(scope)[0].toString()
				scope = scope.slice scopePartA.length 
				setScopeEle scopePartA, scopeArrayName, scopeEle, 'setBoth', (scopeEleVal, odevityVal, scopeEleNumVal) ->
					scopeEle = scopeEleVal
			scopePartB = /^[單雙連].*以[上下]/.exec(scope)[0].toString()
			scope = scope.slice scopePartB.length 
			if /以下$/.test scopePartB 
				setScopeEle scopePartB, scopeArrayName, scopeEle, 'setMax', (scopeEleVal, odevityVal, scopeEleNumVal) ->
					scopeEleVal[scopeEleNumVal][2] = scopeEleVal[scopeEleNumVal][2] + '.999'	if /含附號/.test scopePartB 
					scopeEleVal[scopeEleNumVal][0] = odevityVal
					scopeEle = scopeEleVal
			else if /以上$/.test scopePartB 
				setScopeEle scopePartB, scopeArrayName, scopeEle, 'setMin', (scopeEleVal, odevityVal, scopeEleNumVal) ->
					scopeEleVal[scopeEleNumVal][0] = odevityVal
					scopeEle = scopeEleVal

		when 6 #
			if /^[\d\.巷弄]+[號]/.test scope 
				scopePartA = /^[\d\.巷弄]+[號]/.exec(scope)[0].toString()
				scope = scope.slice scopePartA.length 
				setScopeEle scopePartA, scopeArrayName, scopeEle, 'setBoth', (scopeEleVal, odevityVal, scopeEleNumVal) ->
					scopeEle = scopeEleVal
			scopePartB = /\d+樓以[上下]/.exec(scope)[0].toString()
			scope = scope.slice scopePartB.length 
			if /以下$/.test scopePartB
				setScopeEle scopePartB, scopeArrayName, scopeEle, 'setMax', (scopeEleVal, odevityVal, scopeEleNumVal) ->
					scopeEleVal[scopeEleNumVal][0] = '連'
					scopeEleVal[scopeEleNumVal][2] = scopeEleVal[scopeEleNumVal][2] + '.999'	if /含附號/.test scopePartB 
					scopeEle = scopeEleVal
			else if /以上$/.test scopePartB
				setScopeEle scopePartB, scopeArrayName, scopeEle, 'setMin', (scopeEleVal, odevityVal, scopeEleNumVal) ->
					scopeEleVal[scopeEleNumVal][0] = '連'
					scopeEle = scopeEleVal

		when 7 #
			scopeEleNum = undefined
			scopePartA = /[\d\.巷弄號樓]+(含附號)?/.exec(scope)[0].toString()
			scope = scope.slice scopePartA.length
			setScopeEle scopePartA, scopeArrayName, scopeEle, 'setBoth', (scopeEleVal, odevityVal, scopeEleNumVal) ->
				scopeEleVal[scopeEleNumVal][2] = scopeEleVal[scopeEleNumVal][2] + '.999'	if /含附號/.test scopePartA 
				scopeEleNum = scopeEleNumVal
				scopeEle = scopeEleVal
			#console.log scope
			scopePartB = /^[單雙全][全]?$/.exec(scope)[0].toString()
			scope = scope.slice scopePartB.length
			scopeEle[parseInt(scopeEleNum)+1][0] = scopePartB.slice 0, 1	if scopeEleNum < 3 && scopePartB.slice(0, 1) isnt '全' # except such as 2樓全

		when 8 #
			scopePartA = /^[\d\.巷弄號樓]+$/.exec(scope)[0].toString()
			scope = scope.slice scopePartA.length
			setScopeEle scopePartA, scopeArrayName, scopeEle, 'setBoth', (scopeEleVal, odevityVal, scopeEleNumVal) ->
				scopeEle = scopeEleVal

		when 9 #
			scopePartA = /^[全單雙][全]?/.exec(scope)[0].toString()
			scope = scope.slice scopePartA.length
			scopeEle[0][0] = scopePartA.slice 0, 1

		when 10 #
			scopePartA = /^\d+\.*\d+號及以上附號/.exec(scope)[0].toString()
			scope = scope.slice scopePartA.length
			setScopeEle scopePartA, scopeArrayName, scopeEle, 'setMin', (scopeEleVal, odevityVal, scopeEleNumVal) ->
				scopeEleVal[scopeEleNumVal][0] = '連'
				scopeEleVal[scopeEleNumVal][2] = parseInt(scopeEleVal[scopeEleNumVal][1]) + '.999'
				scopeEle = scopeEleVal

		when 11 #
			scope = scope.replace '附號全', '號含附號' if /^\d+附號全$/.test scope
			scopePartA = /^[\d\.巷弄號]+含附號[全]?/.exec(scope)[0].toString()
			scope = scope.slice scopePartA.length
			setScopeEle scopePartA, scopeArrayName, scopeEle, 'setMin', (scopeEleVal, odevityVal, scopeEleNumVal) ->
				scopeEleVal[scopeEleNumVal][0] = '連'
				scopeEleVal[scopeEleNumVal][2] = scopeEleVal[scopeEleNumVal][1] + '.999'
				scopeEle = scopeEleVal

		when 12 #
			scopePartA = /^\d+號\(.*\)/.exec(scope)[0].toString()
			scope = scope.slice scopePartA.length
			setScopeEle scopePartA, scopeArrayName, scopeEle, 'setBoth', (scopeEleVal, odevityVal, scopeEleNumVal) ->
				scopeEle = scopeEleVal

		else
			console.log number + ' : case' + num + ': ' + scope+ '\n'
			return null
			#fs.appendFile 'default.txt', 'case' + num + ': ' + scope+ '\n'
			#logError = logError + number + ' : case' + num + ': ' + scope+ '\n'
			#console.log 'no process'

	#logEle = logEle + number + ' :' + scopeEle + '\n'
	#console.log 'case' + num + ': ' + scopeEle
	#if scope.length > 0 then console.log 'abbondonScope = ' + scope + ' regexNum = ' + num
	#if scope.length > 0 then log = log + number + ' : abbondonScope = ' + scope + ' regexNum = ' + num + '\n'
	scopeEle

###
將地址分解各個元素,有縣市,鄉鎮區,路,巷,弄,號,樓
addr = 地址
###
exports.decomposeAddr = (addr) ->
	city = area = road = lane = alley = noNum = floor = ''
	regex =  /^..[市縣]/
	if regex.test addr
		city = regex.exec(addr).toString()
		addr = addr.split(regex)[1]
	regex = /^\D+市區|^\D+鎮區|^\D+鎮市|^\D區|^\D{2}[市鎮區鄉]|^\D{3}[區鄉島]/
	if regex.test addr
		area = regex.exec(addr).toString()
		addr = addr.split(regex)[1]
	#將大寫數字變更為小寫,國字變更為數字,去空白,處理-~to之
	addr = zipUtility.numberFullToHalf addr
	addr = zipUtility.chineseToNum addr
	addr = zipUtility.trimAndReplaceDash addr

	regex = /^\D+/
	if regex.test addr
		road = regex.exec(addr).toString()
		addr = addr.split(regex)[1]
	regex = /\D\d/
	i = 0
	while not zipUtility.isMatchScopeRule addr
		if regex.test addr
			seperate = addr.indexOf(regex.exec(addr).toString()) + 1
			road = road + zipUtility.numberToChinese(addr.slice(0, seperate))
			addr = addr.slice seperate
		i++
		break	if i == 5
	i = 0
	scopeArrayName = ['巷', '弄', '號']
	while i < scopeArrayName.length
		scopeName = scopeArrayName[i]
		regex = new RegExp('^\\d+-\\d+' + scopeName)
		if regex.test addr
			dashVal = addr.substring(addr.indexOf('-') + 1, addr.indexOf(scopeName))
			dashValThousandth = (dashVal / 1000).toString().slice(1)
			addr = addr.replace('-' + dashVal, dashValThousandth)
		regex = new RegExp('^\\d+\\.?\\d*' + scopeName)
		if regex.test addr
			switch i
				when 0 #郵遞區號判斷規則僅有號需要有X之Y號來判斷,其餘如X之巷僅需X巷判斷即可
					lane = parseInt(regex.exec(addr).toString().split('巷')[0]) + ''
				when 1
					alley = parseInt(regex.exec(addr).toString().split('弄')[0]) + ''
				when 2
					noNum = regex.exec(addr).toString().split('號')[0]
			addr = addr.split(regex)[1]
		i++

	regex = /^\d+-?\d*[Ff樓]/
	if regex.test addr
		regex = /[Ff樓-]/
		floor = addr.split(regex)[0]
		addr = addr.split(regex)[1]

	addrElement = {
		city: city
		area: area
		road: road
		lane: lane
		alley: alley
		no: noNum
		floor: floor
	}

	addrElement

###
將scope資料填入陣列中
scopePart = scope資料
scopeArrayName = 巷,弄,號,樓
scopeEle = 處理過的scope元素
type = 設定最大最小值或兩者兼有(setMax,setMin,setBoth)
callback return 
	1.scopeEle = 處理過的scope元素
	2.odevity = 處理scope後留下的[單雙連]
	3.sopeEleNum = 此次處理最小處理到[巷號弄樓](0123),通常用於設定[單雙連]應填入哪個陣列欄位中
###
setScopeEle = (scopePart, scopeArrayName, scopeEle, type, callback) ->
	odevity = /^[單雙連]/.exec(scopePart).toString()	if /^[單雙連]/.test scopePart
	scopeEleNum = undefined
	for i of scopeArrayName
		if scopePart.match(scopeArrayName[i])
			scopeEleReg = new RegExp('\\d+\\.?\\d*' + scopeArrayName[i])
			scopeEleVal = scopeEleReg.exec(scopePart).toString().replace(scopeArrayName[i], '')
			if type is 'setBoth'
				scopeEle[i][1] = scopeEle[i][2] = scopeEleVal
			else if type is 'setMin'
				scopeEle[i][1] = scopeEleVal
			else if type is 'setMax'
				scopeEle[i][2] = scopeEleVal	
			scopeEleNum = i
	callback scopeEle, odevity, scopeEleNum

###
將剩下的地址,區分為road與scope時使用.
確認剩餘的地址符合scope的規則
addr = address
###
exports.isMatchScopeRule = (addr) ->
	regArray = [
		/^\d+-?\d*巷\d+弄\d+-?\d*號/
		/^\d+-?\d*巷\d+-?\d*[弄號]/
		/^\d+弄\d+-?\d*號/
		/^\d+-?\d*[號弄巷]/
		/^\d+-/
	]

	i = 0
	while i < regArray.length
		return true if regArray[i].test addr
		i++
	false


###
將大寫數字轉換為小寫數字
str = 欲轉換字串
###
exports.numberFullToHalf = (str) ->
	result = ''
	if !str || str == ''
		return ''
	else
		i = 0
		while i < str.length
			if str.charCodeAt(i) == 12288
				result += " "
			else
				if(str.charCodeAt(i) > 65280 && str.charCodeAt(i) < 65375)
					result += String.fromCharCode(str.charCodeAt(i) - 65248)
				else
					result += String.fromCharCode(str.charCodeAt(i));
			i++
	result

###
將數字轉為國字
由於地址大多僅處理至十,像是ROAD中的 新北市,石碇區,18重溪,
故轉換時,需針對兩位的數字針對時去做處理
str = 欲轉換字串
###
exports.numberToChinese = (str) ->
	result = ''
	chineseNum = '〇一二三四五六七八九'.split('')
	if !str || str == ''
		return ''
	else
		regex = /\D\d{2}\D|^\d{2}\D|^\d{2}$|\D\d{2}$/
		while regex.test str
			source = regex.exec(str).toString()
			if /10/.test source
				dest = source.replace('10','十')
			else if /1\d/.test source
				dest = source.replace('1','十')
			else if /\d0/.test source
				dest = source.replace('0','十')
			else if /^\d{2}\D/.test source
				dest = source.slice(0, 1) + '十' + source.slice(1)
			else
				dest = source.slice(0, 2) + '十' + source.slice(2)
			str = str.replace source, dest
	i = 0
	while i < str.length
		if str.charCodeAt(i) > 47 && str.charCodeAt(i) < 58
			strNum = String.fromCharCode(str.charCodeAt(i))
			result += chineseNum[strNum]
		else
			result += String.fromCharCode(str.charCodeAt(i))
		i++
	result

###
將國字轉回為數字
由於地址大多僅處理至十,像是ROAD中的 新北市,石碇區,18重溪,
故轉換時,需針對兩位的數字針對時去做處理
str = 欲轉換字串
###
exports.chineseToNum = (str) ->
	regex = /[〇ㄧ一二三四五六七八九]/
	while regex.test(str)
		str = str.replace '〇','0' 
		str = str.replace '一','1'
		str = str.replace 'ㄧ','1'
		str = str.replace '二','2'
		str = str.replace '三','3'
		str = str.replace '四','4'
		str = str.replace '五','5'
		str = str.replace '六','6'
		str = str.replace '七','7'
		str = str.replace '八','8'
		str = str.replace '九','9'
	regex = /十/
	if regex.test(str)
		while /\d十\d/.test(str)
			str = str.replace '十', ''
		while /\d十/.test(str)
			str = str.replace '十', '0'
		while /十\d/.test(str)
			str = str.replace '十', '1'
		while /十/.test(str)
			str = str.replace '十', '10'
	str

###
將字串中的空白去除,將~﹣～之,都轉換為-以利後續判斷
str = 欲轉換字串
###
exports.trimAndReplaceDash = (str) ->
	regex =  /[～﹣ ~]/;
	while regex.test str
		str = str.replace ' ', ''
		str = str.replace '～', '-'
		str = str.replace '﹣', '-'
		str = str.replace '~', '-'
	regex =  /\d之/
	while regex.test str
		seperate = str.indexOf(regex.exec(str).toString()) + 1
		str = str.replace(str.substr(seperate, 1), '-')
	str

###
取得符合條件的zipData
zipData = 從資料庫撈出符合city,area,road條件的scope資料
addrElement = user所輸入地址處理後之元素
###
exports.getMatchZipData = (zipData, addrElement) ->
	for i of zipData
		matchZipData = zipData[i]	if zipUtility.isInZipDataScope(zipData[i], addrElement)
	matchZipData

###
###
exports.isInZipDataScope = (zipData, addrElement) ->
	addrContrast = addrElement.lane || addrElement.alley || addrElement.no

	if zipData.laneMin isnt '' and zipData.laneMin == zipData.laneMax
		return false	if zipData.laneMin isnt addrElement.lane
		addrContrast = addrElement.alley || addrElement.no
	if zipData.alleyMin isnt '' and zipData.alleyMin == zipData.alleyMax
		return false	if zipData.alleyMin isnt addrElement.alley
		addrContrast = addrElement.no
	if zipData.noMin isnt '' and zipData.noMin == zipData.noMax
		return false	if zipData.noMin isnt addrElement.no
		addrContrast = addrElement.floor
	if zipData.floorMin isnt '' and zipData.floorMin == zipData.floorMax
		return false	if zipData.floorMin isnt addrElement.floor

	min = zipData.laneMin || zipData.alleyMin || zipData.noMin
	max = zipData.laneMax || zipData.alleyMax || zipData.noMax
	if zipData.laneOdevity
		console.log zipData
		console.log zipUtility.isMatchOdevityAndRange zipData.noOdevity, min, max, addrContrast
		return zipUtility.isMatchOdevityAndRange zipData.laneOdevity, min, max, addrContrast
	else if !(max || min)
		return true

	min = zipData.alleyMin || zipData.noMin
	max = zipData.alleyMax || zipData.noMax
	if zipData.alleyOdevity
		console.log zipData
		console.log zipUtility.isMatchOdevityAndRange zipData.noOdevity, min, max, addrContrast
		return zipUtility.isMatchOdevityAndRange zipData.alleyOdevity, min, max, addrContrast
	else if !(max || min)
		return true

	min = zipData.noMin
	max = zipData.noMax
	if zipData.noOdevity
		console.log zipData
		console.log zipUtility.isMatchOdevityAndRange zipData.noOdevity, min, max, addrContrast
		return zipUtility.isMatchOdevityAndRange zipData.noOdevity, min, max, addrContrast
	else if !(max || min)
		return true
	
	min = zipData.floorMin
	max = zipData.floorMax
	if zipData.floorOdevity
		return zipUtility.isMatchOdevityAndRange zipData.floorOdevity, min, max, addrElement.floor
	else if !(max || min)
		return true

	console.log 'end '




exports.isMatchOdevityAndRange = (odevity, min, max, addrElement) ->
	result = zipUtility.isInRange(min, max, addrElement)
	if odevity is '全'
		return true
	else if not addrElement?
		return false
	else if odevity is '單'
		return false if parseInt(addrElement) % 2 is 0
		return result
	else if odevity is '雙'
		return false if parseInt(addrElement) % 2 isnt 0
		return result
	else if odevity is '連'
		return result
	return false

exports.isInRange = (min, max, addrElement) ->
	min = parseFloat min if min isnt ''
	max = parseFloat max if max isnt ''
	addrElement = parseFloat addrElement if addrElement isnt ''
	if min is '' and max is ''
		return true
	else if not addrElement? || addrElement is ''
		return false
	else if min <= addrElement and max >= addrElement
		return true
	else if min is '' and max >= addrElement
		return true
	else if max is '' and min <= addrElement
		return true
	else
		false
###
test = () ->
	i = 0
	fileData = fs.readFileSync('tmpData/zip5.data','utf8')
	addrDatas = fileData.split('\n');
	while i < addrDatas.length - 1
		addrData = addrDatas[i].split(',')
		scope = addrData[4]
		mine.decomposeScope scope, i
		i++
	fs.appendFile 'default.txt', logError 
	fs.appendFile 'log.txt', log 
	fs.appendFile 'logEle.txt', logEle 
###


