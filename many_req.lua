-- init random
math.randomseed(os.time())-- the request function that will run at each request
request = function() 
	-- url_path = "/UCFile_4K_" .. math.random(0,9983.0) .. ".txt" -- if we want to print the path generated
	url_path = "/UCFile_4K_" .. math.random(0,399) .. ".txt" -- if we want to print the path generated
	-- url_path = "/UCFile_4K_" .. math.random(0,99) .. ".txt" -- if we want to print the path generated
   return wrk.format("GET", url_path)
end
