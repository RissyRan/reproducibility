# Copyright 2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

echo "Running Mixtral 8x7b int8 script"

# Stop execution if any command exits with error
set -e

export EXECUTABLE="train.py"

# Set environment variables
for ARGUMENT in "$@"; do
    IFS='=' read -r KEY VALUE <<< "$ARGUMENT"
    export "$KEY"="$VALUE"
done

# Set up RUN_NAME
if [ -n "$RUN_NAME" ];
then
    export M_RUN_NAME=$RUN_NAME
fi

# Train
export LIBTPU_INIT_ARGS="--xla_tpu_enable_async_collective_fusion_fuse_all_gather=true --xla_tpu_megacore_fusion_allow_ags=false --xla_enable_async_collective_permute=true --xla_tpu_enable_ag_backward_pipelining=true --xla_tpu_enable_data_parallel_all_reduce_opt=true --xla_tpu_data_parallel_opt_different_sized_ops=true --xla_tpu_enable_async_collective_fusion=true --xla_tpu_enable_async_collective_fusion_multiple_steps=true --xla_tpu_overlap_compute_collective_tc=true --xla_enable_async_all_gather=true --xla_tpu_scoped_vmem_limit_kib=81920"
python3 MaxText/$EXECUTABLE MaxText/configs/base.yml\
    model_name=mixtral-8x7b steps=10 per_device_batch_size=8\
    dtype=bfloat16 max_target_length=4096 attention=flash\
    tokenizer_path=assets/tokenizer.mistral-v1 megablox=False\
    profiler=xplane skip_first_n_steps_for_profiler=5\
    dataset_type=synthetic sa_block_q=2048 sa_block_q_dkv=2048 sa_block_q_dq=2048\
    capacity_factor=1.25 quantization=int8
