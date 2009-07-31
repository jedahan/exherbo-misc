#!/usr/bin/env ruby
# vim: set sw=4 sts=4 et tw=80 :

require 'Paludis'
require 'set'
include Paludis

Log.instance.log_level = LogLevel::Warning
Log.instance.program_name = $0

env = Paludis::EnvironmentFactory.instance.create ""
db = env.package_database
allpackages = Set.new

db.repositories do |repo|
    next unless repo.some_ids_might_support_action(SupportsActionTest.new(InstallAction))
    repo.category_names do |cat|
        next if ["group","user","virtual"].include? cat
        repo.package_names(cat) do |pkg|
            allpackages << pkg
        end
    end
end

puts allpackages.size
