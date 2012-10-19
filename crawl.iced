request = require 'request'
conf = require './config'

root = conf.root
timeout = conf.timeout || 100
makeUrl = conf.url

get = (value, cb)->
    if Array.isArray value
        value = value.join '_'
    url = makeUrl value
    console.warn url
    request.get url, (err, res)->
        if err
            cb err
        else
            try
                data = JSON.parse res?.body
                process.nextTick ->cb null, data.d.LS
            catch parseError
                cb parseError

isValidValue = (v)->
    !!v.match /[\d_]+/

hasChildren = (child)->
    v = (child?.value?.split '_').map (i)-> +i
    return false if v[3] isnt 0
    return false if v[2] isnt 0 and v[3] is 0 and !child.metro
    return true

#-------------------------------------------------

seen = {}
queue = {}
queue[root] = 1


while(qlen = Object.keys(queue).length)
    console.warn "####queued #{qlen} items"
    for requestValue of queue
        await get requestValue, defer(err, res)
        process.exit(1) if err
        delete queue[requestValue]

        await setTimeout defer(), timeout

        if children = res.options
            for child in children when isValidValue child.value
                console.log "#{child.value};#{child.text}"
                unless seen[child.value]
                    seen[child.value] = true
                    if hasChildren(child)
                        queue[child.value] = true