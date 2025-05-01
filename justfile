default:
	just --list

# Run the build
build:
	make

# Run all the tests
test:
	find ./tests -type f -name "*.log" -delete
	make test

# List failing regression tests
failing-tests:
	find ./tests -type f -name "*.log" | sed "s/\.log$//"

# Build + serve private docs (does not watch for changes!)
docs:
	dune build @doc-private
	dune build @copy
	httplz _build/default/_doc/_html/

# Watch for changes, build when they happen
watch:
	dune build @@default @check -w
