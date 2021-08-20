#!/bin/bash

# This script prepares data and trains + decodes an ASR system.

# initialization PATH
. ./path.sh  || die "path.sh expected";
# initialization commands
. ./cmd.sh

[ ! -L "steps" ] && ln -s ../../wsj/s5/steps

[ ! -L "utils" ] && ln -s ../../wsj/s5/utils

###############################################################
#                   Configuring the ASR pipeline
###############################################################
stage=0    # from which stage should this script start
nj=4        # number of parallel jobs to run during training
test_nj=2    # number of parallel jobs to run during decoding
# the above two parameters are bounded by the number of speakers in each set
###############################################################
utils/utt2spk_to_spk2utt.pl corpus/data/train/utt2spk > corpus/data/train/spk2utt
utils/utt2spk_to_spk2utt.pl corpus/data/test/utt2spk > corpus/data/test/spk2utt
utils/utt2spk_to_spk2utt.pl corpus/data/truetest/utt2spk > corpus/data/truetest/spk2utt

# Stage 1: Prepares the train/dev data. Prepares the dictionary and the
# language model.
if [ $stage -le 1 ]; then
  echo "Preparing data and training language models"
  local/prepare_data.sh train test
  local/prepare_dict.sh
  utils/prepare_lang.sh data/local/dict "<UNK>" data/local/lang data/lang
  local/prepare_lm.sh
fi

# Feature extraction
# Stage 2: MFCC feature extraction + mean-variance normalization
if [ $stage -le 2 ]; then
   for x in train test; do
      steps/make_mfcc.sh --nj 20 --cmd "$train_cmd" data/$x exp/make_mfcc/$x mfcc
      steps/compute_cmvn_stats.sh data/$x exp/make_mfcc/$x mfcc
   done
fi

#ngram-count -text corpus/LM/train.txt -order 4 -addsmooth 0.001 -lm data/local/tmp/corp_lm4.lm.arpa
#arpa2fst --disambig-symbol=#0 --read-symbol-table=data/lang/words.txt data/local/tmp/corp_lm4.lm.arpa data/lang/G.fst

# Stage 3: Training and decoding monophone acoustic models
if [ $stage -le 3 ]; then
  ### Monophone
    echo "Monophone training"
	steps/train_mono.sh --nj "$nj" --cmd "$train_cmd" data/train data/lang exp/mono
    echo "Monophone training done"
    (
    echo "Decoding the test set"
    utils/mkgraph.sh data/lang exp/mono exp/mono/graph
  
    # This decode command will need to be modified when you 
    # want to use tied-state triphone models 
    steps/decode.sh --nj $test_nj --cmd "$decode_cmd" \
      exp/mono/graph data/test exp/mono/decode_test
    echo "Monophone decoding done."
    ) &
fi

# Stage 4: Training tied-state triphone acoustic models
if [ $stage -le 4 ]; then
  ### Triphone
    echo "Triphone training"
    steps/align_si.sh --nj $nj --cmd "$train_cmd" \
    data/train data/lang exp/mono exp/mono_ali
	steps/train_deltas.sh --boost-silence 1.25  --cmd "$train_cmd"  \
	1000 30000 data/train data/lang exp/mono_ali exp/tri1
    echo "Triphone training done"
	# Add triphone decoding steps here #
	( echo "Decoding the test set"
    utils/mkgraph.sh data/lang exp/tri1 exp/tri1/graph
  
    # This decode command will need to be modified when you 
    # want to use tied-state triphone models 
    steps/decode.sh --nj $test_nj --cmd "$decode_cmd" \
      exp/tri1/graph data/test exp/tri1/decode_test
    echo "Triphone decoding done."
    ) &
fi
# if [ $stage -le 5 ]; then
#  utils/data/perturb_data_dir.sh data/train data/train_sp3
#  #mv  data/train_sp3_speed0.9/* data/train_sp3/
#  for x in train_sp3; do
#       steps/make_mfcc.sh --nj 20 --cmd "$train_cmd" data/$x exp/make_mfcc/$x mfcc
#       steps/compute_cmvn_stats.sh data/$x exp/make_mfcc/$x mfcc
#  done
# steps/train_mono.sh --nj "$nj" --cmd "$train_cmd" data/train_sp3 data/lang exp/mono_sp3
# utils/mkgraph.sh data/lang exp/mono_sp3 exp/mono_sp3/graph  
# steps/align_si.sh --nj $nj --cmd "$train_cmd" \
#   data/train_sp3 data/lang exp/mono_sp3 exp/mono_ali_sp3
# steps/train_deltas.sh --boost-silence 1.25  --cmd "$train_cmd"  \
# 	1000 30000 data/train_sp3 data/lang exp/mono_ali_sp3 exp/tri1_sp3
# echo "Triphone training done"
# 	# Add triphone decoding steps here #
# 	( echo "Decoding the test set"
#     utils/mkgraph.sh data/lang exp/tri1_sp3 exp/tri1_sp3/graph
  
#     # This decode command will need to be modified when you 
#     # want to use tied-state triphone models 
#     steps/decode.sh --nj $test_nj --cmd "$decode_cmd" \
#       exp/tri1_sp3/graph data/test exp/tri1_sp3/decode_test
#     echo "Triphone decoding done."
#     ) &
# fi
wait;
if [ $stage -le 6 ]; then
	
	echo "Task 8"
	mkdir -p data/truetest
	cp corpus/data/truetest/* data/truetest
	steps/make_mfcc.sh --nj 20 --cmd "$train_cmd" data/truetest exp/make_mfcc/truetest mfcc
    steps/compute_cmvn_stats.sh data/truetest exp/make_mfcc/truetest mfcc


	echo "Decoding final test"
    steps/decode.sh --nj $test_nj --cmd "$decode_cmd" \
      exp/tri1/graph data/truetest exp/tri1/decode_truetest

fi

#score
# Computing the best WERs
for x in exp/*/decode*; do [ -d $x ] && grep WER $x/wer_* | utils/best_wer.sh; done
