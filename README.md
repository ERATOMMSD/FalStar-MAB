# Overview
This is a falsification tool for black-box model.


## Interface
### Input from users

user is requested to specify the specification ID, algorithm, and repeating times.

- specification ID: select one or more specification ID from the Column 'Spec' of Table 5 or Table 6.
use '_' for subscript, and '^' for superscript. use semicolon if there are multiple specifications.
e.g.: AT1_1; AT5_5^3

- algorithm: "Breach", "MAB_e" or "MAB_u".
use semicolon if you want to run multiple algorithms.
e.g.: Breach;MAB_u

- repeating times: an integer (<= 30).

# Install
## Prepare
1. make sure that Matlab directory is in your system path.
Mac OS:  write to ~/.bash_profile 
Linux:  write to ~/.bashrc

export PATH=$PATH:[your Matlab path]/bin
and restart the console.

sanity check: type 'matlab' in commandline and you can open Matlab

2. Python 2.7

## Install
1. Download the package and unzip it.

2. (Just in case) Install Breach (src/breach_1213/): follow the instructions of Breach
- Setup a C/C++ compiler using mex -setup
- add path to Breach folder 
- Run InstallBreach
- (Optional) save path 

# Usage:
Run './falstar.py' and follow the instructions.

