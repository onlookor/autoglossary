# autoglossary
This repository is a group of vim scripts for autolabeling glossary terms found in a docbook file, according to a docbook glossary file.
There are 2 vim script: autogloss.vim and constructGlossterms.vim.
The corordination between the two scripts is, constructGlossterms.vim constructs a glossary terms list from a well-formed docbook glossary file when the docbook file being edited loaded into a vim buffer, and then, autogloss.vim labels every word matching any word in the glossary terms list constructed by constructGlossterms.vim, everytime before the docbook file is saved. 
For using the scripts, you need add lines in vim configuration (_vimrc or .vimrc) like that:

au BufRead *.docbk :source constructGlossterms.vim
au BufWritePre *.docbk :source autogloss.vim

The code above assumes the docbook files being edited are named in suffix ".docbk".