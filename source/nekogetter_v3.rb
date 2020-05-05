BEGIN {
    require "digest/md5"
    require "fileutils"
    require "net/http"
    require "open-uri"
    require "json"
    require "uri"

    class Manifest
        # Methods for loading/saving the manifest object in memory, into the file, and vice versa.
        public def LoadManifest() @manifest = JSON.load(open(@manifestFile, "r").read) end
        public def SaveManifest() open(@manifestFile, "w+") do |stream| stream.write JSON.pretty_generate(@manifest) end end
        public def DeleteManifest() if File.exist? @manifestFile then File.delete(@manifestFile) end end
        public def HashPresent(hash) return @manifest.include? hash end
        
        # Getters for the various instance variables.
        public def Manifest() @manifest end
        public def TargetDirectory() @targetDirectory end
        public def ManifestFile() @manifestFile end
        
        public def AddFileToManifest(file)
            # Gets the MD5 checksum of the provided file.
            _md5_checksum = Digest::MD5.hexdigest open(file, "rb").read
    
            # If the checksum already exists in the manifest, insert the filename into the array, otherwise create the array with the filename in it.
            if @manifest[_md5_checksum] == nil then @manifest[_md5_checksum] = [file] else @manifest[_md5_checksum].insert(-1, file) end
            
            # Save changes to the manifest in memory, by storing it into the manifest file.
            SaveManifest()
        end

        public def AddChecksumToManifest(checksum, filename)
            if @manifest[checksum] == nil then @manifest[checksum] = [filename] else @manifest[checksum].insert(-1, filename) end
            SaveManifest()
        end

        public def AddBytesToManifest(bytes, filename)
            AddChecksumToManifest(Digest::MD5.hexdigest(bytes), filename)
        end
    
        # Goes through the target directory, and builds the manifest based off of all of the files.
        public def BuildManifest
            @manifest = Hash.new
    
            # Iterates through each file in the target manifest target directory with the filename joined to the directory name.
            for file in Dir.foreach(@targetDirectory).select {|entry| !File.directory?(entry)}.map{|file| File.join(@targetDirectory, file)}
                AddFileToManifest(file) # Adds the current file to the manifest.
            end
    
            # Saves the manifest from memory, into the manifest file.
            SaveManifest()
        end
        
        public def initialize(targetDirectory, manifestFile)
            @targetDirectory = targetDirectory
            @manifestFile = manifestFile
    
            # Creates the target directory if it doesn't exist.
            if !Dir.exist? @targetDirectory then Dir.mkdir (@targetDirectory) end
            
            # Builds a manifest of the target directory.
            BuildManifest()

            puts "Manifest created."
        end
    end
    
    class HtmlImageGetter
        public def TestRegexp
            begin
                _content_body = open(@htmlContentBodyUrl, "r") do |stream| stream.read end
                puts "(Pattern Test) Received Body MD5: #{Digest::MD5.hexdigest _content_body}"

                _matched_image_url = _content_body.match(@htmlContentImageRegexp)[0]
                puts "(Pattern Test) Matched URL: #{_matched_image_url}"
                
                _image_name = _matched_image_url.split("/").last
                _image_extension = _image_name.split(".").last

                puts "(Pattern Test) Matched image name: #{_image_name}"
                puts "(Pattern Test) Matched image extension: #{_image_extension}"

                _image_bytes = open(_matched_image_url, "rb") do |stream| stream.read end
                puts "(Pattern Test) Image MD5: #{Digest::MD5.hexdigest _image_bytes}"
                
                open("RegexTestImage.#{_image_extension}", "wb+") do |stream| 
                    stream.write(_image_bytes) 
                end

                puts "(Pattern Test) Wrote to file: RegexTestImage.#{_image_extension}"
            rescue => exception
                put "(Pattern Test) FAILED: Exception \"#{exception.message}\" encountered when testing."
                return false
            else
                puts "(Pattern Test) Regular expression test passed."
                return true
            end
        end

        public def GetNextImageUrl
            begin
                _content_body = open(@htmlContentBodyUrl, "r") do |stream| stream.read end
                _matched_image_url = _content_body.match(@htmlContentImageRegexp)[0]
                return _matched_image_url
            rescue => exception
                puts "Exception when getting next image URL: #{exception}"
                return nil
            end
        end

        public def GetNextImageBytes
            begin
                _image_url = GetNextImageUrl()
                
                if _image_url == nil then return nil end

                _image_name = _image_url.split("/").last
                _image_extension = _image_name.split(".").last
                
                _image_bytes = open(_image_url, "rb") do |stream| stream.read end
                return _image_bytes, _image_name, _image_extension
            rescue => exception
                puts "Exception when getting next image: #{exception.message}"
                return nil
            end
        end

        public def SaveNextImage(directory)
            begin
                _image_bytes, _image_name, _image_extension = GetNextImageBytes()

                open(File.join(directory, "#{_image_name}_#{Digest::MD5.hexdigest _image_bytes}.#{_image_extension}"), "wb+") do |stream|
                    stream.write(_image_bytes)
                end
                
                return _image_bytes, _image_name, _image_extension
            rescue => exception
                puts "Exception when saving next image to directory (#{directory}): #{exception.message}"
                return nil
            end
        end
    
        public def initialize(httpContentBodyUrl, htmlContentImageRegexp)
            @htmlContentBodyUrl = httpContentBodyUrl
            @htmlContentImageRegexp = htmlContentImageRegexp

            _test_passed = TestRegexp()
            if !_test_passed then exit end
        end
    end
}

