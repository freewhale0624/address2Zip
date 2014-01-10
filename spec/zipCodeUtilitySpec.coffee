zipUtility = require "../zipCodeUtility.js"

describe "convertScopeDashToPoint", ->
  it "revert X dash Y to dash Z no >> X.Y no to X.Z no", ->
    expect(zipUtility.convertScopeDashToPoint "10之2至之9號").toEqual "10.002號至10.009號"

  it "revert X dash Y no >> X.Y no", ->
    expect(zipUtility.convertScopeDashToPoint "923之112號").toEqual "923.112號"

  it "revert X dash Y lane >> X.Y lane", ->
    expect(zipUtility.convertScopeDashToPoint "102之21巷").toEqual "102.021巷"

  it "besides no change", ->
    expect(zipUtility.convertScopeDashToPoint "102至之9號").toEqual "102至之9號"


describe "decomposeScope", ->
	it "[單雙連].+至.*以[上下]$ decompose", ->	#case1
		expect(zipUtility.decomposeScope("單101號至111號2樓以上")).toEqual [['','',''],['','',''],['單','101','111'],['','','']]
		expect(zipUtility.decomposeScope("連212號至220號4樓以上")).toEqual [['','',''],['','',''],['連','212','220'],['','','']]
		expect(zipUtility.decomposeScope("97號地下1樓")).toEqual [['','',''],['','',''],['','97','97'],['','','']]
		
	it "至.*以[上下]$ decompose", ->	#case2
		expect(zipUtility.decomposeScope("79.001號至79.01號4樓以上")).toEqual [['','',''],['','',''],['連','79.001','79.01'],['','','']]

	it "[單雙連].+至 decompose", ->	#case3
		expect(zipUtility.decomposeScope("連501號至533號")).toEqual [['','',''],['','',''],['連','501','533'],['','','']]
		expect(zipUtility.decomposeScope("單449巷至451號含附號全")).toEqual [['單','449',''],['','',''],['','','451.999'],['','','']]
		expect(zipUtility.decomposeScope("單47號至69巷")).toEqual [['單','','69'],['','',''],['','47',''],['','','']]
		expect(zipUtility.decomposeScope("23巷連5.003號至5.006號")).toEqual [['','23','23'],['','',''],['連','5.003','5.006'],['','','']]
		expect(zipUtility.decomposeScope("單103.006號至105號含附號全")).toEqual [['','',''],['','',''],['單','103.006','105.999'],['','','']]
		expect(zipUtility.decomposeScope("雙980號至1148巷")).toEqual [['雙','','1148'],['','',''],['','980',''],['','','']]

	it "^[\d\.巷弄號樓]+至 decompose", ->	#case4
		expect(zipUtility.decomposeScope("1.01號至1.053號")).toEqual [['','',''],['','',''],['連','1.01','1.053'],['','','']]
		expect(zipUtility.decomposeScope("5號5至9樓")).toEqual [['','',''],['','',''],['','5','5'],['連','5','9']]

	it "[單雙連].*以[上下]$ decompose", ->	#case5
		expect(zipUtility.decomposeScope("雙194號以上")).toEqual [['','',''],['','',''],['雙','194',''],['','','']]
		expect(zipUtility.decomposeScope("連130號含附號以下")).toEqual [['','',''],['','',''],['連','','130.999'],['','','']]
		expect(zipUtility.decomposeScope("110巷97弄連24號以下")).toEqual [['','110','110'],['','97','97'],['連','','24'],['','','']]

	it ".*樓以[上下]$ decompose", ->	#case6
		expect(zipUtility.decomposeScope("12號3樓以上")).toEqual [['','',''],['','',''],['','12','12'],['連','3','']]
		expect(zipUtility.decomposeScope("48巷25號4樓以下")).toEqual [['','48','48'],['','',''],['','25','25'],['連','','4']]

	it "^[\d\.巷弄號樓]+[全單雙][全]?$ decompose", ->		#case7
		expect(zipUtility.decomposeScope("53巷8弄全")).toEqual [['','53','53'],['','8','8'],['','',''],['','','']]
		expect(zipUtility.decomposeScope("199巷雙全")).toEqual [['','199','199'],['雙','',''],['','',''],['','','']]

	it "^[\d\.巷弄號樓]+$ decompose", ->	#case8
		expect(zipUtility.decomposeScope("199巷5號")).toEqual [['','199','199'],['','',''],['','5','5'],['','','']]
		expect(zipUtility.decomposeScope("339巷6弄4號")).toEqual [['','339','339'],['','6','6'],['','4','4'],['','','']]

	it "^[全單雙][全]?$ decompose", ->	#case9
		expect(zipUtility.decomposeScope("雙全")).toEqual [['雙','',''],['','',''],['','',''],['','','']]

	it "號及以上附號 decompose", ->	#case10
		expect(zipUtility.decomposeScope("164.007號及以上附號")).toEqual [['','',''],['','',''],['連','164.007','164.999'],['','','']]

	it "附號 decompose", ->	#case11
		expect(zipUtility.decomposeScope("1號含附號")).toEqual [['','',''],['','',''],['連','1','1.999'],['','','']]
		expect(zipUtility.decomposeScope("69附號全")).toEqual [['','',''],['','',''],['連','69','69.999'],['','','']]

	it "號(XXXXX) decompose", ->	#case12
		expect(zipUtility.decomposeScope("240號(彰化地方法院)")).toEqual [['','',''],['','',''],['','240','240'],['','','']]

