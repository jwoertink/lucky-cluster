module Lucky

  class Cluster
    VERSION = "0.1.0"
    private getter server : HTTP::Server
    private getter processes : Array(Concurrent::Future(Nil))
    property threads : Int32 = 1

    def initialize(stack : Array(HTTP::Handler))
      @server = setup_server(stack)
      @processes = [] of Concurrent::Future(Nil)
    end

    def base_uri
      "http://#{host}:#{port}"
    end

    def host
      Lucky::Server.settings.host
    end

    def port
      Lucky::Server.settings.port
    end

    def master?
      ARGV[0]? != "--child"
    end

    # Threads not specified, or set to 0, 1...
    def single_boot?
      threads < 2
    end

    def listen
      if single_boot?
        listen_once
      else
        listen_carefully
      end
    end

    def close
      processes.each(&.get)
      server.close
    end

    private def setup_server(stack)
      HTTP::Server.new(stack)
    end

    private def listen_once
      log_boot
      server.bind_tcp(host, port)
      server.listen

      Signal::INT.trap do |signal|
        puts "Stopping server"
        server.close
      end
    end

    private def listen_carefully
      if master?
        boot
        Signal::INT.trap do |signal|
          puts " > terminating gracefully"
          spawn { close }
          signal.ignore
        end
      end

      server.bind_tcp(host, port, true)
      server.listen
    end

    private def log_boot
      puts "Listening on #{base_uri}".colorize(:green)
    end

    private def boot
      process_path = Process.executable_path.not_nil!
      args = [] of String
      log_boot
      (0...threads).each do |t|
        args << "--child" if t > 0
        processes << future do
          process = nil
          Process.run(process_path, args,
            input: Process::Redirect::Close,
            output: Process::Redirect::Inherit,
            error: Process::Redirect::Inherit
          ) do |ref|
            process = ref
            puts " > worker #{process.pid} started"
          end

          status = $?
          process = process.not_nil!
          if status.success?
            puts " < worker #{process.pid} stopped"
          else
            puts " ! worker process #{process.pid} failed with #{status.exit_status}"
          end
        end
      end

    end

  end

end

