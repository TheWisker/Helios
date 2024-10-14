# Print an optspec for argparse to handle cmd's options that are independent of any subcommand.
function __fish_arch_audit_global_optspecs
	string join \n q/quiet r/recursive t/show-testing u/upgradable C/color= b/dbpath= f/format= json source= proxy= no-proxy sort= c/show-cve h/help V/version
end

function __fish_arch_audit_needs_command
	# Figure out if the current invocation already has a command.
	set -l cmd (commandline -opc)
	set -e cmd[1]
	argparse -s (__fish_arch_audit_global_optspecs) -- $cmd 2>/dev/null
	or return
	if set -q argv[1]
		# Also print the command, so this can be used to figure out what it is.
		echo $argv[1]
		return 1
	end
	return 0
end

function __fish_arch_audit_using_subcommand
	set -l cmd (__fish_arch_audit_needs_command)
	test -z "$cmd"
	and return 1
	contains -- $cmd[1] $argv
end

complete -c arch-audit -n "__fish_arch_audit_needs_command" -s C -l color -d 'Bypass tty detection for colors' -r -f -a "{auto\t'',always\t'',never\t''}"
complete -c arch-audit -n "__fish_arch_audit_needs_command" -s b -l dbpath -d 'Set an alternate database location' -r -F
complete -c arch-audit -n "__fish_arch_audit_needs_command" -s f -l format -d 'Specify a format to control the output. Placeholders are %n (pkgname), %c (CVEs), %v (fixed version), %t (type), %s (severity), and %r (required by, only when -r is also used)' -r
complete -c arch-audit -n "__fish_arch_audit_needs_command" -l source -d 'Specify the URL or file path to the security tracker json data' -r
complete -c arch-audit -n "__fish_arch_audit_needs_command" -l proxy -d 'Send requests through a proxy' -r
complete -c arch-audit -n "__fish_arch_audit_needs_command" -l sort -d 'Specify how to sort the output' -r -f -a "{severity\t'',pkgname\t'',upgradable\t'',reverse\t''}"
complete -c arch-audit -n "__fish_arch_audit_needs_command" -s q -l quiet -d 'Show only vulnerable package names and their versions. Set twice to hide the versions as well'
complete -c arch-audit -n "__fish_arch_audit_needs_command" -s r -l recursive -d 'Prints packages that depend on vulnerable packages and are thus potentially vulnerable as well. Set twice to show ALL the packages that requires them'
complete -c arch-audit -n "__fish_arch_audit_needs_command" -s t -l show-testing -d 'Show packages which are in the [testing] repos. See https://wiki.archlinux.org/index.php/Official_repositories#Testing_repositories'
complete -c arch-audit -n "__fish_arch_audit_needs_command" -s u -l upgradable -d 'Show only packages that have already been fixed'
complete -c arch-audit -n "__fish_arch_audit_needs_command" -l json -d 'Print json output'
complete -c arch-audit -n "__fish_arch_audit_needs_command" -l no-proxy -d 'Do not use a proxy even if one is configured'
complete -c arch-audit -n "__fish_arch_audit_needs_command" -s c -l show-cve -d 'Print the CVE numbers'
complete -c arch-audit -n "__fish_arch_audit_needs_command" -s h -l help -d 'Print help'
complete -c arch-audit -n "__fish_arch_audit_needs_command" -s V -l version -d 'Print version'
complete -c arch-audit -n "__fish_arch_audit_needs_command" -f -a "completions" -d 'Generate shell completions'
complete -c arch-audit -n "__fish_arch_audit_needs_command" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
complete -c arch-audit -n "__fish_arch_audit_using_subcommand completions" -s h -l help -d 'Print help'
complete -c arch-audit -n "__fish_arch_audit_using_subcommand help; and not __fish_seen_subcommand_from completions help" -f -a "completions" -d 'Generate shell completions'
complete -c arch-audit -n "__fish_arch_audit_using_subcommand help; and not __fish_seen_subcommand_from completions help" -f -a "help" -d 'Print this message or the help of the given subcommand(s)'
