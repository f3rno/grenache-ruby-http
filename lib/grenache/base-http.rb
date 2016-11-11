module Grenache
  class Http < Grenache::Base
    def listen(key, port,  opts={}, &block)
      start_http_service(port,&block)

      announce(key, port, opts) do |res|
        puts "#{key} announced #{res}"
      end
    end

    def start_http_service(port, &block)
      EM.defer {
        app = -> (env) {
          block.call(env)
        }
        server = Thin::Server.start('0.0.0.0', port, app, {signals: false})
      }
    end

    def request(key, payload, &block)
      services = lookup(key)
      if services.size > 0
        json = Oj.dump(payload)
        service = services.sample.sub("tcp://","http://")
        service.prepend("http://") unless service.start_with?("http://")
        return [nil, HTTPClient.post(service,json).body]
      else
        return ["NoPeerFound",nil]
      end
    rescue Exception => e
      return [e, nil]
    end
  end
end
