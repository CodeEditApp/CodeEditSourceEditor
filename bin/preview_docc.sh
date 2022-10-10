set -eu

# A `realpath` alternative using the default C implementation.
filepath() {
    [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

PACKAGE_ROOT="$(dirname $(dirname $(filepath $0)))"

swift package \
    --disable-sandbox \
    preview-documentation \
    --target CodeEditTextView