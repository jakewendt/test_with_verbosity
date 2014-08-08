module JakeWendt; end
module JakeWendt::TestWithVerbosity

	def self.included(base)
		base.extend(ClassMethods)

		base.class_eval do
			class << self
				alias_method_chain( :test, :verbosity 
					) unless method_defined?(:test_without_verbosity)
			end
		end #unless base.respond_to?(:test_without_verbosity)
	end

	module ClassMethods

		#	activesupport-4.1.4/lib/active_support/testing/declarative.rb 
		def test(name, &block)
			#test_name = "test_#{name.gsub(/\s+/,'_')}".to_sym
			test_name = "test_#{name.gsub(/\W+/,'_')}".to_sym					#	NEED THIS
			defined = instance_method(test_name) rescue false
			raise "#{test_name} is already defined in #{self}" if defined
			if block_given?
				define_method(test_name, &block)

#
#	could possibly do something like this, but I can't seem to figure out
#	how to call a passed block correctly.
#
#				define_method(test_name) do
#					print "\n#{self.class.name.gsub(/Test$/,'').titleize} #{name}: "
#					block.call	#	FAIL
#				end
			else
				define_method(test_name) do
					flunk "No implementation provided for #{name}"
				end
			end
		end

		def test_with_verbosity(name,&block)
			test_without_verbosity(name,&block)
			test_name = "test_#{name.gsub(/\W+/,'_')}".to_sym
			define_method("_#{test_name}_with_verbosity") do
				print "\n#{self.class.name.gsub(/Test$/,'').titleize} #{name}: "
				send("_#{test_name}_without_verbosity")
			end
			#
			#	can't do this...
			#		alias_method_chain test_name, :verbosity
			#	end up with 2 methods that begin
			#	with 'test_' so they both get run
			#
			alias_method "_#{test_name}_without_verbosity".to_sym,
				test_name
			alias_method test_name,
				"_#{test_name}_with_verbosity".to_sym
		end

#
#
#	test names with punctuation aren't found when autotest tries to rerun them
#
#		def test_with_verbosity(name,&block)
#			test_without_verbosity(name,&block)
#			test_name = "test_#{name.gsub(/\s+/,'_')}".to_sym
#			define_method("_#{test_name}_with_verbosity") do
#				print "\n#{self.class.name.gsub(/Test$/,'').titleize} #{name}: "
#				send("_#{test_name}_without_verbosity")
#			end
#			#
#			#	can't do this...
#			#		alias_method_chain test_name, :verbosity
#			#	end up with 2 methods that begin
#			#	with 'test_' so they both get run
#			#
#			alias_method "_#{test_name}_without_verbosity".to_sym,
#				test_name
#			alias_method test_name,
#				"_#{test_name}_with_verbosity".to_sym
#		end

#
#	Trying to fix
#
#		def test_with_verbosity(name,&block)
#			test_without_verbosity(name,&block)
#
#
#			#	need to keep the \s+ regex as that is what rails' test_without_verbosity will create
#			#	( could just rewrite that too )
#			#	seems I'm gonna hafta
#			rails_test_name = "test_#{name.gsub(/\s+/,'_')}".to_sym
#
#
#			test_name = "test_#{name.gsub(/\W+/,'_')}".to_sym
#			define_method("_#{test_name}_with_verbosity") do
#				print "\n#{self.class.name.gsub(/Test$/,'').titleize} #{name}: "
#				send("_#{test_name}_without_verbosity")
#			end
#			#
#			#	can't do this...
#			#		alias_method_chain test_name, :verbosity
#			#	end up with 2 methods that begin
#			#	with 'test_' so they both get run
#			#
#			alias_method "_#{test_name}_without_verbosity".to_sym,
#				rails_test_name
#			alias_method rails_test_name,
#				"_#{test_name}_with_verbosity".to_sym
#		end

	end	#	ClassMethods

end	#	JakeWendt::TestWithVerbosity
ActiveSupport::TestCase.send(:include, JakeWendt::TestWithVerbosity)

Rails.backtrace_cleaner.add_silencer {|line|
  line =~ /test_with_verbosity/
} if defined? Rails 
