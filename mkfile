MKSHELL=rc

SCHEMA=iris.schema.json
JSFH_CONFIG=jsfh-config.yaml

# HAVE_STABLE is non-empty once at least one stable release directory exists
# under www/. Controls whether the top-level pointers (www/schema.json and
# www/jsfh) track dev (pre-first-stable) or stay pinned to whatever the most
# recent release cut set them to.
HAVE_STABLE=`{find www -mindepth 1 -maxdepth 1 -type d -name '[0-9]*.[0-9]*.[0-9]*' >[2]/dev/null}

#	Default VERSION. Command-line VERSION=x.y.z overrides for releases.
#	From mk(1) manual page:
#		The initial value of a variable is taken from (in increasing order of precedence) 
#		the default values below, mk’s environment, the mkfiles, and any command line 
#		assignment as an argument to mk.
VERSION=dev

#
#	Default target: rebuild whatever VERSION is (dev by default).
#
default:V: lint www

#
#	Lint — run as a build prereq.
#
lint:V:
	go run ./cmd/iris-lint --check-schema >/dev/null

#
#	Schema for the current VERSION.
#	  VERSION=dev    — cp the repo schema directly.
#	  VERSION=x.y.z  — sed-substitute version strings.
#
www/$VERSION/schema.json: $SCHEMA
	switch($VERSION) {
	case dev
		mkdir -p `{dirname $target}
		cp $prereq $target
	case [0-9]*.[0-9]*.[0-9]*
		if(! echo $VERSION | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$') {
			echo 'mk: VERSION='^$VERSION^' must be strict x.y.z (numeric segments only, no pre-release suffixes)' >[1=2]
			exit 1
		}
		mkdir -p `{dirname $target}
		sed -e 's|"const": "dev"|"const": "'^$VERSION^'"|' \
		    -e 's|/dev/schema\.json|/'^$VERSION^'/schema.json|g' \
		    $prereq > $target
	case *
		echo 'mk: VERSION='^$VERSION^' must be "dev" or strict x.y.z' >[1=2]
		exit 1
	}

#
#	HTML reference docs for the current VERSION. Always jsfh against the
#	schema.json written one path above.
#
www/$VERSION/jsfh/index.html: www/$VERSION/schema.json $JSFH_CONFIG
	switch($VERSION) {
	# Always match because VERSION validation is delegated to our prereqs, specifically
	# if www/$VERSION/schema.json exists, we trust our VERSION is valid
	case *
		if(! uv --version >/dev/null >[2=1]) {
			echo 'mk: uv not installed (curl -LsSf https://astral.sh/uv/install.sh | sh)' >[1=2]
			exit 1
		}
		mkdir -p `{dirname $target}
		uv tool run --from json-schema-for-humans generate-schema-doc \
			--config-file $JSFH_CONFIG $prereq(1) $target
	}

#
#	Top-level www/schema.json. Three branches:
#		VERSION=dev + no stable release exists -> track dev.
#		VERSION=dev + at least one stable exists -> do nothing.
#		VERSION=x.y.z -> flip to that version (unconditional; see RELEASING.md
#			for the hotfix edge case).
#
#	The "track" / "flip" actions are both relative symlinks into the per-
#	version tree. rm -f before ln -s makes the rule idempotent on re-runs
#	and lets it replace a previously-committed regular file on first build.
#
www/schema.json: www/$VERSION/schema.json
	switch($VERSION) {
	case dev
		if(~ $#HAVE_STABLE 0) {
			rm -f $target
			ln -s $VERSION/schema.json $target
			echo 'mk: www/schema.json -> dev (no stable release exists)'
		}
		if not {
			echo 'mk: www/schema.json unchanged; stable releases present'
		}
		status=''
	case [0-9]*.[0-9]*.[0-9]*
		rm -f $target
		ln -s $VERSION/schema.json $target
		echo 'mk: www/schema.json -> '^$VERSION
	case *
		echo 'mk: VERSION='^$VERSION^' does not match "dev" or an x.y.z pattern' >[1=2]
		exit 1
	}

#
#	Top-level www/jsfh/. Same publish/freeze logic as www/schema.json,
#	just pointing at a directory (the per-version jsfh/ output tree)
#	instead of a single file. Tracked via the index.html inside it so mk
#	has a concrete file to stat.
#
www/jsfh/index.html: www/$VERSION/jsfh/index.html
	switch($VERSION) {
	case dev
		if(~ $#HAVE_STABLE 0) {
			rm -f www/jsfh
			ln -s $VERSION/jsfh www/jsfh
			echo 'mk: www/jsfh -> dev (no stable release exists)'
		}
		if not {
			echo 'mk: www/jsfh unchanged; stable releases present'
		}
		status=''
	case [0-9]*.[0-9]*.[0-9]*
		rm -f www/jsfh
		ln -s $VERSION/jsfh www/jsfh
		echo 'mk: www/jsfh -> '^$VERSION
	case *
		echo 'mk: VERSION='^$VERSION^' does not match "dev" or an x.y.z pattern' >[1=2]
		exit 1
	}

#
#	Populate the www/ tree for the current VERSION — the schema, the jsfh
#	reference docs, and the top-level www/schema.json + www/jsfh symlinks.
#
www:V: www/$VERSION/schema.json www/$VERSION/jsfh/index.html www/schema.json www/jsfh/index.html

#
#	Serve www/ over HTTP for local testing.
#
serve:V:
	python3 -m http.server --directory www
