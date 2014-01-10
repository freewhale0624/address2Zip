restify = require 'restify'
async = require 'async'
fs = require 'fs'
MongoClient = require('mongodb').MongoClient
zipUtility = require './zipCodeUtility'
db = require './config/my.conf'
CONN_STRING = 'mongodb://' + ((if db.DB_USER isnt '' then db.DB_USER else '')) + ((if db.DB_PASSWORD isnt '' then ':' + db.DB_PASSWORD else '')) + ((if db.DB_USER isnt '' then '@' else '')) + db.DB_HOST + ':' + db.DB_PORT + '/' + db.DB_NAME
taiwanCityFile = 'tmpData/TWcity.data'
taiwanAreaFile = 'tmpData/TWarea.data'
taiwanZipCodeFile = 'tmpData/zip5.data'

insertTaiwanCity = (req, res, next) ->
  token = '5699F4461D55D57E2A9B9F5923323'
  taiwanCity = fs.readFileSync taiwanCityFile, 'utf8'
  cities = taiwanCity.split '\n'
  if not req.params.token or req.params.token isnt token
    res.write 'Error, please recheck to administrator'
    res.end()
  else
    MongoClient.connect CONN_STRING, (err, db) ->
      db.createCollection 'country', (err, collection) ->
        i = 0
        while i < (cities.length - 1)
          collection.insert
            country: 'TW'
            city: cities[i]
          , ->
          i++
        return
      return
    res.write 'Done!'
    res.end()
  return

insertTaiwanArea = (req, res, next) ->
  token = '775943BD916981C1B9FF52DA29B1E'
  taiwanArea = fs.readFileSync taiwanAreaFile, 'utf8'
  areas = taiwanArea.split '\n'
  if not req.params.token or req.params.token isnt token
    res.write 'Error, please recheck to administrator'
    res.end()
  else
    MongoClient.connect CONN_STRING, (err, db) ->
      db.createCollection 'city', (err, collection) ->
        i = 0
        while i < (areas.length - 1)
          areaElement = areas[i].split ','
          collection.insert
            city: areaElement[0]
            area: areaElement[1]
          , ->
          i++
        return
      return
    res.write 'Done!'
    res.end()
  return

insertTaiwanZipCode = (req, res, next) ->
  token = 'C3D4E96FC83F2ED3674AD11CD3ECC'
  taiwanZipCodes = fs.readFileSync taiwanZipCodeFile, 'utf8'
  zipCodes = taiwanZipCodes.split '\n'
  if not req.params.token or req.params.token isnt token
    res.write 'Error, please recheck to administrator'
    res.end()
  else
    MongoClient.connect CONN_STRING, (err, db) ->
      db.createCollection 'zip', (err, collection) ->
        i = 0
        while i < (zipCodes.length - 1)
          zipElement = zipCodes[i].split(',')
          zipCode = zipElement[0]
          city = zipElement[1]
          area = zipElement[2]
          road = zipUtility.numberToChinese zipUtility.numberFullToHalf zipElement[3]
          scope = zipElement[4]
          scopeEle = zipUtility.decomposeScope scope, i
          if scopeEle?
            collection.insert
              zipcode: zipCode
              city: city
              area: area
              road: road
              laneOdevity: scopeEle[0][0]
              laneMin: scopeEle[0][1]
              laneMax: scopeEle[0][2]
              alleyOdevity: scopeEle[1][0]
              alleyMin: scopeEle[1][1]
              alleyMax: scopeEle[1][2]
              noOdevity: scopeEle[2][0]
              noMin: scopeEle[2][1]
              noMax: scopeEle[2][2]
              floorOdevity: scopeEle[3][0]
              floorMin: scopeEle[3][1]
              floorMax: scopeEle[3][2]
            , ->
          i++
        return
      return
    res.write 'Done!'
    res.end()
  return
 

