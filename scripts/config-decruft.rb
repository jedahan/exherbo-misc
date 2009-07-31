#! /usr/bin/ruby -w

require 'Paludis'

################ output formatting ################

# XXX Don't assume ANSIish escape codes.
def colour(col, text) "[#{col}m#{text}[0m" end

def einfo(msg) puts " #{colour("1;32", "*")} #{msg}" end
def ewarn(msg) puts " #{colour("1;33", "*")} #{msg}" end

def fmt_spec(spec) colour("1;33", spec) end
def fmt_fn(fn)     colour(35,     fn)   end
def fmt_kw(kw)     colour(36,     kw)   end
def fmt_repo(repo) colour(32,     repo) end
def fmt_use(var, use, state = true)
    colour(33, (var.empty? ? "" : "#{var}: ") + (state ? use : "-#{use}"))
end
def fmt_pkg(pkg)
    pkg.slot # force this to be included
    colour(31, pkg)
end

################ config file reader ################

def read_conf(name, extra = nil)
    filenames = Dir["#{$config_dir}/#{name}.conf.d/*.conf"]
    filenames.unshift("#{$config_dir}/#{name}.conf")

    filenames.each do | filename |
        begin
            File.open(filename) do | file |
                einfo "Checking #{fmt_fn filename}#{if extra then " (#{extra})" end}"
                skip_entry, skip_block = false, false

                file.each_line do | line |
                    skip_block = false if line =~ /^\s*$/
                    skip_block = true  if line =~ /^\s*#.*DECRUFT:SKIP_BLOCK/
                    skip_entry = true  if line =~ /^\s*#.*DECRUFT:SKIP_ENTRY/
                    next unless line =~ /^\s*[^\s#]/

                    line.sub!(/\\$/) do | m |
                        file.gets.sub(/\n$/, "")
                    end while line =~ /\\$/

                    if skip_block || skip_entry then
                        # We pass the line to the block anyway, just
                        # hiding any messages, in case it affects any
                        # state that affects later lines.
                        report = proc { | msg | }
                    else
                        report = proc { | msg | puts msg }
                    end

                    yield line, report
                    skip_entry = false
                end

            end
        rescue Errno::ENOENT
            # treat as empty (should only happen for the .conf itself)
        end
    end
end

def tokenise(str)
    arr, str = [], str.dup
    arr << $2 while str.sub!(/^\s*(['"]?)(.+?)\1(?:\s|$)/, "")
    arr
end

################ query wrapper ################

# XXX take a block
def query_installed(spec, selection)
    if !spec.in_repository.nil? then
        repo  = spec.in_repository
        # XXX this is slightly sloppy, but should be fine
        mygen = Paludis::Generator::Matches.new(
                    Paludis::parse_user_package_dep_spec(spec.to_s.sub(/(?:::(?:->)?)?#{repo}$/, ""), $env, [:allow_wildcards]), []) &
                    Paludis::Generator::FromRepository.new(repo)
    else
        mygen = Paludis::Generator::Matches.new(spec, [])
    end

    $env[selection.new(mygen | Paludis::Filter::SupportsAction.new(Paludis::InstalledAction))]
end

################ evil trickery ################

class FakeFromRepositoriesKey
    def initialize(value)
        @value = value
    end
    attr_reader :value
end

class Paludis::PackageID
    @@faked_source_origins = {}
    @@origins = {}

    alias :real_from_repositories_key :from_repositories_key
    def from_repositories_key
        real = real_from_repositories_key
        return real if (real && !real.value.empty?) ||
            !supports_action(Paludis::SupportsActionTest.new(Paludis::InstalledAction))

        return FakeFromRepositoriesKey.new(["virtuals"]) unless virtual_for_key.nil?

        Paludis::Log.instance.
            message("config-decruft.unknown_origin", Paludis::LogLevel::Warning,
                    "Unable to determine origin repository for #{self}, assuming #{$db.favourite_repository}") unless @@faked_source_origins[self]
        @@faked_source_origins[self] = true
        FakeFromRepositoriesKey.new([$db.favourite_repository])
    end

    def origin
        return @@origins[self] if @@origins.has_key?(self)
        from_sorted = from_repositories_key.value.sort
        from_sorted.each do | repo_name |
            id = $env[Paludis::Selection::BestVersionOnly.new(
                 Paludis::Generator::Matches.new(
                     Paludis::parse_user_package_dep_spec(
                         "#{name}::#{repo_name}[=#{version}]", $env, [:allow_wildcards]), []))].last
            next if id.nil?
            return @@origins[self] = id if (id.from_repositories_key ||
                                            FakeFromRepositoriesKey.new([])).
                value.unshift(repo_name).sort == from_sorted
        end
        @@origins[self] = nil
    end
end

################ initialisation ################

Paludis::Log.instance.program_name = $0
$envspec = ""

require 'getoptlong'
GetoptLong.new(

    ["--help",          "-h", GetoptLong::NO_ARGUMENT],

    ["--log-level",           GetoptLong::REQUIRED_ARGUMENT],
    ["--environment",   "-E", GetoptLong::REQUIRED_ARGUMENT]

).each do | opt, arg |
    case opt

    when "--help"
        puts <<HELP
Usage: #$0 [options]

Options:
  --log-level            Specify the log level
      debug                Show debug output (noisy)
      qa                   Show QA messages and warnings only (default)
      warning              Show warnings only
      silent               Suppress all log messages (UNSAFE)
  --environment, -E      Environment specification (class:suffix, both parts optional, class must be 'paludis' if specified)

Scans Paludis configuration files (currently: use.conf, keywords.conf,
package_mask.conf and package_unmask.conf, and their corresponding
.conf.d directories) and reports apparently redundant constructs.  A
comment containing DECRUFT:SKIP_ENTRY will cause it to ignore the
following line; DECRUFT:SKIP_BLOCK will ignore everything up to the
next blank line.
HELP
        exit

    when "--log-level"
        Paludis::Log.instance.log_level = case arg
            when "debug":   Paludis::LogLevel::Debug
            when "qa":      Paludis::LogLevel::Qa
            when "warning": Paludis::LogLevel::Warning
            when "silent":  Paludis::LogLevel::Silent
            else
                $stderr.puts "#$0: invalid #{opt}: #{arg}"
                exit 1
        end
    when "--environment"
        $envspec = arg

    end
end

$env = Paludis::EnvironmentFactory.instance.create($envspec)
if $env.format_key.value != "paludis" then
    $stderr.puts "#$0: --environment must specify class 'paludis'"
    exit 1
end
$config_dir = $env.config_location_key.value
$db = $env.package_database

################ keywords.conf ################

global_kws = {}
read_conf("keywords", "pass 1/2") do | line, report |
    spec_str, *kws = tokenise(line)
    spec_str = "*/*" if spec_str == "*"

    if spec_str == "*/*" then
        kws.each do | kw |
            if global_kws[kw] then
                report["#{fmt_spec spec_str}: #{fmt_kw kw} specified more than once"]
            else
                global_kws[kw] = true
            end
        end
    end
end

seen_specs = {}
read_conf("keywords", "pass 2/2") do | line, report |
    spec_str, *kws = tokenise(line)
    spec_str = "*/*" if spec_str == "*"
    next if spec_str == "*/*"

    # XXX Check for overlapping but non-identical specs?
    if seen_specs[spec_str] then
        report["#{fmt_spec spec_str}: specified more than once"]
    else
        seen_specs[spec_str] = true
    end

    accepted_kws, seen_kws, use_global = [], {}, !kws.include?("-*")
    kws.each do | kw |
        if seen_kws[kw] then
            report["#{fmt_spec spec_str}: #{fmt_kw kw} specified more than once"]
        elsif global_kws[kw] && use_global then
            report["#{fmt_spec spec_str}: #{fmt_kw kw} is specified globally"]
        elsif kw != "-*" then
            seen_kws[kw] = true
            accepted_kws << kw unless kw == "-*"
            if kw != "*" && seen_kws["*"] then
                report["#{fmt_spec spec_str}: #{fmt_kw kw} is redundant after #{fmt_kw "*"}"]
            end
        end
    end

    begin
        spec = Paludis::parse_user_package_dep_spec(spec_str, $env, [:no_disambiguation, :throw_if_set])
    rescue Paludis::GotASetNotAPackageDepSpec
        # A set name, we don't handle those (XXX yet?)
        next
    rescue Paludis::PackageDepSpecError
        # A wildcard, we don't handle those (XXX yet?)
        next
    end

    installed_slots = {}
    query_installed(spec, Paludis::Selection::AllVersionsUnsorted).each do | pkg |
        installed_slots[pkg.slot] = pkg
    end

    if installed_slots.empty? then
        report["#{fmt_spec spec_str}: not installed"]
        next
    end

    # Cache the list of uninstalled packages that match the current
    # keywords entry, in reverse order because we like higher versions
    # best.
    uninst = $env[Paludis::Selection::AllVersionsGroupedBySlot.new(
                      Paludis::Generator::Matches.new(spec, []) |
                      Paludis::Filter::NotMasked.new |
                      Paludis::Filter::SupportsAction.new(Paludis::InstallAction))].reverse

    installed_slots.each_key do | slot |
        # newest_older_kw == nil => was accepted by global keywords
        newest_older, newest_older_kw, newest_older_kws = nil, nil, nil

        uninst.each do | older |
            # Since we're grouping by slot, if we've found one in the
            # correct slot and this one is in a different slot, then
            # there can be no more to come.
            break if older.slot != slot && newest_older
            next  if older.slot != slot

            kws = older.keywords_key.value
            accepted = kws & global_kws.keys
            if use_global && !accepted.empty? then
                newest_older, newest_older_kw, newest_older_kws = older, nil, accepted
                # Since we're sorting in reverse order, no chance of a
                # better match later.
                break
            end

            accepted_kws.each do | kw |
                # We assume earlier keywords are prefered over later
                # ones.  We're sorting in reverse and we prefer newer
                # packages, so don't override if we have the same
                # keyword as the previously chosen package.
                break if kw == newest_older_kw
                if kws.include?(kw) then
                    newest_older, newest_older_kw, newest_older_kws =
                        older, kw, [kw]
                    break
                end
            end
        end

        if newest_older && newest_older_kw != accepted_kws[-1] then
            report["#{fmt_spec spec_str}: #{fmt_pkg installed_slots[slot]} installed, #{fmt_pkg newest_older} available with keywords #{fmt_kw newest_older_kws.join(" ")}"]
        end
    end

end

################ use.conf ################

def parse_flags(flags)
    var = ""
    flags.each do | flag |

        if flag[-1] == ?: then
            var = flag[0..-2]
            next
        end

        if flag[0] == ?- then
            state = false
            flag = flag[1..-1]
        else
            state = true
        end

        yield var, flag, state
    end
end

global_uses, skip_defaults = {}, {}
read_conf("use", "pass 1/2") do | line, report |
    spec_str, *flags = tokenise(line)
    spec_str = "*/*" if spec_str == "*"
    parse_flags(flags) do | var, flag, state |

        skip_defaults[spec_str] ||= {}
        if flag == "*" then
            if skip_defaults[spec_str][var] then
                report["#{fmt_spec spec_str}: #{fmt_use var, flag} specified more than once"]
            end
            skip_defaults[spec_str][var] = true
            next
        end

        next unless spec_str == "*/*"
        global_uses[var] ||= {}
        global_uses[var][flag] = state
    end
end

global_uses.default = {}
missing_origins = {}
all_uses = {}

read_conf("use", "pass 2/2") do | line, report |
    spec_str, *flags = tokenise(line)
    spec_str = "*/*" if spec_str == "*"

    begin
        spec = Paludis::parse_user_package_dep_spec(spec_str, $env, [:allow_wildcards, :no_disambiguation, :throw_if_set])
        installed = []
        query_installed(spec, Paludis::Selection::AllVersionsSorted).each do | pkg |
            iuse = {}

            if pkg.origin.nil? then
                if !missing_origins.has_key?(pkg) && !pkg.choices_key.nil? then
                    Paludis::Log.instance.
                        message("config-decruft.missing_origin", Paludis::LogLevel::Warning,
                                "Unable to find origin package for #{pkg}, ignoring masks/forces/defaults")
                    missing_origins[pkg] = true
                end

                pkg.choices_key.value.each do | choice |
                    choice.each do | value |
                        iuse[choice.prefix] = {} unless iuse.has_key?(choice.prefix)
                        iuse[choice.prefix][value.unprefixed_name] = :maybe
                    end
                end unless pkg.choices_key.nil?

            else
                pkg.origin.choices_key.value.each do | choice |
                    choice.each do | value |
                        iuse[choice.prefix] = {} unless iuse.has_key?(choice.prefix)
                        iuse[choice.prefix][value.unprefixed_name] =
                            if value.locked? then
                                value.enabled? ? :forced : :masked
                            else
                                value.enabled_by_default?
                            end
                    end
                end unless pkg.origin.choices_key.nil?
            end

            installed << [pkg, iuse, pkg.origin ? pkg.origin.repository_name : pkg.from_repositories_key.value.last]
        end

        if installed.empty? then
            report["#{fmt_spec spec_str}: not installed"]
            next
        end

    rescue Paludis::GotASetNotAPackageDepSpec
        # XXX implement me
    end

    # DON'T check for duplicated specs here, because the list can get
    # long and therefore the user might want to split it up.  XXX
    # Might want to check that the parts are adjacent, though (for
    # sanity purposes), and that the same flag isn't set twice for
    # overlapping but non-identical specs.
    all_uses[spec_str] ||= {}

    parse_flags(flags) do | var, flag, state |
        next if flag == "*"
        all_uses[spec_str][var] ||= {}

        if all_uses[spec_str][var].has_key?(flag) then
            if all_uses[spec_str][var][flag] == state then
                report["#{fmt_spec spec_str}: #{fmt_use var, flag, state} specified more than once"]
            else
                report["#{fmt_spec spec_str}: #{fmt_use var, flag, all_uses[spec_str][var][flag]} overridden by #{fmt_use var, flag, state}"]
            end
        end
        all_uses[spec_str][var][flag] = state

        if !state && skip_defaults[spec_str][var] then
            report["#{fmt_spec spec_str}: #{fmt_use var, flag, state} implied by #{fmt_use var, "-*"}"]
        else
            # XXX handle more levels of subsetting than "anything subsetof */*"
            if spec_str != "*/*" then
                if global_uses[var][flag] == state && !skip_defaults[spec_str][var] then
                    report["#{fmt_spec spec_str}: #{fmt_use var, flag, state} set globally in config file"]
                elsif !state && skip_defaults["*/*"][var] &&
                        !global_uses[var].has_key?(flag) then
                    report["#{fmt_spec spec_str}: #{fmt_use var, flag, state} implied by global #{fmt_use var, "-*"}"]
                end
            end
        end

        next if spec.nil?

        var_down = var.downcase
        relevant, whynot = false, {}

        installed.each do | pkg, iuse, repo_name |
            if !iuse.has_key?(var_down) || !iuse[var_down].has_key?(flag) then
                if spec.package then
                    report["#{fmt_spec spec_str}: #{fmt_pkg pkg} installed from #{fmt_repo repo_name}, does not use #{fmt_use var, flag}"]
                end

            elsif iuse[var_down][flag] == :masked then
                whynot[:masked] = true
                if spec.package then
                    report["#{fmt_spec spec_str}: #{fmt_pkg pkg} installed from #{fmt_repo repo_name}, has #{fmt_use var, flag} masked by profile"]
                end

            elsif iuse[var_down][flag] == :forced then
                whynot[:forced] = true
                if spec.package then
                    report["#{fmt_spec spec_str}: #{fmt_pkg pkg} installed from #{fmt_repo repo_name}, has #{fmt_use var, flag} forced by profile"]
                end

            elsif !skip_defaults[spec_str][var] &&
                    (spec_str == "*/*" ||
                     (!skip_defaults["*/*"][var] &&
                      !global_uses[var].has_key?(flag))) &&
                    iuse[var_down][flag] == state then
                whynot[:set] = true
                if spec.package then
                    report["#{fmt_spec spec_str}: #{fmt_pkg pkg} installed from #{fmt_repo repo_name}, has #{fmt_use var, flag, state} set by profile and/or package defaults"]
                end

            else
                relevant = true
            end
        end

        if spec.package.nil? && !relevant then
            if whynot.empty? then
                report["#{fmt_spec spec_str}: #{fmt_use var, flag} not used by any matching installed packages"]
            else
                report["#{fmt_spec spec_str}: #{fmt_use var, flag} #{whynot.keys.join('/')} by profile#{whynot[:set] && " and/or package defaults"} for all matching installed packages"]
            end
        end
    end

end

################ package_mask.conf ################

# Store these so we can check package_unmask.conf entries against
# them.
masked_specs = {}

seen_specs = {}
read_conf("package_mask") do | line, report |
    spec_str = line.chomp

    # XXX Check for overlapping but non-identical specs?
    if seen_specs[spec_str] then
        report["#{fmt_spec spec_str}: specified more than once"]
        # Unlike for keywords.conf, there's nothing more that a second
        # occurance of the same spec can add.
        next
    end
    seen_specs[spec_str] = true

    begin
        spec = Paludis::parse_user_package_dep_spec(spec_str, $env, [:allow_wildcards, :no_disambiguation, :throw_if_set])
    rescue Paludis::GotASetNotAPackageDepSpec
        # XXX do something here
        next
    end

    masked_specs[spec.package] ||= []
    masked_specs[spec.package] << spec

    # Can't use NotMasked because we're dealing with things in package_mask.conf.
    uninst = $env[Paludis::Selection::AllVersionsSorted.new(
                      Paludis::Generator::Matches.new(spec, []) |
                      Paludis::Filter::SupportsAction.new(Paludis::InstallAction))]
    if uninst.empty? then
        report["#{fmt_spec spec_str}: does not match any packages"]
        next
    end

    unmask_conf = true
    unmasked = uninst.reject do | pkg |
        masked = false
        # Seems more useful not to consider keyword masks here,
        # because they often get unmasked eventually.
        pkg.masks.each do | mask |
            if mask.kind_of?(Paludis::UserMask) then
                unmask_conf = false
            elsif !(mask.kind_of?(Paludis::UnacceptedMask) && pkg.keywords_key &&
                    mask.unaccepted_key.raw_name == pkg.keywords_key.raw_name &&
                    $env.accept_keywords(pkg.keywords_key.value.collect { | kw |
                                             kw.sub(/^~/, "") }, pkg)) then
                masked = true
            end
        end
        masked
    end

    if unmasked.empty? then
        report["#{fmt_spec spec_str}: all matching packages are already masked"]
        next
    end

    if unmask_conf then
        report["#{fmt_spec spec_str}: all matching packages are unmasked in #{fmt_fn "package_unmask.conf (.d)"}"]
        next
    end

    next if spec.package.nil?

    unmasked_slots = {}
    unmasked.each do | pkg |
        unmasked_slots[pkg.slot] = pkg unless
            unmasked_slots[pkg.slot] &&
            unmasked_slots[pkg.slot].version > pkg.version
    end

    unmasked_slots.each_pair do | slot, pkg |
        # The assumption here is that if you mask specific versions,
        # it's probably because those versions don't work for you, and
        # therefore once you've upgraded past them there's no need for
        # the mask anymore.  XXX Should consider the interaction with
        # keywords here: if you upgrade past the broken version,
        # remove the mask and then the broken version goes stable, the
        # script might suggest downgrading to the broken version.
        query_installed(Paludis::parse_user_package_dep_spec(">#{pkg.name}-#{pkg.version}:#{slot}", $env, []),
                        Paludis::Selection::AllVersionsSorted).each do | inst_pkg |
            report["#{fmt_spec spec_str}: installed version #{fmt_pkg inst_pkg} is higher than highest masked version #{fmt_pkg pkg}"]
        end
    end

end

################ package_unmask.conf ################

# Much the same as keywords.conf....

seen_specs = {}
read_conf("package_unmask") do | line, report |
    spec_str = line.chomp

    # XXX Check for overlapping but non-identical specs?
    if seen_specs[spec_str] then
        report["#{fmt_spec spec_str}: specified more than once"]
        # Unlike for keywords.conf, there's nothing more that a second
        # occurance of the same spec can add.
        next
    end
    seen_specs[spec_str] = true

    begin
        spec = Paludis::parse_user_package_dep_spec(spec_str, $env, [:no_disambiguation, :throw_if_set])
    rescue Paludis::GotASetNotAPackageDepSpec
        next
    rescue Paludis::PackageDepSpecError
        next
    end

    installed_slots = {}
    query_installed(spec, Paludis::Selection::AllVersionsUnsorted).each do | pkg |
        installed_slots[pkg.slot] = pkg
    end

    if installed_slots.empty? then
        report["#{fmt_spec spec_str}: not installed"]
        next
    end

    # Cache the list of uninstalled packages that match the current
    # unmask entry, in reverse order because we like higher versions
    # best.
    uninst = $env[Paludis::Selection::AllVersionsGroupedBySlot.new(
                      Paludis::Generator::Matches.new(spec, []) |
                      Paludis::Filter::NotMasked.new |
                      Paludis::Filter::SupportsAction.new(Paludis::InstallAction))].reverse

    installed_slots.each_key do | slot |
        # To check for applicable older packages, only find the ones
        # covered by the unmask entry (assume anything else isn't
        # useful to the user).

        uninst.each do | older |
            next if older.slot != slot
            repo = $db.fetch_repository(older.repository_name)

            # These won't be checked by NotMasked because we're in
            # package_unmask.conf.
            catch :masked do
                older.each_metadata do | key |
                    throw :masked, true if
                        key.kind_of?(Paludis::MetadataRepositoryMaskInfoKey) &&
                        !key.value.nil?
                end

                ((masked_specs[older.name] || []) +
                 (masked_specs[nil] || [])).each do | masked |
                    throw :masked, true if
                        Paludis::match_package($env, masked, older, [])
                end

                false
            end and next

            # Since we're in reverse order, there's no chance of
            # finding anything newer.
            report["#{fmt_spec spec_str}: #{fmt_pkg installed_slots[slot]} installed, #{fmt_pkg older} available and not masked"]
            break
        end

    end

end

