# shsh
Arrays, Maps & modern syntax for POSIX shells.

### Install
```sh
curl -fsSL https://sh.dawn.day | sh
```

#### Before
```sh
if [ "$x" -le 10 ]; then
  echo "Low"
elif [ "$x" -gt 20 ]; then
  echo "High"
fi

case "$opt" in
  "a") run_a ;;
  *)   exit 1 ;;
esac
```

#### After
```sh
if $x <= 10
  echo "Low"
elif $x > 20
  echo "High"
end

switch $opt
  case "a"
    run_a
  default
    exit 1
end
```

TBD: readme, install, syntax
