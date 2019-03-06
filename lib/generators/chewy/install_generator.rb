module Chewy
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('../../templates', __FILE__)

      def copy_configuration
        template 'hs_chewy.yml', 'config/hs_chewy.yml'
      end
    end
  end
end
