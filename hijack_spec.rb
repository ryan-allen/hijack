require 'hijack'

class Processor

  def self.process(string)
    string.upcase
  end
  
  def process(string)
    string.upcase
  end
  
end

%w(rubygems spec).each { |lib| require lib }

describe Processor do
  
  it 'upcases strings with Process.process()' do
    Processor.process('hi').should == 'HI'
  end
  
  it 'upcases strings with Process#process()' do
    Processor.process('ho').should == 'HO'
  end
  
end

describe Hijack do
  
  [:instances_of, :metaclass].each do |method|
    describe ".#{method}()" do
      
      before do
        case method
        when :instances_of
          @target = Processor.clone.new
          @class  = @target.class
        when :metaclass
          @target = Processor.clone
          @class = @target
        end
      end
      
      it 'hijacks method args with before' do
        Hijack.send(method, @class).before(:process) do |string|
          string.gsub!('be', 'zombie ')
        end
        @target.process('great bejesus').should == 'GREAT ZOMBIE JESUS'
      end
      
      it 'chains before in order of definition' do
        Hijack.send(method, @class).before(:process) do |string|
          string.gsub!('oh my god', 'zomg')
        end
        Hijack.send(method, @class).before(:process) do |string|
          string.gsub!('zomg', 'zomg!!1')
        end
        @target.process('oh my god').should == 'ZOMG!!1'
      end
      
      it 'hijacks return value with after' do
        Hijack.send(method, @class).after(:process) do |result|
          "#{result} x2"
        end
        @target.process(method.to_s).should == "#{method.to_s.upcase} x2"
      end
      
      it 'chains after in order of definition' do
        Hijack.send(method, @class).after(:process) { |r| "#{r} x1" }
        Hijack.send(method, @class).after(:process) { |r| "#{r} x2" }
        @target.process(method.to_s).should == "#{method.to_s.upcase} x1 x2"
      end
      
      it 'plays nicely with #before and #after at the same time' do
        Hijack.send(method, @class).before(:process) do |string|
          string.gsub!('ryan', 'heidi')
        end
        Hijack.send(method, @class).after(:process) { |r| "#{r} dog!!" }
        @target.process('ryan').should == 'HEIDI dog!!'
      end
      
      it 'plays nicely when chaining #before and #after at the same time' do
        Hijack.send(method, @class).before(:process) do |string|
          string.gsub!('ryan', 'heidi')
        end
        Hijack.send(method, @class).before(:process) do |string|
          string.gsub!('heidi', 'woofer')
        end
        Hijack.send(method, @class).after(:process) { |r| "#{r} is a" } 
        Hijack.send(method, @class).after(:process) { |r| "#{r} MONSTER!" }
        @target.process('ryan').should == 'WOOFER is a MONSTER!'
      end
                              
    end
    
  end
  
  # now we're only testing this in the context of a class, i'm not
  # sure that it'd be customary to include Hijack into a metaclass,
  # though you could - but that would require us to do more futzing
  # and we're already sick of doing that :)
  
  it 'mixes in #before and #after when Hijack is included' do
    @target = Processor.clone.new
    @target.class.class_eval { include Hijack }
    @target.instance_eval do
      before :process do |string|
        string.gsub!('seen', 'where is')
      end
      after :process do |result|
        result.gsub!('KEYS?', 'LEG??!')
      end
    end
    @target.process('seen my keys?').should == 'WHERE IS MY LEG??!'
  end
  
  # later, later!
  
  it 'is refactored to get rid of nasty duplication :O'    
  it 'does not forget blocks in method sigs - use lame eval meta :('
  it 'is thread safe (on meta methods? how the f do you test this?)'
  it 'has performance tests for memory leaks :)'
  it 'is decided if after hooks should have access to before attrs?'
  it 'works with inheritance (fucking inheritance!)'
  
end
