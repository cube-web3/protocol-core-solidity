coverage:
				@forge coverage --report lcov && genhtml lcov.info --branch-coverage --output-dir coverage

analyze:
				@slither .

.PHONY: coverage