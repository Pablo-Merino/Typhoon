require 'socket'
require 'yaml'

class HTTPd

	def initialize(client, request, config)

		@client = client
		@config = config
		@request = request
		@webRoot = config['webRoot']
		@publicPath = config['publicHTMLDir']
		getPath(request)
	end
	def work
		begin
			
			ENV['REQUEST_URI'] = "/"+@request.gsub(/GET \//, '').gsub(/ HTTP.*/, '')
			 
			if File.exist?(@fileName) and File.file?(@fileName)
				headers = ["HTTP/1.1 200 OK", 'Server: Typhoon', "Connection: Keep-Alive", "Content-Type: #{contentType(@fileName)}; charset=UTF-8"]
				unless @config['customHeaders'].nil? || @config['customHeaders'].empty?
					@config['customHeaders'].each { |key, value|
						headers.push("#{key}: #{value}")
					}
				end
				if File.extname(@fileName) =~ /.php/
					baseCommand = "php-cgi -q -f #{@fileName}"

					if @request =~ /(\?\S*)/
						@request.gsub(/(\?\S*)/) {
							str = "#{$1}"
							@content = `#{baseCommand} #{str.gsub("?", "").split('&').join(" ")}` 
						}
					else
						@content = `#{baseCommand}` 
					end
				else
					@content = File.open(@fileName, "rb").read
				end
				@client.puts headers.join("\r\n")+"\r\n\r\n"+"#{@content}"

			else
				@client.puts "HTTP/1.1 404 Object Not Found\r\nServer: Typhoon\r\nContent-type: text/html\r\n\r\n#{File.open(File.expand_path(File.dirname(__FILE__))+"/assets/404.html", "rb").read}"

			end
			@client.close


		rescue Exception => e
			puts "Exception! #{e.backtrace}"
			log = "#{Time.now.localtime.strftime("%Y/%m/%d %H:%M")} - #{@client.peeraddr[2]} - #{@request.gsub("\r\n","" )} - #{e.backtrace}\r\n"
		  	File.open(@webRoot+"logs/error_log", 'a') {|f| f.write(log) }

			@client.puts "HTTP/1.1 404 Object Not Found\r\nServer: Typhoon\r\nContent-type: text/html\r\n\r\n#{File.open(File.expand_path(File.dirname(__FILE__))+"/assets/500.html", "rb").read}"
			@client.close

		end

	end

	private
	def getPath(request)
		if request =~ /GET .* HTTP.*/

			@fileName = request.gsub(/GET \//, '').gsub(/ HTTP.*/, '').gsub(/(\?\S*)/, "")

		else
			@client.puts "HTTP/1.1 501 Not Implemented\r\nServer: Typhoon\r\nContent-type: text/html\r\n\r\n<h1>501 Not Implemented</h1>"
		

			@client.close
		end

		@fileName = @fileName.strip
		unless @fileName == nil
			@fileName = @webRoot+@publicPath+"/" + @fileName
		end
		@fileName << "/index.html" if  File.directory?(@fileName)
	end
	def contentType(file)
		return 'text/html' if File.extname(file) =~ /\.htm*[a-zA-Z]/
		return 'text/html' if File.extname(file) == ".php"

		return 'text/css' if File.extname(file) == ".css"
		return `file --mime -b #{file}`.gsub(/; charset=\S*/, "")
	end

end

@config = YAML.load_file("config.yml")
listenAddr = @config['listenAddr']
listenPort = @config['listenPort']

server = TCPServer.new(listenAddr, listenPort)
@root = @config['webRoot']

puts "[Typhoon 1.0] Running on #{listenAddr}:#{listenPort}!"

trap("INT") { 
	puts "[Typhoon 1.0] Bye!"
	exit
}


def requestLogger(session, request)
	log = "#{Time.now.localtime.strftime("%Y/%m/%d %H:%M:%S")} - #{session.peeraddr[2]} (#{session.peeraddr[3]}) - #{request}"
  	File.open(@root+"logs/access_log", 'a') {|f| f.write(log) }
	puts log
end

loop do
  	session = server.accept
  	request = session.gets
  	requestLogger(session, request)

	Thread.start(session, request) do |session, request|
    	HTTPd.new(session, request, @config).work
  	end
end