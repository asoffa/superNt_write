#!/bin/bash

ls ./out_mc_bkg*    1> /dev/null 2>&1  &&  mv -i ./out_mc_bkg*    ../datasets_superNt/mc_bkg/
ls ./out_mc_signal* 1> /dev/null 2>&1  &&  mv -i ./out_mc_signal* ../datasets_superNt/mc_signal/
ls ./out_data*      1> /dev/null 2>&1  &&  mv -i ./out_data*      ../datasets_superNt/data/

