require './init'

class AnakinDummyDeamon  < EventMachine::Connection
  include EventMachine::HttpServer

  
  def process_http_request
    @json_body = ""
    resp = EventMachine::DelegatedHttpResponse.new( self )
    operation = proc do
      @json_body = Yajl::Parser.parse(@http_post_content)
    end

    # Callback block to execute once the request is fulfilled
    callback = proc do
      puts "responding to #{@json_body.inspect}" 
      content = case @json_body['action']
      when 'add_indexes'
        {status: 'ok'} 
      when 'update_index'
        {status: 'ok'} 
      when 'matching'
        {status: 'ok'} 
      when 'comparison'
      end
      resp.content = Yajl::Encoder.encode(content)
      resp.send_response 
    end

    # Let the thread pool (20 Ruby threads) handle request
    EM.defer(operation, callback)
  end
end


EventMachine::run {
  (ARGV[0] || 2).times do |t|
    EventMachine::start_server("0.0.0.0", 6000 + t, AnakinDummyDeamon)
    puts "runnin on port #{6000 + t}"
  end
}
