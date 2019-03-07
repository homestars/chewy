require 'hs_chewy/runtime/version'

module HSChewy
  module Runtime
    def self.version
      Thread.current[:chewy_runtime_version] ||= Version.new(HSChewy.client.info['version']['number'])
    end
  end
end
