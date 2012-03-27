## Typhoon, a Ruby Webserver
Typhoon is a fast and extendible HTTP webserver, with basic PHP support.

### Required gems:

- Daemons: `gem install daemons`

### How to run it

*Special Windows support*

Configure it via `config.yml`. I think it's self explanatory, then `dir` to the server directory and run `ruby boot.rb start` (or `ruby boot.rb start -t` to start it verbose) and go to `http://localhost:9091`. It'll show you the `index.html` that you put inside the `public_html` (or whatever value you set on `publicHTMLDir` on the config). Done! Now fork and make it better :D