#!/bin/bash

test -d ./out_mc_bkg*    && mv -i ./out_mc_bkg*    ../datasets_superNt/mc_bkg/
test -d ./out_fakes*     && mv -i ./out_fakes*     ../datasets_superNt/fakes/
test -d ./out_qflip*     && mv -i ./out_qflip*     ../datasets_superNt/qflip/
test -d ./out_mc_signal* && mv -i ./out_mc_signal* ../datasets_superNt/mc_signal/
test -d ./out_data*      && mv -i ./out_data*      ../datasets_superNt/data/

