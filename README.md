# Overview
This is a falsification tool for black-box model.


## Interface
### Input from users

User is requested to specify the specification ID, algorithm, and repeating times.

- Specification ID: select one or more specification ID from the Column 'Spec' of Table 5 or Table 6.
use '_' for subscript, and '^' for superscript. use semicolon if there are multiple specifications.
e.g.: AT1_1; AT5_5^3

- Algorithm: "Breach", "MAB_e" or "MAB_u".
use semicolon if you want to run multiple algorithms.
e.g.: Breach;MAB_u

- The number of trials.

# Install
## System requirement

- Operating system: Linux or MacOS;

- Matlab version: >= 2017.


## Installation
1. make sure that Matlab directory is in your system path.

Mac OS:  write to ~/.bash_profile 

Linux:  write to ~/.bashrc

'export PATH=$PATH:[your Matlab path]/bin'

and restart the console.

sanity check: type 'matlab' in commandline and you can open Matlab

2. Python 2.7

### Installing Breach

1. Open Matlab;

2. clone Breach from https://github.com/decyphir/breach, and reset it to version 1.2.13. Put it under 'src/' and name it as 'breach_1213'.

3. move to folder “FalStar-MAB/src/breach 1213/” of the cloned repository (either
from command line or using the browsing facilities of the GUI);

4. setup a C/C++ compiler using command ’mex -setup’
– Please check here for instructions on how to select the compiler for different
operating systems: https://www.mathworks.com/help/matlab/matlab_
external/changing-default-compiler.html

5. run ’InstallBreach’

### Installing FalStar-MAB

1. run 'sh Install' or copy the related files manually.

# Usage:
## Reproducing the experiments of the paper
1. Open a terminal;

2. Move to the repository root “FalStar-MAB/”;

3. Run ’./falstar.py’

4. You will be asked to input the specification ID (possibly, more than one), the falsification
tool to use (possibly, more than one), and the number of trials. In the
following, we describe each input in details.

## Adding new models and specifications

1. put the new Simulink model in folder “FalStar-MAB/src/model/”;

2. run the script as ’./falstar.py new’

### Interface
Now, the user will be interactively guided to input some information needed for
initializing the problem:

– name of the Simulink model;

– name(s) of the input signal(s) of the model, separated by semicolon;

– the range(s) of the input signal(s) in format ’lb ub’ (being lb the lower bound
and ub the upper bound), separated by semicolon;

– the value(s) for the model parameter(s) (if any), in format ’p1=v’ (being p1 a
parameter and v a real number);

– an ID for the specification;

– an STL specification, using the format introduced in [Donze CAV'10].

– the total timeout;

– the number of control points that are used to approximate the inputs as piece-wise
constant signals.

