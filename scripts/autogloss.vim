"Vim for auto embracing glossary term in a DocBook file editing.
"Last Change: Apr. 23th, 2020
"Maintainer: Mark Way <MarkWay@gmail.com>
"License: This file is placed in the public domain.

"如果缓冲区中是一个格式良好的XML文件，且根元素为glossary，则退出执行。b:isGlossary变量应已在constructGlossterms.vim中赋值，若该变量未被赋值，则在此赋值。
try
	if b:isGlossary==1
		finish	
	endif
catch
	normal gg
	let b:isGlossary=search('<?xml.\+>\_s*<glossary\_.\+</glossary>')
	norm \<c-o>
	if b:isGlossary==1
		finish	
	endif
endtry

"如果 constructGlossterms.vim未能在文件载入缓冲区时建立术语集合，则退出执行。
try
	if empty(b:terms)==1	"变量b:terms在脚本constructGlossterms.vim中赋值。
		finish	
	endif
catch
	echo '没有可用的术语词条。'
	finish
endtry

try
	let b:changelist=getchangelist(bufnr("%"))
catch
	finish
endtry

if empty(b:changelist)==1
	finish
else
	let b:changedlinenrlist=map(b:changelist[0],'v:val["lnum"]')
endif

cal uniq(sort(b:changedlinenrlist,'n'))

"let b:changedlines=map(b:changedlinenrlist,'getline(v:val)')
let b:changedlines=map(b:changedlinenrlist,'[v:val,getline(v:val)]')

for b:item in b:changedlines
	let b:linenumber=b:item[0]
	let b:line=b:item[1]
	for term in b:terms
		"以下各正则算法假设parents和children没有交集，假设各XML文档结构良好，符合docbook规范定义。
		"let b:patterns1=map(copy(b:parents),'"<".v:val.">".term."</".v:val.">"')
		"let b:patterns2=map(copy(b:parents),'"<\\(".v:val."\\)[^<>]\\{-}>\\zs".term."\\(<\/".v:val.">\\)\\@!"')
		"let b:patterns3=map(copy(b:parents),'"\\(<\\(".v:val."\\)[^<>]\\{-}>\\)\\@<!".term."\\ze</".v:val.">"')
		"let b:patterns4=map(copy(b:parents),'"\\(<".v:val."[^<>]\\{-}>.\\{-}\\)\\@<=>\\@<!".term."<\\@!\\(.\\{-}</".v:val.">\\)\\@="')
		"下面的模式可以全匹配头接、尾接、头尾不接，且不匹配glossterm子元素内的值，但运行时间超长
		"let b:patterns=map(copy(b:parents),'"\\(<".v:val."[^<>]\\{-}>.\\{-}\\)\\@<=\\(\\(<glossterm[^<>]\\{-}>\\)\\|".b:childrenhead."\\)\\@<!".term."\\(\\(</glossterm>\\)\\|".b:childrentail."\\)\\@!\\(.\\{-}</".v:val.">\\)\\@="')
		"下面的模式可以全匹配头接、尾接、头尾不接，但匹配glossterm子元素内的值，需对子元素另行处理
		let b:patterns=map(copy(b:parents),'"\\(<".v:val."[^<>]\\{-}>.\\{-}\\)\\@<=\\(<glossterm[^<>]\\{-}>\\)\\@<!".term."\\(</glossterm>\\)\\@!\\(.\\{-}</".v:val.">\\)\\@="')
		"let b:subs1=map(copy(b:parents),'"<".v:val."><glossterm>".term."</glossterm></".v:val.">"')
		let b:subs2='<glossterm>'.term.'</glossterm>'
		let b:i=0
		while b:i<len(b:parents)
			"let b:line=substitute(b:line,b:patterns1[b:i],b:subs1[b:i],'g')
			"let b:line=substitute(b:line,b:patterns2[b:i],b:subs2,'g')
			"let b:line=substitute(b:line,b:patterns3[b:i],b:subs2,'g')
			"let b:line=substitute(b:line,b:patterns4[b:i],b:subs2,'g')
			let b:line=substitute(b:line,b:patterns[b:i],b:subs2,'g')
			let b:i=b:i+1
		endwhile
		let b:patterns=map(copy(b:children),'"<".v:val.">".term."</".v:val.">"')
		let b:patterns1=map(copy(b:children),'"<".v:val."><glossterm>".term."</glossterm></".v:val.">"')
		let b:subs=map(copy(b:children),'"<glossterm><".v:val.">".term."</".v:val."></glossterm>"')
		let b:i=0
		while b:i<len(b:children)
			let b:line=substitute(b:line,b:patterns[b:i],b:subs[b:i],'g')
			let b:line=substitute(b:line,b:patterns1[b:i],b:subs[b:i],'g')
			let b:i=b:i+1
		endwhile
		"以下算法假设
		"匹配前面异或后面紧挨
		"let b:line=substitute(b:line,'\(<.\{-}>'.term.'</.\{-}>\)\@!'.term,'<glossterm>'.term.'</glossterm>','g')
	endfor
	call setline(b:linenumber,b:line)
endfor