getCity = (req, res, next) ->
  token = '1658F7ED9FBACF737B58FE3DA1933'
  country = req.params.country
  if not req.params.token or req.params.token isnt token or not country
    res.write 'Error, please recheck to administrator'    
    res.end()
  else
    MongoClient.connect CONN_STRING, (err, db) ->
      countryCollection = db.collection('country')
      countryCollection.find({country: country}).toArray (err, cities) ->
        res.write JSON.stringify(cities)
        res.end()
        db.close
  return

getArea = (req, res, next) ->
  token = 'DD4A26913FA6118E36BFA6741DD91'
  city = req.params.city
  if not req.params.token or req.params.token isnt token or not city
    res.write 'Error, please recheck to administrator'    
    res.end()
  else
    MongoClient.connect CONN_STRING, (err, db) ->
      cityCollection = db.collection('city')
      cityCollection.find({city: city}).toArray (err, areas) ->
        res.write JSON.stringify(areas)
        res.end()
        db.close
  return

getZipCode = (req, res, next) ->
  token = '8FC282BCF8E63E267F66E63A75A1D'
  addrSource = req.params.addr
  zipJSON =
    zipCode: ''
    addrSource: addrSource

  res.setHeader 'X-Powered-By', 'ZipCode'
  if not req.params.token or req.params.token isnt token or not addrSource
    res.write 'Error, please recheck to administrator'
    res.end()
  else    
    #解析地址 將其分解為 縣市,鄉鎮區,路街,[巷弄號]範圍
    addrElement = zipUtility.decomposeAddr addrSource
    # query 
    zipQuery =
      city: addrElement.city
      area: addrElement.area
      road: addrElement.road
    
    #若搜尋無結果則變更條件後再查詢
    #   1.原條件
    #   2.remove 鄰
    #   3.remove ^..[里村] (村里 僅處里剛好三字之村里)
    #   4.modify lane alley no to integer
    #   5.remove [里村]$ cause people always type 東清 as 東清村
    #   6.將road資料去'十'後查詢, 因有部份路名包含十 部份不包含 
    #   7.重新判斷road 原road為文字數字斷點 將巷弄資料合併入road條件
    #   ex: 原 road = 國泰, lane = 1, alley = 2  >> road = 國泰一巷, lane = '', alley = 2
    #   8.將road資料去'十'後查詢, 因有部份路名包含十 部份不包含 
    MongoClient.connect CONN_STRING, (err, db) ->
      zipCollection = db.collection('zip')
      addrZip = undefined
      async.waterfall [(callback) ->
        if addrElement.road
          zipCollection.find(zipQuery).toArray (err, zipDatas) ->
            return next(err)  if err
            for zipData in zipDatas
              addrZip = zipData if zipUtility.isInZipDataScope(zipData, addrElement)
            if (addrZip) then callback('success', addrZip) else callback(null)

        else
          callback 'failure'
      , (callback) ->
        roadAdjust = (/[〇ㄧ一二三四五六七八九十]+鄰/).exec(addrElement.road)
        if roadAdjust
          addrElement.road = addrElement.road.replace(roadAdjust, '')
          zipQuery.road = addrElement.road
          zipCollection.find(zipQuery).toArray (err, zipDatas) ->
            return next(err)  if err
            for zipData in zipDatas
              addrZip = zipData if zipUtility.isInZipDataScope(zipData, addrElement)
            if (addrZip) then callback('success', addrZip) else callback(null, addrElement)
        else
          callback null, addrElement
      , (addrElement, callback) ->
        roadAdjust = addrElement.road.split(/^.里里|^.里村|^.村里|^.{2}[里村]/)[1]
        if roadAdjust
          addrElement.road = roadAdjust
          zipQuery.road = addrElement.road
          zipCollection.find(zipQuery).toArray (err, zipDatas) ->
            return next(err)  if err
            for zipData in zipDatas
              addrZip = zipData if zipUtility.isInZipDataScope(zipData, addrElement)
            if (addrZip) then callback('success', addrZip) else callback(null, addrElement)

        else
          callback null, addrElement
      , (addrElement, callback) ->
        flag = false
        if addrElement.lane and (addrElement.lane % 1) isnt 0
          addrElement.lane = parseInt(addrElement.lane)
          flag = true
        if addrElement.alley and (addrElement.alley % 1) isnt 0
          addrElement.alley = parseInt(addrElement.alley)
          flag = true
        if addrElement.no and (addrElement.no % 1) isnt 0
          addrElement.no = parseInt(addrElement.no)
          flag = true
        if flag
          zipCollection.find(zipQuery).toArray (err, zipDatas) ->
            return next(err)  if err
            for zipData in zipDatas
              addrZip = zipData if zipUtility.isInZipDataScope(zipData, addrElement)
            if (addrZip) then callback('success', addrZip) else callback(null, addrElement)

        else
          callback null, addrElement
      , (addrElement, callback) ->
        reg = /村$|里$/
        if reg.test(addrElement.road)
          zipQuery.road = addrElement.road.replace(reg, '')
          zipCollection.find(zipQuery).toArray (err, zipDatas) ->
            return next(err)  if err
            for zipData in zipDatas
              addrZip = zipData if zipUtility.isInZipDataScope(zipData, addrElement)
            if (addrZip) then callback('success', addrZip) else callback(null, addrElement)

        else
          callback null, addrElement
      , (addrElement, callback) ->
        if addrElement.road.indexOf('十') > 0
          zipQuery.road = addrElement.road.replace('十', '')
          zipCollection.find(zipQuery).toArray (err, zipDatas) ->
            return next(err)  if err
            for zipData in zipDatas
              addrZip = zipData if zipUtility.isInZipDataScope(zipData, addrElement)
            if (addrZip) then callback('success', addrZip) else callback(null, addrElement)
        else
          callback null, addrElement
      , (addrElement, callback) ->
        flag = false
        if addrElement.lane
          addrElement.road = addrElement.road + zipUtility.numberToChinese(addrElement.lane) + '巷'
          addrElement.lane = ''
          flag = true
        else if addrElement.alley
          addrElement.road = addrElement.road + zipUtility.numberToChinese(addrElement.alley) + '弄'
          addrElement.alley = ''
          flag = true
        if flag
          zipQuery.road = addrElement.road
          zipCollection.find(zipQuery).toArray (err, zipDatas) ->
            return next(err)  if err
            for zipData in zipDatas
              addrZip = zipData if zipUtility.isInZipDataScope(zipData, addrElement)
            if (addrZip) then callback('success', addrZip) else callback(null, addrElement)
        else
          callback null, addrElement
      , (addrElement, callback) ->
        if addrElement.road.indexOf('十') > 0
          zipQuery.road = addrElement.road.replace('十', '')
          zipCollection.find(zipQuery).toArray (err, zipDatas) ->
            return next(err)  if err
            for zipData in zipDatas
              addrZip = zipData if zipUtility.isInZipDataScope(zipData, addrElement)
            if (addrZip) then callback('success', addrZip) else callback(null, addrElement)
        else
          callback 'failure'
      ], (message, addrZip) ->
        zipJSON.zipCode = addrZip.zipcode  if message is 'success'
        res.write JSON.stringify(zipJSON)
        res.end()
        db.close()
  return


###
Creat a server
###
server = restify.createServer(
  name: 'ZipCodeApi'
  version: '1.0.0'
)

server.use restify.queryParser()
server.get '/insertTaiwanCity', insertTaiwanCity
server.get '/insertTaiwanArea', insertTaiwanArea
server.get '/insertTaiwanZipCode', insertTaiwanZipCode
server.get '/getZipCode', getZipCode
server.get '/getCity', getCity
server.get '/getArea', getArea
server.listen 1357, ->
  console.log '%s listening at %s', server.name, server.url
