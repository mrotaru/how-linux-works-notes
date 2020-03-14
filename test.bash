function f {
    # ls -la;
    cd /;
    return "foo"
}

ret=$(f)
echo $?;
echo \"$ret\";

foo=42
bar=100
echo pre-${foo,bar}-post

echo $(echo foo-$(echo bar))
echo `echo foo`