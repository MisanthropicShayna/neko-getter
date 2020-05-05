require 'digest/md5'
require "fileutils"
require "net/http"
require "open-uri"
require "uri"

class ImageGetter
    private def matchImageUrlFromContent_()
        return Net::HTTP.get(URI.parse(@ContentUrl)).match(@UrlRegexPattern)[0]
    end

    private def testRegexp_()
        begin
            _image = Net::HTTP.get(URI.parse(matchImageUrlFromContent_()))
            puts "Url/Regex combo passed without throwing exceptions."
            return true
        rescue => exception
            puts "Url/Regex combo failed, throwing the exception => " + exception.message
            return false
        end
    end

    public def ContentUrl() @ContentUrl end
    public def UrlRegexPattern() @UrlRegexPattern end

    public def StartFetching(directory, delay = 1)
        if !Dir.exist? directory then Dir.mkdir(directory) end
        if !File.exist? "manifest.txt" then File.write("manifest.txt", "") end
            
        _build_manifest = lambda do
            _manifest = Array.new 
            Dir.foreach(directory) do |file| 
                if File.file?(File.join(directory, file)) then
                    open(File.join(directory, file), "rb") do |stream| 
                        _manifest.insert(-1, Digest::MD5.hexdigest(stream.read)) 
                    end
                end
            end

            open("manifest.txt", "w+") do |stream|
                for line in _manifest
                    stream.write(line+"\n")
                end
            end

            return _manifest
        end

        _update_manifest = lambda do |entry|
            open("manifest.txt", "a+") do |stream|
                lines = stream.read.split("\n")
                lines.insert(-1, entry)
                stream.write(entry + "\n")
                return lines
            end
        end

        _manifest = _build_manifest.call

        while true 
            _url = matchImageUrlFromContent_()
            _url_filename = _url.split("/").last

            _image_bytes = open(_url, "rb").read
            _image_digest = Digest::MD5.hexdigest(_image_bytes)
            
            if _manifest.include? _image_digest then
                puts "Skipping file #{_url_filename} with hash #{_image_digest} as the hash exsits in the manifest."
                next
            else
                puts "Downloading #{_url_filename} from #{_url}"
                
                _manifest = _update_manifest.call(_image_digest)

                open(File.join(directory, "#{_image_digest}_#{_url_filename}"), "wb") do |stream|
                    stream.write(_image_bytes)
                end
            end

            sleep(delay)
        end
    end

    def initialize(contentUrl, urlRegexPattern)
        @UrlRegexPattern = urlRegexPattern
        @ContentUrl = contentUrl

        if testRegexp_() then
            puts "Ready to start fetching."
        end
    end
end

class LewdNekoGetter < ImageGetter
    public def StartFetching
        super("LewdNekos")
    end

    def initialize
        super("https://nekos.life/lewd", /https:\/\/cdn\.nekos\.life\/lewd\/.+\.(jpg|png|jpeg)/)
    end
end


class WholesomeNekoGetter < ImageGetter
    public def StartFetching
        super("WholesomeNekos")
    end

    def initialize
        super("https://nekos.life/", /https:\/\/cdn\.nekos\.life\/neko\/.+\.(jpg|png|jpeg)/)
    end
end

# Lewd NekoGetter
lng = LewdNekoGetter.new
lng.StartFetching