describe "numberFullToHalf", ->
	it "revrt full to half", ->
		expect(zipUtility.numberFullToHalf "１２３４５６７８９０").toEqual "1234567890"
		expect(zipUtility.numberFullToHalf "中山北路１段").toEqual "中山北路1段"
	it "no number to revrt, keep same", ->
		expect(zipUtility.numberFullToHalf "中山北路").toEqual "中山北路"


describe "numberToChinese", ->
	it "revert str's number to chinese", ->
		expect(zipUtility.numberToChinese "中山11北路11段").toEqual "中山十一北路十一段"
		expect(zipUtility.numberToChinese "中山10北路10段").toEqual "中山十北路十段"
		expect(zipUtility.numberToChinese "中山21北路21段").toEqual "中山二十一北路二十一段"
		expect(zipUtility.numberToChinese "22段22").toEqual "二十二段二十二"

describe "chineseToNum", ->
	it "revert str's chinese to number", ->
		expect(zipUtility.chineseToNum "中山十一北路十一段").toEqual "中山11北路11段"
		expect(zipUtility.chineseToNum "中山十北路十段").toEqual "中山10北路10段"
		expect(zipUtility.chineseToNum "中山二十一北路二十一段").toEqual "中山21北路21段"
		expect(zipUtility.chineseToNum "二十二段二十二").toEqual "22段22"

describe "trimAndReplaceDash", ->
	it "trim space and replact some symbol to dash", ->
		expect(zipUtility.trimAndReplaceDash "中山北路﹣~～ 11 段").toEqual "中山北路---11段"
		expect(zipUtility.trimAndReplaceDash "中山北路10之10段").toEqual "中山北路10-10段"

describe "isMatchScopeRule", ->
	it "check rest of addreess is match scope rule", ->
		expect(zipUtility.isMatchScopeRule "五段45號8樓之3").toBeFalsy()
		expect(zipUtility.isMatchScopeRule "45號8樓之3").toBeTruthy()

describe "decomposeAddr", ->
	it "decompose Addr to AddrElement", ->
		addrEle = {city: '新北市',area: '新店區',road: '二十張路',lane: '129',alley: '5',no: '6',floor: ''}
		expect(zipUtility.decomposeAddr "新北市新店區二十張路129巷5弄6號").toEqual addrEle
		addrEle = {city: '台北市',area: '',road: '南京東路五段',lane: '',alley: '',no: '45',floor: '8'}
		expect(zipUtility.decomposeAddr "台北市南京東路五段45號8樓之3").toEqual addrEle
		addrEle = {city: '台北市',area: '',road: '南京東路五段',lane: '',alley: '',no: '',floor: ''}
		expect(zipUtility.decomposeAddr "台北市南京東路五段45").toEqual addrEle
		addrEle = {city: '台北市',area: '',road: '南京東路五段',lane: '45',alley: '',no: '6',floor: ''}
		expect(zipUtility.decomposeAddr "台北市南京東路五段45~3巷6號").toEqual addrEle

