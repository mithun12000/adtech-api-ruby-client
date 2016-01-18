require 'java'
require 'logger'

java_import java.lang.System
System.setProperty('http.nonProxyHosts', '')
$CLASSPATH << 'lib/adtech/HeliosWSClientSystem'
$CLASSPATH << 'lib/adtech/HeliosWSClientSystem/lib'

PROG_NAME = 'ADTechAPIClient'

module ADTech
  class << self
    attr_writer :logger

    def logger
      @logger ||= Logger.new($stdout).tap { |log| log.progname = PROG_NAME }
    end
  end
end

require 'lib/adtech/HeliosWSClientSystem/HeliosWSClientSystem'
require 'adtech/client'
require 'adtech/api/report'