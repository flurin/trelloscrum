basedir = File.expand_path(File.dirname(__FILE__))
require "#{basedir}/lib/version"

Gem::Specification.new do |spec|
  spec.name = "trelloscrum"
  spec.version = TrelloScrum::VERSION
  spec.platform = Gem::Platform::RUBY
  spec.summary = "Creates product backlog cards from trello cards"
  spec.files =  Dir.glob("{bin,lib,resources}/**/**/*") +
                ["trelloscrum.gemspec", "Gemfile", "readme.md"]
  spec.require_path = "lib"

  spec.executables = ["trelloscrum"]

  spec.required_ruby_version = '>= 1.9.3'
  spec.required_rubygems_version = ">= 1.3.6"

  spec.authors = ["Flurin Egger"]
  spec.email = ["flurin@digitpaint.nl"]
  spec.licenses = ['MIT', 'SIL OFL']


  spec.add_dependency "json", "~> 1.8.1"
  spec.add_dependency "prawn", "~> 2.0.1"
  spec.add_dependency "prawn-table", "~> 0.2.1"
  spec.add_dependency "chronic", "~> 0.10.2"
  spec.add_dependency "ruby-trello", "~> 1.1.2"
  spec.add_dependency "thor", "~> 0.19.1"
  spec.add_dependency "launchy", "~> 2.4.3"

  spec.homepage = "https://github.com/flurin/trelloscrum"
  spec.description = <<END_DESC
  Generates PDF's with (+/-) one page per card with title, body and checklists. Print 4 of them on an A4 for the best action.
END_DESC
end
