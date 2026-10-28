#!/usr/bin/env bash
# Loads one model on port 8095, records its memory, runs every check, then stops it.
# usage: run.sh LABEL LLAMA_SERVER MODEL_FILE "SERVER FLAGS" 'BENCH_EXTRA JSON' [IMAGE]
set -u
label=$1 server=$2 model=$3 flags=$4 extra=$5 image=${6:-}
here=$(dirname "$(readlink -f "$0")")
out=${BENCH_OUT:-$here/results}
mkdir -p "$out"
log=$out/$label.server.log
# shellcheck disable=SC2086
$server -m "$model" --port 8095 --no-webui $flags >"$log" 2>&1 &
pid=$!
for _ in $(seq 1 200); do
  grep -qE "listening on|error loading|exiting" "$log" && break
  sleep 3
done
if ! grep -q "listening on" "$log"; then
  echo "$label: failed to load"; grep -E " E " "$log" | head -5; kill $pid 2>/dev/null; exit 1
fi
gpu() { echo $(( ($(cat /sys/class/drm/card1/device/mem_info_gtt_used) + $(cat /sys/class/drm/card1/device/mem_info_vram_used)) / 1024 / 1024 / 1024 )); }
rss=$(( $(ps -o rss= -p $pid) / 1024 / 1024 ))
echo "$label: loaded, GPU ${gpu_before:-$(gpu)} GB, server RSS ${rss} GB, $(free -g | awk '/Mem/{print $7}') GB available"
cd "$out" || exit 1
export BENCH_EXTRA=$extra
python3 -I "$here/bench.py" http://127.0.0.1:8095 m "$label" ${image:+"$image"} | head -3
python3 -I "$here/followup.py" http://127.0.0.1:8095 m "$label" | cut -c1-300
python3 -I "$here/par2.py" http://127.0.0.1:8095 2
echo "$label: peak GPU $(gpu) GB, $(free -g | awk '/Mem/{print $7}') GB available"
kill $pid
wait $pid 2>/dev/null