describe "isInRange", ->
	it "AddrElement is in the range of min and max", ->
		expect(zipUtility.isInRange '','','').toBeTruthy()
		expect(zipUtility.isInRange '1','321','92').toBeTruthy()
		expect(zipUtility.isInRange '','30','8').toBeTruthy()
		expect(zipUtility.isInRange '9','','11').toBeTruthy()
		expect(zipUtility.isInRange '','3','').toBeFalsy()

describe "isMatchOdevityAndRange", ->
	it "check AddrElement is match Odevity and in range", ->
		expect(zipUtility.isMatchOdevityAndRange '全', '', '', '5').toBeTruthy()
		expect(zipUtility.isMatchOdevityAndRange '單', '11', '77', '5').toBeFalsy()
		expect(zipUtility.isMatchOdevityAndRange '雙', '1', '71', '15').toBeFalsy()
		expect(zipUtility.isMatchOdevityAndRange '連', '1', '18', '5').toBeTruthy()
		expect(zipUtility.isMatchOdevityAndRange '連', '1', '8', '').toBeFalsy()
		expect(zipUtility.isMatchOdevityAndRange '', '1', '8', '5').toBeFalsy()
		expect(zipUtility.isMatchOdevityAndRange '雙', '386', '642', '4').toBeFalsy()

describe "isInZipDataScope", ->
	it "check AddrElement is match zipData", ->
		zipData = {zipCode: '10043',city: '台北市',area: '中正區',road: '中華路１段',laneOdevity: '',laneMin: '',laneMax: '',alleyOdevity: '',alleyMin: '',alleyMax: '',noOdevity: '單',noMin: '',noMax: '25.003',floorOdevity: '',floorMin: '',floorMax: ''}
		addrEle = {city: '台北市',area: '中正區',road: '中華路１段',lane: '',alley: '',no: '23.005',floor: ''}
		expect(zipUtility.isInZipDataScope zipData, addrEle).toBeTruthy()
		zipData = {zipCode: '40343',city: '台中市',area: '西區',road: '懷寧街',laneOdevity: '',laneMin: '155',laneMax: '155',alleyOdevity: '',alleyMin: '',alleyMax: '',noOdevity: '雙',noMin: '',noMax: '4',floorOdevity: '',floorMin: '',floorMax: ''}
		addrEle = {city: '台中市',area: '西區',road: '懷寧街',lane: '155',alley: '',no: '1',floor: ''}
		expect(zipUtility.isInZipDataScope zipData, addrEle).toBeFalsy()
		zipData = {zipCode: '40343',city: '台中市',area: '西區',road: '懷寧街',laneOdevity: '',laneMin: '155',laneMax: '155',alleyOdevity: '',alleyMin: '',alleyMax: '',noOdevity: '雙',noMin: '',noMax: '4',floorOdevity: '',floorMin: '',floorMax: ''}
		addrEle = {city: '台中市',area: '西區',road: '懷寧街',lane: '155',alley: '',no: '2',floor: ''}
		expect(zipUtility.isInZipDataScope zipData, addrEle).toBeTruthy()
		zipData = {zipCode: '10068',city: '台北市',area: '中正區',road: '和平西路２段',laneOdevity: '',laneMin: '104',laneMax: '104',alleyOdevity: '',alleyMin: '',alleyMax: '',noOdevity: '',noMin: '131',noMax: '131',floorOdevity: '',floorMin: '',floorMax: ''}
		addrEle = {city: '台北市',area: '中正區',road: '和平西路２段',lane: '104',alley: '',no: '131',floor: '4'}
		expect(zipUtility.isInZipDataScope zipData, addrEle).toBeTruthy()
		zipData = {zipCode: '10043',city: '台北市',area: '中正區',road: '仁愛路２段',laneOdevity: '',laneMin: '',laneMax: '',alleyOdevity: '',alleyMin: '',alleyMax: '',noOdevity: '雙',noMin: '48.001',noMax: '64',floorOdevity: '',floorMin: '',floorMax: ''}
		addrEle = {city: '台北',area: '中正區',road: '仁愛路２段',lane: '',alley: '',no: '48.009',floor: ''}
		expect(zipUtility.isInZipDataScope zipData, addrEle).toBeTruthy()

