require "yaml"
require "language_pack/shell_helpers"

module LanguagePack
  class Fetcher
    include ShellHelpers
    CDN_YAML_FILE = File.expand_path("../../../config/cdn.yml", __FILE__)
    FETCHER_RETRY = ENV.fetch('FETCHER_RETRY') { 5 }.to_i

    def initialize(host_url, stack = nil)
      @config   = load_config
      @host_url = fetch_cdn(host_url)
      @host_url += File.basename(stack) if stack
    end

    def fetch(path)
      curl = curl_command("-O #{@host_url.join(path)}")
      run!(curl, :attempts => FETCHER_RETRY)
    end

    def fetch_untar(path, files_to_extract = nil)
      curl = curl_command("#{@host_url.join(path)} -s -o")
      run!("#{curl} - | tar zxf - #{files_to_extract}", :attempts => FETCHER_RETRY)
    end

    def fetch_bunzip2(path, files_to_extract = nil)
      curl = curl_command("#{@host_url.join(path)} -s -o")
      run!("#{curl} - | tar jxf - #{files_to_extract}", :attempts => FETCHER_RETRY)
    end

    private
    def curl_command(command)
      "set -o pipefail; curl -v --fail --retry 10 --connect-timeout #{curl_connect_timeout_in_seconds} --max-time #{curl_timeout_in_seconds} #{command}"
    end

    def curl_timeout_in_seconds
      ENV['CURL_TIMEOUT'] || 30
    end

    def curl_connect_timeout_in_seconds
      ENV['CURL_CONNECT_TIMEOUT'] || 3
    end

    def load_config
      YAML.load_file(CDN_YAML_FILE) || {}
    end

    def fetch_cdn(url)
      url = @config[url] || url
      Pathname.new(url)
    end
  end
end
