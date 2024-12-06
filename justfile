test:
	make test

docs:
	dune build @doc-private
	httplz _build/default/_doc/_html/
