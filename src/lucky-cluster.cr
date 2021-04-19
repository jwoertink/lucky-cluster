require "future"

module Lucky
  class Cluster < ::AppServer
    VERSION = {{ `shards version #{__DIR__}`.chomp.stringify }}
    private getter processes : Array(Future::Compute(Nil))
    private getter reuse_port : Bool
    property threads : Int32 = 1

    def initialize
      @processes = [] of Future::Compute(Nil)
      @reuse_port = true
      super
    end

    # The parent process controlls the children
    def parent?
      ARGV[0]? != "--child"
    end

    # Threads not specified, or set to 0, 1...
    def single_boot?
      threads < 2
    end

    def listen : Nil
      if single_boot?
        @reuse_port = false
        listen_once
      else
        @reuse_port = true
        listen_carefully
      end
    end

    def close : Nil
      processes.each(&.get)
      server.close
    end

    private def bind_tcp_and_listen
      server.bind_tcp(host, port, reuse_port: @reuse_port)
      server.listen
    end

    private def listen_once
      log_boot
      bind_tcp_and_listen

      Signal::INT.trap do |_signal|
        puts "Stopping server"
        server.close
      end
    end

    private def listen_carefully
      if parent?
        boot
        Signal::INT.trap do |signal|
          puts " > terminating gracefully"
          spawn { close }
          signal.ignore
        end
      end

      bind_tcp_and_listen
    end

    private def log_boot
      puts "Listening on http://#{host}:#{port}"
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
