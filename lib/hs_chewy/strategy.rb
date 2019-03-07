require 'hs_chewy/strategy/base'
require 'hs_chewy/strategy/bypass'
require 'hs_chewy/strategy/urgent'
require 'hs_chewy/strategy/atomic'

begin
  require 'resque'
  require 'hs_chewy/strategy/resque'
rescue LoadError
  nil
end

begin
  require 'sidekiq'
  require 'hs_chewy/strategy/sidekiq'
rescue LoadError
  nil
end

begin
  require 'shoryuken'
  require 'hs_chewy/strategy/shoryuken'
rescue LoadError
  nil
end

begin
  require 'active_job'
  require 'hs_chewy/strategy/active_job'
rescue LoadError
  nil
end

module HSChewy
  # This class represents strategies stack with `:base`
  # Strategy on top of it. This causes raising exceptions
  # on every index update attempt, so other strategy must
  # be choosen.
  #
  #   User.first.save # Raises UndefinedUpdateStrategy exception
  #
  #   HSChewy.strategy(:atomic) do
  #     User.last.save # Save user according to the `:atomic` strategy rules
  #   end
  #
  class Strategy
    def initialize
      @stack = [resolve(HSChewy.root_strategy).new]
    end

    def current
      @stack.last
    end

    def push(name)
      result = @stack.push resolve(name).new
      debug "[#{@stack.size - 1}] <- #{current.name}" if @stack.size > 2
      result
    end

    def pop
      raise "Can't pop root strategy" if @stack.one?
      result = @stack.pop.tap(&:leave)
      debug "[#{@stack.size}] -> #{result.name}, now #{current.name}" if @stack.size > 1
      result
    end

    def wrap(name)
      stack = push(name)
      yield
    ensure
      pop if stack
    end

  private

    def debug(string)
      return unless HSChewy.logger && HSChewy.logger.debug?
      line = caller.detect { |l| l !~ %r{lib/chewy/strategy.rb:|lib/hs_chewy.rb:} }
      HSChewy.logger.debug(["Chewy strategies stack: #{string}", line.sub(/:in\s.+$/, '')].join(' @ '))
    end

    def resolve(name)
      "HSChewy::Strategy::#{name.to_s.camelize}".safe_constantize or raise "Can't find update strategy `#{name}`"
    rescue NameError => ex
      # WORKAROUND: Strange behavior of `safe_constantize` with mongoid gem
      raise "Can't find update strategy `#{name}`" if ex.name.to_s.demodulize == name.to_s.camelize
      raise
    end
  end
end
