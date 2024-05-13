# Benchmarking shell

## Option 1 - [Hyperfine](https://github.com/sharkdp/hyperfine)
```sh
hyperfine "echo test"
```

## Option 2 - Native

```sh
s=$(date +%s%N) && \
COMMAND_TO_TEST && \
e=$(date +%s%N) && \
perf=$(((e-s)/1000000)) && \
printf "\nTime: $perf ms\n"
```