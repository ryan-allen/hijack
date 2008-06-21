%w(rubygems metaid).each { |lib| require lib }

module Hijack
  
  class << self
    
    # supporting include hack-style since 2008, only for use
    # in classes, not in metaclasses :)
    
    def append_features(receiver)
      receiver.class_eval do
        def before(m, &hook)
          Hijack.instances_of(self.class).before(m, &hook)
        end
        def after(m, &hook)
          Hijack.instances_of(self.class).after(m, &hook)
        end
      end
    end
    
    # be a repository for hijackings? kthxbye
  
    def befores(c, m)
      (@@befores||={};@@befores[c]||={};@@befores[c][m]||=[])
    end

    def afters(c, m)
      (@@afters||={};@@afters[c]||={};@@afters[c][m]||=[])
    end

    # we don't reset coz we don't need it, in real life usage we
    # don't ever reset hijackings, it only makes sense in tests
    # scenarios and in this case coz we're cloning classes to 
    # ensure isolation, this method is redundant (and possibly
    # confusing).
    #
    # def reset!
    #   @@befores, @@afters = nil, nil
    # end
  
    # the API for hijacking unsuspecting classes
  
    def instances_of(klass)
      @eval = :class_eval
      @class = klass
      self
    end
  
    def metaclass(klass)
      @eval = :instance_eval
      @class = klass.metaclass
      self
    end
  
    # the follow-on methods, higher order functions
  
    def before(m, &hook)
      evaluator = @eval == :class_eval ? 'self.class' : 'metaclass'
      @class.send(@eval) do
        if Hijack.befores(self, m).empty? and Hijack.afters(self, m).empty?
          alias_method "hijacked_#{m}", m
          define_method m do |*args|
            Hijack.befores(eval(evaluator), m).each { |h| h.call(*args) }
            r = send("hijacked_#{m}", *args)
            Hijack.afters(eval(evaluator), m).each { |h| r = h.call(r) }
            r            
          end
        end
        Hijack.befores(self, m) << hook
      end
    end
  
    def after(m, &hook)
      evaluator = @eval == :class_eval ? 'self.class' : 'metaclass'
      @class.send(@eval) do
        if Hijack.befores(self, m).empty? and Hijack.afters(self, m).empty?
          alias_method "hijacked_#{m}", m
          define_method m do |*args|
            Hijack.befores(eval(evaluator), m).each { |h| h.call(*args) }
            r = send("hijacked_#{m}", *args)
            Hijack.afters(eval(evaluator), m).each { |h| r = h.call(r) }
            r            
          end
        end
        Hijack.afters(self, m) << hook
      end
    end
  end
  
end