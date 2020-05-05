require "fileutils"
require "net/http"
require "uri"

# puts "Select Neko type."
# puts "1.) Wholesome"
# puts "2.) Lewd"

# class NekoDownloader
#     private def promptType_()
#         # Display the prompt message, requesting a type.
#         puts "1.) Wholesome";
#         puts "2.) Lewd";
# 
#         _neko_type = nil # Temporary variable that will store the entered type, will either be 1 or 2.
# 
#         # Repeats the prompt until the entered string matches is either 1 or 2, storing the result in _neko_type.
#         until ["1", "2"].include? _neko_type = (lambda do print "> "; return gets.chomp end).call do next end
# 
#         return _neko_type;
#     end
# 
#     private def getWholesomeNekoUrl_()
#         return Net::HTTP.get(URI.parse("https://nekos.life/lewd")).match(/https:\/\/cdn\.nekos\.life\/lewd\/.+\.(jpg|png|jpeg)/)[0]
#     end
#     
#     private def getLewdNekoUrl_()
# 
#     end
# 
#     # Various getter methods for instance variables.
#     public def NekoType() @NekoType end
#     public def StoreDirectory() @StoreDirectory end
# 
#     
#     public def initialize(nekoType = nil)
#         @lewdHtmlUrl_ = "https://nekos.life/lewd"
#         @wholesomeHtmlUrl_ = "https://nekos.life/"
#         
#         @lewdHtmlRegex_ = /https:\/\/cdn\.nekos\.life\/neko\/.+\.(jpg|png|jpeg)/
#         @wholesomeHtmlRegex_ = /https:\/\/cdn\.nekos\.life\/lewd\/.+\.(jpg|png|jpeg)/
#     
#         # Assign neko type to argument if not nil, otherwise run the prompt method to prompt for a type.
#         @NekoType = nekoType == nil ? promptType_() : nekoType;
# 
#         # Assigns the storage directory to either "WholesomeNekos" or "LewdNekos" depending on the provided type.
#         @StorageDirectory = @NekoType == "1" ? "WholesomeNekos" : "LewdNekos";
#     end
# end

f = NekoDownloader.new
puts f.NekoType

# if neko_type == "1" then
#     $directory = "WholesomeNekos"
# else
#     $directory = "LewdNekos"
# end

# until ["1", "2"].include? @neko_type = (lambda do print "> "; return gets.chomp end).call do next end
exit
# directory = neko_type == "1" ? "WholesomeNekos" : "LewdNekos"

if !Dir.exist? directory then Dir.mkdir(directory) end

WholesomeUrlGetter = lambda do return Net::HTTP.get(URI.parse("https://nekos.life/lewd")).match(/https:\/\/cdn\.nekos\.life\/lewd\/.+\.(jpg|png|jpeg)/)[0] end
LewdUrlgetter = lambda do return Net::HTTP.get(URI.parse("https://nekos.life/")).match(/https:\/\/cdn\.nekos\.life\/neko\/.+\.(jpg|png|jpeg)/)[0] end

# def DownloadFile(url)
#     filename = url.split("/").last
#     data = Net::HTTP.get(URI.parse(url)) 
#     File.write(filename, data)
# end

# while true
#     DownloadFile(GetLewdNekoUrl())
#     sleep(1)
# end