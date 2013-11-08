youtube = require("youtube-feeds")
youtube.httpProtocol = "https"
humanize = require 'humanize'
HowDoI = require './lib/howdoi'
cheerio = require 'cheerio'

random = (ar)->
  return ar[Math.floor(Math.random() * ar.length)];

fetch = (url, cb)->
  request.get url, (e, r, body)->
    if !e and r.statusCode is 200
      cb(JSON.parse(body))
    else
      logger.log e
      cb false

module.exports = (bot) ->

  bot.regexp /^.yt (.+)/,
    ".yt <iskalni niz> -- Išči na youtube",
    (match, r) ->

      fixyt = (url)->
        if url
          return url.replace("/v/", "/watch?v=").replace("&feature=youtube_gdata_player", "")
        else
          return ""

      f = match[1].trim()
      youtube.feeds.videos
        q: f
        "max-results": 5
      , (err, data) ->
        unless err
          izbran = _.first(data.items)
          r.reply "#{izbran.title}(#{moment.duration(izbran.duration, 'seconds').humanize()}) #{fixyt(izbran.player.default)} ♥#{humanize.numberFormat(izbran.likeCount,0)} ▶#{humanize.numberFormat(izbran.viewCount,0)}"
        else
          r.reply "Ni zadetka"

  bot.regexp /^.sc (.+)/,
    ".sc <iskalni niz> -- Išči na soundcloud",
    (match, r) ->
      f = match[1].trim()
      fetch "http://api.soundcloud.com/tracks.json?order=hotness&client_id=93e33e327fd8a9b77becd179652272e2&q=#{encodeURI(f)}", (data) ->
        if data
          izbran = _.first(data)
          r.reply "#{izbran.title}(#{moment.duration(izbran.duration).humanize()}) #{izbran.permalink_url} ♥#{humanize.numberFormat(izbran.favoritings_count,0)} ▶#{humanize.numberFormat(izbran.playback_count,0)}"
        else
          r.reply "Ni zadetka"

  bot.regexp /^.asku (.+)/,
    ".asku <pojem> -- Išči po askubuntu, če vsebuje !! potem prikaže povezave",
    (match, r) ->
      f = match[1].trim()
      res = new HowDoI f, "askubuntu.com"
      res.get_answer (answer)->
        r.reply answer

  bot.regexp /^.stof (.+)/,
    ".stof <pojem> -- Išči po stackoverflow, če vsebuje !! potem prikaže povezave",
    (match, r) ->
      f = match[1].trim()
      res = new HowDoI f, "stackoverflow.com"
      res.get_answer (answer)->
        r.reply answer

  bot.regexp /^.stx (.+)/,
    ".stx <pojem> -- Išči po stackexchange, če vsebuje !! potem prikaže povezave",
    (match, r) ->
      f = match[1].trim()
      res = new HowDoI f, "stackexchange.com"
      res.get_answer (answer)->
        r.reply answer

  bot.regexp /^.apt (.+)/,
    ".apt <paket> -- Najde pakete po imenu v packages.ubuntu.com",
    (match, r) ->

      apt = (paket, cb)=>
        url = "http://packages.ubuntu.com/search?suite=all&searchon=names&keywords=#{encodeURI(paket)}"
        request.get url, (e, r, body)->
          if !e and r.statusCode is 200
            $ = cheerio.load(body)
            paketi = $("#psearchres h3").map (i, el) ->
                return $(this).text()
            cisti = []
            for paket in paketi
              cisti.push paket.replace "Package ", ""
            cb cisti.join ", "
          else
            logger.log e
            cb "Ne najdem"

      f = match[1].trim()
      apt f, (answer)->
        r.reply answer
      
  bot.regexp /^.pretvori ([\d,.]+) (.+) (.+)/,
    ".pretvori <vrednost> <valuta> <valuta> -- Pretvori med valutami (primer .pretvori 10 eur usd)",
    (match, r) ->

      zamenjaj = (v, f, t, cb)=>
        url = "http://rate-exchange.appspot.com/currency?from=#{f}&to=#{t}"
        v = Number(v.replace(",","."))
        
        if v
          request.get url, (e, r, body)->
            if !e and r.statusCode is 200
              rate = Number(JSON.parse(body).rate)
              cb "#{v * rate} #{t}"
            else
              logger.log e
              cb "Napaka"
        else
          cb "Napaka"

      vrednost = match[1].trim()
      from = match[2].trim()
      to = match[3].trim()
      zamenjaj vrednost, from, to, (answer)->
        r.reply "#{r.nick}: #{answer}"

  bot.regexp /^.imdb (.+)/,
    ".imdb <naslov> -- Dobi osnovne podatke z IMBD ",
    (match, r) ->
      f = match[1].trim()
      gimdb2 f, (answer)->
        r.reply answer

  bot.regexp /^\.stran (.*)/i,
    ".stran <domena> -- Ali stran dela?",
    (match, r) ->

      isUp = (domain, cb) ->
        default_headers = {
          'User-Agent': 'Mozilla/5.0 (X11; Linux i686; rv:7.0.1) Gecko/20100101 Firefox/7.0.1',
        }
        request {
          url: "http://isitup.org/#{domain.replace(" ", "")}.json",
          headers: default_headers,
          method: 'GET',
        }, (err, res, body) ->
          unless err
            response = JSON.parse(body)
            if response.status_code is 1
              cb "#{response.domain}(#{response.response_ip}) JE dosegljiva."
            else if response.status_code is 2
              cb "#{response.domain}(#{response.response_ip}) NI dosegljiva."
            else if response.status_code is 3
              cb "Si prepričan da je '#{response.domain}' res domena?"
            else
              cb "Neznano za #{response.domain}."
          else
            cb "API limit"

      isUp match[1], (domain) ->
        r.reply domain