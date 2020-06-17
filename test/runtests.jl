using Merly
using Test
using HTTP
using JSON
#Pkg.add("BenchmarkTools")
#using BenchmarkTools

ip = "127.0.0.1"
port = 8086

@test File("index.html") == read( open(joinpath(pwd(),"index.html")), String)


useCORS(true)
@test useCORS(true) == true
headersalways("Strict-Transport-Security","max-age=10886400; includeSubDomains; preload")
notfound("""<!DOCTYPE html>
              <html>
              <head><title>Not found</title></head>
              <body><h1>404, Not found</h1></body>
              </html>""") 
notfound("cosa/notfound.html")

u = "hello"

@page "/" "Hello World!"
@page "/hola/:usr>" "<b>Hello {{usr}}!</b>"

@page "/mifile" File("Index.html")

@route GET "/get/:data1>" begin
  "get this back: {{data1}}"
end

@route GET "/regex/(\\w+\\d+)" begin

  println("req.version ",req.version)
  println("req.headers ",req.headers)

   "datos $(req.params[1])"
end

@route POST "/post" begin
  res.body = "I did something!"
  "I did something!"
end

@route POST|PUT|DELETE "/" begin
  println("params: ",req.params)
  println("query: ",req.query)
  println("body: ",req.body)

  res.headers["Content-Type"]= "text/plain"

  "I did something!"
end

Get("/data", (req,res)->(begin
  res.headers["Content-Type"]= "text/plain"
  println("params: ",req.params)
  println("query: ",req.query)
  u*"data"
end))

Post("/data", (req,res)->(begin
  println("params: ",req.params)
  println("query: ",req.query)
  println("body: ",req.body)
  res.headers["Content-Type"]= "text/plain"
  global u="bye"
  "I did something!"
end))

@test webserverpath("cosa") == joinpath(pwd(),"cosa")
webserverfiles("*")

 @async start(host = ip, port = port, verbose = false)
 sleep(2)


 r = HTTP.get("http://$(ip):$(port)/")
 @test r.status == 200
 @test String(r.body) == "Hello World!"

r = HTTP.get("http://$(ip):$(port)/hola/usuario")
@test r.status == 200
@test String(r.body) == "<b>Hello usuario!</b>"

r = HTTP.get("http://$(ip):$(port)/get/testdata")
@test r.status == 200
@test String(r.body) == "get this back: testdata"

r= HTTP.get("http://$(ip):$(port)/regex/test1")
@test String(r.body) == "datos test1"


r = HTTP.get("http://$(ip):$(port)/data?hola=1")
@test r.status == 200
@test String(r.body) == "hellodata"

myjson = Dict("query"=>"data")
my_headers = HTTP.mkheaders(["Accept" => "application/json","Content-Type" => "application/xml"])
r = HTTP.post("http://$(ip):$(port)/data",my_headers,JSON.json(myjson))
@test r.status == 200
@test String(r.body) == "I did something!"

r = HTTP.get("http://$(ip):$(port)/data")
@test r.status == 200
@test String(r.body) == "byedata"


my_headers = HTTP.mkheaders(["Accept" => "application/json"])
r = HTTP.post("http://$(ip):$(port)/post",my_headers,JSON.json(myjson))
@test r.status == 200
@test String(r.body) == "I did something!"

my_headers = HTTP.mkheaders(["Accept" => "application/json","Content-Type" => "application/json"])
r = HTTP.post("http://$(ip):$(port)/",my_headers,JSON.json(myjson))
@test r.status == 200
@test String(r.body) == "I did something!"

r = HTTP.put("http://$(ip):$(port)/",my_headers,JSON.json(myjson))
@test r.status == 200
@test String(r.body) == "I did something!"

r = HTTP.delete("http://$(ip):$(port)/")
@test r.status == 200
@test String(r.body) == "I did something!"
@test r.headers == Pair{SubString{String},SubString{String}}["Content-Type"=>"text/plain", "Access-Control-Allow-Origin"=>"*", "Access-Control-Allow-Methods"=>"POST,GET,OPTIONS", "Strict-Transport-Security"=>"max-age=10886400; includeSubDomains; preload", "Transfer-Encoding"=>"chunked"]

try
  r = HTTP.get("http://$(ip):$(port)/nada")
catch e
  @test String(e.response.body) == File("notfound.html")
end

r = HTTP.get("http://$(ip):$(port)/prueba.txt")
@test r.status == 200
@test String(r.body) == "probando webserver"
@test r.headers == Pair{SubString{String},SubString{String}}["Content-Type"=>"text/plain", "Access-Control-Allow-Origin"=>"*", "Access-Control-Allow-Methods"=>"POST,GET,OPTIONS", "Strict-Transport-Security"=>"max-age=10886400; includeSubDomains; preload", "Transfer-Encoding"=>"chunked"]


r= HTTP.get("http://$(ip):$(port)/algomas/ja.txt")
@test String(r.body) == "jajajajaj"

#@btime HTTP.get("http://$(ip):$(port)/?hola=5")
# 3.864 ms (8304 allocations: 381.20 KiB)
# 453.803 μs (748 allocations: 30.92 KiB)
#@btime HTTP.get("http://$(ip):$(port)/hola/usuario")
# 4.211 ms (7685 allocations: 353.44 KiB)
# 483.861 μs (743 allocations: 30.41 KiB)
#@benchmark r= HTTP.get("http://$(ip):$(port)/get/testdata")
# 3.906 ms (7693 allocations: 353.78 KiB)
# 484.960 μs (744 allocations: 30.44 KiB)
#=
 minimum time:     740.087 μs (0.00% GC)
  median time:      843.457 μs (0.00% GC)
  mean time:        1.099 ms (1.45% GC)
  maximum time:     367.611 ms (0.00% GC)
=#

