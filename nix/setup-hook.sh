unpackCmdHooks+=(_tryZiptoolsUnzip)
_tryZiptoolsUnzip() {
    if ! [[ "$curSrc" =~ \.zip$ ]]; then return 1; fi

    ziptools unzip "$curSrc"
}