def FormatMetricSize(bytes)
    divisions = 0

    while bytes > 1024
        bytes /= 1024
        divisions += 1
    end 

    suffix = {
        0 => "Bytes", 
        1 => "KB", 
        2 => "MB", 
        3 => "GB", 
        4 => "TB"
    } [divisions]

    bytes = (bytes.to_s).reverse.scan(/\d{3}|.+/).join(",").reverse
    return "#{bytes} #{suffix}"
end

def GetDirectorySize(directory) Dir["#{directory}/*"].select{ |file| File.file?(file)}.sum{|file| File.size(file) } end

puts "1.) Wholesome Nekos"
puts "2.) Lewd Nekos"

mode = nil; while !["1", "2"].include? mode = (lambda do print "> "; return gets.chomp end).call do next end

neko_manifest, neko_getter, store_directory = nil, nil, nil

if mode == "1" then
    neko_manifest = Manifest.new("WholesomeNekos", "WholesomeNekosManifest.json")
    neko_getter = HtmlImageGetter.new("https://nekos.life/", /https:\/\/cdn\.nekos\.life\/neko\/.+\.(jpg|png|jpeg)/)
    store_directory = "WholesomeNekos"
else
    neko_manifest = Manifest.new("LewdNekos", "LewdNekosManifest.json")
    neko_getter = HtmlImageGetter.new("https://nekos.life/lewd", /https:\/\/cdn\.nekos\.life\/lewd\/.+\.(jpg|png|jpeg)/)
    store_directory = "LewdNekos"
end

requests, unique_responses = 0,0

while true 
    bytes, name, extension = neko_getter.GetNextImageBytes
    if bytes == nil then puts "Error encountered, skipping.."; next
    else requests += 1 end

    image_md5_checksum = Digest::MD5.hexdigest bytes

    full_store_path = File.join(store_directory, "#{name}_#{image_md5_checksum}.#{extension}")

    puts "\e[H\e[2J"

    if neko_manifest.HashPresent(image_md5_checksum) then
        puts "Skipping #{name} as the hash of it (#{image_md5_checksum}) already exists in the manifest."
    else 
        open(full_store_path, "wb+") do |stream| stream.write(bytes) end
            neko_manifest.AddChecksumToManifest(image_md5_checksum, full_store_path)
        puts "Downloaded #{full_store_path}"
        unique_responses += 1
    end

    puts "Success Rate #{(unique_responses/requests)*100}% (#{unique_responses} / #{requests})"
    puts "Total Size: #{FormatMetricSize(GetDirectorySize(store_directory))}"

    sleep(1)
end

END {
    neko_manifest.DeleteManifest
    puts "Manifest deleted."
}