require 'openssl'
module Yeller
  Server = Struct.new(:host, :port) do
    def client
      @client ||= Net::HTTP.new(host, port)
    end
  end

  SecureServer = Struct.new(:host, :port) do
    def client
      @client ||= setup_client
    end

    def setup_client
      http = Net::HTTP.new(host, port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      if http.respond_to?(:ciphers=)
        http.ciphers = "DEFAULT:!aNULL:!eNULL:!LOW:!EXPORT:!SSLv2"
      end
      http
    end
  end
end
