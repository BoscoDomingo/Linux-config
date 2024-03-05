# Benchmarking shell

```sh
s=$(date +%s%N) && \
COMMAND_TO_TEST && \
e=$(date +%s%N) && \
perf=$(((e-s)/1000000)) && \
printf "\nTime: $perf ms\n"
```