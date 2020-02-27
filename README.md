CLIMADA
=======
MATLAB (R2017a) version of CLIMADA

please use the Python version: https://github.com/CLIMADA-project/climada_python

Follow the [Installation](https://climada-python.readthedocs.io/en/stable/guide/install.html) instructions to install climada's development version and climada's stable version.

The MATLAB version (this repository) is not futher developed neither maintained any more.

First steps
-----------
* Go to the [wiki](../../wiki/Home) and read the [introduction](../../wiki/Home) and find out what _**climada**_ and ECA is. 
* See an [example video](../../wiki/NatCat-modelling#example-hurricane-sidr-affects-bangladesh) of Hurricane Sidr affecting Bangladesh. 
* Are you ready to start adapting? This wiki page helps you to [get started!](../../wiki/Getting-started)  
* Read more on [natural catastrophe modelling](../../wiki/NatCat-modelling) and look at the GUI that we have prepared for you.
* Read the [***climada*** manual (PDF)](/docs/climada_manual.pdf?raw=true).

Additional information
----------------------
climada core module (MATLAB), https://github.com/davidnbresch/climada

This contains the full climada distribution. To get it all in one, click on the "Download ZIP" button on the lower right hand side of github, or just clone this repository. Works both if main folder renamed to 'climada' or left as 'climada-root', just source startup.m in MATLAB and test using climada_demo.

See folder [docs/climada_manual.pdf](https://github.com/davidnbresch/climada/blob/master/docs/climada_manual.pdf?raw=true) to get started. Consider running *compile_all_function_headers* to generate a html file with all the function headers and direct links to the source code of your local installation.

Once you have installed core climada, you might expand its functionality by adding additional modules (see repositories on GitHub under https://github.com/davidnbresch). In order to grant core climada access to additional modules, create a folder 'modules' in the core climada folder and copy/move any additional modules into climada/modules. You can shorten the folder names (i.e. get rid of 'climada_modules' and '-master' in the module folder names, e.g. shorten 'climada_modules_tc_surge-master' to 'tc_surge' - climada parses the content of the modules dir and treats what's in there). You might also create a folder 'parallel' to climada (i.e. in the same folder as the core climada folder) and name it climada_modules to store additional modules, but this special setup is for developer use mainly). Once you've cloned repositories to your desktop, please consider the climada command climada_git_pull_repositories to update your repositories from within climada (saves you keeping track of all repositories and updating each separately).

copyright (c) 2015, 2018, David N. Bresch, david.bresch@gmail.com
all rights reserved.
