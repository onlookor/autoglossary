"Vim script for construct a glossary terms collection in a DocBook file editing.
"Last Change: Apr. 23th, 2020
"Maintainer: Mark Way <MarkWay@gmail.com>
"License: This file is placed in the public domain.

"function s:resolvepath(path)
"	let last=strpart(a:path,strlen(a:path)-1)
"	if last=='\' || last=='/'
"		throw 'Not a file name.'
"	endif
"	let lastsep=strridx(a:path,s:sep)
"	let head=strpart(a:path,0,lastsep)
"	let tail=strpart(a:path,lastsep+1)
"	let found=findfile(tail,head)
"	if found==''
"		throw 'The file '.a:path.' is not found.'
"	endif
"	return [tail,head]
"endfunc
"

"如果缓冲区中是一个格式良好的XML文件，且根元素为glossary，则退出执行
normal gg
let b:isGlossary=search('<?xml.\+>\_s*<glossary\_.\+</glossary>')
exe "norm \<c-o>"
if b:isGlossary==1
	finish	
endif

function! s:collectterms(termslib)
	try
		let glossarylist=readfile(a:termslib[1].s:sep.a:termslib[0])
	catch
		throw 'Failed to read the glossary lib: '.a:termslib[1].s:sep.a:termslib[0]
	endtry
	let glossary=join(glossarylist)
	let glossary=substitute(glossary,'\s','','g')
	let terms=[]
	let i=1
	let term='anything but null'
	while term!=''
		let term=matchstr(glossary,'\(<glossterm>\)\@<=.\{-}\(<\/glossterm>\)\@=',0,i)
		let terms=add(terms,term)
		let i=i+1
	endwhile
	call remove(terms,len(terms)-1)
	return terms
endfunction

function! s:finalize()
	"unlet! s:escape 这个变量没有用到，暂注释
	unlet! s:lib
	unlet! s:targetbuf
	unlet! s:sep
endfunction

"被以下元素包围的文本应忽略
"let s:escape=['glossterm'] 这个变量没有用到，暂注释
"glossterm元素的父元素，见tdg。与tdg相比，此处不包含glossterm元素。如果词条文本被以下元素包围，可以glossterm元素包围词条文本。quote元素与glossterm可互为父子。
let b:parents=['biblioentry','bibliomixed','bibliomset','biblioset','bridgehead','caption','citation','citetitle','classsynopsisinfo','contrib','emphasis','entry','firstterm','foreignphrase','funcsynopsisinfo','glossentry','glosssee','glossseealso','link','literallayout','member','olink','orgdiv','para','phrase','primary','primaryie','programlisting','quote','refdescriptor','refentrytitle','refname','refpurpose','remark','screen','secondary','secondaryie','see','seealso','seealsoie','seeie','seg','segtitle','simpara','subtitle','synopsis','td','term','termdef','tertiary','tertiaryie','th','title','titleabbrev','tocentry']
"glossterm元素的子元素，见tdg。与tdg相比，此处不包含glossterm元素。如果词条文本被以下元素包围，可以glossterm元素包围以下元素。quote元素与glossterm可互为父子。
let b:children=['abbrev','accel','acronym','alt','anchor','annotation','application','author','biblioref','citation','citebiblioid','citerefentry','citetitle','classname','code','command','computeroutput','constant','coref','database','date','editor','email','emphasis','emphasis','envar','errorcode','errorname','errortext','errortype','exceptionname','filename','firstterm','firstterm','footnote','footnoteref','foreignphrase','foreignphrase','function','guibutton','guiicon','guilabel','guimenu','guimenuitem','guisubmenu','hardware','indexterm','indexterm','indexterm','initializer','inlineequation','inlinemediaobject','interfacename','jobtitle','keycap','keycode','keycombo','keysym','link','literal','markup','menuchoice','methodname','modifier','mousebutton','nonterminal','olink','ooclass','ooexception','oointerface','option','optional','org','orgname','package','parameter','person','personname','phrase','phrase','productname','productnumber','prompt','property','quote','remark','replaceable','returnvalue','shortcut','subscript','superscript','symbol','systemitem','tag','termdef','token','trademark','type','uri','userinput','varname','wordasword','xref']

let b:terms=[]

"exists('+shellslash')==1?let s:sep='\':let s:sep='/'
if has('win32') || has('win64')
	let s:sep='\'
elseif has('unix') || has('osx')
	let s:sep='/'
endif

"从缓冲区文件所在目录自底向上寻找docbook glossary文件。
let b:defaultpath=getcwd()
let b:defaultlib='glossary.docbk'

let s:targetbuf=bufnr('%')
let s:lib=[b:defaultlib,b:defaultpath]

cd %:h
let b:parentpath=''
let b:childpath=getcwd()
while b:parentpath!=b:childpath
	"vimgrep %\(<\(\_[^?<>]\)\+>\_s*\)\@!<?xml.\+>\_s*<glossary\_.\+</glossary>%*
	try
		vimgrep %<?xml.\+>\_s*<glossary\_.\+</glossary>%*
	catch
		echo v:errmsg
	endtry
	let b:qf=getqflist()
	if empty(b:qf)
		let b:childpath=b:parentpath
		cd ..
		let b:parentpath=getcwd()
	else
		let s:lib[0]=bufname(b:qf[0].bufnr)
		let s:lib[1]=getcwd()
		break
	endif
endwhile
execute 'buffer '.s:targetbuf
cd %:h

"构建术语词条集合b:terms，该变量用于autogloss.vim脚本。
try
	let b:terms=s:collectterms(s:lib)
catch /Failed to read the glossary lib/
	echo v:exception
finally
	call s:finalize()
endtry

