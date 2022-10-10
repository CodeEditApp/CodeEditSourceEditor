set -eu

# A `realpath` alternative using the default C implementation.
filepath() {
    [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

PACKAGE_ROOT="$(dirname $(dirname $(filepath $0)))"

swift package \
    --allow-writing-to-directory "$PACKAGE_ROOT/docs" \
    generate-documentation \
    --target CodeEditTextView \
    --disable-indexing \
    --output-path "$PACKAGE_ROOT/docs"