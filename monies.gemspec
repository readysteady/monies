Gem::Specification.new do |s|
  s.name = 'monies'
  s.version = '2.0.1'
  s.license = 'LGPL-3.0'
  s.platform = Gem::Platform::RUBY
  s.authors = ['Tim Craft']
  s.email = ['email@timcraft.com']
  s.homepage = 'https://github.com/readysteady/monies'
  s.description = 'Ruby gem for representing monetary values'
  s.summary = 'Ruby gem for representing monetary values'
  s.files = Dir.glob('lib/**/*.rb') + %w[CHANGES.md LICENSE.txt README.md monies.gemspec]
  s.required_ruby_version = '>= 3.3.0'
  s.require_path = 'lib'
  s.metadata = {
    'homepage' => 'https://github.com/readysteady/monies',
    'source_code_uri' => 'https://github.com/readysteady/monies',
    'bug_tracker_uri' => 'https://github.com/readysteady/monies/issues',
    'changelog_uri' => 'https://github.com/readysteady/monies/blob/main/CHANGES.md'
  }
end
