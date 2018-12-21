MRuby::Gem::Specification.new 'mruby-tcc-port' do |spec|
  spec.author = 'take-cheeze'
  spec.license = 'MIT'

  add_dependency 'mruby-struct'
  add_dependency 'mruby-shellwords'

  add_test_dependency 'mruby-stringio'
end
